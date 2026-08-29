#pragma once

#include <string>

#include "system_dns_configurator.h"

namespace clearguard::system_dns {

class ResolvConfConfigurator : public SystemDnsConfigurator {
public:
    explicit ResolvConfConfigurator(std::string resolvConfPath = "/etc/resolv.conf");

    bool isSupported() const override;
    bool apply() override;
    bool restore() override;

private:
    std::string resolvConfPath_;
    std::string backupPath_;
    bool applied_ = false;
};

}
