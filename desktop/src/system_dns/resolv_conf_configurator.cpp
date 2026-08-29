#include "resolv_conf_configurator.h"

#include <filesystem>
#include <fstream>

namespace clearguard::system_dns {

namespace fs = std::filesystem;

ResolvConfConfigurator::ResolvConfConfigurator(std::string resolvConfPath)
    : resolvConfPath_(std::move(resolvConfPath)), backupPath_(resolvConfPath_ + ".clearguard-backup") {}

bool ResolvConfConfigurator::isSupported() const {
    std::error_code ec;
    return fs::exists(fs::path(resolvConfPath_).parent_path(), ec);
}

bool ResolvConfConfigurator::apply() {
    if (applied_) return false;

    std::error_code ec;
    if (!fs::exists(backupPath_, ec)) {
        if (fs::exists(resolvConfPath_, ec)) {
            fs::copy_file(resolvConfPath_, backupPath_, fs::copy_options::overwrite_existing, ec);
            if (ec) return false;
        } else {
            std::ofstream empty(backupPath_);
            if (!empty.is_open()) return false;
        }
    }

    std::ofstream out(resolvConfPath_, std::ios::trunc);
    if (!out.is_open()) return false;
    out << "nameserver 127.0.0.1\n";
    out.close();

    applied_ = true;
    return true;
}

bool ResolvConfConfigurator::restore() {
    std::error_code ec;
    if (!fs::exists(backupPath_, ec)) return false;

    fs::copy_file(backupPath_, resolvConfPath_, fs::copy_options::overwrite_existing, ec);
    if (ec) return false;

    fs::remove(backupPath_, ec);
    applied_ = false;
    return true;
}

}
