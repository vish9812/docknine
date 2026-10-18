# 01 — Scope and behavior

Status: Complete. [Spec 02](02-app-activation.md) supersedes the window behavior noted below.

## Purpose

DockNine is a macOS menu bar app that provides numbered shortcuts for pinned Dock apps. A shortcut brings the selected app forward, launching it when necessary.

## First-version scope

- Support slots 1–9, assigned automatically from Dock order. Slot 10 and a shortcut using 0 are outside this version.
- Count pinned application icons in visual order: left to right for a horizontal Dock, top to bottom for a vertical Dock. Finder counts as slot 1 when it is the first icon.
- Exclude unpinned running apps, suggested/recent apps, minimized-window thumbnails, folders, files, spacers, and Trash. Excluded items do not consume slots.
- Use the same mapping regardless of the active app, display, or Space. Dock visibility and magnification do not affect numbering.
- Follow changes to pinned apps and their order without requiring a DockNine restart. Read Dock preferences every two seconds and refresh before shortcuts, when the menu opens, after wake, and on enable. Dock preference writes can lag visible changes; the preference format is a macOS implementation detail.
- Run from the menu bar, with an enable/disable control and quit action. Launch at login is optional and user controlled.

Option+1–9 is the implemented shortcut. Shortcut customization is out of scope. If any hotkey registration fails, release all nine shortcuts, disable DockNine, and report the conflict in the menu.

## Shortcut behavior

| Selected app state | Expected result |
| --- | --- |
| Not running | Launch it and request foreground activation. |
| Running in the background or hidden | Activate it and bring its available window forward. |
| Already active | Keep it active; do not toggle hiding, cycle windows, or request another window. |
| Launch in progress | Avoid issuing duplicate launch requests for repeated presses. |
| No app assigned to the slot | Take no action. |
| Assigned app cannot be found or opened | Keep its slot, leave other mappings unchanged, and expose an actionable failure through the menu bar UI. |

A physical key press triggers at most one action; holding the key must not repeatedly launch or activate the app. A later press may activate it again.

In this initial version, DockNine does not explicitly create documents or windows. An app may create a window as part of its own launch or reopen behavior. Spec 02 replaces this behavior with best-effort restoration and window requests, and defines activation across Spaces and full-screen sessions.

When disabled or quit, DockNine performs no shortcut actions. An unavailable mapping must not cause a shortcut to launch a guessed app. Unreadable or ambiguous mapping data blocks actions until a successful refresh. A `!` in the menu bar indicates a failure; the menu shows its reason and recovery action.

## Out of scope

- Manual app-to-number assignments, window cycling, and per-Space or per-display mappings.
- Drawing number badges over Dock icons or changing Dock contents.
- App Store distribution, an updater, cloud sync, accounts, and network services.

## Acceptance examples

1. With Finder, Safari, and Terminal pinned in that order, slots 1, 2, and 3 select those apps. An unpinned running app and a Downloads folder do not affect numbering.
2. Selecting Terminal launches it if closed and focuses it if running. Pressing its shortcut again does not deliberately create a second window or hide it.
3. After Terminal is moved ahead of Safari, slot 2 selects Terminal and slot 3 selects Safari without restarting DockNine.
4. With only three eligible apps, slots 4–9 do nothing.
5. An unavailable app retains its numbered slot until its Dock entry is removed; its shortcut reports the failure without activating another app.
6. Disabling DockNine stops shortcut actions; enabling it restores them using the refreshed mapping.
