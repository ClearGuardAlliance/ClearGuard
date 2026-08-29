#include <QtTest>

#include "dns/blocklist.h"
#include "dns/dns_message.h"

using namespace clearguard::dns;

namespace {

Bytes buildQueryMessage(uint16_t id, const std::string &domain, uint16_t type = 1, uint16_t dnsClass = 1) {
    Bytes header(12, 0);
    header[0] = static_cast<uint8_t>(id >> 8);
    header[1] = static_cast<uint8_t>(id & 0xFF);
    header[5] = 1;

    Bytes name = encodeName(domain);
    Bytes typeAndClass = {
        static_cast<uint8_t>(type >> 8), static_cast<uint8_t>(type & 0xFF),
        static_cast<uint8_t>(dnsClass >> 8), static_cast<uint8_t>(dnsClass & 0xFF),
    };

    Bytes message;
    message.insert(message.end(), header.begin(), header.end());
    message.insert(message.end(), name.begin(), name.end());
    message.insert(message.end(), typeAndClass.begin(), typeAndClass.end());
    return message;
}

}

class TestDnsMessage : public QObject {
    Q_OBJECT

private slots:
    void parsesSimpleDomainName();
    void encodeRoundTripsThroughParse();
    void sinkholeResponseAnswersWithZeroIp();
    void translateProxyDecodesPlainDomain();
    void translateProxyDecodesLiteralDashes();
    void translateProxyReturnsNulloptForNonProxyDomains();
    void blocklistMatchesExactAndSubdomains();
    void blocklistCatchesTranslateProxyBypass();
};

void TestDnsMessage::parsesSimpleDomainName() {
    auto message = buildQueryMessage(0x1234, "example.com");
    auto query = parseQuery(message);

    QVERIFY(query.has_value());
    QCOMPARE(query->id, 0x1234);
    QCOMPARE(QString::fromStdString(query->domainName), QString("example.com"));
    QCOMPARE(query->questionEndOffset, message.size());
}

void TestDnsMessage::encodeRoundTripsThroughParse() {
    auto message = buildQueryMessage(1, "forcesafesearch.google.com");
    auto query = parseQuery(message);

    QVERIFY(query.has_value());
    QCOMPARE(QString::fromStdString(query->domainName), QString("forcesafesearch.google.com"));
}

void TestDnsMessage::sinkholeResponseAnswersWithZeroIp() {
    auto message = buildQueryMessage(42, "pornhub.com");
    auto query = parseQuery(message);
    QVERIFY(query.has_value());

    auto response = buildSinkholeResponse(message, *query);
    auto reparsed = parseQuery(response);

    QVERIFY(reparsed.has_value());
    QCOMPARE(reparsed->id, 42);
    QCOMPARE(QString::fromStdString(reparsed->domainName), QString("pornhub.com"));

    Bytes rdata(response.end() - 4, response.end());
    QCOMPARE(rdata, Bytes({0, 0, 0, 0}));
}

void TestDnsMessage::translateProxyDecodesPlainDomain() {
    auto decoded = decodeTranslateProxyHost("pornhub-com.translate.goog");
    QVERIFY(decoded.has_value());
    QCOMPARE(QString::fromStdString(*decoded), QString("pornhub.com"));
}

void TestDnsMessage::translateProxyDecodesLiteralDashes() {
    auto decoded = decodeTranslateProxyHost("my--site-com.translate.goog");
    QVERIFY(decoded.has_value());
    QCOMPARE(QString::fromStdString(*decoded), QString("my-site.com"));
}

void TestDnsMessage::translateProxyReturnsNulloptForNonProxyDomains() {
    QVERIFY(!decodeTranslateProxyHost("pornhub.com").has_value());
    QVERIFY(!decodeTranslateProxyHost("translate.goog").has_value());
    QVERIFY(!decodeTranslateProxyHost(".translate.goog").has_value());
}

void TestDnsMessage::blocklistMatchesExactAndSubdomains() {
    Blocklist blocklist;
    blocklist.setDomains({"pornhub.com"});

    QVERIFY(blocklist.isBlocked("pornhub.com"));
    QVERIFY(blocklist.isBlocked("www.pornhub.com"));
    QVERIFY(!blocklist.isBlocked("notpornhub.com"));
    QVERIFY(!blocklist.isBlocked("example.com"));
}

void TestDnsMessage::blocklistCatchesTranslateProxyBypass() {
    Blocklist blocklist;
    blocklist.setDomains({"pornhub.com"});

    QVERIFY(blocklist.isBlockedIncludingProxies("pornhub-com.translate.goog"));
    QVERIFY(!blocklist.isBlockedIncludingProxies("example-com.translate.goog"));
}

QTEST_MAIN(TestDnsMessage)
#include "test_dns_message.moc"
