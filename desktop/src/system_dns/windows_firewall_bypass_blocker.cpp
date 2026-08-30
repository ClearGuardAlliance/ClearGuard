#include "windows_firewall_bypass_blocker.h"

#include <cstdlib>

#include "bypass_resolver_ips.h"

namespace clearguard::system_dns {

namespace {

int runCommand(const std::string &command) {
    return std::system(command.c_str());
}

}

WindowsFirewallBypassBlocker::WindowsFirewallBypassBlocker(std::string ruleNamePrefix)
    : ruleNamePrefix_(std::move(ruleNamePrefix)) {}

bool WindowsFirewallBypassBlocker::isSupported() const {
#ifdef _WIN32
    return runCommand("where netsh > nul 2>&1") == 0;
#else
    return false;
#endif
}

bool WindowsFirewallBypassBlocker::apply() {
    if (applied_) return false;
    if (!isSupported()) return false;

    for (const auto &ip : bypassResolverIps()) {
        runCommand("netsh advfirewall firewall add rule name=\"" + ruleNamePrefix_ +
                    "\" dir=out action=block remoteip=" + ip + " protocol=TCP remoteport=443");
        runCommand("netsh advfirewall firewall add rule name=\"" + ruleNamePrefix_ +
                    "\" dir=out action=block remoteip=" + ip + " protocol=TCP remoteport=853");
        runCommand("netsh advfirewall firewall add rule name=\"" + ruleNamePrefix_ +
                    "\" dir=out action=block remoteip=" + ip + " protocol=UDP remoteport=443");
    }

    applied_ = true;
    return true;
}

bool WindowsFirewallBypassBlocker::restore() {
    if (!applied_) return false;

    runCommand("netsh advfirewall firewall delete rule name=\"" + ruleNamePrefix_ + "\"");

    applied_ = false;
    return true;
}

}
