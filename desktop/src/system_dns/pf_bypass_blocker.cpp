#include "pf_bypass_blocker.h"

#include <cstdio>
#include <cstdlib>
#include <fstream>

#include "bypass_resolver_ips.h"

namespace clearguard::system_dns {

namespace {

int runCommand(const std::string &command) {
    return std::system(command.c_str());
}

}

PfBypassBlocker::PfBypassBlocker(std::string anchorName, std::string rulesFilePath)
    : anchorName_(std::move(anchorName)), rulesFilePath_(std::move(rulesFilePath)) {}

bool PfBypassBlocker::isSupported() const {
    return runCommand("which pfctl > /dev/null 2>&1") == 0;
}

bool PfBypassBlocker::apply() {
    if (applied_) return false;
    if (!isSupported()) return false;

    std::ofstream rulesFile(rulesFilePath_, std::ios::trunc);
    if (!rulesFile.is_open()) return false;

    for (const auto &ip : bypassResolverIps()) {
        rulesFile << "block drop out quick proto tcp from any to " << ip << " port 443\n";
        rulesFile << "block drop out quick proto tcp from any to " << ip << " port 853\n";
        rulesFile << "block drop out quick proto udp from any to " << ip << " port 443\n";
    }
    rulesFile.close();

    int loaded = runCommand("pfctl -a " + anchorName_ + " -f " + rulesFilePath_ + " 2>/dev/null");
    if (loaded != 0) return false;

    applied_ = true;
    return true;
}

bool PfBypassBlocker::restore() {
    if (!applied_) return false;

    runCommand("pfctl -a " + anchorName_ + " -F rules 2>/dev/null");
    std::remove(rulesFilePath_.c_str());

    applied_ = false;
    return true;
}

}
