#include "pin_credentials.h"

#include <random>

#include "sha256.h"

namespace clearguard::crypto {

namespace {

constexpr size_t kSaltBytes = 16;

}

std::string generateSalt() {
    std::random_device device;
    std::uniform_int_distribution<int> distribution(0, 255);

    static const char *hexChars = "0123456789abcdef";
    std::string salt;
    salt.reserve(kSaltBytes * 2);
    for (size_t i = 0; i < kSaltBytes; ++i) {
        auto byte = static_cast<uint8_t>(distribution(device));
        salt.push_back(hexChars[byte >> 4]);
        salt.push_back(hexChars[byte & 0x0F]);
    }
    return salt;
}

std::string hashPin(const std::string &pin, const std::string &salt) {
    return toHex(sha256(salt + ":" + pin));
}

bool verifyPin(const std::string &pin, const std::string &salt, const std::string &expectedHash) {
    return hashPin(pin, salt) == expectedHash;
}

}
