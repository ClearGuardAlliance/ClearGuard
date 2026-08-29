#pragma once

#include <chrono>
#include <string>

namespace clearguard::domain {

struct AccountabilityConfig {
    std::string pinHash;
    std::string pinSalt;
    std::string webhookUrl;
    std::string partnerLabel;
    std::chrono::minutes sensitiveActionDelay{30};

    static constexpr std::chrono::minutes defaultDelay() {
        return std::chrono::minutes(30);
    }

    static constexpr std::chrono::minutes minimumDelay() {
        return std::chrono::minutes(15);
    }
};

}
