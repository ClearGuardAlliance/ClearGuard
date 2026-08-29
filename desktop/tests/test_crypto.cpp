#include <QtTest>

#include "crypto/pin_credentials.h"
#include "crypto/sha256.h"

using namespace clearguard::crypto;

class TestCrypto : public QObject {
    Q_OBJECT

private slots:
    void sha256MatchesKnownVectorForEmptyString();
    void sha256MatchesKnownVectorForAbc();
    void sha256MatchesKnownVectorForLongerInput();
    void pinHashIsDeterministicForSameSalt();
    void pinHashDiffersAcrossSalts();
    void verifyPinAcceptsCorrectPin();
    void verifyPinRejectsWrongPin();
};

void TestCrypto::sha256MatchesKnownVectorForEmptyString() {
    auto digest = sha256(std::string(""));
    QCOMPARE(QString::fromStdString(toHex(digest)),
              QString("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"));
}

void TestCrypto::sha256MatchesKnownVectorForAbc() {
    auto digest = sha256(std::string("abc"));
    QCOMPARE(QString::fromStdString(toHex(digest)),
              QString("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"));
}

void TestCrypto::sha256MatchesKnownVectorForLongerInput() {
    auto digest = sha256(std::string("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"));
    QCOMPARE(QString::fromStdString(toHex(digest)),
              QString("248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"));
}

void TestCrypto::pinHashIsDeterministicForSameSalt() {
    QCOMPARE(QString::fromStdString(hashPin("123456", "abcd")),
              QString::fromStdString(hashPin("123456", "abcd")));
}

void TestCrypto::pinHashDiffersAcrossSalts() {
    QVERIFY(hashPin("123456", "abcd") != hashPin("123456", "efgh"));
}

void TestCrypto::verifyPinAcceptsCorrectPin() {
    auto salt = generateSalt();
    auto hash = hashPin("445566", salt);
    QVERIFY(verifyPin("445566", salt, hash));
}

void TestCrypto::verifyPinRejectsWrongPin() {
    auto salt = generateSalt();
    auto hash = hashPin("445566", salt);
    QVERIFY(!verifyPin("000000", salt, hash));
}

QTEST_MAIN(TestCrypto)
#include "test_crypto.moc"
