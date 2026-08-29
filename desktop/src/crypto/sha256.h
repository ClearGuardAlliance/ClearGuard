#pragma once

#include <array>
#include <cstdint>
#include <string>
#include <vector>

namespace clearguard::crypto {

std::array<uint8_t, 32> sha256(const std::vector<uint8_t> &data);
std::array<uint8_t, 32> sha256(const std::string &data);
std::string toHex(const std::array<uint8_t, 32> &digest);

}
