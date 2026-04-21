import XCTest
@testable import BrowserPicker

final class AppMatcherTests: XCTestCase {

    func testNameMatchHits() {
        let m = AppMatcher(name: "Slack")
        XCTAssertTrue(m.matches(appName: "Slack", bundleID: "com.tinyspeck.slackmacgap"))
    }

    func testNameMatchMisses() {
        let m = AppMatcher(name: "Slack")
        XCTAssertFalse(m.matches(appName: "Discord", bundleID: "com.discord"))
    }

    func testNameMatchIsCaseSensitive() {
        let m = AppMatcher(name: "slack")
        XCTAssertFalse(m.matches(appName: "Slack", bundleID: "com.tinyspeck.slackmacgap"))
    }

    func testBundleIDMatchHits() {
        let m = AppMatcher(bundleID: "com.tinyspeck.slackmacgap")
        XCTAssertTrue(m.matches(appName: "Slack", bundleID: "com.tinyspeck.slackmacgap"))
    }

    func testBundleIDMatchMisses() {
        let m = AppMatcher(bundleID: "com.tinyspeck.slackmacgap")
        XCTAssertFalse(m.matches(appName: "Slack", bundleID: "com.discord"))
    }

    func testRegexPatternHits() {
        let m = AppMatcher(pattern: "^Slack.*")
        XCTAssertTrue(m.matches(appName: "Slack for Teams", bundleID: "com.slack"))
        XCTAssertTrue(m.matches(appName: "Slack", bundleID: "com.slack"))
    }

    func testRegexPatternMisses() {
        let m = AppMatcher(pattern: "^Slack$")
        XCTAssertFalse(m.matches(appName: "Slack for Teams", bundleID: "com.slack"))
    }

    func testInvalidRegexReturnsFalse() {
        let m = AppMatcher(pattern: "[invalid(")
        XCTAssertFalse(m.matches(appName: "Slack", bundleID: "com.slack"))
    }

    func testEmptyMatcherReturnsFalse() {
        let m = AppMatcher()
        XCTAssertTrue(m.isEmpty)
        XCTAssertFalse(m.matches(appName: "Slack", bundleID: "com.slack"))
    }
}
