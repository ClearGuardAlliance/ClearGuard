#include "pending_action.h"

#include <algorithm>
#include <stdexcept>

namespace clearguard::domain {

bool PendingAction::isReadyToApply() const {
    return state == PendingActionState::Pending && std::chrono::system_clock::now() >= readyAt;
}

std::chrono::seconds PendingAction::timeRemaining() const {
    auto remaining = std::chrono::duration_cast<std::chrono::seconds>(readyAt - std::chrono::system_clock::now());
    return std::max(remaining, std::chrono::seconds::zero());
}

std::string toString(PendingActionType type) {
    switch (type) {
        case PendingActionType::DisableProtection: return "disableProtection";
        case PendingActionType::RemoveBlocklistDomain: return "removeBlocklistDomain";
        case PendingActionType::ChangeWebhookUrl: return "changeWebhookUrl";
        case PendingActionType::ChangeRemoteBlocklistUrl: return "changeRemoteBlocklistUrl";
        case PendingActionType::IncreaseSensitiveActionDelay: return "increaseSensitiveActionDelay";
        case PendingActionType::DecreaseSensitiveActionDelay: return "decreaseSensitiveActionDelay";
    }
    throw std::invalid_argument("Unknown PendingActionType");
}

PendingActionType pendingActionTypeFromString(const std::string &value) {
    if (value == "disableProtection") return PendingActionType::DisableProtection;
    if (value == "removeBlocklistDomain") return PendingActionType::RemoveBlocklistDomain;
    if (value == "changeWebhookUrl") return PendingActionType::ChangeWebhookUrl;
    if (value == "changeRemoteBlocklistUrl") return PendingActionType::ChangeRemoteBlocklistUrl;
    if (value == "increaseSensitiveActionDelay") return PendingActionType::IncreaseSensitiveActionDelay;
    if (value == "decreaseSensitiveActionDelay") return PendingActionType::DecreaseSensitiveActionDelay;
    throw std::invalid_argument("Unknown PendingActionType: " + value);
}

std::string toString(PendingActionState state) {
    switch (state) {
        case PendingActionState::Pending: return "pending";
        case PendingActionState::Applied: return "applied";
        case PendingActionState::Cancelled: return "cancelled";
    }
    throw std::invalid_argument("Unknown PendingActionState");
}

PendingActionState pendingActionStateFromString(const std::string &value) {
    if (value == "pending") return PendingActionState::Pending;
    if (value == "applied") return PendingActionState::Applied;
    if (value == "cancelled") return PendingActionState::Cancelled;
    throw std::invalid_argument("Unknown PendingActionState: " + value);
}

}
