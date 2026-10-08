#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p build/module-cache
export SWIFT_MODULECACHE_PATH="$PWD/build/module-cache"
export CLANG_MODULE_CACHE_PATH="$PWD/build/module-cache"
xcrun swiftc -module-cache-path "$PWD/build/module-cache" -O -target arm64-apple-macos14.6 Sources/Core.swift Sources/Installer.swift tests/CoreTests.swift -o build/core-tests
build/core-tests
xcrun swiftc -module-cache-path "$PWD/build/module-cache" -O -target arm64-apple-macos14.6 Sources/Core.swift Sources/Installer.swift tests/InstallerTests.swift -o build/installer-tests
build/installer-tests
python3 -B tests/ReleaseTests.py
python3 -B scripts/audit_release.py --source-only
