#include <QtTest>
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

QTEST_MAIN(TestMainWindow)
#include "test_mainwindow.moc"
