#include <QtTest>

#include "mainwindow.h"

class TestMainWindow : public QObject {
    Q_OBJECT

private slots:
    void startsAtZero();
    void incrementsOnClick();
};

void TestMainWindow::startsAtZero() {
    MainWindow window;
    QCOMPARE(window.clickCount(), 0);
}

void TestMainWindow::incrementsOnClick() {
    MainWindow window;
    QMetaObject::invokeMethod(&window, "onButtonClicked");
    QMetaObject::invokeMethod(&window, "onButtonClicked");
    QCOMPARE(window.clickCount(), 2);
}

QTEST_MAIN(TestMainWindow)
#include "test_mainwindow.moc"
