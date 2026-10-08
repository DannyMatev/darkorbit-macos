#!/bin/sh
set -eu

# Build a local, ad-hoc signed Apple Silicon application with Apple's toolchain.
# The app contains only this project's code and an original geometric icon.
repository=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
output="$repository/build/DarkOrbit for Mac.app"

if [ "$(uname -s)" != "Darwin" ]; then
    echo "Build this application on macOS with the Apple command line tools installed." >&2
    exit 1
fi
if ! /usr/bin/xcrun --find swiftc >/dev/null 2>&1; then
    echo "Install the Apple command line tools before building." >&2
    exit 1
fi

cd "$repository"
mkdir -p build
build_staging=$(mktemp -d "$repository/build/.app-build.XXXXXX")
trap 'rm -rf "$build_staging"' EXIT HUP INT TERM
bundle="$build_staging/DarkOrbit for Mac.app"
mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources"
/usr/bin/xcrun swiftc \
    -O \
    -target arm64-apple-macos14.6 \
    -module-name DarkOrbitCommunity \
    -module-cache-path "$build_staging/module-cache" \
    -file-compilation-dir . \
    -file-prefix-map "$repository"=. \
    Sources/*.swift \
    -o "$bundle/Contents/MacOS/DarkOrbitCommunity"
/usr/bin/xcrun swiftc -O -module-cache-path "$build_staging/module-cache" -file-compilation-dir . -file-prefix-map "$repository"=. \
    scripts/make-icon.swift -o "$build_staging/make-icon"
"$build_staging/make-icon" "$bundle/Contents/Resources/AppIcon.icns"
cp Resources/Info.plist "$bundle/Contents/Info.plist"
/usr/bin/plutil -lint "$bundle/Contents/Info.plist"
/usr/bin/codesign --force --sign - "$bundle"
/usr/bin/codesign --verify --strict "$bundle"
# Replace only this generated app. The staging cleanup removes the old build.
if [ -e "$output" ]; then
    mv "$output" "$build_staging/previous-build.app"
fi
mv "$bundle" "$output"
echo "Built build/DarkOrbit for Mac.app with a local ad-hoc signature."
echo "This build is not Developer ID signed or notarized."
