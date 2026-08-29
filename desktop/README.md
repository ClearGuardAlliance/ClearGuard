# ClearGuard Desktop

Native Qt Widgets app (no webview), CMake, C++17. Targets Linux, macOS, Windows, FreeBSD.

## Dependencies

- CMake >= 3.16
- Qt6 (or Qt5 >= 5.15 as a fallback)
- A C++17 compiler (gcc/clang/MSVC)

### Installing Qt per platform

- **Linux (Debian/Ubuntu)**: `sudo apt install qt6-base-dev cmake build-essential`
- **macOS**: `brew install qt cmake`
- **Windows**: official Qt Company installer, or `vcpkg install qt6-base`
- **FreeBSD**: `pkg install qt6-base cmake`

## Build

```sh
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

The binary lands at `build/clearguard_desktop` (or `build/clearguard_desktop.app` on macOS).

## Run

```sh
./build/clearguard_desktop
```

## Tests

```sh
ctest --test-dir build
```

## CI

Linux, macOS and Windows via GitHub Actions (`.github/workflows/desktop.yml`, at the repo root). FreeBSD via Cirrus CI (`.cirrus.yml`, at the repo root) — needs the repository connected at cirrus-ci.com after pushing.
