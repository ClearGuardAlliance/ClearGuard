#include "iptables_bypass_blocker.h"

#include <cstdlib>

#include "bypass_resolver_ips.h"

namespace clearguard::system_dns {

namespace {

int runCommand(const std::string &command) {
    return std::system(command.c_str());
}

}

IptablesBypassBlocker::IptablesBypassBlocker(std::string chainName) : chainName_(std::move(chainName)) {}

bool IptablesBypassBlocker::isSupported() const {
    return runCommand("which iptables > /dev/null 2>&1") == 0;
}

bool IptablesBypassBlocker::apply() {
    if (applied_) return false;
    if (!isSupported()) return false;

    runCommand("iptables -N " + chainName_ + " 2>/dev/null");
    runCommand("iptables -F " + chainName_);
    runCommand("iptables -C OUTPUT -j " + chainName_ + " 2>/dev/null || iptables -I OUTPUT -j " + chainName_);

    for (const auto &ip : bypassResolverIps()) {
        runCommand("iptables -A " + chainName_ + " -d " + ip + " -p tcp --dport 443 -j DROP");
        runCommand("iptables -A " + chainName_ + " -d " + ip + " -p tcp --dport 853 -j DROP");
        runCommand("iptables -A " + chainName_ + " -d " + ip + " -p udp --dport 443 -j DROP");
    }

    applied_ = true;
    return true;
}

bool IptablesBypassBlocker::restore() {
    if (!applied_) return false;

    runCommand("iptables -D OUTPUT -j " + chainName_ + " 2>/dev/null");
    runCommand("iptables -F " + chainName_ + " 2>/dev/null");
    runCommand("iptables -X " + chainName_ + " 2>/dev/null");

    applied_ = false;
    return true;
}

}
