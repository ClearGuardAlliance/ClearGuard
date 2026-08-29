#include <QtTest>
#include <QTemporaryDir>

#include "accountability/accountability_repository.h"

using namespace clearguard::accountability;
using namespace clearguard::domain;

class TestAccountabilityRepository : public QObject {
    Q_OBJECT

private slots:
    void isNotConfiguredInitially();
    void setUpAccountabilityPersistsConfig();
    void verifyPinAcceptsCorrectPinOnly();
    void createPendingActionPersistsAndIsLoadable();
    void cancelPendingActionRemovesIt();
    void markAppliedChangesState();
    void applyDelayChangeUpdatesConfig();
};

namespace {

AccountabilityRepository makeRepository(QTemporaryDir &dir, NullWebhookNotifier &notifier) {
    return AccountabilityRepository(dir.path().toStdString(), notifier);
}

}

void TestAccountabilityRepository::isNotConfiguredInitially() {
    QTemporaryDir dir;
    NullWebhookNotifier notifier;
    auto repo = makeRepository(dir, notifier);
    QVERIFY(!repo.isConfigured());
}

void TestAccountabilityRepository::setUpAccountabilityPersistsConfig() {
    QTemporaryDir dir;
    NullWebhookNotifier notifier;
    auto repo = makeRepository(dir, notifier);

    QVERIFY(repo.setUpAccountability("123456", "https://example.com/webhook", "Ana", std::chrono::minutes(45)));
    QVERIFY(repo.isConfigured());

    auto config = repo.loadConfig();
    QVERIFY(config.has_value());
    QCOMPARE(QString::fromStdString(config->webhookUrl), QString("https://example.com/webhook"));
    QCOMPARE(QString::fromStdString(config->partnerLabel), QString("Ana"));
    QCOMPARE(config->sensitiveActionDelay.count(), 45LL);
}

void TestAccountabilityRepository::verifyPinAcceptsCorrectPinOnly() {
    QTemporaryDir dir;
    NullWebhookNotifier notifier;
    auto repo = makeRepository(dir, notifier);

    repo.setUpAccountability("123456", "https://example.com/webhook", "Ana", std::chrono::minutes(30));

    QVERIFY(repo.verifyPin("123456"));
    QVERIFY(!repo.verifyPin("000000"));
}

void TestAccountabilityRepository::createPendingActionPersistsAndIsLoadable() {
    QTemporaryDir dir;
    NullWebhookNotifier notifier;
    auto repo = makeRepository(dir, notifier);
    repo.setUpAccountability("123456", "https://example.com/webhook", "Ana", std::chrono::minutes(30));

    auto action = repo.createPendingAction(PendingActionType::RemoveBlocklistDomain, {{"domain", "example.com"}});

    auto loaded = repo.loadPendingActions();
    QCOMPARE(loaded.size(), size_t(1));
    QCOMPARE(QString::fromStdString(loaded[0].id), QString::fromStdString(action.id));
    QVERIFY(loaded[0].type == PendingActionType::RemoveBlocklistDomain);
    QCOMPARE(QString::fromStdString(loaded[0].payload.at("domain")), QString("example.com"));
}

void TestAccountabilityRepository::cancelPendingActionRemovesIt() {
    QTemporaryDir dir;
    NullWebhookNotifier notifier;
    auto repo = makeRepository(dir, notifier);
    repo.setUpAccountability("123456", "https://example.com/webhook", "Ana", std::chrono::minutes(30));

    auto action = repo.createPendingAction(PendingActionType::DisableProtection);
    QVERIFY(repo.cancelPendingAction(action.id));
    QVERIFY(repo.loadPendingActions().empty());
}

void TestAccountabilityRepository::markAppliedChangesState() {
    QTemporaryDir dir;
    NullWebhookNotifier notifier;
    auto repo = makeRepository(dir, notifier);
    repo.setUpAccountability("123456", "https://example.com/webhook", "Ana", std::chrono::minutes(30));

    auto action = repo.createPendingAction(PendingActionType::DisableProtection);
    QVERIFY(repo.markApplied(action.id));

    auto loaded = repo.loadPendingActions();
    QCOMPARE(loaded.size(), size_t(1));
    QVERIFY(loaded[0].state == PendingActionState::Applied);
}

void TestAccountabilityRepository::applyDelayChangeUpdatesConfig() {
    QTemporaryDir dir;
    NullWebhookNotifier notifier;
    auto repo = makeRepository(dir, notifier);
    repo.setUpAccountability("123456", "https://example.com/webhook", "Ana", std::chrono::minutes(30));

    QVERIFY(repo.applyDelayChange(std::chrono::minutes(60)));

    auto config = repo.loadConfig();
    QCOMPARE(config->sensitiveActionDelay.count(), 60LL);
}

QTEST_MAIN(TestAccountabilityRepository)
#include "test_accountability_repository.moc"
