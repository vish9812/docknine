import AppKit
import DockNineCore

@MainActor
final class AppLauncher: AppLaunching {
    func activate(_ app: DockApp, completion: @escaping @MainActor (String?) -> Void) {
        guard let url = app.url, FileManager.default.fileExists(atPath: url.path),
              Bundle(url: url) != nil else {
            completion("\(app.name) is missing. Restore it at its pinned location, or remove and re-pin it in the Dock.")
            return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.createsNewApplicationInstance = false
        // A running copy at another location must not replace the pinned bundle.
        configuration.allowsRunningApplicationSubstitution = false
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, error in
            Task { @MainActor in
                completion(error.map { "Cannot open \(app.name): \($0.localizedDescription). Check the app or re-pin it in the Dock." })
            }
        }
    }
}
