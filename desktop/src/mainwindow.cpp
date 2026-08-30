#include "mainwindow.h"

#include <algorithm>

#include <QCheckBox>
#include <QComboBox>
#include <QInputDialog>
#include <QLabel>
#include <QLineEdit>
#include <QPushButton>
#include <QStackedWidget>
#include <QStandardPaths>
#include <QTimer>
#include <QVBoxLayout>

using namespace clearguard::dns;
using namespace clearguard::accountability;
using namespace clearguard::domain;
using namespace clearguard::system_dns;

MainWindow::MainWindow(QWidget *parent, std::string storageDirectory, WebhookNotifier *notifierOverride,
                        std::unique_ptr<SystemDnsConfigurator> systemDnsOverride,
                        std::unique_ptr<FirewallBypassBlocker> firewallBypassOverride)
    : QMainWindow(parent), notifier(notifierOverride ? *notifierOverride : defaultNotifier) {
    setWindowTitle("ClearGuard Desktop");
    resize(480, 420);

    if (storageDirectory.empty()) {
        storageDirectory = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation).toStdString();
    }
    accountability = std::make_unique<AccountabilityRepository>(storageDirectory, notifier);

    systemDnsConfigurator =
        systemDnsOverride ? std::move(systemDnsOverride) : createSystemDnsConfigurator();
    firewallBypassBlocker =
        firewallBypassOverride ? std::move(firewallBypassOverride) : createFirewallBypassBlocker();

    blocklist.loadDefaults();

    stack = new QStackedWidget(this);
    stack->addWidget(buildSetupPage());
    stack->addWidget(buildMainPage());
    stack->addWidget(buildSettingsPage());
    setCentralWidget(stack);

    stack->setCurrentIndex(isConfigured() ? 1 : 0);
    refreshMainPage();

    pendingActionsTimer = new QTimer(this);
    connect(pendingActionsTimer, &QTimer::timeout, this, &MainWindow::checkPendingActions);
    pendingActionsTimer->start(2000);
}

MainWindow::~MainWindow() {
    stopProtection();
}

void MainWindow::stopProtection() {
    server.stop();
    if (systemDnsApplied) {
        systemDnsConfigurator->restore();
        systemDnsApplied = false;
    }
    if (firewallBypassApplied) {
        firewallBypassBlocker->restore();
        firewallBypassApplied = false;
    }
}

QWidget *MainWindow::buildSetupPage() {
    auto *page = new QWidget();
    auto *layout = new QVBoxLayout(page);

    auto *title = new QLabel("Set up ClearGuard");
    title->setStyleSheet("font-size: 18px; font-weight: bold;");

    auto *explanation = new QLabel(
        "The PIN and webhook below should belong to your accountability partner, not you. "
        "Any attempt to weaken protection later notifies them and waits out a delay before it "
        "takes effect.");
    explanation->setWordWrap(true);

    pinEdit = new QLineEdit();
    pinEdit->setEchoMode(QLineEdit::Password);
    pinEdit->setPlaceholderText("PIN (6+ digits)");

    pinConfirmEdit = new QLineEdit();
    pinConfirmEdit->setEchoMode(QLineEdit::Password);
    pinConfirmEdit->setPlaceholderText("Confirm PIN");

    webhookEdit = new QLineEdit();
    webhookEdit->setPlaceholderText("Partner webhook URL (Discord/Slack)");

    partnerEdit = new QLineEdit();
    partnerEdit->setPlaceholderText("Partner name");

    delayCombo = new QComboBox();
    delayCombo->addItem("15 minutes", 15);
    delayCombo->addItem("30 minutes", 30);
    delayCombo->addItem("60 minutes", 60);
    delayCombo->addItem("120 minutes", 120);
    delayCombo->setCurrentIndex(1);

    setupErrorLabel = new QLabel();
    setupErrorLabel->setStyleSheet("color: #c0392b;");

    auto *submitButton = new QPushButton("Continue");
    connect(submitButton, &QPushButton::clicked, this, &MainWindow::onSetupSubmitted);

    layout->addWidget(title);
    layout->addWidget(explanation);
    layout->addWidget(pinEdit);
    layout->addWidget(pinConfirmEdit);
    layout->addWidget(webhookEdit);
    layout->addWidget(partnerEdit);
    layout->addWidget(delayCombo);
    layout->addWidget(setupErrorLabel);
    layout->addWidget(submitButton);
    layout->addStretch();

    return page;
}

QWidget *MainWindow::buildMainPage() {
    auto *page = new QWidget();
    auto *layout = new QVBoxLayout(page);
    layout->setAlignment(Qt::AlignCenter);

    statusLabel = new QLabel();
    statusLabel->setAlignment(Qt::AlignCenter);

    pendingLabel = new QLabel();
    pendingLabel->setAlignment(Qt::AlignCenter);
    pendingLabel->setWordWrap(true);
    pendingLabel->setVisible(false);

    actionErrorLabel = new QLabel();
    actionErrorLabel->setAlignment(Qt::AlignCenter);
    actionErrorLabel->setStyleSheet("color: #c0392b;");
    actionErrorLabel->setWordWrap(true);
    actionErrorLabel->setVisible(false);

    systemDnsCheckbox = new QCheckBox("Also redirect system DNS (needs admin/root privileges)");
    systemDnsCheckbox->setObjectName("systemDnsCheckbox");
    systemDnsCheckbox->setEnabled(systemDnsConfigurator->isSupported());
    if (!systemDnsConfigurator->isSupported()) {
        systemDnsCheckbox->setToolTip("Not supported yet on this platform.");
    }

    firewallBypassCheckbox =
        new QCheckBox("Also block known DNS-over-HTTPS/TLS bypass resolvers (needs admin/root privileges)");
    firewallBypassCheckbox->setObjectName("firewallBypassCheckbox");
    firewallBypassCheckbox->setEnabled(firewallBypassBlocker->isSupported());
    if (!firewallBypassBlocker->isSupported()) {
        firewallBypassCheckbox->setToolTip("Not supported yet on this platform.");
    }

    toggleButton = new QPushButton();
    connect(toggleButton, &QPushButton::clicked, this, &MainWindow::onToggleClicked);

    cancelPendingButton = new QPushButton("Cancel request");
    cancelPendingButton->setVisible(false);
    connect(cancelPendingButton, &QPushButton::clicked, this, &MainWindow::onCancelPendingClicked);

    openSettingsButton = new QPushButton("Settings");
    connect(openSettingsButton, &QPushButton::clicked, this, &MainWindow::onOpenSettingsClicked);

    layout->addWidget(statusLabel);
    layout->addWidget(pendingLabel);
    layout->addWidget(actionErrorLabel);
    layout->addWidget(systemDnsCheckbox);
    layout->addWidget(firewallBypassCheckbox);
    layout->addWidget(toggleButton);
    layout->addWidget(cancelPendingButton);
    layout->addWidget(openSettingsButton);

    return page;
}

QWidget *MainWindow::buildSettingsPage() {
    auto *page = new QWidget();
    auto *layout = new QVBoxLayout(page);

    auto *backButton = new QPushButton("Back");
    connect(backButton, &QPushButton::clicked, this, &MainWindow::onBackFromSettingsClicked);

    auto *webhookTitle = new QLabel("Accountability webhook");
    webhookTitle->setStyleSheet("font-weight: bold;");

    currentWebhookLabel = new QLabel();

    newWebhookEdit = new QLineEdit();
    newWebhookEdit->setObjectName("newWebhookEdit");
    newWebhookEdit->setPlaceholderText("New webhook URL");

    auto *requestWebhookButton = new QPushButton("Request webhook change");
    connect(requestWebhookButton, &QPushButton::clicked, this, &MainWindow::onRequestWebhookChangeClicked);

    webhookPendingLabel = new QLabel();
    webhookPendingLabel->setWordWrap(true);
    webhookPendingLabel->setVisible(false);

    cancelWebhookPendingButton = new QPushButton("Cancel webhook change");
    cancelWebhookPendingButton->setVisible(false);
    connect(cancelWebhookPendingButton, &QPushButton::clicked, this, &MainWindow::onCancelWebhookPendingClicked);

    auto *delayTitle = new QLabel("Delay before changes apply");
    delayTitle->setStyleSheet("font-weight: bold;");

    currentDelayLabel = new QLabel();

    newDelayCombo = new QComboBox();
    newDelayCombo->setObjectName("newDelayCombo");
    newDelayCombo->addItem("15 minutes", 15);
    newDelayCombo->addItem("30 minutes", 30);
    newDelayCombo->addItem("60 minutes", 60);
    newDelayCombo->addItem("120 minutes", 120);

    auto *requestDelayButton = new QPushButton("Request delay change");
    connect(requestDelayButton, &QPushButton::clicked, this, &MainWindow::onRequestDelayChangeClicked);

    delayPendingLabel = new QLabel();
    delayPendingLabel->setWordWrap(true);
    delayPendingLabel->setVisible(false);

    cancelDelayPendingButton = new QPushButton("Cancel delay change");
    cancelDelayPendingButton->setVisible(false);
    connect(cancelDelayPendingButton, &QPushButton::clicked, this, &MainWindow::onCancelDelayPendingClicked);

    settingsErrorLabel = new QLabel();
    settingsErrorLabel->setStyleSheet("color: #c0392b;");
    settingsErrorLabel->setVisible(false);

    layout->addWidget(backButton);
    layout->addWidget(webhookTitle);
    layout->addWidget(currentWebhookLabel);
    layout->addWidget(newWebhookEdit);
    layout->addWidget(requestWebhookButton);
    layout->addWidget(webhookPendingLabel);
    layout->addWidget(cancelWebhookPendingButton);
    layout->addWidget(delayTitle);
    layout->addWidget(currentDelayLabel);
    layout->addWidget(newDelayCombo);
    layout->addWidget(requestDelayButton);
    layout->addWidget(delayPendingLabel);
    layout->addWidget(cancelDelayPendingButton);
    layout->addWidget(settingsErrorLabel);
    layout->addStretch();

    return page;
}

bool MainWindow::isProtectionRunning() const {
    return server.status() == ServerStatus::Running;
}

bool MainWindow::isConfigured() const {
    return accountability->isConfigured();
}

bool MainWindow::hasPendingDisableRequest() const {
    return pendingDisableActionId.has_value();
}

bool MainWindow::isSystemDnsApplied() const {
    return systemDnsApplied;
}

bool MainWindow::isSystemDnsSupported() const {
    return systemDnsConfigurator->isSupported();
}

bool MainWindow::isFirewallBypassBlockApplied() const {
    return firewallBypassApplied;
}

bool MainWindow::isFirewallBypassBlockSupported() const {
    return firewallBypassBlocker->isSupported();
}

AccountabilityRepository &MainWindow::accountabilityRepository() {
    return *accountability;
}

std::optional<std::string> MainWindow::promptForPin() {
    bool ok = false;
    QString pin = QInputDialog::getText(this, "Confirm with PIN", "Accountability PIN", QLineEdit::Password,
                                         QString(), &ok);
    if (!ok || pin.isEmpty()) return std::nullopt;
    return pin.toStdString();
}

void MainWindow::onSetupSubmitted() {
    setupErrorLabel->setText("");
    QString pin = pinEdit->text();
    QString confirm = pinConfirmEdit->text();

    if (pin.length() < 6) {
        setupErrorLabel->setText("PIN must be at least 6 digits.");
        return;
    }
    if (pin != confirm) {
        setupErrorLabel->setText("PINs do not match.");
        return;
    }

    int delayMinutes = delayCombo->currentData().toInt();
    std::string partnerLabel = partnerEdit->text().isEmpty() ? "Partner" : partnerEdit->text().toStdString();

    accountability->setUpAccountability(pin.toStdString(), webhookEdit->text().toStdString(), partnerLabel,
                                         std::chrono::minutes(delayMinutes));

    refreshMainPage();
    stack->setCurrentIndex(1);
}

void MainWindow::onToggleClicked() {
    actionErrorLabel->setVisible(false);

    if (!isProtectionRunning()) {
        bool wantsSystemDns = systemDnsCheckbox->isChecked();
        uint16_t port = wantsSystemDns ? 53 : 0;

        if (!server.start(blocklist, port, "208.67.222.123", 53)) {
            actionErrorLabel->setText(wantsSystemDns
                                           ? "Could not bind port 53 — try running as administrator/root, "
                                             "or turn off system DNS redirect."
                                           : "Could not start the protection server.");
            actionErrorLabel->setVisible(true);
            refreshMainPage();
            return;
        }

        if (wantsSystemDns) {
            systemDnsApplied = systemDnsConfigurator->apply();
            if (!systemDnsApplied) {
                actionErrorLabel->setText(
                    "Filter is running, but the system DNS redirect failed (needs admin/root "
                    "privileges). Point your network's DNS to 127.0.0.1 manually for full protection.");
                actionErrorLabel->setVisible(true);
            }
        }

        if (firewallBypassCheckbox->isChecked()) {
            firewallBypassApplied = firewallBypassBlocker->apply();
            if (!firewallBypassApplied) {
                actionErrorLabel->setText(
                    "Filter is running, but blocking DNS-over-HTTPS/TLS bypass resolvers failed "
                    "(needs admin/root privileges).");
                actionErrorLabel->setVisible(true);
            }
        }

        refreshMainPage();
        return;
    }

    if (hasPendingDisableRequest()) return;

    auto pin = promptForPin();
    if (!pin) return;

    if (!accountability->verifyPin(*pin)) {
        actionErrorLabel->setText("Incorrect PIN.");
        actionErrorLabel->setVisible(true);
        return;
    }

    auto action = accountability->createPendingAction(PendingActionType::DisableProtection);
    pendingDisableActionId = action.id;
    refreshMainPage();
}

void MainWindow::onCancelPendingClicked() {
    if (!pendingDisableActionId) return;
    accountability->cancelPendingAction(*pendingDisableActionId);
    pendingDisableActionId.reset();
    refreshMainPage();
}

void MainWindow::onOpenSettingsClicked() {
    refreshSettingsPage();
    stack->setCurrentIndex(2);
}

void MainWindow::onBackFromSettingsClicked() {
    stack->setCurrentIndex(1);
}

void MainWindow::onRequestWebhookChangeClicked() {
    settingsErrorLabel->setVisible(false);
    QString newUrl = newWebhookEdit->text();
    if (newUrl.isEmpty() || pendingWebhookActionId) return;

    auto pin = promptForPin();
    if (!pin) return;

    if (!accountability->verifyPin(*pin)) {
        settingsErrorLabel->setText("Incorrect PIN.");
        settingsErrorLabel->setVisible(true);
        return;
    }

    auto action =
        accountability->createPendingAction(PendingActionType::ChangeWebhookUrl, {{"newUrl", newUrl.toStdString()}});
    pendingWebhookActionId = action.id;
    refreshSettingsPage();
}

void MainWindow::onCancelWebhookPendingClicked() {
    if (!pendingWebhookActionId) return;
    accountability->cancelPendingAction(*pendingWebhookActionId);
    pendingWebhookActionId.reset();
    refreshSettingsPage();
}

void MainWindow::onRequestDelayChangeClicked() {
    settingsErrorLabel->setVisible(false);
    if (pendingDelayActionId) return;

    int newMinutes = newDelayCombo->currentData().toInt();

    auto pin = promptForPin();
    if (!pin) return;

    if (!accountability->verifyPin(*pin)) {
        settingsErrorLabel->setText("Incorrect PIN.");
        settingsErrorLabel->setVisible(true);
        return;
    }

    auto config = accountability->loadConfig();
    int currentMinutes = config ? static_cast<int>(config->sensitiveActionDelay.count())
                                 : static_cast<int>(AccountabilityConfig::defaultDelay().count());
    auto type = newMinutes >= currentMinutes ? PendingActionType::IncreaseSensitiveActionDelay
                                              : PendingActionType::DecreaseSensitiveActionDelay;

    auto action =
        accountability->createPendingAction(type, {{"newDelayMinutes", std::to_string(newMinutes)}});
    pendingDelayActionId = action.id;
    refreshSettingsPage();
}

void MainWindow::onCancelDelayPendingClicked() {
    if (!pendingDelayActionId) return;
    accountability->cancelPendingAction(*pendingDelayActionId);
    pendingDelayActionId.reset();
    refreshSettingsPage();
}

void MainWindow::checkPendingActions() {
    if (!isConfigured()) return;

    auto actions = accountability->loadPendingActions();
    for (const auto &action : actions) {
        if (action.state != PendingActionState::Pending || !action.isReadyToApply()) continue;

        switch (action.type) {
            case PendingActionType::DisableProtection:
                stopProtection();
                accountability->markApplied(action.id);
                break;
            case PendingActionType::ChangeWebhookUrl: {
                auto payloadIt = action.payload.find("newUrl");
                if (payloadIt != action.payload.end()) accountability->applyWebhookUrlChange(payloadIt->second);
                accountability->markApplied(action.id);
                break;
            }
            case PendingActionType::IncreaseSensitiveActionDelay:
            case PendingActionType::DecreaseSensitiveActionDelay: {
                auto payloadIt = action.payload.find("newDelayMinutes");
                if (payloadIt != action.payload.end()) {
                    accountability->applyDelayChange(std::chrono::minutes(std::stoi(payloadIt->second)));
                }
                accountability->markApplied(action.id);
                break;
            }
            case PendingActionType::RemoveBlocklistDomain:
            case PendingActionType::ChangeRemoteBlocklistUrl:
                break;
        }
    }

    auto refreshed = accountability->loadPendingActions();
    auto disableIt = std::find_if(refreshed.begin(), refreshed.end(), [](const auto &a) {
        return a.type == PendingActionType::DisableProtection && a.state == PendingActionState::Pending;
    });
    pendingDisableActionId = disableIt != refreshed.end() ? std::optional<std::string>(disableIt->id) : std::nullopt;

    refreshMainPage();
    refreshSettingsPage();
}

void MainWindow::refreshMainPage() {
    if (isProtectionRunning()) {
        statusLabel->setText(QString("Protection running on 127.0.0.1:%1 (%2 domains blocked)")
                                  .arg(server.boundPort())
                                  .arg(blocklist.size()));
    } else {
        statusLabel->setText(QString("Protection stopped (%1 domains loaded)").arg(blocklist.size()));
    }

    if (pendingDisableActionId) {
        auto actions = accountability->loadPendingActions();
        auto it = std::find_if(actions.begin(), actions.end(),
                                [&](const auto &a) { return a.id == *pendingDisableActionId; });
        if (it != actions.end()) {
            auto remaining = std::chrono::duration_cast<std::chrono::minutes>(it->timeRemaining());
            pendingLabel->setText(
                QString("Stop requested — takes effect in %1 min unless cancelled.").arg(remaining.count()));
            pendingLabel->setVisible(true);
            cancelPendingButton->setVisible(true);
            toggleButton->setEnabled(false);
            return;
        }
    }

    pendingLabel->setVisible(false);
    cancelPendingButton->setVisible(false);
    toggleButton->setEnabled(true);
    toggleButton->setText(isProtectionRunning() ? "Request stop protection" : "Start protection");
}

void MainWindow::refreshSettingsPage() {
    auto config = accountability->loadConfig();

    currentWebhookLabel->setText(config ? QString("Current: %1").arg(QString::fromStdString(config->webhookUrl))
                                         : QString("Current: (not set)"));
    currentDelayLabel->setText(
        QString("Current: %1 minutes")
            .arg(config ? config->sensitiveActionDelay.count() : AccountabilityConfig::defaultDelay().count()));

    auto actions = accountability->loadPendingActions();

    auto webhookIt = std::find_if(actions.begin(), actions.end(), [](const auto &a) {
        return a.type == PendingActionType::ChangeWebhookUrl && a.state == PendingActionState::Pending;
    });
    if (webhookIt != actions.end()) {
        pendingWebhookActionId = webhookIt->id;
        auto remaining = std::chrono::duration_cast<std::chrono::minutes>(webhookIt->timeRemaining());
        webhookPendingLabel->setText(QString("Change pending — takes effect in %1 min.").arg(remaining.count()));
        webhookPendingLabel->setVisible(true);
        cancelWebhookPendingButton->setVisible(true);
    } else {
        pendingWebhookActionId.reset();
        webhookPendingLabel->setVisible(false);
        cancelWebhookPendingButton->setVisible(false);
    }

    auto delayIt = std::find_if(actions.begin(), actions.end(), [](const auto &a) {
        return (a.type == PendingActionType::IncreaseSensitiveActionDelay ||
                a.type == PendingActionType::DecreaseSensitiveActionDelay) &&
               a.state == PendingActionState::Pending;
    });
    if (delayIt != actions.end()) {
        pendingDelayActionId = delayIt->id;
        auto remaining = std::chrono::duration_cast<std::chrono::minutes>(delayIt->timeRemaining());
        delayPendingLabel->setText(QString("Change pending — takes effect in %1 min.").arg(remaining.count()));
        delayPendingLabel->setVisible(true);
        cancelDelayPendingButton->setVisible(true);
    } else {
        pendingDelayActionId.reset();
        delayPendingLabel->setVisible(false);
        cancelDelayPendingButton->setVisible(false);
    }
}
