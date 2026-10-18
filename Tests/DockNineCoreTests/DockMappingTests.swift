import XCTest
@testable import DockNineCore

final class DockMappingTests: XCTestCase {
    private func app(_ name: String, path: String? = nil) -> [String: Any] {
        ["tile-type": "file-tile", "tile-data": [
            "file-label": name, "bundle-identifier": "example.\(name)",
            "file-data": ["_CFURLString": path ?? "file:///Applications/\(name).app/"],
        ]]
    }

    private func parse(_ entries: [[String: Any]], extra: [String: Any] = [:]) throws -> [DockApp] {
        var root = extra
        root["persistent-apps"] = entries
        return try DockMapping.apps(from: PropertyListSerialization.data(fromPropertyList: root, format: .binary, options: 0))
    }

    func testFinderAndPinnedOrderExcludeOtherDockItems() throws {
        let folder: [String: Any] = ["tile-type": "directory-tile"]
        let file: [String: Any] = ["tile-type": "file-tile", "tile-data": [
            "file-data": ["_CFURLString": "file:///Users/test/readme.txt"],
        ]]
        let result = try parse([
            app("Safari"), ["tile-type": "spacer-tile"], folder, file, app("Terminal"),
        ], extra: ["recent-apps": [app("Recent")], "persistent-others": [folder, app("Other")]])
        XCTAssertEqual(result.map(\.name), ["Finder", "Safari", "Terminal"])
    }

    func testReorderAndRemovalAreReflectedInNextSnapshot() throws {
        XCTAssertEqual(try parse([app("Safari"), app("Terminal")]).map(\.name), ["Finder", "Safari", "Terminal"])
        XCTAssertEqual(try parse([app("Terminal"), app("Safari")]).map(\.name), ["Finder", "Terminal", "Safari"])
        XCTAssertEqual(try parse([app("Terminal")]).map(\.name), ["Finder", "Terminal"])
    }

    func testMissingAppRetainsSlotAndEncodedPathsAreDecoded() throws {
        let result = try parse([app("Missing"), app("Code", path: "file:///Applications/Visual%20Studio%20Code.app/")])
        XCTAssertEqual(result.map(\.name), ["Finder", "Missing", "Code"])
        XCTAssertEqual(result[2].url?.path, "/Applications/Visual Studio Code.app")
    }

    func testIdentifierWithoutURLRetainsUnavailableSlot() throws {
        let result = try parse([["tile-type": "file-tile", "tile-data": [
            "bundle-identifier": "example.missing", "file-label": "Missing",
        ]], app("Terminal")])
        XCTAssertEqual(result.map(\.name), ["Finder", "Missing", "Terminal"])
        XCTAssertNil(result[1].url)
    }

    func testMaximumNineAndEmptyDock() throws {
        XCTAssertEqual(try parse((1...12).map { app("App\($0)") }).map(\.name), ["Finder"] + (1...8).map { "App\($0)" })
        XCTAssertEqual(try parse([]), [DockMapping.finder])
    }

    func testUnreadableAndAmbiguousEntriesFailRatherThanShiftSlots() throws {
        XCTAssertThrowsError(try DockMapping.apps(from: Data("broken".utf8)))
        let missing = try PropertyListSerialization.data(fromPropertyList: [:], format: .xml, options: 0)
        XCTAssertThrowsError(try DockMapping.apps(from: missing))
        XCTAssertThrowsError(try parse([["tile-type": "file-tile"], app("Terminal")]))
    }
}
