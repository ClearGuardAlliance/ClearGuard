#pragma once

#include <memory>

namespace clearguard::system_dns {

class SystemDnsConfigurator {
public:
    virtual ~SystemDnsConfigurator() = default;
    virtual bool isSupported() const = 0;
    virtual bool apply() = 0;
    virtual bool restore() = 0;
};

class NullSystemDnsConfigurator : public SystemDnsConfigurator {
public:
    bool isSupported() const override;
    bool apply() override;
    bool restore() override;
};

std::unique_ptr<SystemDnsConfigurator> createSystemDnsConfigurator();

}
