import Foundation

public struct DockApp: Equatable, Sendable {
    public let name: String
    public let bundleIdentifier: String?
    public let url: URL?

    public init(name: String, bundleIdentifier: String?, url: URL?) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.url = url
    }
}

public enum DockMappingError: LocalizedError {
    case unreadable
    case invalidApp

    public var errorDescription: String? {
        switch self {
        case .unreadable: return "Cannot read the Dock mapping. Check Dock settings, then choose Refresh Mapping."
        case .invalidApp: return "A pinned Dock app could not be identified. Remove or re-pin that entry, then refresh."
        }
    }
}

public enum DockMapping {
    public static let finder = DockApp(
        name: "Finder", bundleIdentifier: "com.apple.finder",
        url: URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")
    )

    public static func apps(from data: Data) throws -> [DockApp] {
        guard let root = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let entries = root["persistent-apps"] as? [[String: Any]] else {
            throw DockMappingError.unreadable
        }
        // Finder is fixed in the Dock and is absent from persistent-apps on macOS.
        var apps = [finder]
        for entry in entries {
            guard entry["tile-type"] as? String == "file-tile" else { continue }
            guard let tile = entry["tile-data"] as? [String: Any] else {
                throw DockMappingError.invalidApp
            }
            let identifier = tile["bundle-identifier"] as? String
            let file = tile["file-data"] as? [String: Any]
            let rawURL = file?["_CFURLString"] as? String
            let url = rawURL.flatMap(URL.init(string:)).flatMap { $0.isFileURL ? $0 : nil }
            let isApp = url?.pathExtension.lowercased() == "app" || !(identifier ?? "").isEmpty
            guard isApp else {
                if url == nil { throw DockMappingError.invalidApp }
                continue
            }
            if identifier == finder.bundleIdentifier || url == finder.url { continue }
            let name = tile["file-label"] as? String ?? url?.deletingPathExtension().lastPathComponent ?? identifier ?? "Unavailable app"
            apps.append(DockApp(name: name, bundleIdentifier: identifier, url: url))
            if apps.count == 9 { break }
        }
        return apps
    }
}
