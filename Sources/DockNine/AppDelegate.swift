import AppKit
import DockNineCore
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let controller = ShortcutController(launcher: AppLauncher())
    private let hotKeys = GlobalHotKeys()
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var shortcutFailure: String?
    private var loginFailure: String?
    private let dockPreferences = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Preferences/com.apple.dock.plist")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "⌥#"
        statusItem.button?.toolTip = "DockNine — Option+1–9"
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        controller.enabled = !UserDefaults.standard.bool(forKey: "disabled")
        hotKeys.onKey = { [weak self] slot, down in
            guard let self else { return }
            if down {
                self.refreshMapping()
                self.controller.press(slot: slot)
            } else {
                self.controller.release(slot: slot)
            }
        }
        refreshMapping()
        if controller.enabled { enableShortcuts() }
        timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshMapping() }
        }
        RunLoop.main.add(timer!, forMode: .common)
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(woke), name: NSWorkspace.didWakeNotification, object: nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        hotKeys.unregister()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    func menuWillOpen(_ menu: NSMenu) {
        refreshMapping()
        menu.removeAllItems()
        add("DockNine — Option+1–9", to: menu)
        let enabled = add("Enable DockNine", action: #selector(toggleEnabled), to: menu)
        enabled.state = controller.enabled ? .on : .off
        menu.addItem(.separator())
        for (index, app) in controller.apps.enumerated() {
            add("\(index + 1)  \(app.name)", to: menu)
        }
        let failures = [controller.mappingFailure, controller.activationFailure, shortcutFailure, loginFailure].compactMap { $0 }
        if !failures.isEmpty {
            menu.addItem(.separator())
            for failure in failures {
                let item = add(failure, to: menu)
                item.toolTip = failure
            }
        }
        menu.addItem(.separator())
        add("Refresh Mapping", action: #selector(refreshFromMenu), to: menu)
        let login = add("Launch at Login", action: #selector(toggleLogin), to: menu)
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        if SMAppService.mainApp.status == .requiresApproval {
            add("Approve DockNine in Login Items…", action: #selector(openLoginSettings), to: menu)
        }
        menu.addItem(.separator())
        let quit = add("Quit DockNine", action: #selector(quit), to: menu)
        quit.keyEquivalent = "q"
    }

    @discardableResult
    private func add(_ title: String, action: Selector? = nil, to menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.isEnabled = action != nil
        menu.addItem(item)
        return item
    }

    private func refreshMapping() {
        controller.updateMapping(Result { try DockMapping.apps(from: Data(contentsOf: dockPreferences)) })
        updateIndicator()
    }

    private func updateIndicator() {
        let failed = controller.mappingFailure != nil || controller.activationFailure != nil || shortcutFailure != nil || loginFailure != nil
        statusItem.button?.title = failed ? "⌥#!" : (controller.enabled ? "⌥#" : "⌥# Off")
    }

    private func enableShortcuts() {
        do {
            try hotKeys.register()
            shortcutFailure = nil
        } catch {
            shortcutFailure = error.localizedDescription
            controller.enabled = false
        }
        updateIndicator()
    }

    @objc private func toggleEnabled() {
        controller.enabled.toggle()
        controller.resetKeys()
        if controller.enabled {
            refreshMapping()
            enableShortcuts()
        } else {
            hotKeys.unregister()
            shortcutFailure = nil
        }
        UserDefaults.standard.set(!controller.enabled, forKey: "disabled")
        updateIndicator()
    }

    @objc private func refreshFromMenu() { refreshMapping() }
    @objc private func woke() { controller.resetKeys(); refreshMapping() }
    @objc private func quit() { NSApp.terminate(nil) }
    @objc private func openLoginSettings() { SMAppService.openSystemSettingsLoginItems() }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
            loginFailure = nil
        } catch {
            loginFailure = "Cannot change launch at login: \(error.localizedDescription). Run DockNine from its app bundle and try again."
        }
        updateIndicator()
    }
}
