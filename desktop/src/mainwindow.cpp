#include "mainwindow.h"

#include <algorithm>

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

MainWindow::MainWindow(QWidget *parent, std::string storageDirectory, WebhookNotifier *notifierOverride)
    : QMainWindow(parent), notifier(notifierOverride ? *notifierOverride : defaultNotifier) {
    setWindowTitle("ClearGuard Desktop");
    resize(480, 420);

    if (storageDirectory.empty()) {
        storageDirectory = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation).toStdString();
    }
    accountability = std::make_unique<AccountabilityRepository>(storageDirectory, notifier);

    blocklist.loadDefaults();

    stack = new QStackedWidget(this);
    stack->addWidget(buildSetupPage());
    stack->addWidget(buildMainPage());
    setCentralWidget(stack);

    stack->setCurrentIndex(isConfigured() ? 1 : 0);
    refreshMainPage();

    pendingActionsTimer = new QTimer(this);
    connect(pendingActionsTimer, &QTimer::timeout, this, &MainWindow::checkPendingActions);
    pendingActionsTimer->start(2000);
}

MainWindow::~MainWindow() {
    server.stop();
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
    actionErrorLabel->setVisible(false);

    toggleButton = new QPushButton();
    connect(toggleButton, &QPushButton::clicked, this, &MainWindow::onToggleClicked);

    cancelPendingButton = new QPushButton("Cancel request");
    cancelPendingButton->setVisible(false);
    connect(cancelPendingButton, &QPushButton::clicked, this, &MainWindow::onCancelPendingClicked);

    layout->addWidget(statusLabel);
    layout->addWidget(pendingLabel);
    layout->addWidget(actionErrorLabel);
    layout->addWidget(toggleButton);
    layout->addWidget(cancelPendingButton);

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
        server.start(blocklist, 0, "208.67.222.123", 53);
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

void MainWindow::checkPendingActions() {
    if (!isConfigured()) return;

    auto actions = accountability->loadPendingActions();
    auto it = std::find_if(actions.begin(), actions.end(), [](const auto &a) {
        return a.type == PendingActionType::DisableProtection && a.state == PendingActionState::Pending;
    });

    if (it == actions.end()) {
        pendingDisableActionId.reset();
        refreshMainPage();
        return;
    }

    pendingDisableActionId = it->id;

    if (it->isReadyToApply()) {
        server.stop();
        accountability->markApplied(it->id);
        pendingDisableActionId.reset();
    }

    refreshMainPage();
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
