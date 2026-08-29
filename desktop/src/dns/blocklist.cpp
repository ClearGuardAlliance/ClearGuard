#include "blocklist.h"

#include <algorithm>
#include <cctype>
#include <fstream>
#include <sstream>

#include "dns_message.h"

namespace clearguard::dns {

namespace {

std::string trim(const std::string &value) {
    size_t start = value.find_first_not_of(" \t\r\n");
    if (start == std::string::npos) return "";
    size_t end = value.find_last_not_of(" \t\r\n");
    return value.substr(start, end - start + 1);
}

}

void Blocklist::setDomains(std::set<std::string> domains) {
    domains_ = std::move(domains);
}

bool Blocklist::loadFromFile(const std::string &path) {
    std::ifstream file(path);
    if (!file.is_open()) return false;

    std::set<std::string> domains;
    std::string line;
    while (std::getline(file, line)) {
        std::string trimmed = trim(line);
        if (trimmed.empty() || trimmed[0] == '#') continue;
        std::transform(trimmed.begin(), trimmed.end(), trimmed.begin(), [](unsigned char c) {
            return static_cast<char>(std::tolower(c));
        });
        domains.insert(trimmed);
    }

    domains_ = std::move(domains);
    return true;
}

void Blocklist::loadDefaults() {
    domains_ = {
        "pornhub.com",
        "xvideos.com",
        "xnxx.com",
        "xhamster.com",
        "redtube.com",
        "youporn.com",
        "onlyfans.com",
        "chaturbate.com",
        "livejasmin.com",
        "brazzers.com",
        "spankbang.com",
    };
}

size_t Blocklist::size() const {
    return domains_.size();
}

bool Blocklist::isBlocked(const std::string &domain) const {
    std::string candidate = domain;
    while (true) {
        if (domains_.count(candidate)) return true;
        auto dot = candidate.find('.');
        if (dot == std::string::npos) return false;
        candidate = candidate.substr(dot + 1);
    }
}

bool Blocklist::isBlockedIncludingProxies(const std::string &domain) const {
    if (isBlocked(domain)) return true;
    auto proxiedTarget = decodeTranslateProxyHost(domain);
    if (!proxiedTarget) return false;
    return isBlocked(*proxiedTarget);
}

}
