import AppKit
import DockNineCore

@main
struct DockNineMain {
    @MainActor
    static func main() {
        if CommandLine.arguments.contains("--print-mapping") {
            do {
                let preferences = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent("Library/Preferences/com.apple.dock.plist")
                for (index, app) in try DockMapping.apps(from: Data(contentsOf: preferences)).enumerated() {
                    print("\(index + 1): \(app.name) — \(app.url?.path ?? "unavailable")")
                }
            } catch {
                fputs("DockNine: \(error.localizedDescription)\n", stderr)
                exit(1)
            }
        } else {
            let app = NSApplication.shared
            let delegate = AppDelegate()
            app.delegate = delegate
            withExtendedLifetime(delegate) { app.run() }
        }
    }
}
