#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace clearguard::dns {

using Bytes = std::vector<uint8_t>;

struct DnsQuery {
    uint16_t id = 0;
    std::string domainName;
    size_t nameEndOffset = 0;
    size_t questionEndOffset = 0;
};

std::optional<DnsQuery> parseQuery(const Bytes &message);
Bytes encodeName(const std::string &domain);
Bytes buildSinkholeResponse(const Bytes &message, const DnsQuery &query);
std::optional<std::string> decodeTranslateProxyHost(const std::string &domain);

}
