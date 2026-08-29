#include <QtTest>
#include <QUdpSocket>

#include "dns/blocklist.h"
#include "dns/dns_filter_server.h"
#include "dns/dns_message.h"

using namespace clearguard::dns;

namespace {

Bytes buildQueryMessage(uint16_t id, const std::string &domain) {
    Bytes header(12, 0);
    header[0] = static_cast<uint8_t>(id >> 8);
    header[1] = static_cast<uint8_t>(id & 0xFF);
    header[5] = 1;

    Bytes name = encodeName(domain);
    Bytes typeAndClass = {0, 1, 0, 1};

    Bytes message;
    message.insert(message.end(), header.begin(), header.end());
    message.insert(message.end(), name.begin(), name.end());
    message.insert(message.end(), typeAndClass.begin(), typeAndClass.end());
    return message;
}

}

class TestDnsFilterServer : public QObject {
    Q_OBJECT

private slots:
    void sinkholesBlockedDomainOverLoopback();
};

void TestDnsFilterServer::sinkholesBlockedDomainOverLoopback() {
    Blocklist blocklist;
    blocklist.setDomains({"pornhub.com"});

    DnsFilterServer server;
    QVERIFY(server.start(blocklist, 0, "208.67.222.123", 53));
    QCOMPARE(server.status(), ServerStatus::Running);
    QVERIFY(server.boundPort() != 0);

    QUdpSocket client;
    auto query = buildQueryMessage(0x55AA, "pornhub.com");
    QByteArray payload(reinterpret_cast<const char *>(query.data()), static_cast<int>(query.size()));

    client.writeDatagram(payload, QHostAddress::LocalHost, server.boundPort());
    QVERIFY(client.waitForReadyRead(3000));

    QByteArray responseData;
    responseData.resize(static_cast<int>(client.pendingDatagramSize()));
    client.readDatagram(responseData.data(), responseData.size());

    Bytes response(responseData.begin(), responseData.end());
    auto parsed = parseQuery(response);

    QVERIFY(parsed.has_value());
    QCOMPARE(parsed->id, 0x55AA);
    QCOMPARE(QString::fromStdString(parsed->domainName), QString("pornhub.com"));

    Bytes rdata(response.end() - 4, response.end());
    QCOMPARE(rdata, Bytes({0, 0, 0, 0}));

    server.stop();
    QCOMPARE(server.status(), ServerStatus::Stopped);
}

QTEST_MAIN(TestDnsFilterServer)
#include "test_dns_filter_server.moc"
