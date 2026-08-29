#pragma once

#include <string>

namespace clearguard::crypto {

std::string generateSalt();
std::string hashPin(const std::string &pin, const std::string &salt);
bool verifyPin(const std::string &pin, const std::string &salt, const std::string &expectedHash);

}
