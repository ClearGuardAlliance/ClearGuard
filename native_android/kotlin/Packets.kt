package com.clearguard.app

/**
 * Minimal, hand-rolled IPv4 / UDP / DNS parsing and building, just enough
 * to support BlockerVpnService's single job (read a DNS query out of a raw
 * IP packet, answer or forward it, write a DNS response back as a raw IP
 * packet). Not a general-purpose network stack: no IPv6, no TCP, no IP
 * options, no DNS message compression on the parse side.
 */

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

internal data class DnsQuery(val id: Int, val domainName: String, val questionEndOffset: Int) {
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
                // DNS name compression pointers are a response-only concern
                // for us; a query using one is malformed for our purposes.
                if (labelLength and 0xC0 == 0xC0) return null

                offset += 1
                if (offset + labelLength > dnsMessage.size) return null
                if (name.isNotEmpty()) name.append('.')
                name.append(String(dnsMessage, offset, labelLength, Charsets.US_ASCII))
                offset += labelLength
            }

            if (offset + 4 > dnsMessage.size) return null
            val questionEndOffset = offset + 4 // QTYPE + QCLASS

            return DnsQuery(id = id, domainName = name.toString().lowercase(), questionEndOffset = questionEndOffset)
        }
    }
}

internal object DnsResponses {
    /** Synthesizes a response answering the query with 0.0.0.0 (the
     * standard DNS-sinkhole technique), reusing the original question
     * section verbatim and pointing the answer's name at it via a
     * compression pointer. */
    fun sinkhole(dnsMessage: ByteArray, query: DnsQuery): ByteArray {
        val question = dnsMessage.copyOfRange(12, query.questionEndOffset)
        val response = ByteArray(12 + question.size + ANSWER_LENGTH)

        writeUInt16(response, 0, query.id)
        writeUInt16(response, 2, FLAGS_RESPONSE_NO_ERROR)
        writeUInt16(response, 4, 1) // QDCOUNT
        writeUInt16(response, 6, 1) // ANCOUNT
        writeUInt16(response, 8, 0) // NSCOUNT
        writeUInt16(response, 10, 0) // ARCOUNT

        question.copyInto(response, 12)

        var offset = 12 + question.size
        writeUInt16(response, offset, 0xC00C) // pointer to name at byte 12
        offset += 2
        writeUInt16(response, offset, 1) // TYPE A
        offset += 2
        writeUInt16(response, offset, 1) // CLASS IN
        offset += 2
        writeUInt32(response, offset, 60) // TTL
        offset += 4
        writeUInt16(response, offset, 4) // RDLENGTH
        offset += 2
        // RDATA 0.0.0.0, already zero-initialized.

        return response
    }

    private const val FLAGS_RESPONSE_NO_ERROR = 0x8180
    private const val ANSWER_LENGTH = 2 + 2 + 2 + 4 + 2 + 4 // name ptr, type, class, ttl, rdlength, rdata
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

        // --- IPv4 header ---
        packet[0] = ((4 shl 4) or 5).toByte() // version 4, IHL 5 (20 bytes, no options)
        packet[1] = 0 // DSCP/ECN
        writeUInt16(packet, 2, totalLength)
        writeUInt16(packet, 4, 0) // identification
        writeUInt16(packet, 6, 0) // flags/fragment offset
        packet[8] = 64 // TTL
        packet[9] = PROTOCOL_UDP.toByte()
        writeUInt16(packet, 10, 0) // checksum placeholder
        sourceAddress.copyInto(packet, 12)
        destinationAddress.copyInto(packet, 16)
        writeUInt16(packet, 10, ipv4Checksum(packet, 0, IPV4_HEADER_LENGTH))

        // --- UDP header ---
        val udpOffset = IPV4_HEADER_LENGTH
        writeUInt16(packet, udpOffset, sourcePort)
        writeUInt16(packet, udpOffset + 2, destinationPort)
        writeUInt16(packet, udpOffset + 4, udpLength)
        writeUInt16(packet, udpOffset + 6, 0) // checksum disabled, optional over IPv4

        payload.copyInto(packet, udpOffset + UdpHeader.LENGTH)

        return packet
    }

    /** Standard Internet checksum (RFC 791): one's-complement sum of all
     * 16-bit words, computed with the checksum field itself zeroed. */
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
