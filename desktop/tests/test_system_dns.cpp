#include <QtTest>
#include <QTemporaryDir>

#include <filesystem>
#include <fstream>

#include "system_dns/resolv_conf_configurator.h"
#include "system_dns/systemd_resolved_configurator.h"

using namespace clearguard::system_dns;
namespace fs = std::filesystem;

class TestSystemDns : public QObject {
    Q_OBJECT

private slots:
    void resolvConfBacksUpAndRestoresOriginalContent();
    void resolvConfApplyWritesLoopbackNameserver();
    void resolvConfApplyIsRejectedWhenAlreadyApplied();
    void systemdResolvedDetectsStubSymlink();
    void systemdResolvedIgnoresUnrelatedSymlink();
    void systemdResolvedIgnoresPlainFile();
};

void TestSystemDns::resolvConfBacksUpAndRestoresOriginalContent() {
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    std::string resolvPath = (dir.filePath("resolv.conf")).toStdString();

    {
        std::ofstream original(resolvPath);
        original << "nameserver 8.8.8.8\n";
    }

    ResolvConfConfigurator configurator(resolvPath);
    QVERIFY(configurator.apply());

    {
        std::ifstream applied(resolvPath);
        std::string content((std::istreambuf_iterator<char>(applied)), std::istreambuf_iterator<char>());
        QVERIFY(content.find("127.0.0.1") != std::string::npos);
    }

    QVERIFY(configurator.restore());

    std::ifstream restored(resolvPath);
    std::string content((std::istreambuf_iterator<char>(restored)), std::istreambuf_iterator<char>());
    QCOMPARE(QString::fromStdString(content), QString("nameserver 8.8.8.8\n"));
}

void TestSystemDns::resolvConfApplyWritesLoopbackNameserver() {
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    std::string resolvPath = (dir.filePath("resolv.conf")).toStdString();

    ResolvConfConfigurator configurator(resolvPath);
    QVERIFY(configurator.apply());

    std::ifstream applied(resolvPath);
    std::string content((std::istreambuf_iterator<char>(applied)), std::istreambuf_iterator<char>());
    QCOMPARE(QString::fromStdString(content), QString("nameserver 127.0.0.1\n"));
}

void TestSystemDns::resolvConfApplyIsRejectedWhenAlreadyApplied() {
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    std::string resolvPath = (dir.filePath("resolv.conf")).toStdString();

    ResolvConfConfigurator configurator(resolvPath);
    QVERIFY(configurator.apply());
    QVERIFY(!configurator.apply());
}

void TestSystemDns::systemdResolvedDetectsStubSymlink() {
    QTemporaryDir dir;
    QVERIFY(dir.isValid());

    std::string targetDir = (dir.filePath("run/systemd/resolve")).toStdString();
    fs::create_directories(targetDir);
    std::string target = targetDir + "/resolv.conf";
    std::ofstream(target) << "nameserver 127.0.0.53\n";

    std::string symlinkPath = (dir.filePath("resolv.conf")).toStdString();
    fs::create_symlink(target, symlinkPath);

    SystemdResolvedConfigurator configurator("/tmp/does-not-matter.conf", symlinkPath);
    QVERIFY(configurator.isSupported());
}

void TestSystemDns::systemdResolvedIgnoresUnrelatedSymlink() {
    QTemporaryDir dir;
    QVERIFY(dir.isValid());

    std::string target = (dir.filePath("some-other-target.conf")).toStdString();
    std::ofstream(target) << "nameserver 1.1.1.1\n";

    std::string symlinkPath = (dir.filePath("resolv.conf")).toStdString();
    fs::create_symlink(target, symlinkPath);

    SystemdResolvedConfigurator configurator("/tmp/does-not-matter.conf", symlinkPath);
    QVERIFY(!configurator.isSupported());
}

void TestSystemDns::systemdResolvedIgnoresPlainFile() {
    QTemporaryDir dir;
    QVERIFY(dir.isValid());

    std::string path = (dir.filePath("resolv.conf")).toStdString();
    std::ofstream(path) << "nameserver 1.1.1.1\n";

    SystemdResolvedConfigurator configurator("/tmp/does-not-matter.conf", path);
    QVERIFY(!configurator.isSupported());
}

QTEST_MAIN(TestSystemDns)
#include "test_system_dns.moc"
