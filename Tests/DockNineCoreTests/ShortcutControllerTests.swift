import XCTest
@testable import DockNineCore

final class ShortcutControllerTests: XCTestCase {
    @MainActor
    private final class Launcher: AppLaunching {
        var calls: [DockApp] = []
        var completions: [@MainActor (String?) -> Void] = []
        func activate(_ app: DockApp, completion: @escaping @MainActor (String?) -> Void) {
            calls.append(app)
            completions.append(completion)
        }
        func finish(_ failure: String? = nil) { completions.removeFirst()(failure) }
    }

    func testPhysicalPressAndInFlightLaunchAreDeduplicated() async {
        await MainActor.run {
            let launcher = Launcher()
            let controller = ShortcutController(launcher: launcher)
            controller.updateMapping(.success([DockMapping.finder]))
            controller.press(slot: 1)
            launcher.finish()
            controller.press(slot: 1)
            XCTAssertEqual(launcher.calls.count, 1, "Holding a completed shortcut must not activate repeatedly")
            controller.release(slot: 1)
            controller.press(slot: 1)
            controller.release(slot: 1)
            controller.press(slot: 1)
            XCTAssertEqual(launcher.calls.count, 2, "A later press must not duplicate an in-flight launch")
            launcher.finish()
            controller.release(slot: 1)
            controller.press(slot: 1)
            XCTAssertEqual(launcher.calls.count, 3)
        }
    }

    func testFreshPressRequestsReopenAfterSuccessfulActivation() async {
        await MainActor.run {
            let launcher = Launcher()
            let controller = ShortcutController(launcher: launcher)
            controller.updateMapping(.success([DockMapping.finder]))
            controller.press(slot: 1)
            XCTAssertEqual(launcher.calls, [DockMapping.finder], "An active app may have no windows or only minimized windows")
            guard !launcher.completions.isEmpty else { return }
            launcher.finish()
            controller.press(slot: 1)
            XCTAssertEqual(launcher.calls.count, 1, "Holding the key must not send another reopen request")
            controller.release(slot: 1)
            controller.press(slot: 1)
            XCTAssertEqual(launcher.calls.count, 2, "A later physical press may request a window again")
        }
    }

    func testDisabledEmptyAndInvalidSlotsDoNothing() async {
        await MainActor.run {
            let launcher = Launcher()
            let controller = ShortcutController(launcher: launcher)
            controller.updateMapping(.success([DockMapping.finder]))
            for slot in [0, 2, 9, 10] { controller.press(slot: slot) }
            controller.enabled = false
            controller.press(slot: 1)
            controller.enabled = true
            XCTAssertTrue(launcher.calls.isEmpty)
        }
    }

    func testMappingFailureClearsStaleAppsAndRecovers() async {
        await MainActor.run {
            let launcher = Launcher()
            let controller = ShortcutController(launcher: launcher)
            controller.updateMapping(.success([DockMapping.finder]))
            controller.updateMapping(.failure(DockMappingError.unreadable))
            controller.press(slot: 1)
            XCTAssertTrue(launcher.calls.isEmpty)
            XCTAssertTrue(controller.apps.isEmpty)
            XCTAssertNotNil(controller.mappingFailure)
            controller.updateMapping(.success([DockMapping.finder]))
            controller.release(slot: 1)
            controller.press(slot: 1)
            XCTAssertNil(controller.mappingFailure)
            XCTAssertEqual(launcher.calls, [DockMapping.finder])
        }
    }

    func testFailureKeepsMappingAndAllowsRetry() async {
        await MainActor.run {
            let launcher = Launcher()
            let controller = ShortcutController(launcher: launcher)
            let missing = DockApp(name: "Missing", bundleIdentifier: "example.missing", url: nil)
            controller.updateMapping(.success([missing, DockMapping.finder]))
            controller.press(slot: 1)
            launcher.finish("Restore or re-pin Missing")
            XCTAssertEqual(controller.activationFailure, "Restore or re-pin Missing")
            XCTAssertEqual(controller.apps, [missing, DockMapping.finder])
            controller.release(slot: 1)
            controller.press(slot: 1)
            XCTAssertEqual(launcher.calls, [missing, missing])
            XCTAssertNil(controller.activationFailure)
            launcher.finish()
            XCTAssertNil(controller.activationFailure)
        }
    }

    func testInstalledCopiesWithSameIdentifierHaveIndependentRequests() async {
        await MainActor.run {
            let launcher = Launcher()
            let controller = ShortcutController(launcher: launcher)
            let first = DockApp(name: "Browser", bundleIdentifier: "example.browser", url: URL(fileURLWithPath: "/Applications/Browser.app"))
            let second = DockApp(name: "Browser", bundleIdentifier: "example.browser", url: URL(fileURLWithPath: "/Users/test/Applications/Browser.app"))
            controller.updateMapping(.success([first, second, first]))
            controller.press(slot: 1)
            controller.press(slot: 2)
            controller.press(slot: 3)
            XCTAssertEqual(launcher.calls, [first, second], "Deduplicate the same bundle while allowing another pinned copy")
            launcher.finish()
            controller.release(slot: 3)
            controller.press(slot: 3)
            XCTAssertEqual(launcher.calls, [first, second, first])
        }
    }

    func testEnableUsesRefreshedOrder() async {
        await MainActor.run {
            let launcher = Launcher()
            let controller = ShortcutController(launcher: launcher)
            let terminal = DockApp(name: "Terminal", bundleIdentifier: "com.apple.Terminal", url: nil)
            controller.updateMapping(.success([DockMapping.finder, terminal]))
            controller.enabled = false
            controller.updateMapping(.success([terminal, DockMapping.finder]))
            controller.resetKeys()
            controller.enabled = true
            controller.press(slot: 1)
            XCTAssertEqual(launcher.calls, [terminal])
        }
    }
}
