#include "systemd_resolved_configurator.h"

#include <cstdlib>
#include <filesystem>
#include <fstream>

namespace clearguard::system_dns {

namespace fs = std::filesystem;

namespace {

bool restartSystemdResolved() {
    return std::system("systemctl restart systemd-resolved") == 0;
}

}

SystemdResolvedConfigurator::SystemdResolvedConfigurator(std::string dropInPath, std::string resolvConfSymlinkPath)
    : dropInPath_(std::move(dropInPath)), resolvConfSymlinkPath_(std::move(resolvConfSymlinkPath)) {}

bool SystemdResolvedConfigurator::isSupported() const {
    std::error_code ec;
    if (!fs::is_symlink(resolvConfSymlinkPath_, ec) || ec) return false;

    auto target = fs::read_symlink(resolvConfSymlinkPath_, ec);
    if (ec) return false;

    return target.string().find("systemd/resolve") != std::string::npos;
}

bool SystemdResolvedConfigurator::apply() {
    if (applied_) return false;

    std::error_code ec;
    fs::create_directories(fs::path(dropInPath_).parent_path(), ec);
    if (ec) return false;

    std::ofstream out(dropInPath_, std::ios::trunc);
    if (!out.is_open()) return false;
    out << "[Resolve]\n";
    out << "DNS=127.0.0.1\n";
    out << "Domains=~.\n";
    out.close();

    if (!restartSystemdResolved()) {
        fs::remove(dropInPath_, ec);
        return false;
    }

    applied_ = true;
    return true;
}

bool SystemdResolvedConfigurator::restore() {
    std::error_code ec;
    if (!fs::exists(dropInPath_, ec)) return false;

    fs::remove(dropInPath_, ec);
    if (ec) return false;

    restartSystemdResolved();
    applied_ = false;
    return true;
}

}
