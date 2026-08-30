#pragma once

#include <memory>

namespace clearguard::system_dns {

class FirewallBypassBlocker {
public:
    virtual ~FirewallBypassBlocker() = default;
    virtual bool isSupported() const = 0;
    virtual bool apply() = 0;
    virtual bool restore() = 0;
};

class NullFirewallBypassBlocker : public FirewallBypassBlocker {
public:
    bool isSupported() const override;
    bool apply() override;
    bool restore() override;
};

std::unique_ptr<FirewallBypassBlocker> createFirewallBypassBlocker();

}
