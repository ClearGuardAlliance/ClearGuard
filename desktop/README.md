# ClearGuard Desktop

Esqueleto Qt Widgets nativo (sem webview), CMake, C++17. Alvo: Linux, macOS, Windows, FreeBSD.

## Dependências

- CMake >= 3.16
- Qt6 (ou Qt5 >= 5.15 como fallback)
- Um compilador C++17 (gcc/clang/MSVC)

### Instalar Qt por plataforma

- **Linux (Debian/Ubuntu)**: `sudo apt install qt6-base-dev cmake build-essential`
- **macOS**: `brew install qt cmake`
- **Windows**: instalador oficial da Qt Company, ou `vcpkg install qt6-base`
- **FreeBSD**: `pkg install qt6-base cmake`

## Build

```sh
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

O binário fica em `build/clearguard_desktop` (ou `build/clearguard_desktop.app` no macOS).

## Rodar

```sh
./build/clearguard_desktop
```

## Testes

```sh
ctest --test-dir build
```

## CI

Linux, macOS e Windows via GitHub Actions (`.github/workflows/desktop.yml`, na raiz do repo). FreeBSD via Cirrus CI (`.cirrus.yml`, na raiz do repo) — precisa conectar o repositório em cirrus-ci.com depois do push.
