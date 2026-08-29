#pragma once

#include <memory>
#include <optional>
#include <string>

#include <QMainWindow>

#include "accountability/accountability_repository.h"
#include "accountability/webhook_notifier.h"
#include "dns/blocklist.h"
#include "dns/dns_filter_server.h"

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
                         clearguard::accountability::WebhookNotifier *notifierOverride = nullptr);
    ~MainWindow() override;

    bool isProtectionRunning() const;
    bool isConfigured() const;
    bool hasPendingDisableRequest() const;
    clearguard::accountability::AccountabilityRepository &accountabilityRepository();

protected:
    virtual std::optional<std::string> promptForPin();

private slots:
    void onSetupSubmitted();
    void onToggleClicked();
    void onCancelPendingClicked();
    void checkPendingActions();

private:
    QWidget *buildSetupPage();
    QWidget *buildMainPage();
    void refreshMainPage();

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
    QPushButton *toggleButton;
    QPushButton *cancelPendingButton;

    QTimer *pendingActionsTimer;

    clearguard::dns::Blocklist blocklist;
    clearguard::dns::DnsFilterServer server;
    clearguard::accountability::HttpWebhookNotifier defaultNotifier;
    clearguard::accountability::WebhookNotifier &notifier;
    std::unique_ptr<clearguard::accountability::AccountabilityRepository> accountability;
    std::optional<std::string> pendingDisableActionId;
};
