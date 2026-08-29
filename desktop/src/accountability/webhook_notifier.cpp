#include "webhook_notifier.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrl>

namespace clearguard::accountability {

void NullWebhookNotifier::notify(const std::string &, const std::string &) {}

void HttpWebhookNotifier::notify(const std::string &webhookUrl, const std::string &message) {
    if (webhookUrl.empty()) return;

    auto *manager = new QNetworkAccessManager();

    QJsonObject body;
    body["content"] = QString::fromStdString(message);
    body["text"] = QString::fromStdString(message);

    QNetworkRequest request{QUrl(QString::fromStdString(webhookUrl))};
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json; charset=UTF-8");

    auto *reply = manager->post(request, QJsonDocument(body).toJson(QJsonDocument::Compact));
    QObject::connect(reply, &QNetworkReply::finished, [manager, reply]() {
        reply->deleteLater();
        manager->deleteLater();
    });
}

}
