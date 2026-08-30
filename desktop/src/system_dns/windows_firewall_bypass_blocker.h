#pragma once

#include <string>

#include "firewall_bypass_blocker.h"

namespace clearguard::system_dns {

class WindowsFirewallBypassBlocker : public FirewallBypassBlocker {
public:
    explicit WindowsFirewallBypassBlocker(std::string ruleNamePrefix = "ClearGuard Bypass Block");

    bool isSupported() const override;
    bool apply() override;
    bool restore() override;

private:
    std::string ruleNamePrefix_;
    bool applied_ = false;
};

}
