#include "dns_message.h"

#include <algorithm>
#include <cctype>

namespace clearguard::dns {

namespace {

constexpr size_t kHeaderLength = 12;
constexpr int kMaxLabelHops = 128;

void writeU16(Bytes &bytes, size_t offset, uint16_t value) {
    bytes[offset] = static_cast<uint8_t>(value >> 8);
    bytes[offset + 1] = static_cast<uint8_t>(value & 0xFF);
}

void writeU32(Bytes &bytes, size_t offset, uint32_t value) {
    bytes[offset] = static_cast<uint8_t>((value >> 24) & 0xFF);
    bytes[offset + 1] = static_cast<uint8_t>((value >> 16) & 0xFF);
    bytes[offset + 2] = static_cast<uint8_t>((value >> 8) & 0xFF);
    bytes[offset + 3] = static_cast<uint8_t>(value & 0xFF);
}

uint16_t readU16(const Bytes &bytes, size_t offset) {
    return static_cast<uint16_t>((bytes[offset] << 8) | bytes[offset + 1]);
}

}

std::optional<DnsQuery> parseQuery(const Bytes &message) {
    if (message.size() < kHeaderLength + 5) return std::nullopt;

    uint16_t id = readU16(message, 0);
    uint16_t questionCount = readU16(message, 4);
    if (questionCount < 1) return std::nullopt;

    std::string name;
    size_t offset = kHeaderLength;
    int hops = 0;

    while (offset < message.size()) {
        hops++;
        if (hops > kMaxLabelHops) return std::nullopt;

        uint8_t labelLength = message[offset];
        if (labelLength == 0) {
            offset += 1;
            break;
        }
        if ((labelLength & 0xC0) == 0xC0) return std::nullopt;

        offset += 1;
        if (offset + labelLength > message.size()) return std::nullopt;
        if (!name.empty()) name += '.';
        name.append(reinterpret_cast<const char *>(&message[offset]), labelLength);
        offset += labelLength;
    }

    if (offset + 4 > message.size()) return std::nullopt;
    size_t nameEndOffset = offset;
    size_t questionEndOffset = offset + 4;

    std::transform(name.begin(), name.end(), name.begin(), [](unsigned char c) {
        return static_cast<char>(std::tolower(c));
    });

    DnsQuery query;
    query.id = id;
    query.domainName = name;
    query.nameEndOffset = nameEndOffset;
    query.questionEndOffset = questionEndOffset;
    return query;
}

Bytes encodeName(const std::string &domain) {
    std::vector<std::string> labels;
    size_t start = 0;
    while (start <= domain.size()) {
        size_t dot = domain.find('.', start);
        size_t length = dot == std::string::npos ? std::string::npos : dot - start;
        std::string label = domain.substr(start, length);
        if (!label.empty()) labels.push_back(label);
        if (dot == std::string::npos) break;
        start = dot + 1;
    }

    Bytes encoded;
    for (const auto &label : labels) {
        encoded.push_back(static_cast<uint8_t>(label.size()));
        for (char c : label) encoded.push_back(static_cast<uint8_t>(c));
    }
    encoded.push_back(0);
    return encoded;
}

Bytes buildSinkholeResponse(const Bytes &message, const DnsQuery &query) {
    Bytes question(message.begin() + kHeaderLength, message.begin() + static_cast<long>(query.questionEndOffset));
    Bytes response(kHeaderLength + question.size() + 16, 0);

    writeU16(response, 0, query.id);
    writeU16(response, 2, 0x8180);
    writeU16(response, 4, 1);
    writeU16(response, 6, 1);
    writeU16(response, 8, 0);
    writeU16(response, 10, 0);

    std::copy(question.begin(), question.end(), response.begin() + kHeaderLength);

    size_t offset = kHeaderLength + question.size();
    writeU16(response, offset, 0xC00C);
    offset += 2;
    writeU16(response, offset, 1);
    offset += 2;
    writeU16(response, offset, 1);
    offset += 2;
    writeU32(response, offset, 60);
    offset += 4;
    writeU16(response, offset, 4);

    return response;
}

std::optional<std::string> decodeTranslateProxyHost(const std::string &domain) {
    static const std::string suffix = ".translate.goog";
    if (domain.size() <= suffix.size()) return std::nullopt;
    if (domain.compare(domain.size() - suffix.size(), suffix.size(), suffix) != 0) return std::nullopt;

    std::string encoded = domain.substr(0, domain.size() - suffix.size());
    if (encoded.empty()) return std::nullopt;

    std::string decoded;
    size_t i = 0;
    while (i < encoded.size()) {
        char c = encoded[i];
        if (c == '-') {
            if (i + 1 < encoded.size() && encoded[i + 1] == '-') {
                decoded += '-';
                i += 2;
            } else {
                decoded += '.';
                i += 1;
            }
        } else {
            decoded += c;
            i += 1;
        }
    }
    return decoded;
}

}
