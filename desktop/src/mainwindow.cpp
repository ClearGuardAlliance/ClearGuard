#include "mainwindow.h"

#include <QLabel>
#include <QPushButton>
#include <QVBoxLayout>
#include <QWidget>

MainWindow::MainWindow(QWidget *parent) : QMainWindow(parent) {
    setWindowTitle("ClearGuard Desktop");
    resize(480, 320);

    auto *central = new QWidget(this);
    auto *layout = new QVBoxLayout(central);
    layout->setAlignment(Qt::AlignCenter);

    statusLabel = new QLabel("Nenhum clique ainda.", central);
    statusLabel->setAlignment(Qt::AlignCenter);

    actionButton = new QPushButton("Clique aqui", central);
    connect(actionButton, &QPushButton::clicked, this, &MainWindow::onButtonClicked);

    layout->addWidget(statusLabel);
    layout->addWidget(actionButton);

    setCentralWidget(central);
}

int MainWindow::clickCount() const {
    return m_clickCount;
}

void MainWindow::onButtonClicked() {
    m_clickCount++;
    statusLabel->setText(QString("Cliques: %1").arg(m_clickCount));
}
