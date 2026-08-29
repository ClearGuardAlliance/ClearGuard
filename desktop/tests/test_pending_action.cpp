#include <QtTest>

#include "domain/pending_action.h"

using namespace clearguard::domain;

class TestPendingAction : public QObject {
    Q_OBJECT

private slots:
    void isReadyToApplyIsFalseBeforeReadyAt();
    void isReadyToApplyIsTrueOnceReadyAtPassed();
    void isReadyToApplyIsFalseWhenAlreadyApplied();
    void timeRemainingNeverGoesNegative();
    void typeRoundTripsThroughString();
    void stateRoundTripsThroughString();
};

void TestPendingAction::isReadyToApplyIsFalseBeforeReadyAt() {
    PendingAction action;
    action.readyAt = std::chrono::system_clock::now() + std::chrono::minutes(30);
    action.state = PendingActionState::Pending;
    QVERIFY(!action.isReadyToApply());
}

void TestPendingAction::isReadyToApplyIsTrueOnceReadyAtPassed() {
    PendingAction action;
    action.readyAt = std::chrono::system_clock::now() - std::chrono::minutes(1);
    action.state = PendingActionState::Pending;
    QVERIFY(action.isReadyToApply());
}

void TestPendingAction::isReadyToApplyIsFalseWhenAlreadyApplied() {
    PendingAction action;
    action.readyAt = std::chrono::system_clock::now() - std::chrono::minutes(1);
    action.state = PendingActionState::Applied;
    QVERIFY(!action.isReadyToApply());
}

void TestPendingAction::timeRemainingNeverGoesNegative() {
    PendingAction action;
    action.readyAt = std::chrono::system_clock::now() - std::chrono::hours(1);
    QCOMPARE(action.timeRemaining().count(), 0LL);
}

void TestPendingAction::typeRoundTripsThroughString() {
    for (auto type : {
             PendingActionType::DisableProtection,
             PendingActionType::RemoveBlocklistDomain,
             PendingActionType::ChangeWebhookUrl,
             PendingActionType::ChangeRemoteBlocklistUrl,
             PendingActionType::IncreaseSensitiveActionDelay,
             PendingActionType::DecreaseSensitiveActionDelay,
         }) {
        QVERIFY(pendingActionTypeFromString(toString(type)) == type);
    }
}

void TestPendingAction::stateRoundTripsThroughString() {
    for (auto state : {PendingActionState::Pending, PendingActionState::Applied, PendingActionState::Cancelled}) {
        QVERIFY(pendingActionStateFromString(toString(state)) == state);
    }
}

QTEST_MAIN(TestPendingAction)
#include "test_pending_action.moc"
