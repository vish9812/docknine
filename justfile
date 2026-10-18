build:
    ./scripts/build-app.sh

test:
    CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache" swift test --disable-sandbox --cache-path "$PWD/.build/cache"

run: build
    open build/DockNine.app

install: build
    mkdir -p "$HOME/Applications"
    ditto build/DockNine.app "$HOME/Applications/DockNine.app"
