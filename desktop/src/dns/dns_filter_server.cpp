#include "dns_filter_server.h"

#include <cstring>
#include <vector>

#include "dns_message.h"

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#else
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>
#endif

namespace clearguard::dns {

namespace {

#ifdef _WIN32
constexpr ClearGuardSocketHandle kInvalidSocket = static_cast<ClearGuardSocketHandle>(INVALID_SOCKET);
#else
constexpr ClearGuardSocketHandle kInvalidSocket = static_cast<ClearGuardSocketHandle>(-1);
#endif

bool initializeSocketLibrary() {
#ifdef _WIN32
    WSADATA data;
    return WSAStartup(MAKEWORD(2, 2), &data) == 0;
#else
    return true;
#endif
}

void cleanupSocketLibrary() {
#ifdef _WIN32
    WSACleanup();
#endif
}

void closeSocketHandle(ClearGuardSocketHandle handle) {
#ifdef _WIN32
    closesocket(static_cast<SOCKET>(handle));
#else
    close(handle);
#endif
}

void setReceiveTimeout(ClearGuardSocketHandle handle, int milliseconds) {
#ifdef _WIN32
    DWORD timeout = static_cast<DWORD>(milliseconds);
    setsockopt(static_cast<SOCKET>(handle), SOL_SOCKET, SO_RCVTIMEO,
               reinterpret_cast<const char *>(&timeout), sizeof(timeout));
#else
    struct timeval timeout {};
    timeout.tv_sec = milliseconds / 1000;
    timeout.tv_usec = (milliseconds % 1000) * 1000;
    setsockopt(handle, SOL_SOCKET, SO_RCVTIMEO,
               reinterpret_cast<const char *>(&timeout), sizeof(timeout));
#endif
}

ClearGuardSocketHandle createUdpSocket() {
#ifdef _WIN32
    SOCKET raw = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (raw == INVALID_SOCKET) return kInvalidSocket;
    return static_cast<ClearGuardSocketHandle>(raw);
#else
    int raw = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (raw < 0) return kInvalidSocket;
    return static_cast<ClearGuardSocketHandle>(raw);
#endif
}

bool bindLoopback(ClearGuardSocketHandle handle, uint16_t port, uint16_t &outBoundPort) {
    struct sockaddr_in address {};
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    address.sin_port = htons(port);

#ifdef _WIN32
    auto socketHandle = static_cast<SOCKET>(handle);
#else
    auto socketHandle = handle;
#endif

    if (bind(socketHandle, reinterpret_cast<struct sockaddr *>(&address), sizeof(address)) != 0) {
        return false;
    }

    struct sockaddr_in bound {};
    socklen_t boundLength = sizeof(bound);
    if (getsockname(socketHandle, reinterpret_cast<struct sockaddr *>(&bound), &boundLength) == 0) {
        outBoundPort = ntohs(bound.sin_port);
    } else {
        outBoundPort = port;
    }
    return true;
}

Bytes forwardToUpstream(const Bytes &message, const std::string &upstreamHost, uint16_t upstreamPort) {
    ClearGuardSocketHandle handle = createUdpSocket();
    if (handle == kInvalidSocket) return {};
    setReceiveTimeout(handle, 3000);

    struct sockaddr_in upstreamAddress {};
    upstreamAddress.sin_family = AF_INET;
    upstreamAddress.sin_port = htons(upstreamPort);
    if (inet_pton(AF_INET, upstreamHost.c_str(), &upstreamAddress.sin_addr) != 1) {
        closeSocketHandle(handle);
        return {};
    }

#ifdef _WIN32
    auto socketHandle = static_cast<SOCKET>(handle);
    int sent = sendto(socketHandle, reinterpret_cast<const char *>(message.data()), static_cast<int>(message.size()),
                       0, reinterpret_cast<struct sockaddr *>(&upstreamAddress), sizeof(upstreamAddress));
#else
    auto socketHandle = handle;
    ssize_t sent = sendto(socketHandle, message.data(), message.size(), 0,
                           reinterpret_cast<struct sockaddr *>(&upstreamAddress), sizeof(upstreamAddress));
#endif
    if (sent < 0) {
        closeSocketHandle(handle);
        return {};
    }

    std::vector<uint8_t> buffer(4096);
#ifdef _WIN32
    int received = recv(socketHandle, reinterpret_cast<char *>(buffer.data()), static_cast<int>(buffer.size()), 0);
#else
    ssize_t received = recv(socketHandle, buffer.data(), buffer.size(), 0);
#endif

    closeSocketHandle(handle);
    if (received <= 0) return {};

    return Bytes(buffer.begin(), buffer.begin() + received);
}

}

DnsFilterServer::~DnsFilterServer() {
    stop();
}

bool DnsFilterServer::start(const Blocklist &blocklist, uint16_t port, const std::string &upstreamHost,
                             uint16_t upstreamPort) {
    if (running_.load()) return false;
    if (!initializeSocketLibrary()) {
        status_.store(ServerStatus::Error);
        return false;
    }

    ClearGuardSocketHandle handle = createUdpSocket();
    if (handle == kInvalidSocket) {
        cleanupSocketLibrary();
        status_.store(ServerStatus::Error);
        return false;
    }

    setReceiveTimeout(handle, 500);

    uint16_t boundPort = 0;
    if (!bindLoopback(handle, port, boundPort)) {
        closeSocketHandle(handle);
        cleanupSocketLibrary();
        status_.store(ServerStatus::Error);
        return false;
    }

    boundPort_.store(boundPort);
    socketHandle_ = handle;
    running_.store(true);
    status_.store(ServerStatus::Running);

    worker_ = std::thread(&DnsFilterServer::run, this, handle, blocklist, upstreamHost, upstreamPort);
    return true;
}

void DnsFilterServer::stop() {
    if (!running_.load()) return;
    running_.store(false);
    if (worker_.joinable()) worker_.join();
    status_.store(ServerStatus::Stopped);
    boundPort_.store(0);
}

ServerStatus DnsFilterServer::status() const {
    return status_.load();
}

uint16_t DnsFilterServer::boundPort() const {
    return boundPort_.load();
}

void DnsFilterServer::run(ClearGuardSocketHandle socketHandle, Blocklist blocklist, std::string upstreamHost,
                           uint16_t upstreamPort) {
    std::vector<uint8_t> buffer(4096);

    while (running_.load()) {
        struct sockaddr_in clientAddress {};
        socklen_t clientLength = sizeof(clientAddress);

#ifdef _WIN32
        auto nativeHandle = static_cast<SOCKET>(socketHandle);
        int received = recvfrom(nativeHandle, reinterpret_cast<char *>(buffer.data()), static_cast<int>(buffer.size()),
                                 0, reinterpret_cast<struct sockaddr *>(&clientAddress), &clientLength);
#else
        auto nativeHandle = socketHandle;
        ssize_t received = recvfrom(nativeHandle, buffer.data(), buffer.size(), 0,
                                     reinterpret_cast<struct sockaddr *>(&clientAddress), &clientLength);
#endif
        if (received <= 0) continue;

        Bytes message(buffer.begin(), buffer.begin() + received);
        auto query = parseQuery(message);
        if (!query) continue;

        Bytes response;
        if (blocklist.isBlockedIncludingProxies(query->domainName)) {
            response = buildSinkholeResponse(message, *query);
        } else {
            response = forwardToUpstream(message, upstreamHost, upstreamPort);
            if (response.empty()) continue;
        }

#ifdef _WIN32
        sendto(nativeHandle, reinterpret_cast<const char *>(response.data()), static_cast<int>(response.size()), 0,
               reinterpret_cast<struct sockaddr *>(&clientAddress), clientLength);
#else
        sendto(nativeHandle, response.data(), response.size(), 0,
               reinterpret_cast<struct sockaddr *>(&clientAddress), clientLength);
#endif
    }

    closeSocketHandle(socketHandle);
    cleanupSocketLibrary();
}

}
