#include <QtTest>

#include <algorithm>
#include <set>

#include "system_dns/bypass_resolver_ips.h"
#include "system_dns/firewall_bypass_blocker.h"
#include "system_dns/iptables_bypass_blocker.h"

using namespace clearguard::system_dns;

class TestFirewallBypassBlocker : public QObject {
    Q_OBJECT

private slots:
    void bypassResolverIpListIsNonEmptyAndDeduplicated();
    void nullBlockerReportsUnsupportedAndDoesNothing();
    void iptablesBlockerDetectsBinaryPresence();
};

void TestFirewallBypassBlocker::bypassResolverIpListIsNonEmptyAndDeduplicated() {
    const auto &ips = bypassResolverIps();
    QVERIFY(!ips.empty());

    std::set<std::string> unique(ips.begin(), ips.end());
    QCOMPARE(unique.size(), ips.size());
}

void TestFirewallBypassBlocker::nullBlockerReportsUnsupportedAndDoesNothing() {
    NullFirewallBypassBlocker blocker;
    QVERIFY(!blocker.isSupported());
    QVERIFY(!blocker.apply());
    QVERIFY(!blocker.restore());
}

void TestFirewallBypassBlocker::iptablesBlockerDetectsBinaryPresence() {
    IptablesBypassBlocker blocker;
    QVERIFY(blocker.isSupported());
}

QTEST_MAIN(TestFirewallBypassBlocker)
#include "test_firewall_bypass_blocker.moc"
