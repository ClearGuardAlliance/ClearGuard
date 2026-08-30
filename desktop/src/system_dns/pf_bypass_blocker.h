#pragma once

#include <string>

#include "firewall_bypass_blocker.h"

namespace clearguard::system_dns {

class PfBypassBlocker : public FirewallBypassBlocker {
public:
    explicit PfBypassBlocker(std::string anchorName = "clearguard.bypass",
                              std::string rulesFilePath = "/etc/pf.anchors/clearguard.bypass");

    bool isSupported() const override;
    bool apply() override;
    bool restore() override;

private:
    std::string anchorName_;
    std::string rulesFilePath_;
    bool applied_ = false;
};

}
