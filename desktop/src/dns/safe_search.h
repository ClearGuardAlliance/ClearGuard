#pragma once

#include <optional>
#include <string>

#include "dns_message.h"

namespace clearguard::dns {

std::optional<std::string> enforcedSafeSearchHostFor(const std::string &domain);

Bytes buildSafeSearchUpstreamQuery(const Bytes &message, const DnsQuery &query, const std::string &enforcedHost);
size_t safeSearchRewrittenQuestionLength(const DnsQuery &query, const std::string &enforcedHost);
std::optional<Bytes> restoreSafeSearchOriginalName(const Bytes &upstreamResponse, const Bytes &originalQuestion,
                                                    size_t rewrittenQuestionLength);

}
