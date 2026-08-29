#include <QtTest>

#include "mainwindow.h"

class TestMainWindow : public QObject {
    Q_OBJECT

private slots:
    void startsStopped();
    void toggleStartsAndStopsProtection();
};

void TestMainWindow::startsStopped() {
    MainWindow window;
    QVERIFY(!window.isProtectionRunning());
}

void TestMainWindow::toggleStartsAndStopsProtection() {
    MainWindow window;

    QMetaObject::invokeMethod(&window, "onToggleClicked");
    QVERIFY(window.isProtectionRunning());

    QMetaObject::invokeMethod(&window, "onToggleClicked");
    QVERIFY(!window.isProtectionRunning());
}

QTEST_MAIN(TestMainWindow)
#include "test_mainwindow.moc"
