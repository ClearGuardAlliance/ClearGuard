#include "accountability_repository.h"

#include <algorithm>

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUuid>

#include "crypto/pin_credentials.h"

namespace clearguard::accountability {

namespace {

qint64 toEpochSeconds(std::chrono::system_clock::time_point point) {
    return std::chrono::duration_cast<std::chrono::seconds>(point.time_since_epoch()).count();
}

std::chrono::system_clock::time_point fromEpochSeconds(qint64 seconds) {
    return std::chrono::system_clock::time_point(std::chrono::seconds(seconds));
}

}

AccountabilityRepository::AccountabilityRepository(std::string storageDirectory, WebhookNotifier &notifier)
    : storageDirectory_(std::move(storageDirectory)), notifier_(notifier) {
    QDir().mkpath(QString::fromStdString(storageDirectory_));
}

std::string AccountabilityRepository::configPath() const {
    return storageDirectory_ + "/accountability_config.json";
}

std::string AccountabilityRepository::pendingActionsPath() const {
    return storageDirectory_ + "/pending_actions.json";
}

bool AccountabilityRepository::isConfigured() const {
    return loadConfig().has_value();
}

std::optional<domain::AccountabilityConfig> AccountabilityRepository::loadConfig() const {
    QFile file(QString::fromStdString(configPath()));
    if (!file.open(QIODevice::ReadOnly)) return std::nullopt;

    auto doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isObject()) return std::nullopt;

    auto obj = doc.object();
    if (!obj.contains("pinHash") || !obj.contains("pinSalt")) return std::nullopt;

    domain::AccountabilityConfig config;
    config.pinHash = obj["pinHash"].toString().toStdString();
    config.pinSalt = obj["pinSalt"].toString().toStdString();
    config.webhookUrl = obj["webhookUrl"].toString().toStdString();
    config.partnerLabel = obj["partnerLabel"].toString().toStdString();
    config.sensitiveActionDelay =
        std::chrono::minutes(obj["delayMinutes"].toInt(static_cast<int>(domain::AccountabilityConfig::defaultDelay().count())));
    return config;
}

void AccountabilityRepository::saveConfig(const domain::AccountabilityConfig &config) const {
    QJsonObject obj;
    obj["pinHash"] = QString::fromStdString(config.pinHash);
    obj["pinSalt"] = QString::fromStdString(config.pinSalt);
    obj["webhookUrl"] = QString::fromStdString(config.webhookUrl);
    obj["partnerLabel"] = QString::fromStdString(config.partnerLabel);
    obj["delayMinutes"] = static_cast<int>(config.sensitiveActionDelay.count());

    QFile file(QString::fromStdString(configPath()));
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) return;
    file.write(QJsonDocument(obj).toJson(QJsonDocument::Indented));
}

bool AccountabilityRepository::setUpAccountability(const std::string &pin, const std::string &webhookUrl,
                                                     const std::string &partnerLabel, std::chrono::minutes delay) {
    domain::AccountabilityConfig config;
    config.pinSalt = crypto::generateSalt();
    config.pinHash = crypto::hashPin(pin, config.pinSalt);
    config.webhookUrl = webhookUrl;
    config.partnerLabel = partnerLabel;
    config.sensitiveActionDelay = delay;

    saveConfig(config);

    notifier_.notify(webhookUrl, "ClearGuard Desktop foi configurado. " + partnerLabel +
                                      " agora recebe avisos de qualquer tentativa de mudar a proteção.");
    return true;
}

bool AccountabilityRepository::verifyPin(const std::string &pin) const {
    auto config = loadConfig();
    if (!config) return false;
    return crypto::verifyPin(pin, config->pinSalt, config->pinHash);
}

std::vector<domain::PendingAction> AccountabilityRepository::loadPendingActions() const {
    QFile file(QString::fromStdString(pendingActionsPath()));
    if (!file.open(QIODevice::ReadOnly)) return {};

    auto doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isObject()) return {};

    std::vector<domain::PendingAction> actions;
    for (const auto &value : doc.object()["actions"].toArray()) {
        auto obj = value.toObject();

        domain::PendingAction action;
        action.id = obj["id"].toString().toStdString();
        action.type = domain::pendingActionTypeFromString(obj["type"].toString().toStdString());
        action.state = domain::pendingActionStateFromString(obj["state"].toString().toStdString());
        action.requestedAt = fromEpochSeconds(obj["requestedAt"].toVariant().toLongLong());
        action.readyAt = fromEpochSeconds(obj["readyAt"].toVariant().toLongLong());

        auto payloadObj = obj["payload"].toObject();
        for (auto it = payloadObj.begin(); it != payloadObj.end(); ++it) {
            action.payload[it.key().toStdString()] = it.value().toString().toStdString();
        }

        actions.push_back(action);
    }
    return actions;
}

void AccountabilityRepository::savePendingActions(const std::vector<domain::PendingAction> &actions) const {
    QJsonArray array;
    for (const auto &action : actions) {
        QJsonObject obj;
        obj["id"] = QString::fromStdString(action.id);
        obj["type"] = QString::fromStdString(domain::toString(action.type));
        obj["state"] = QString::fromStdString(domain::toString(action.state));
        obj["requestedAt"] = toEpochSeconds(action.requestedAt);
        obj["readyAt"] = toEpochSeconds(action.readyAt);

        QJsonObject payloadObj;
        for (const auto &[key, value] : action.payload) {
            payloadObj[QString::fromStdString(key)] = QString::fromStdString(value);
        }
        obj["payload"] = payloadObj;

        array.append(obj);
    }

    QJsonObject root;
    root["actions"] = array;

    QFile file(QString::fromStdString(pendingActionsPath()));
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) return;
    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
}

domain::PendingAction AccountabilityRepository::createPendingAction(domain::PendingActionType type,
                                                                      std::map<std::string, std::string> payload) {
    auto config = loadConfig();
    auto delay = config ? config->sensitiveActionDelay : domain::AccountabilityConfig::defaultDelay();
    auto now = std::chrono::system_clock::now();

    domain::PendingAction action;
    action.id = QUuid::createUuid().toString(QUuid::WithoutBraces).toStdString();
    action.type = type;
    action.requestedAt = now;
    action.readyAt = now + delay;
    action.state = domain::PendingActionState::Pending;
    action.payload = std::move(payload);

    auto actions = loadPendingActions();
    actions.push_back(action);
    savePendingActions(actions);

    if (config) {
        notifier_.notify(config->webhookUrl, "Mudança solicitada: " + describeType(type) + ". Vale em " +
                                                  std::to_string(delay.count()) + " minutos se não for cancelada.");
    }

    return action;
}

bool AccountabilityRepository::cancelPendingAction(const std::string &id) {
    auto actions = loadPendingActions();
    auto it = std::find_if(actions.begin(), actions.end(), [&](const auto &a) { return a.id == id; });
    if (it == actions.end()) return false;

    auto type = it->type;
    actions.erase(it);
    savePendingActions(actions);

    auto config = loadConfig();
    if (config) {
        notifier_.notify(config->webhookUrl, "Solicitação cancelada: " + describeType(type) + ".");
    }
    return true;
}

bool AccountabilityRepository::markApplied(const std::string &id) {
    auto actions = loadPendingActions();
    auto it = std::find_if(actions.begin(), actions.end(), [&](const auto &a) { return a.id == id; });
    if (it == actions.end()) return false;

    it->state = domain::PendingActionState::Applied;
    auto type = it->type;
    savePendingActions(actions);

    auto config = loadConfig();
    if (config) {
        notifier_.notify(config->webhookUrl, "Mudança aplicada: " + describeType(type) + ".");
    }
    return true;
}

bool AccountabilityRepository::applyWebhookUrlChange(const std::string &newUrl) {
    auto config = loadConfig();
    if (!config) return false;
    config->webhookUrl = newUrl;
    saveConfig(*config);
    return true;
}

bool AccountabilityRepository::applyDelayChange(std::chrono::minutes newDelay) {
    auto config = loadConfig();
    if (!config) return false;
    config->sensitiveActionDelay = newDelay;
    saveConfig(*config);
    return true;
}

std::string AccountabilityRepository::describeType(domain::PendingActionType type) const {
    switch (type) {
        case domain::PendingActionType::DisableProtection: return "desativar a proteção";
        case domain::PendingActionType::RemoveBlocklistDomain: return "remover domínio da lista de bloqueio";
        case domain::PendingActionType::ChangeWebhookUrl: return "trocar o webhook";
        case domain::PendingActionType::ChangeRemoteBlocklistUrl: return "trocar a lista remota de bloqueio";
        case domain::PendingActionType::IncreaseSensitiveActionDelay: return "aumentar o tempo de espera";
        case domain::PendingActionType::DecreaseSensitiveActionDelay: return "diminuir o tempo de espera";
    }
    return "ação desconhecida";
}

}
