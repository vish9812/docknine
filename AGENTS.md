# Repository Guidelines

## Project Structure & Module Organization

DockNine is a dependency-free macOS 14+ menu bar utility that opens pinned Dock apps with Option+1–9.

- `Sources/DockNine/`: AppKit lifecycle, menu UI, Carbon hotkeys, and native app launching.
- `Sources/DockNineCore/`: Dock preference parsing and shortcut state management; keep independently testable logic here.
- `Tests/DockNineCoreTests/`: XCTest coverage for mapping and controller behavior.
- `Resources/Info.plist`: App bundle metadata.
- `scripts/build-app.sh`: Release build, bundle assembly, and signing.
- `specs/`: Behavior requirements. Read both specs; spec 02 supersedes parts of spec 01.
- `readme.md`: Setup, implementation limits, and observed integration results.

Generated `.build/`, `.swiftpm/`, and `build/` directories are ignored by Git.

## Build, Test, and Development Commands

Use Xcode with Swift 5.9 or later. Open `Package.swift` in Xcode to edit or debug.

- `swift build`: Compile a debug build.
- `./scripts/build-app.sh`: Produce `build/DockNine.app`, signed ad hoc by default. Set `DOCKNINE_SIGN_IDENTITY` for a specific local signing identity.
- `open build/DockNine.app`: Run the bundled menu bar app; use this for launch-at-login checks.
- `.build/debug/DockNine --print-mapping`: Inspect this Mac’s mapping without activating apps, after a debug build.

Run tests with repository-local caches:

```sh
CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache" \
SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache" \
swift test --disable-sandbox --cache-path "$PWD/.build/cache"
```

## Coding Style & Naming Conventions

Follow existing Swift style: four-space indentation, `UpperCamelCase` types, and `lowerCamelCase` members. Match filenames to their principal type. Preserve `@MainActor` isolation for UI and controller work. No formatter or linter is configured; keep changes focused and comments limited to non-obvious contracts.

## Testing Guidelines

Use `XCTestCase` classes named `*Tests` and descriptive `test...` methods. Reproduce bugs before fixing and add focused regressions. No numeric coverage threshold is configured. Exercise mapping errors, slot preservation, held keys, and in-flight suppression when relevant.

For activation or hotkey changes, exercise the affected behavior on macOS against spec 02. Record observed results and untested setups; mocks cannot establish window or Space behavior.

## Commit & Pull Request Guidelines

History favors short, imperative subjects, such as `Fix shortcut conflict detection`; occasional `docs:` prefixes appear. Follow that style. PRs should explain behavior changes, reference relevant specs or issues, and report automated and live validation. Include screenshots for visible menu changes and update documented limits when behavior changes.
