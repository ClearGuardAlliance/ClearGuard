#include "system_dns_configurator.h"

#include "resolv_conf_configurator.h"

#if defined(__linux__)
#include "systemd_resolved_configurator.h"
#endif

namespace clearguard::system_dns {

bool NullSystemDnsConfigurator::isSupported() const {
    return false;
}

bool NullSystemDnsConfigurator::apply() {
    return false;
}

bool NullSystemDnsConfigurator::restore() {
    return false;
}

std::unique_ptr<SystemDnsConfigurator> createSystemDnsConfigurator() {
#if defined(__linux__)
    auto systemdResolved = std::make_unique<SystemdResolvedConfigurator>();
    if (systemdResolved->isSupported()) return systemdResolved;
    return std::make_unique<ResolvConfConfigurator>();
#elif defined(__FreeBSD__)
    return std::make_unique<ResolvConfConfigurator>();
#else
    return std::make_unique<NullSystemDnsConfigurator>();
#endif
}

}
