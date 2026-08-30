#include <QtTest>

#include "dns/dns_message.h"
#include "dns/safe_search.h"

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

class TestSafeSearch : public QObject {
    Q_OBJECT

private slots:
    void matchesGoogleSearchDomainsButNotOtherSubdomains();
    void matchesYoutubeBingAndDuckDuckGo();
    void rewritesTheQueryNameForUpstream();
    void restoresTheOriginalNameInTheUpstreamResponse();
};

void TestSafeSearch::matchesGoogleSearchDomainsButNotOtherSubdomains() {
    QCOMPARE(QString::fromStdString(*enforcedSafeSearchHostFor("google.com")),
              QString("forcesafesearch.google.com"));
    QCOMPARE(QString::fromStdString(*enforcedSafeSearchHostFor("www.google.com")),
              QString("forcesafesearch.google.com"));
    QCOMPARE(QString::fromStdString(*enforcedSafeSearchHostFor("google.com.br")),
              QString("forcesafesearch.google.com"));
    QCOMPARE(QString::fromStdString(*enforcedSafeSearchHostFor("www.google.co.uk")),
              QString("forcesafesearch.google.com"));
    QVERIFY(!enforcedSafeSearchHostFor("mail.google.com").has_value());
    QVERIFY(!enforcedSafeSearchHostFor("accounts.google.com").has_value());
    QVERIFY(!enforcedSafeSearchHostFor("drive.google.com").has_value());
}

void TestSafeSearch::matchesYoutubeBingAndDuckDuckGo() {
    QCOMPARE(QString::fromStdString(*enforcedSafeSearchHostFor("youtube.com")), QString("restrict.youtube.com"));
    QCOMPARE(QString::fromStdString(*enforcedSafeSearchHostFor("m.youtube.com")), QString("restrict.youtube.com"));
    QCOMPARE(QString::fromStdString(*enforcedSafeSearchHostFor("www.bing.com")), QString("strict.bing.com"));
    QCOMPARE(QString::fromStdString(*enforcedSafeSearchHostFor("duckduckgo.com")), QString("safe.duckduckgo.com"));
    QVERIFY(!enforcedSafeSearchHostFor("clearguard.example").has_value());
}

void TestSafeSearch::rewritesTheQueryNameForUpstream() {
    auto original = buildQueryMessage(0xABCD, "google.com");
    auto query = parseQuery(original);
    QVERIFY(query.has_value());

    auto rewritten = buildSafeSearchUpstreamQuery(original, *query, "forcesafesearch.google.com");
    auto rewrittenQuery = parseQuery(rewritten);
    QVERIFY(rewrittenQuery.has_value());

    QCOMPARE(rewrittenQuery->id, 0xABCD);
    QCOMPARE(QString::fromStdString(rewrittenQuery->domainName), QString("forcesafesearch.google.com"));
    QCOMPARE(safeSearchRewrittenQuestionLength(*query, "forcesafesearch.google.com"),
              rewrittenQuery->questionEndOffset - 12);
}

void TestSafeSearch::restoresTheOriginalNameInTheUpstreamResponse() {
    auto original = buildQueryMessage(42, "google.com");
    auto query = parseQuery(original);
    QVERIFY(query.has_value());
    Bytes originalQuestion(original.begin() + 12, original.begin() + static_cast<long>(query->questionEndOffset));

    size_t rewrittenLength = safeSearchRewrittenQuestionLength(*query, "forcesafesearch.google.com");
    Bytes rewrittenName = encodeName("forcesafesearch.google.com");
    Bytes typeAndClass(original.begin() + static_cast<long>(query->nameEndOffset),
                        original.begin() + static_cast<long>(query->questionEndOffset));

    Bytes header(12, 0);
    header[1] = 42;
    header[5] = 1;
    header[7] = 1;
    Bytes answerIp = {142, 250, 1, 1};
    Bytes answer = {0xC0, 0x0C, 0, 1, 0, 1, 0, 0, 0, 60, 0, 4};
    answer.insert(answer.end(), answerIp.begin(), answerIp.end());

    Bytes upstreamResponse;
    upstreamResponse.insert(upstreamResponse.end(), header.begin(), header.end());
    upstreamResponse.insert(upstreamResponse.end(), rewrittenName.begin(), rewrittenName.end());
    upstreamResponse.insert(upstreamResponse.end(), typeAndClass.begin(), typeAndClass.end());
    upstreamResponse.insert(upstreamResponse.end(), answer.begin(), answer.end());

    QCOMPARE(size_t(12) + rewrittenLength, header.size() + rewrittenName.size() + typeAndClass.size());

    auto restored = restoreSafeSearchOriginalName(upstreamResponse, originalQuestion, rewrittenLength);
    QVERIFY(restored.has_value());

    auto restoredQuery = parseQuery(*restored);
    QVERIFY(restoredQuery.has_value());
    QCOMPARE(QString::fromStdString(restoredQuery->domainName), QString("google.com"));

    Bytes restoredAnswer(restored->end() - static_cast<long>(answer.size()), restored->end());
    QCOMPARE(restoredAnswer, answer);
}

QTEST_MAIN(TestSafeSearch)
#include "test_safe_search.moc"
