#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache"
swift build --disable-sandbox --cache-path "$PWD/.build/cache" -c release
bin_dir="$(swift build --disable-sandbox --cache-path "$PWD/.build/cache" -c release --show-bin-path)"
app="$(pwd)/build/DockNine.app"
mkdir -p "$app/Contents/MacOS"
cp "$bin_dir/DockNine" "$app/Contents/MacOS/DockNine"
cp Resources/Info.plist "$app/Contents/Info.plist"
codesign --force --sign "${DOCKNINE_SIGN_IDENTITY:--}" "$app"
printf 'Built %s\n' "$app"
