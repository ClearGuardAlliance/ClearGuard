#include "mainwindow.h"

#include <QLabel>
#include <QPushButton>
#include <QVBoxLayout>
#include <QWidget>

using namespace clearguard::dns;

MainWindow::MainWindow(QWidget *parent) : QMainWindow(parent) {
    setWindowTitle("ClearGuard Desktop");
    resize(480, 320);

    blocklist.loadDefaults();

    auto *central = new QWidget(this);
    auto *layout = new QVBoxLayout(central);
    layout->setAlignment(Qt::AlignCenter);

    statusLabel = new QLabel(central);
    statusLabel->setAlignment(Qt::AlignCenter);

    toggleButton = new QPushButton(central);
    connect(toggleButton, &QPushButton::clicked, this, &MainWindow::onToggleClicked);

    layout->addWidget(statusLabel);
    layout->addWidget(toggleButton);

    setCentralWidget(central);
    refreshStatusLabel();
}

MainWindow::~MainWindow() {
    server.stop();
}

bool MainWindow::isProtectionRunning() const {
    return server.status() == ServerStatus::Running;
}

void MainWindow::onToggleClicked() {
    if (isProtectionRunning()) {
        server.stop();
    } else {
        server.start(blocklist, 0, "208.67.222.123", 53);
    }
    refreshStatusLabel();
}

void MainWindow::refreshStatusLabel() {
    if (isProtectionRunning()) {
        statusLabel->setText(
            QString("Protection running on 127.0.0.1:%1 (%2 domains blocked)")
                .arg(server.boundPort())
                .arg(blocklist.size()));
        toggleButton->setText("Stop protection");
    } else {
        statusLabel->setText(QString("Protection stopped (%1 domains loaded)").arg(blocklist.size()));
        toggleButton->setText("Start protection");
    }
}
