# DockNine

Launch or focus your first nine pinned Dock apps with **Option+1–9**.
A macOS 14+ menu bar app with no third-party dependencies.

Finder is slot 1. Folders, spacers, recent apps, and unpinned running apps
are skipped. The mapping follows your Dock order automatically.

## Build and run

Requires Xcode with Swift 5.9 or later.

```sh
./scripts/build-app.sh
open build/DockNine.app
```

For regular use, copy `build/DockNine.app` to `~/Applications` and launch it
from there before enabling **Launch at Login** in the menu.

Builds are signed ad hoc by default and are not notarized. Set
`DOCKNINE_SIGN_IDENTITY` to use a local signing identity.

## Usage

Press **Option+1–9** to open or focus an app. Use the menu bar icon to view
the mapping, enable or disable shortcuts, refresh, or configure launch at login.
A `!` indicates an error; open the menu for details.

Shortcuts use the top-row number keys and cannot be customized. A shortcut
conflict disables DockNine until resolved. Window restoration and Space
switching depend on macOS and the target app.

[MIT License](LICENSE)
