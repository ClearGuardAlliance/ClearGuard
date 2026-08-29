#pragma once

#include <set>
#include <string>

namespace clearguard::dns {

class Blocklist {
public:
    void setDomains(std::set<std::string> domains);
    bool loadFromFile(const std::string &path);
    void loadDefaults();
    bool isBlocked(const std::string &domain) const;
    bool isBlockedIncludingProxies(const std::string &domain) const;
    size_t size() const;

private:
    std::set<std::string> domains_;
};

}
