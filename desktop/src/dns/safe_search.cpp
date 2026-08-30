#include "safe_search.h"

namespace clearguard::dns {

namespace {

constexpr const char *kGoogleSearch = "forcesafesearch.google.com";
constexpr const char *kYoutube = "restrict.youtube.com";
constexpr const char *kBing = "strict.bing.com";
constexpr const char *kDuckDuckGo = "safe.duckduckgo.com";

bool startsWith(const std::string &value, const std::string &prefix) {
    return value.size() >= prefix.size() && value.compare(0, prefix.size(), prefix) == 0;
}

}

std::optional<std::string> enforcedSafeSearchHostFor(const std::string &domain) {
    if (domain == "google.com") return kGoogleSearch;
    if (startsWith(domain, "www.google.")) return kGoogleSearch;
    if (startsWith(domain, "google.")) return kGoogleSearch;
    if (domain == "youtube.com" || domain == "www.youtube.com" || domain == "m.youtube.com") return kYoutube;
    if (domain == "bing.com" || domain == "www.bing.com") return kBing;
    if (domain == "duckduckgo.com" || domain == "www.duckduckgo.com") return kDuckDuckGo;
    return std::nullopt;
}

Bytes buildSafeSearchUpstreamQuery(const Bytes &message, const DnsQuery &query, const std::string &enforcedHost) {
    Bytes header(message.begin(), message.begin() + 12);
    Bytes encodedName = encodeName(enforcedHost);
    Bytes qtypeAndClass(message.begin() + static_cast<long>(query.nameEndOffset),
                         message.begin() + static_cast<long>(query.questionEndOffset));
    Bytes tail(message.begin() + static_cast<long>(query.questionEndOffset), message.end());

    Bytes rewritten;
    rewritten.insert(rewritten.end(), header.begin(), header.end());
    rewritten.insert(rewritten.end(), encodedName.begin(), encodedName.end());
    rewritten.insert(rewritten.end(), qtypeAndClass.begin(), qtypeAndClass.end());
    rewritten.insert(rewritten.end(), tail.begin(), tail.end());
    return rewritten;
}

size_t safeSearchRewrittenQuestionLength(const DnsQuery &query, const std::string &enforcedHost) {
    return encodeName(enforcedHost).size() + (query.questionEndOffset - query.nameEndOffset);
}

std::optional<Bytes> restoreSafeSearchOriginalName(const Bytes &upstreamResponse, const Bytes &originalQuestion,
                                                    size_t rewrittenQuestionLength) {
    size_t responseQuestionEnd = 12 + rewrittenQuestionLength;
    if (upstreamResponse.size() < responseQuestionEnd) return std::nullopt;

    Bytes header(upstreamResponse.begin(), upstreamResponse.begin() + 12);
    Bytes tail(upstreamResponse.begin() + static_cast<long>(responseQuestionEnd), upstreamResponse.end());

    Bytes restored;
    restored.insert(restored.end(), header.begin(), header.end());
    restored.insert(restored.end(), originalQuestion.begin(), originalQuestion.end());
    restored.insert(restored.end(), tail.begin(), tail.end());
    return restored;
}

}
