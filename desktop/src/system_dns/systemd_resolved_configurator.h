#pragma once

#include <string>

#include "system_dns_configurator.h"

namespace clearguard::system_dns {

class SystemdResolvedConfigurator : public SystemDnsConfigurator {
public:
    explicit SystemdResolvedConfigurator(
        std::string dropInPath = "/etc/systemd/resolved.conf.d/clearguard.conf",
        std::string resolvConfSymlinkPath = "/etc/resolv.conf");

    bool isSupported() const override;
    bool apply() override;
    bool restore() override;

private:
    std::string dropInPath_;
    std::string resolvConfSymlinkPath_;
    bool applied_ = false;
};

}
