#pragma once

#include <atomic>
#include <cstdint>
#include <string>
#include <thread>

#include "blocklist.h"

#ifdef _WIN32
using ClearGuardSocketHandle = std::uintptr_t;
#else
using ClearGuardSocketHandle = int;
#endif

namespace clearguard::dns {

enum class ServerStatus {
    Stopped,
    Running,
    Error,
};

class DnsFilterServer {
public:
    ~DnsFilterServer();

    bool start(const Blocklist &blocklist, uint16_t port, const std::string &upstreamHost, uint16_t upstreamPort);
    void stop();
    ServerStatus status() const;
    uint16_t boundPort() const;

private:
    void run(ClearGuardSocketHandle socketHandle, Blocklist blocklist, std::string upstreamHost, uint16_t upstreamPort);

    std::thread worker_;
    std::atomic<bool> running_{false};
    std::atomic<ServerStatus> status_{ServerStatus::Stopped};
    std::atomic<uint16_t> boundPort_{0};
    ClearGuardSocketHandle socketHandle_{};
};

}
