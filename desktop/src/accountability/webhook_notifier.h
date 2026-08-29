#pragma once

#include <string>

namespace clearguard::accountability {

class WebhookNotifier {
public:
    virtual ~WebhookNotifier() = default;
    virtual void notify(const std::string &webhookUrl, const std::string &message) = 0;
};

class NullWebhookNotifier : public WebhookNotifier {
public:
    void notify(const std::string &webhookUrl, const std::string &message) override;
};

class HttpWebhookNotifier : public WebhookNotifier {
public:
    void notify(const std::string &webhookUrl, const std::string &message) override;
};

}
