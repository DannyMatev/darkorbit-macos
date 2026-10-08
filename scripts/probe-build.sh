#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p build/module-cache
export SWIFT_MODULECACHE_PATH="$PWD/build/module-cache"
export CLANG_MODULE_CACHE_PATH="$PWD/build/module-cache"
xcrun swiftc -O -target arm64-apple-macos14.6 -module-cache-path "$PWD/build/module-cache" \
  -file-compilation-dir . -file-prefix-map "$PWD"=. \
  Sources/Core.swift Sources/Installer.swift tests/InstallationProbe.swift -o build/installation-probe
printf '%s\n' 'Built developer installation probe. It never launches the game.'
