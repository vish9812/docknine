import Foundation

@MainActor
public protocol AppLaunching: AnyObject {
    func activate(_ app: DockApp, completion: @escaping @MainActor (String?) -> Void)
}

@MainActor
public final class ShortcutController {
    public var enabled = true
    public private(set) var apps: [DockApp] = []
    public private(set) var mappingFailure: String?
    public private(set) var activationFailure: String?
    private var pressed: Set<Int> = []
    private var launching: Set<DockAppKey> = []
    private let launcher: AppLaunching

    public init(launcher: AppLaunching) { self.launcher = launcher }

    public func updateMapping(_ result: Result<[DockApp], Error>) {
        switch result {
        case .success(let apps):
            self.apps = Array(apps.prefix(9))
            mappingFailure = nil
        case .failure(let error):
            apps = []
            mappingFailure = error.localizedDescription
        }
    }

    public func release(slot: Int) { pressed.remove(slot) }
    public func resetKeys() { pressed.removeAll() }

    public func press(slot: Int) {
        guard enabled, (1...9).contains(slot), pressed.insert(slot).inserted,
              mappingFailure == nil, apps.indices.contains(slot - 1) else { return }
        let app = apps[slot - 1]
        let key = DockAppKey(app: app)
        guard !launching.contains(key) else { return }
        launching.insert(key)
        activationFailure = nil
        launcher.activate(app) { [weak self] failure in
            guard let self else { return }
            self.launching.remove(key)
            self.activationFailure = failure
        }
    }

    private struct DockAppKey: Hashable {
        let url: URL?
        let identifier: String?
        init(app: DockApp) {
            url = app.url
            identifier = app.bundleIdentifier
        }
    }
}
