cmake_minimum_required(VERSION 3.16)
project(clearguard_desktop LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 COMPONENTS Widgets Test Network QUIET)
if(NOT Qt6_FOUND)
    find_package(Qt5 5.15 REQUIRED COMPONENTS Widgets Test Network)
endif()

if(Qt6_FOUND)
    set(QT_CORE_TARGET Qt6::Core)
    set(QT_WIDGETS_TARGET Qt6::Widgets)
    set(QT_TEST_TARGET Qt6::Test)
    set(QT_NETWORK_TARGET Qt6::Network)
else()
    set(QT_CORE_TARGET Qt5::Core)
    set(QT_WIDGETS_TARGET Qt5::Widgets)
    set(QT_TEST_TARGET Qt5::Test)
    set(QT_NETWORK_TARGET Qt5::Network)
endif()

add_library(dns_lib STATIC
    src/dns/dns_message.cpp
    src/dns/dns_message.h
    src/dns/blocklist.cpp
    src/dns/blocklist.h
    src/dns/dns_filter_server.cpp
    src/dns/dns_filter_server.h
)
target_include_directories(dns_lib PUBLIC src)

if(WIN32)
    target_link_libraries(dns_lib PUBLIC ws2_32)
endif()

find_package(Threads REQUIRED)
target_link_libraries(dns_lib PUBLIC Threads::Threads)

add_library(system_dns_lib STATIC
    src/system_dns/system_dns_configurator.cpp
    src/system_dns/system_dns_configurator.h
    src/system_dns/resolv_conf_configurator.cpp
    src/system_dns/resolv_conf_configurator.h
    src/system_dns/systemd_resolved_configurator.cpp
    src/system_dns/systemd_resolved_configurator.h
)
target_include_directories(system_dns_lib PUBLIC src)

add_library(crypto_lib STATIC
    src/crypto/sha256.cpp
    src/crypto/sha256.h
    src/crypto/pin_credentials.cpp
    src/crypto/pin_credentials.h
)
target_include_directories(crypto_lib PUBLIC src)

add_library(accountability_lib STATIC
    src/domain/pending_action.cpp
    src/domain/pending_action.h
    src/domain/accountability_config.h
    src/accountability/webhook_notifier.cpp
    src/accountability/webhook_notifier.h
    src/accountability/accountability_repository.cpp
    src/accountability/accountability_repository.h
)
target_include_directories(accountability_lib PUBLIC src)
target_link_libraries(accountability_lib PUBLIC crypto_lib ${QT_CORE_TARGET} ${QT_NETWORK_TARGET})

add_library(mainwindow_lib STATIC
    src/mainwindow.cpp
    src/mainwindow.h
)
target_link_libraries(mainwindow_lib PUBLIC ${QT_WIDGETS_TARGET} dns_lib)
target_include_directories(mainwindow_lib PUBLIC src)

add_executable(clearguard_desktop src/main.cpp)
target_link_libraries(clearguard_desktop PRIVATE mainwindow_lib)

if(APPLE)
    set_target_properties(clearguard_desktop PROPERTIES MACOSX_BUNDLE TRUE)
endif()

enable_testing()

add_executable(test_mainwindow tests/test_mainwindow.cpp)
target_link_libraries(test_mainwindow PRIVATE mainwindow_lib ${QT_TEST_TARGET})
add_test(NAME test_mainwindow COMMAND test_mainwindow)

add_executable(test_dns_message tests/test_dns_message.cpp)
target_link_libraries(test_dns_message PRIVATE dns_lib ${QT_TEST_TARGET})
add_test(NAME test_dns_message COMMAND test_dns_message)

add_executable(test_dns_filter_server tests/test_dns_filter_server.cpp)
target_link_libraries(test_dns_filter_server PRIVATE dns_lib ${QT_TEST_TARGET} ${QT_NETWORK_TARGET})
add_test(NAME test_dns_filter_server COMMAND test_dns_filter_server)

add_executable(test_system_dns tests/test_system_dns.cpp)
target_link_libraries(test_system_dns PRIVATE system_dns_lib ${QT_TEST_TARGET})
add_test(NAME test_system_dns COMMAND test_system_dns)

add_executable(test_crypto tests/test_crypto.cpp)
target_link_libraries(test_crypto PRIVATE crypto_lib ${QT_TEST_TARGET})
add_test(NAME test_crypto COMMAND test_crypto)

add_executable(test_pending_action tests/test_pending_action.cpp)
target_link_libraries(test_pending_action PRIVATE accountability_lib ${QT_TEST_TARGET})
add_test(NAME test_pending_action COMMAND test_pending_action)

add_executable(test_accountability_repository tests/test_accountability_repository.cpp)
target_link_libraries(test_accountability_repository PRIVATE accountability_lib ${QT_TEST_TARGET})
add_test(NAME test_accountability_repository COMMAND test_accountability_repository)
