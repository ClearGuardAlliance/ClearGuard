#include <QtTest>
#include <QComboBox>
#include <QLineEdit>
#include <QTemporaryDir>

#include "mainwindow.h"

namespace {

class TestableMainWindow : public MainWindow {
public:
    explicit TestableMainWindow(std::string storageDirectory)
        : MainWindow(nullptr, std::move(storageDirectory), &nullNotifier) {}

    std::optional<std::string> fixedPin;

private:
    clearguard::accountability::NullWebhookNotifier nullNotifier;

protected:
    std::optional<std::string> promptForPin() override {
        return fixedPin;
    }
};

}

class TestMainWindow : public QObject {
    Q_OBJECT

private slots:
    void startsUnconfigured();
    void startingProtectionDoesNotRequireConfiguration();
    void requestingStopWithWrongPinDoesNothing();
    void requestingStopWithCorrectPinCreatesPendingAction();
    void cancellingPendingRequestKeepsProtectionRunning();
    void pendingRequestAppliesOnceDelayElapses();
    void requestingWebhookChangeWithWrongPinDoesNothing();
    void requestingWebhookChangeAppliesOnceDelayElapses();
    void cancellingWebhookChangeLeavesOriginalUrl();
    void requestingDelayChangePicksIncreaseWhenRaisingDelay();
    void requestingDelayChangePicksDecreaseWhenLoweringDelay();
    void requestingDelayChangeAppliesOnceDelayElapses();
};

void TestMainWindow::startsUnconfigured() {
    QTemporaryDir dir;
    MainWindow window(nullptr, dir.path().toStdString());
    QVERIFY(!window.isConfigured());
}

void TestMainWindow::startingProtectionDoesNotRequireConfiguration() {
    QTemporaryDir dir;
    MainWindow window(nullptr, dir.path().toStdString());

    QVERIFY(!window.isProtectionRunning());
    QMetaObject::invokeMethod(&window, "onToggleClicked");
    QVERIFY(window.isProtectionRunning());
}

void TestMainWindow::requestingStopWithWrongPinDoesNothing() {
    QTemporaryDir dir;
    TestableMainWindow window(dir.path().toStdString());
    window.accountabilityRepository().setUpAccountability("123456", "https://example.com/webhook", "Ana",
                                                            std::chrono::minutes(30));

    QMetaObject::invokeMethod(&window, "onToggleClicked");
    QVERIFY(window.isProtectionRunning());

    window.fixedPin = "000000";
    QMetaObject::invokeMethod(&window, "onToggleClicked");

    QVERIFY(window.isProtectionRunning());
    QVERIFY(!window.hasPendingDisableRequest());
}

void TestMainWindow::requestingStopWithCorrectPinCreatesPendingAction() {
    QTemporaryDir dir;
    TestableMainWindow window(dir.path().toStdString());
    window.accountabilityRepository().setUpAccountability("123456", "https://example.com/webhook", "Ana",
                                                            std::chrono::minutes(30));

    QMetaObject::invokeMethod(&window, "onToggleClicked");
    QVERIFY(window.isProtectionRunning());

    window.fixedPin = "123456";
    QMetaObject::invokeMethod(&window, "onToggleClicked");

    QVERIFY(window.hasPendingDisableRequest());
    QVERIFY(window.isProtectionRunning());
}

void TestMainWindow::cancellingPendingRequestKeepsProtectionRunning() {
    QTemporaryDir dir;
    TestableMainWindow window(dir.path().toStdString());
    window.accountabilityRepository().setUpAccountability("123456", "https://example.com/webhook", "Ana",
                                                            std::chrono::minutes(30));

    QMetaObject::invokeMethod(&window, "onToggleClicked");
    window.fixedPin = "123456";
    QMetaObject::invokeMethod(&window, "onToggleClicked");
    QVERIFY(window.hasPendingDisableRequest());

    QMetaObject::invokeMethod(&window, "onCancelPendingClicked");

    QVERIFY(!window.hasPendingDisableRequest());
    QVERIFY(window.isProtectionRunning());
}

void TestMainWindow::pendingRequestAppliesOnceDelayElapses() {
    QTemporaryDir dir;
    TestableMainWindow window(dir.path().toStdString());
    window.accountabilityRepository().setUpAccountability("123456", "https://example.com/webhook", "Ana",
                                                            std::chrono::minutes(0));

    QMetaObject::invokeMethod(&window, "onToggleClicked");
    window.fixedPin = "123456";
    QMetaObject::invokeMethod(&window, "onToggleClicked");
    QVERIFY(window.hasPendingDisableRequest());

    QMetaObject::invokeMethod(&window, "checkPendingActions");

    QVERIFY(!window.hasPendingDisableRequest());
    QVERIFY(!window.isProtectionRunning());
}

void TestMainWindow::requestingWebhookChangeWithWrongPinDoesNothing() {
    QTemporaryDir dir;
    TestableMainWindow window(dir.path().toStdString());
    window.accountabilityRepository().setUpAccountability("123456", "https://example.com/webhook", "Ana",
                                                            std::chrono::minutes(30));

    auto *webhookEdit = window.findChild<QLineEdit *>("newWebhookEdit");
    QVERIFY(webhookEdit);
    webhookEdit->setText("https://example.com/new-webhook");

    window.fixedPin = "000000";
    QMetaObject::invokeMethod(&window, "onRequestWebhookChangeClicked");

    QVERIFY(window.accountabilityRepository().loadPendingActions().empty());
}

void TestMainWindow::requestingWebhookChangeAppliesOnceDelayElapses() {
    QTemporaryDir dir;
    TestableMainWindow window(dir.path().toStdString());
    window.accountabilityRepository().setUpAccountability("123456", "https://example.com/webhook", "Ana",
                                                            std::chrono::minutes(0));

    auto *webhookEdit = window.findChild<QLineEdit *>("newWebhookEdit");
    QVERIFY(webhookEdit);
    webhookEdit->setText("https://example.com/new-webhook");

    window.fixedPin = "123456";
    QMetaObject::invokeMethod(&window, "onRequestWebhookChangeClicked");

    auto pendingBefore = window.accountabilityRepository().loadPendingActions();
    QCOMPARE(pendingBefore.size(), size_t(1));
    QVERIFY(pendingBefore[0].type == clearguard::domain::PendingActionType::ChangeWebhookUrl);

    QMetaObject::invokeMethod(&window, "checkPendingActions");

    auto config = window.accountabilityRepository().loadConfig();
    QVERIFY(config.has_value());
    QCOMPARE(QString::fromStdString(config->webhookUrl), QString("https://example.com/new-webhook"));

    auto pendingAfter = window.accountabilityRepository().loadPendingActions();
    QVERIFY(pendingAfter[0].state == clearguard::domain::PendingActionState::Applied);
}

void TestMainWindow::cancellingWebhookChangeLeavesOriginalUrl() {
    QTemporaryDir dir;
    TestableMainWindow window(dir.path().toStdString());
    window.accountabilityRepository().setUpAccountability("123456", "https://example.com/webhook", "Ana",
                                                            std::chrono::minutes(30));

    auto *webhookEdit = window.findChild<QLineEdit *>("newWebhookEdit");
    QVERIFY(webhookEdit);
    webhookEdit->setText("https://example.com/new-webhook");
    window.fixedPin = "123456";
    QMetaObject::invokeMethod(&window, "onRequestWebhookChangeClicked");

    QMetaObject::invokeMethod(&window, "onCancelWebhookPendingClicked");

    QVERIFY(window.accountabilityRepository().loadPendingActions().empty());
    auto config = window.accountabilityRepository().loadConfig();
    QVERIFY(config.has_value());
    QCOMPARE(QString::fromStdString(config->webhookUrl), QString("https://example.com/webhook"));
}

void TestMainWindow::requestingDelayChangePicksIncreaseWhenRaisingDelay() {
    QTemporaryDir dir;
    TestableMainWindow window(dir.path().toStdString());
    window.accountabilityRepository().setUpAccountability("123456", "https://example.com/webhook", "Ana",
                                                            std::chrono::minutes(30));

    auto *delayCombo = window.findChild<QComboBox *>("newDelayCombo");
    QVERIFY(delayCombo);
    int index = delayCombo->findData(60);
    QVERIFY(index >= 0);
    delayCombo->setCurrentIndex(index);

    window.fixedPin = "123456";
    QMetaObject::invokeMethod(&window, "onRequestDelayChangeClicked");

    auto pending = window.accountabilityRepository().loadPendingActions();
    QCOMPARE(pending.size(), size_t(1));
    QVERIFY(pending[0].type == clearguard::domain::PendingActionType::IncreaseSensitiveActionDelay);
}

void TestMainWindow::requestingDelayChangePicksDecreaseWhenLoweringDelay() {
    QTemporaryDir dir;
    TestableMainWindow window(dir.path().toStdString());
    window.accountabilityRepository().setUpAccountability("123456", "https://example.com/webhook", "Ana",
                                                            std::chrono::minutes(60));

    auto *delayCombo = window.findChild<QComboBox *>("newDelayCombo");
    QVERIFY(delayCombo);
    int index = delayCombo->findData(15);
    QVERIFY(index >= 0);
    delayCombo->setCurrentIndex(index);

    window.fixedPin = "123456";
    QMetaObject::invokeMethod(&window, "onRequestDelayChangeClicked");

    auto pending = window.accountabilityRepository().loadPendingActions();
    QCOMPARE(pending.size(), size_t(1));
    QVERIFY(pending[0].type == clearguard::domain::PendingActionType::DecreaseSensitiveActionDelay);
}

void TestMainWindow::requestingDelayChangeAppliesOnceDelayElapses() {
    QTemporaryDir dir;
    TestableMainWindow window(dir.path().toStdString());
    window.accountabilityRepository().setUpAccountability("123456", "https://example.com/webhook", "Ana",
                                                            std::chrono::minutes(0));

    auto *delayCombo = window.findChild<QComboBox *>("newDelayCombo");
    QVERIFY(delayCombo);
    int index = delayCombo->findData(120);
    QVERIFY(index >= 0);
    delayCombo->setCurrentIndex(index);

    window.fixedPin = "123456";
    QMetaObject::invokeMethod(&window, "onRequestDelayChangeClicked");

    QMetaObject::invokeMethod(&window, "checkPendingActions");

    auto config = window.accountabilityRepository().loadConfig();
    QVERIFY(config.has_value());
    QCOMPARE(config->sensitiveActionDelay.count(), 120LL);
}

QTEST_MAIN(TestMainWindow)
#include "test_mainwindow.moc"
