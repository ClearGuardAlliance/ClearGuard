#pragma once

#include <QMainWindow>

#include "dns/blocklist.h"
#include "dns/dns_filter_server.h"

class QLabel;
class QPushButton;

class MainWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow() override;

    bool isProtectionRunning() const;

private slots:
    void onToggleClicked();

private:
    void refreshStatusLabel();

    QLabel *statusLabel;
    QPushButton *toggleButton;
    clearguard::dns::Blocklist blocklist;
    clearguard::dns::DnsFilterServer server;
};
