#pragma once

#include <chrono>
#include <map>
#include <string>

namespace clearguard::domain {

enum class PendingActionType {
    DisableProtection,
    RemoveBlocklistDomain,
    ChangeWebhookUrl,
    ChangeRemoteBlocklistUrl,
    IncreaseSensitiveActionDelay,
    DecreaseSensitiveActionDelay,
};

enum class PendingActionState {
    Pending,
    Applied,
    Cancelled,
};

struct PendingAction {
    std::string id;
    PendingActionType type = PendingActionType::DisableProtection;
    std::chrono::system_clock::time_point requestedAt;
    std::chrono::system_clock::time_point readyAt;
    PendingActionState state = PendingActionState::Pending;
    std::map<std::string, std::string> payload;

    bool isReadyToApply() const;
    std::chrono::seconds timeRemaining() const;
};

std::string toString(PendingActionType type);
PendingActionType pendingActionTypeFromString(const std::string &value);
std::string toString(PendingActionState state);
PendingActionState pendingActionStateFromString(const std::string &value);

}
