#pragma once

#include <chrono>
#include <map>
#include <optional>
#include <string>
#include <vector>

#include "domain/accountability_config.h"
#include "domain/pending_action.h"
#include "webhook_notifier.h"

namespace clearguard::accountability {

class AccountabilityRepository {
public:
    AccountabilityRepository(std::string storageDirectory, WebhookNotifier &notifier);

    bool isConfigured() const;
    bool setUpAccountability(const std::string &pin, const std::string &webhookUrl, const std::string &partnerLabel,
                              std::chrono::minutes delay = domain::AccountabilityConfig::defaultDelay());
    std::optional<domain::AccountabilityConfig> loadConfig() const;
    bool verifyPin(const std::string &pin) const;

    domain::PendingAction createPendingAction(domain::PendingActionType type,
                                               std::map<std::string, std::string> payload = {});
    std::vector<domain::PendingAction> loadPendingActions() const;
    bool cancelPendingAction(const std::string &id);
    bool markApplied(const std::string &id);

    bool applyWebhookUrlChange(const std::string &newUrl);
    bool applyDelayChange(std::chrono::minutes newDelay);

private:
    std::string configPath() const;
    std::string pendingActionsPath() const;
    void saveConfig(const domain::AccountabilityConfig &config) const;
    void savePendingActions(const std::vector<domain::PendingAction> &actions) const;
    std::string describeType(domain::PendingActionType type) const;

    std::string storageDirectory_;
    WebhookNotifier &notifier_;
};

}
