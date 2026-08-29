#pragma once

#include <QMainWindow>

class QLabel;
class QPushButton;

class MainWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);

    int clickCount() const;

private slots:
    void onButtonClicked();

private:
    QLabel *statusLabel;
    QPushButton *actionButton;
    int m_clickCount = 0;
};
