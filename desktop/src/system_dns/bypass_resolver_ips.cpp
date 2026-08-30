#include "bypass_resolver_ips.h"

namespace clearguard::system_dns {

const std::vector<std::string> &bypassResolverIps() {
    static const std::vector<std::string> ips = {
        "1.1.1.1",
        "1.0.0.1",
        "8.8.8.8",
        "8.8.4.4",
        "9.9.9.9",
        "149.112.112.112",
        "208.67.222.222",
        "208.67.220.220",
        "94.140.14.14",
        "94.140.15.15",
        "185.222.222.222",
        "45.11.45.11",
    };
    return ips;
}

}
