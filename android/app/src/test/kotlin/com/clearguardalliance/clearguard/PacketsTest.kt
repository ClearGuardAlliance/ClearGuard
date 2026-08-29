package com.clearguardalliance.clearguard

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

private fun buildQueryMessage(id: Int, domain: String, type: Int = 1, dnsClass: Int = 1): ByteArray {
    val header = ByteArray(12)
    header[0] = (id shr 8).toByte()
    header[1] = (id and 0xFF).toByte()
    header[5] = 1 // QDCOUNT = 1
    val name = DnsNames.encode(domain)
    val typeAndClass = byteArrayOf(
        (type shr 8).toByte(), (type and 0xFF).toByte(),
        (dnsClass shr 8).toByte(), (dnsClass and 0xFF).toByte(),
    )
    return header + name + typeAndClass
}

class PacketsTest {

    @Test
    fun `DnsQuery parses a simple domain name`() {
        val message = buildQueryMessage(id = 0x1234, domain = "example.com")
        val query = DnsQuery.parse(message)

        assertNotNull(query)
        assertEquals(0x1234, query!!.id)
        assertEquals("example.com", query.domainName)
        assertEquals(message.size, query.questionEndOffset)
    }

    @Test
    fun `DnsNames encode round trips through DnsQuery parse`() {
        val message = buildQueryMessage(id = 1, domain = "forcesafesearch.google.com")
        val query = DnsQuery.parse(message)

        assertNotNull(query)
        assertEquals("forcesafesearch.google.com", query!!.domainName)
    }

    @Test
    fun `SafeSearchPolicy matches google search domains but not other google subdomains`() {
        assertEquals("forcesafesearch.google.com", SafeSearchPolicy.enforcedHostFor("google.com"))
        assertEquals("forcesafesearch.google.com", SafeSearchPolicy.enforcedHostFor("www.google.com"))
        assertEquals("forcesafesearch.google.com", SafeSearchPolicy.enforcedHostFor("google.com.br"))
        assertEquals("forcesafesearch.google.com", SafeSearchPolicy.enforcedHostFor("www.google.co.uk"))
        assertNull(SafeSearchPolicy.enforcedHostFor("mail.google.com"))
        assertNull(SafeSearchPolicy.enforcedHostFor("accounts.google.com"))
        assertNull(SafeSearchPolicy.enforcedHostFor("drive.google.com"))
    }

    @Test
    fun `SafeSearchPolicy matches youtube, bing and duckduckgo search domains`() {
        assertEquals("restrict.youtube.com", SafeSearchPolicy.enforcedHostFor("youtube.com"))
        assertEquals("restrict.youtube.com", SafeSearchPolicy.enforcedHostFor("m.youtube.com"))
        assertEquals("strict.bing.com", SafeSearchPolicy.enforcedHostFor("www.bing.com"))
        assertEquals("safe.duckduckgo.com", SafeSearchPolicy.enforcedHostFor("duckduckgo.com"))
        assertNull(SafeSearchPolicy.enforcedHostFor("clearguard.example"))
    }

    @Test
    fun `SafeSearchRewriter rewrites the query name for upstream`() {
        val original = buildQueryMessage(id = 0xABCD, domain = "google.com")
        val query = DnsQuery.parse(original)!!

        val rewritten = SafeSearchRewriter.buildUpstreamQuery(original, query, "forcesafesearch.google.com")
        val rewrittenQuery = DnsQuery.parse(rewritten)!!

        assertEquals(0xABCD, rewrittenQuery.id)
        assertEquals("forcesafesearch.google.com", rewrittenQuery.domainName)
        assertEquals(
            SafeSearchRewriter.rewrittenQuestionLength(query, "forcesafesearch.google.com"),
            rewrittenQuery.questionEndOffset - 12,
        )
    }

    @Test
    fun `SafeSearchRewriter restores the original name in the upstream response`() {
        val original = buildQueryMessage(id = 42, domain = "google.com")
        val query = DnsQuery.parse(original)!!
        val originalQuestion = original.copyOfRange(12, query.questionEndOffset)

        val rewrittenQuestionLength = SafeSearchRewriter.rewrittenQuestionLength(query, "forcesafesearch.google.com")
        val rewrittenName = DnsNames.encode("forcesafesearch.google.com")
        val typeAndClass = original.copyOfRange(query.nameEndOffset, query.questionEndOffset)

        // Simulate an upstream response: header + echoed (rewritten) question + one A answer.
        val header = ByteArray(12)
        header[0] = 0
        header[1] = 42
        header[5] = 1 // QDCOUNT
        header[7] = 1 // ANCOUNT
        val answerIp = byteArrayOf(142.toByte(), 250.toByte(), 1, 1)
        val answer = byteArrayOf(0xC0.toByte(), 0x0C, 0, 1, 0, 1, 0, 0, 0, 60, 0, 4) + answerIp
        val upstreamResponse = header + rewrittenName + typeAndClass + answer

        assertEquals(12 + rewrittenQuestionLength, header.size + rewrittenName.size + typeAndClass.size)

        val restored = SafeSearchRewriter.restoreOriginalName(
            upstreamResponse,
            originalQuestion,
            rewrittenQuestionLength,
        )

        assertNotNull(restored)
        val restoredQuery = DnsQuery.parse(restored!!)!!
        assertEquals("google.com", restoredQuery.domainName)

        // The answer section (with the real resolved IP) must be untouched by the splice.
        val restoredAnswer = restored.copyOfRange(restored.size - answer.size, restored.size)
        assertArrayEquals(answer, restoredAnswer)
    }
}
