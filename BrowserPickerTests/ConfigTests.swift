import XCTest
@testable import BrowserPicker

final class ConfigTests: XCTestCase {

    // MARK: - PickerConfig encoding/decoding

    func testRoundTrip() throws {
        let original = PickerConfig(
            defaultBrowserID: "com.apple.Safari",
            rules: [
                RoutingRule(
                    id: "r1",
                    priority: 5,
                    app: AppMatcher(name: "Slack"),
                    url: URLMatcher(pattern: "*.github.com"),
                    browserID: "com.google.Chrome",
                    incognito: true,
                    newWindow: false
                )
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(PickerConfig.self, from: data)

        XCTAssertEqual(decoded.defaultBrowserID, original.defaultBrowserID)
        XCTAssertEqual(decoded.rules.count, 1)
        XCTAssertEqual(decoded.rules[0].id, "r1")
        XCTAssertEqual(decoded.rules[0].priority, 5)
        XCTAssertEqual(decoded.rules[0].browserID, "com.google.Chrome")
        XCTAssertTrue(decoded.rules[0].incognito)
        XCTAssertFalse(decoded.rules[0].newWindow)
        XCTAssertEqual(decoded.rules[0].app?.name, "Slack")
        XCTAssertEqual(decoded.rules[0].url?.pattern, "*.github.com")
    }

    func testEmptyConfigDecodes() throws {
        let json = #"{"default_browser":"","rules":[]}"#
        let config = try JSONDecoder().decode(PickerConfig.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(config.defaultBrowserID, "")
        XCTAssertTrue(config.rules.isEmpty)
    }

    func testOptionalFieldsAreNilWhenAbsent() throws {
        let json = #"{"default_browser":"com.apple.Safari","rules":[{"id":"r1","priority":1,"browser_id":"org.mozilla.firefox","incognito":false,"new_window":false}]}"#
        let config = try JSONDecoder().decode(PickerConfig.self, from: json.data(using: .utf8)!)
        XCTAssertNil(config.rules[0].app)
        XCTAssertNil(config.rules[0].url)
    }

    func testInvalidJSONThrows() {
        let data = "not json at all".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(PickerConfig.self, from: data))
    }

    // MARK: - LaunchTarget

    func testPlainTargetHasNoFlags() {
        let t = LaunchTarget.plain(browserID: "com.apple.Safari")
        XCTAssertEqual(t.browserID, "com.apple.Safari")
        XCTAssertFalse(t.incognito)
        XCTAssertFalse(t.newWindow)
    }

    // MARK: - ConfigStore

    func testConfigStoreRoundTrip() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("browserpicker-test-\(UUID().uuidString).json")

        let store = ConfigStore.__testing(url: tempURL)

        let config = PickerConfig(
            defaultBrowserID: "org.mozilla.firefox",
            rules: [RoutingRule(id: "t1", priority: 1, browserID: "org.mozilla.firefox")]
        )

        try store.save(config)
        let loaded = try store.load()

        XCTAssertEqual(loaded.defaultBrowserID, "org.mozilla.firefox")
        XCTAssertEqual(loaded.rules.count, 1)
        XCTAssertEqual(loaded.rules[0].id, "t1")

        try? FileManager.default.removeItem(at: tempURL)
    }

    func testConfigStoreThrowsOnMissingFile() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent-\(UUID().uuidString).json")
        let store = ConfigStore.__testing(url: tempURL)

        // Missing file returns default config (not an error)
        XCTAssertNoThrow(try store.load())
    }

    func testConfigStoreThrowsOnInvalidJSON() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("bad-\(UUID().uuidString).json")
        try "not json".write(to: tempURL, atomically: true, encoding: .utf8)

        let store = ConfigStore.__testing(url: tempURL)
        XCTAssertThrowsError(try store.load())

        try? FileManager.default.removeItem(at: tempURL)
    }
}
