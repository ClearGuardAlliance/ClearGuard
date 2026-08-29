cmake_minimum_required(VERSION 3.16)
project(clearguard_desktop LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 COMPONENTS Widgets Test QUIET)
if(NOT Qt6_FOUND)
    find_package(Qt5 5.15 REQUIRED COMPONENTS Widgets Test)
endif()

if(Qt6_FOUND)
    set(QT_WIDGETS_TARGET Qt6::Widgets)
    set(QT_TEST_TARGET Qt6::Test)
else()
    set(QT_WIDGETS_TARGET Qt5::Widgets)
    set(QT_TEST_TARGET Qt5::Test)
endif()

add_library(mainwindow_lib STATIC
    src/mainwindow.cpp
    src/mainwindow.h
)
target_link_libraries(mainwindow_lib PUBLIC ${QT_WIDGETS_TARGET})
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
