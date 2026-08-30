#pragma once

#include <memory>
#include <optional>
#include <string>

#include <QMainWindow>

#include "accountability/accountability_repository.h"
#include "accountability/webhook_notifier.h"
#include "dns/blocklist.h"
#include "dns/dns_filter_server.h"
#include "system_dns/system_dns_configurator.h"

class QCheckBox;
class QComboBox;
class QLabel;
class QLineEdit;
class QPushButton;
class QStackedWidget;
class QTimer;

class MainWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr, std::string storageDirectory = std::string(),
                         clearguard::accountability::WebhookNotifier *notifierOverride = nullptr,
                         std::unique_ptr<clearguard::system_dns::SystemDnsConfigurator> systemDnsOverride = nullptr);
    ~MainWindow() override;

    bool isProtectionRunning() const;
    bool isConfigured() const;
    bool hasPendingDisableRequest() const;
    bool isSystemDnsApplied() const;
    bool isSystemDnsSupported() const;
    clearguard::accountability::AccountabilityRepository &accountabilityRepository();

protected:
    virtual std::optional<std::string> promptForPin();

private slots:
    void onSetupSubmitted();
    void onToggleClicked();
    void onCancelPendingClicked();
    void onOpenSettingsClicked();
    void onBackFromSettingsClicked();
    void onRequestWebhookChangeClicked();
    void onCancelWebhookPendingClicked();
    void onRequestDelayChangeClicked();
    void onCancelDelayPendingClicked();
    void checkPendingActions();

private:
    QWidget *buildSetupPage();
    QWidget *buildMainPage();
    QWidget *buildSettingsPage();
    void refreshMainPage();
    void refreshSettingsPage();
    void stopProtection();

    QStackedWidget *stack;

    QLineEdit *pinEdit;
    QLineEdit *pinConfirmEdit;
    QLineEdit *webhookEdit;
    QLineEdit *partnerEdit;
    QComboBox *delayCombo;
    QLabel *setupErrorLabel;

    QLabel *statusLabel;
    QLabel *pendingLabel;
    QLabel *actionErrorLabel;
    QCheckBox *systemDnsCheckbox;
    QPushButton *toggleButton;
    QPushButton *cancelPendingButton;
    QPushButton *openSettingsButton;

    QLabel *currentWebhookLabel;
    QLineEdit *newWebhookEdit;
    QLabel *webhookPendingLabel;
    QPushButton *cancelWebhookPendingButton;

    QLabel *currentDelayLabel;
    QComboBox *newDelayCombo;
    QLabel *delayPendingLabel;
    QPushButton *cancelDelayPendingButton;

    QLabel *settingsErrorLabel;

    QTimer *pendingActionsTimer;

    clearguard::dns::Blocklist blocklist;
    clearguard::dns::DnsFilterServer server;
    std::unique_ptr<clearguard::system_dns::SystemDnsConfigurator> systemDnsConfigurator;
    bool systemDnsApplied = false;
    clearguard::accountability::HttpWebhookNotifier defaultNotifier;
    clearguard::accountability::WebhookNotifier &notifier;
    std::unique_ptr<clearguard::accountability::AccountabilityRepository> accountability;
    std::optional<std::string> pendingDisableActionId;
    std::optional<std::string> pendingWebhookActionId;
    std::optional<std::string> pendingDelayActionId;
};
