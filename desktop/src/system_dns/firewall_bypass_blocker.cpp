#include "firewall_bypass_blocker.h"

#include "iptables_bypass_blocker.h"
#include "pf_bypass_blocker.h"
#include "windows_firewall_bypass_blocker.h"

namespace clearguard::system_dns {

bool NullFirewallBypassBlocker::isSupported() const {
    return false;
}

bool NullFirewallBypassBlocker::apply() {
    return false;
}

bool NullFirewallBypassBlocker::restore() {
    return false;
}

std::unique_ptr<FirewallBypassBlocker> createFirewallBypassBlocker() {
#if defined(__linux__)
    auto iptables = std::make_unique<IptablesBypassBlocker>();
    if (iptables->isSupported()) return iptables;
    return std::make_unique<NullFirewallBypassBlocker>();
#elif defined(__APPLE__) || defined(__FreeBSD__)
    auto pf = std::make_unique<PfBypassBlocker>();
    if (pf->isSupported()) return pf;
    return std::make_unique<NullFirewallBypassBlocker>();
#elif defined(_WIN32)
    auto windowsFirewall = std::make_unique<WindowsFirewallBypassBlocker>();
    if (windowsFirewall->isSupported()) return windowsFirewall;
    return std::make_unique<NullFirewallBypassBlocker>();
#else
    return std::make_unique<NullFirewallBypassBlocker>();
#endif
}

}
