# 02 — App activation

Status: Complete. This change follows [spec 01](01-scope-and-behavior.md) and supersedes its window-creation restriction and unconditional no-op for already active apps.

## Goal

Pressing Option+1–9 should try to give the user a usable window for the selected pinned app: launch it, bring a window forward, restore a minimized window, or request a window when none is open.

Keep the implementation small and readable, use native macOS behavior, and add no preferences or customization. Elaborate recovery machinery is outside this change.

## Expected behavior

| Selected app state | Expected result |
| --- | --- |
| Not running | Open the pinned app and request foreground activation. |
| Running with an available window | Activate the app and let macOS choose the window to bring forward. |
| Hidden | Unhide and activate it through normal macOS app-opening behavior. |
| All windows minimized | Ask the app to reopen and try to restore an existing window. Prefer restoration over creating an extra window. |
| Running without windows | Ask the app to reopen so it can create or present a window, including when it is already active. |
| Already active with a usable window | Keep it active without deliberately cycling windows, hiding it, or requesting an additional document. |
| Open request in progress | Avoid issuing another request for that app until the request completes. |
| Empty slot, disabled shortcuts, or unavailable mapping | Take no action, as in spec 01. |
| App missing or open request fails | Preserve its slot and report the failure through the existing menu bar UI. |

A physical key press still triggers at most one request. Holding the key must not repeatedly reopen the app. A later press may issue another request.

Window restoration and creation are best effort: the target app controls how it responds. Finder should be able to present a Finder window when none is open. Apps that normally show a start screen or document chooser may show that instead of a blank document. A successful open request does not prove that a window appeared.

## Spaces, displays, and multiple windows

- Keep the same Dock numbering across all displays and Spaces, including full-screen and Split View sessions.
- Respect macOS Space-switching settings and app assignments to desktops or displays. Do not force a particular Space.
- Bring existing windows forward where macOS places them. Do not move windows between monitors, exit full screen, or rearrange Split View.
- Let macOS and the target app choose among multiple windows. Do not add window cycling or window selection.
- Connecting or disconnecting a monitor must not change the mapping rules. macOS remains responsible for repositioning windows.

## App identity and multiple instances

- Open the exact app bundle pinned in the Dock. Two installed copies with the same name or bundle identifier must not be treated as interchangeable.
- Reuse a running instance of that bundle rather than deliberately launching another process.
- Prefer an already active matching instance. Otherwise, use native macOS instance selection where possible; do not add activation-history tracking solely to rank instances.
- Do not add process selection UI. If native APIs cannot enforce exact bundle identity or choose an instance reliably, document the limitation before introducing additional machinery.

## Implementation approach and limits

Use a native open/reopen request through `NSWorkspace`, with foreground activation requested and creation of a new application instance disabled. Apple's [reopen documentation](https://developer.apple.com/documentation/appkit/nsapplicationdelegate/applicationshouldhandlereopen%28_%3Ahasvisiblewindows%3A%29?language=objc) describes how apps respond when the Dock or Finder reopens them; it does not guarantee identical window behavior in every app.

The implementation opens only the pinned file URL and disables `allowsRunningApplicationSubstitution` to prevent substitution of another installed copy. macOS chooses among running instances of that bundle; the open configuration cannot guarantee preference for an already active instance.

Issue reopen requests even for an active app, which can have no windows or only minimized windows. Preserve the held-key and in-flight-request guards.

Use normal app-opening behavior rather than simulating Command+N or sending app-specific document commands. Do not add Accessibility, Input Monitoring, Automation permissions, private window-management APIs, polling for windows, retry loops, or a background activation-history service.

If native reopening does not restore or present a window in a particular app, record the observed behavior. Forced window control or app-specific workarounds require a separate decision. Retain the existing error UI; an app declining to show a window is not automatically an API failure.
