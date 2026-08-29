package com.clearguardalliance.clearguard

internal data class Ipv4Header(
    val headerLength: Int,
    val protocol: Int,
    val sourceAddress: ByteArray,
    val destinationAddress: ByteArray,
) {
    companion object {
        private const val MIN_HEADER_LENGTH = 20

        fun parse(packet: ByteArray): Ipv4Header? {
            if (packet.size < MIN_HEADER_LENGTH) return null
            val versionAndIhl = packet[0].toInt() and 0xFF
            val version = versionAndIhl shr 4
            if (version != 4) return null

            val headerLength = (versionAndIhl and 0x0F) * 4
            if (headerLength < MIN_HEADER_LENGTH || packet.size < headerLength) return null

            return Ipv4Header(
                headerLength = headerLength,
                protocol = packet[9].toInt() and 0xFF,
                sourceAddress = packet.copyOfRange(12, 16),
                destinationAddress = packet.copyOfRange(16, 20),
            )
        }
    }
}

internal data class UdpHeader(val sourcePort: Int, val destinationPort: Int) {
    companion object {
        const val LENGTH = 8

        fun parse(packet: ByteArray, offset: Int): UdpHeader? {
            if (packet.size < offset + LENGTH) return null
            return UdpHeader(
                sourcePort = readUInt16(packet, offset),
                destinationPort = readUInt16(packet, offset + 2),
            )
        }
    }
}

internal data class DnsQuery(
    val id: Int,
    val domainName: String,
    val nameEndOffset: Int,
    val questionEndOffset: Int,
) {
    companion object {
        private const val HEADER_LENGTH = 12
        private const val MAX_LABEL_HOPS = 128

        fun parse(dnsMessage: ByteArray): DnsQuery? {
            if (dnsMessage.size < HEADER_LENGTH + 5) return null

            val id = readUInt16(dnsMessage, 0)
            val questionCount = readUInt16(dnsMessage, 4)
            if (questionCount < 1) return null

            val name = StringBuilder()
            var offset = HEADER_LENGTH
            var hops = 0

            while (offset < dnsMessage.size) {
                hops++
                if (hops > MAX_LABEL_HOPS) return null

                val labelLength = dnsMessage[offset].toInt() and 0xFF
                if (labelLength == 0) {
                    offset += 1
                    break
                }

                if (labelLength and 0xC0 == 0xC0) return null

                offset += 1
                if (offset + labelLength > dnsMessage.size) return null
                if (name.isNotEmpty()) name.append('.')
                name.append(String(dnsMessage, offset, labelLength, Charsets.US_ASCII))
                offset += labelLength
            }

            if (offset + 4 > dnsMessage.size) return null
            val nameEndOffset = offset
            val questionEndOffset = offset + 4

            return DnsQuery(
                id = id,
                domainName = name.toString().lowercase(),
                nameEndOffset = nameEndOffset,
                questionEndOffset = questionEndOffset,
            )
        }
    }
}

internal object DnsNames {
    fun encode(domain: String): ByteArray {
        val labels = domain.split('.').filter { it.isNotEmpty() }
        val size = labels.sumOf { it.length + 1 } + 1
        val encoded = ByteArray(size)
        var offset = 0
        for (label in labels) {
            val bytes = label.toByteArray(Charsets.US_ASCII)
            encoded[offset] = bytes.size.toByte()
            offset += 1
            bytes.copyInto(encoded, offset)
            offset += bytes.size
        }
        encoded[offset] = 0
        return encoded
    }
}

internal object SafeSearchRewriter {
    fun buildUpstreamQuery(dnsMessage: ByteArray, query: DnsQuery, enforcedHost: String): ByteArray {
        val header = dnsMessage.copyOfRange(0, 12)
        val encodedName = DnsNames.encode(enforcedHost)
        val qtypeAndClass = dnsMessage.copyOfRange(query.nameEndOffset, query.questionEndOffset)
        val tail = dnsMessage.copyOfRange(query.questionEndOffset, dnsMessage.size)
        return header + encodedName + qtypeAndClass + tail
    }

    fun rewrittenQuestionLength(query: DnsQuery, enforcedHost: String): Int {
        return DnsNames.encode(enforcedHost).size + (query.questionEndOffset - query.nameEndOffset)
    }

    fun restoreOriginalName(
        upstreamResponse: ByteArray,
        originalQuestion: ByteArray,
        rewrittenQuestionLength: Int,
    ): ByteArray? {
        val responseQuestionEnd = 12 + rewrittenQuestionLength
        if (upstreamResponse.size < responseQuestionEnd) return null
        val header = upstreamResponse.copyOfRange(0, 12)
        val tail = upstreamResponse.copyOfRange(responseQuestionEnd, upstreamResponse.size)
        return header + originalQuestion + tail
    }
}

internal object SafeSearchPolicy {
    fun enforcedHostFor(domain: String): String? {
        return when {
            domain == "google.com" -> GOOGLE_SEARCH
            domain.startsWith("www.google.") -> GOOGLE_SEARCH
            domain.startsWith("google.") -> GOOGLE_SEARCH
            domain == "youtube.com" || domain == "www.youtube.com" || domain == "m.youtube.com" -> YOUTUBE
            domain == "bing.com" || domain == "www.bing.com" -> BING
            domain == "duckduckgo.com" || domain == "www.duckduckgo.com" -> DUCKDUCKGO
            else -> null
        }
    }

    private const val GOOGLE_SEARCH = "forcesafesearch.google.com"
    private const val YOUTUBE = "restrict.youtube.com"
    private const val BING = "strict.bing.com"
    private const val DUCKDUCKGO = "safe.duckduckgo.com"
}

internal object DnsResponses {
    fun sinkhole(dnsMessage: ByteArray, query: DnsQuery): ByteArray {
        val question = dnsMessage.copyOfRange(12, query.questionEndOffset)
        val response = ByteArray(12 + question.size + ANSWER_LENGTH)

        writeUInt16(response, 0, query.id)
        writeUInt16(response, 2, FLAGS_RESPONSE_NO_ERROR)
        writeUInt16(response, 4, 1)
        writeUInt16(response, 6, 1)
        writeUInt16(response, 8, 0)
        writeUInt16(response, 10, 0)

        question.copyInto(response, 12)

        var offset = 12 + question.size
        writeUInt16(response, offset, 0xC00C)
        offset += 2
        writeUInt16(response, offset, 1)
        offset += 2
        writeUInt16(response, offset, 1)
        offset += 2
        writeUInt32(response, offset, 60)
        offset += 4
        writeUInt16(response, offset, 4)
        offset += 2

        return response
    }

    private const val FLAGS_RESPONSE_NO_ERROR = 0x8180
    private const val ANSWER_LENGTH = 2 + 2 + 2 + 4 + 2 + 4
}

internal object PacketBuilder {
    private const val IPV4_HEADER_LENGTH = 20
    private const val PROTOCOL_UDP = 17

    fun buildIpv4Udp(
        sourceAddress: ByteArray,
        sourcePort: Int,
        destinationAddress: ByteArray,
        destinationPort: Int,
        payload: ByteArray,
    ): ByteArray {
        val udpLength = UdpHeader.LENGTH + payload.size
        val totalLength = IPV4_HEADER_LENGTH + udpLength
        val packet = ByteArray(totalLength)

        packet[0] = ((4 shl 4) or 5).toByte()
        packet[1] = 0
        writeUInt16(packet, 2, totalLength)
        writeUInt16(packet, 4, 0)
        writeUInt16(packet, 6, 0)
        packet[8] = 64
        packet[9] = PROTOCOL_UDP.toByte()
        writeUInt16(packet, 10, 0)
        sourceAddress.copyInto(packet, 12)
        destinationAddress.copyInto(packet, 16)
        writeUInt16(packet, 10, ipv4Checksum(packet, 0, IPV4_HEADER_LENGTH))

        val udpOffset = IPV4_HEADER_LENGTH
        writeUInt16(packet, udpOffset, sourcePort)
        writeUInt16(packet, udpOffset + 2, destinationPort)
        writeUInt16(packet, udpOffset + 4, udpLength)
        writeUInt16(packet, udpOffset + 6, 0)

        payload.copyInto(packet, udpOffset + UdpHeader.LENGTH)

        return packet
    }

    private fun ipv4Checksum(packet: ByteArray, offset: Int, length: Int): Int {
        var sum = 0
        var i = offset
        while (i < offset + length) {
            val word = (readUInt8(packet, i) shl 8) or readUInt8(packet, i + 1)
            sum += word
            i += 2
        }
        while (sum shr 16 != 0) {
            sum = (sum and 0xFFFF) + (sum shr 16)
        }
        return sum.inv() and 0xFFFF
    }
}

private fun readUInt8(bytes: ByteArray, offset: Int): Int = bytes[offset].toInt() and 0xFF

private fun readUInt16(bytes: ByteArray, offset: Int): Int {
    return ((bytes[offset].toInt() and 0xFF) shl 8) or (bytes[offset + 1].toInt() and 0xFF)
}

private fun writeUInt16(bytes: ByteArray, offset: Int, value: Int) {
    bytes[offset] = ((value shr 8) and 0xFF).toByte()
    bytes[offset + 1] = (value and 0xFF).toByte()
}

private fun writeUInt32(bytes: ByteArray, offset: Int, value: Int) {
    bytes[offset] = ((value shr 24) and 0xFF).toByte()
    bytes[offset + 1] = ((value shr 16) and 0xFF).toByte()
    bytes[offset + 2] = ((value shr 8) and 0xFF).toByte()
    bytes[offset + 3] = (value and 0xFF).toByte()
}
