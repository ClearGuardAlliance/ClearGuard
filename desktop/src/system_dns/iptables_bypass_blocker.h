#pragma once

#include <string>

#include "firewall_bypass_blocker.h"

namespace clearguard::system_dns {

class IptablesBypassBlocker : public FirewallBypassBlocker {
public:
    explicit IptablesBypassBlocker(std::string chainName = "CLEARGUARD_BYPASS");

    bool isSupported() const override;
    bool apply() override;
    bool restore() override;

private:
    std::string chainName_;
    bool applied_ = false;
};

}
