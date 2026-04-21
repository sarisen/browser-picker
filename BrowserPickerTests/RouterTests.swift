import XCTest
@testable import BrowserPicker

final class RouterTests: XCTestCase {

    // MARK: - Default fallback

    func testDefaultBrowserWithNoRules() {
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari"))
        let target = router.route(url: URL(string: "https://example.com")!, from: nil)
        XCTAssertEqual(target.browserID, "com.apple.Safari")
        XCTAssertFalse(target.incognito)
        XCTAssertFalse(target.newWindow)
    }

    func testDefaultBrowserWhenNoRuleMatches() {
        let rule = RoutingRule(
            id: "r1", priority: 10,
            app: AppMatcher(name: "Slack"),
            browserID: "com.google.Chrome"
        )
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari", rules: [rule]))
        let target = router.route(url: URL(string: "https://example.com")!, from: SourceApp(name: "Discord", bundleID: "com.discord"))
        XCTAssertEqual(target.browserID, "com.apple.Safari")
    }

    // MARK: - App matching

    func testRoutesByAppName() {
        let rule = RoutingRule(id: "r1", priority: 10, app: AppMatcher(name: "Slack"), browserID: "com.google.Chrome")
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari", rules: [rule]))
        let target = router.route(url: URL(string: "https://example.com")!, from: SourceApp(name: "Slack", bundleID: "com.tinyspeck.slackmacgap"))
        XCTAssertEqual(target.browserID, "com.google.Chrome")
    }

    func testRoutesByBundleID() {
        let rule = RoutingRule(id: "r1", priority: 10, app: AppMatcher(bundleID: "com.tinyspeck.slackmacgap"), browserID: "com.google.Chrome")
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari", rules: [rule]))
        let target = router.route(url: URL(string: "https://example.com")!, from: SourceApp(name: "Slack", bundleID: "com.tinyspeck.slackmacgap"))
        XCTAssertEqual(target.browserID, "com.google.Chrome")
    }

    func testAppRuleRequiresSourceApp() {
        let rule = RoutingRule(id: "r1", priority: 10, app: AppMatcher(name: "Slack"), browserID: "com.google.Chrome")
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari", rules: [rule]))
        let target = router.route(url: URL(string: "https://example.com")!, from: nil)
        XCTAssertEqual(target.browserID, "com.apple.Safari")
    }

    // MARK: - URL matching

    func testRoutesByExactDomain() {
        let rule = RoutingRule(id: "r1", priority: 10, url: URLMatcher(exact: "github.com"), browserID: "org.mozilla.firefox")
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari", rules: [rule]))
        let target = router.route(url: URL(string: "https://github.com/user/repo")!, from: nil)
        XCTAssertEqual(target.browserID, "org.mozilla.firefox")
    }

    func testRoutesByWildcardDomain() {
        let rule = RoutingRule(id: "r1", priority: 10, url: URLMatcher(pattern: "*.github.com"), browserID: "org.mozilla.firefox")
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari", rules: [rule]))
        let target = router.route(url: URL(string: "https://gist.github.com/user")!, from: nil)
        XCTAssertEqual(target.browserID, "org.mozilla.firefox")
    }

    func testRoutesByContainsDomain() {
        let rule = RoutingRule(id: "r1", priority: 10, url: URLMatcher(contains: "google"), browserID: "com.google.Chrome")
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari", rules: [rule]))
        let target = router.route(url: URL(string: "https://mail.google.com")!, from: nil)
        XCTAssertEqual(target.browserID, "com.google.Chrome")
    }

    // MARK: - Combined matching

    func testRequiresBothAppAndDomainToMatch() {
        let rule = RoutingRule(
            id: "r1", priority: 10,
            app: AppMatcher(name: "Slack"),
            url: URLMatcher(exact: "github.com"),
            browserID: "com.google.Chrome"
        )
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari", rules: [rule]))

        // Both match
        let hit = router.route(url: URL(string: "https://github.com")!, from: SourceApp(name: "Slack", bundleID: "com.slack"))
        XCTAssertEqual(hit.browserID, "com.google.Chrome")

        // App matches, domain doesn't
        let miss1 = router.route(url: URL(string: "https://gitlab.com")!, from: SourceApp(name: "Slack", bundleID: "com.slack"))
        XCTAssertEqual(miss1.browserID, "com.apple.Safari")

        // Domain matches, app doesn't
        let miss2 = router.route(url: URL(string: "https://github.com")!, from: SourceApp(name: "Discord", bundleID: "com.discord"))
        XCTAssertEqual(miss2.browserID, "com.apple.Safari")
    }

    // MARK: - Priority

    func testHigherPriorityWins() {
        let low  = RoutingRule(id: "low",  priority: 10,  url: URLMatcher(exact: "github.com"), browserID: "org.mozilla.firefox")
        let high = RoutingRule(id: "high", priority: 100, url: URLMatcher(exact: "github.com"), browserID: "com.google.Chrome")
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari", rules: [low, high]))
        let target = router.route(url: URL(string: "https://github.com")!, from: nil)
        XCTAssertEqual(target.browserID, "com.google.Chrome")
    }

    func testPriorityIsIndependentOfInsertionOrder() {
        let low  = RoutingRule(id: "low",  priority: 10,  url: URLMatcher(exact: "github.com"), browserID: "org.mozilla.firefox")
        let high = RoutingRule(id: "high", priority: 100, url: URLMatcher(exact: "github.com"), browserID: "com.google.Chrome")
        // Inserted in reverse order
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari", rules: [high, low]))
        let target = router.route(url: URL(string: "https://github.com")!, from: nil)
        XCTAssertEqual(target.browserID, "com.google.Chrome")
    }

    // MARK: - Launch target flags

    func testIncognitoFromRule() {
        let rule = RoutingRule(id: "r1", priority: 10, url: URLMatcher(exact: "private.com"), browserID: "com.google.Chrome", incognito: true)
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari", rules: [rule]))
        let target = router.route(url: URL(string: "https://private.com")!, from: nil)
        XCTAssertTrue(target.incognito)
        XCTAssertFalse(target.newWindow)
    }

    func testNewWindowFromRule() {
        let rule = RoutingRule(id: "r1", priority: 10, url: URLMatcher(exact: "popup.io"), browserID: "com.google.Chrome", newWindow: true)
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari", rules: [rule]))
        let target = router.route(url: URL(string: "https://popup.io")!, from: nil)
        XCTAssertTrue(target.newWindow)
    }

    func testDefaultTargetHasNoFlags() {
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari"))
        let target = router.route(url: URL(string: "https://example.com")!, from: nil)
        XCTAssertFalse(target.incognito)
        XCTAssertFalse(target.newWindow)
    }

    // MARK: - Edge cases / graceful fallback

    func testRuleWithNoMatchersIsSkipped() {
        let rule = RoutingRule(id: "empty", priority: 100, browserID: "com.google.Chrome")
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari", rules: [rule]))
        let target = router.route(url: URL(string: "https://example.com")!, from: nil)
        XCTAssertEqual(target.browserID, "com.apple.Safari")
    }

    func testInvalidRegexInURLMatcherFallsBack() {
        let rule = RoutingRule(id: "bad", priority: 100, url: URLMatcher(pattern: "[invalid(regex"), browserID: "com.google.Chrome")
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari", rules: [rule]))
        let target = router.route(url: URL(string: "https://example.com")!, from: nil)
        XCTAssertEqual(target.browserID, "com.apple.Safari")
    }

    func testInvalidRegexInAppMatcherFallsBack() {
        let rule = RoutingRule(id: "bad", priority: 100, app: AppMatcher(pattern: "[invalid"), browserID: "com.google.Chrome")
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari", rules: [rule]))
        let target = router.route(url: URL(string: "https://example.com")!, from: SourceApp(name: "Slack", bundleID: "com.slack"))
        XCTAssertEqual(target.browserID, "com.apple.Safari")
    }

    func testURLWithNoHostFallsBack() {
        let rule = RoutingRule(id: "r1", priority: 100, url: URLMatcher(exact: "github.com"), browserID: "com.google.Chrome")
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari", rules: [rule]))
        let target = router.route(url: URL(string: "file:///path/to/file.html")!, from: nil)
        XCTAssertEqual(target.browserID, "com.apple.Safari")
    }

    func testEmptyURLMatcherFallsBack() {
        let rule = RoutingRule(id: "r1", priority: 100, url: URLMatcher(), browserID: "com.google.Chrome")
        XCTAssertTrue(rule.url!.isEmpty)
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari", rules: [rule]))
        let target = router.route(url: URL(string: "https://example.com")!, from: nil)
        XCTAssertEqual(target.browserID, "com.apple.Safari")
    }

    func testEmptyAppMatcherFallsBack() {
        let rule = RoutingRule(id: "r1", priority: 100, app: AppMatcher(), browserID: "com.google.Chrome")
        XCTAssertTrue(rule.app!.isEmpty)
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari", rules: [rule]))
        let target = router.route(url: URL(string: "https://example.com")!, from: SourceApp(name: "Slack", bundleID: "com.slack"))
        XCTAssertEqual(target.browserID, "com.apple.Safari")
    }

    func testValidRuleMatchesAfterInvalidRule() {
        let invalid = RoutingRule(id: "bad",   priority: 200, url: URLMatcher(pattern: "[invalid"), browserID: "org.mozilla.firefox")
        let valid   = RoutingRule(id: "good",  priority: 100, url: URLMatcher(exact: "github.com"), browserID: "com.google.Chrome")
        let router = Router(config: PickerConfig(defaultBrowserID: "com.apple.Safari", rules: [invalid, valid]))
        let target = router.route(url: URL(string: "https://github.com")!, from: nil)
        XCTAssertEqual(target.browserID, "com.google.Chrome")
    }

    // MARK: - Immutability

    func testRouterDoesNotReflectExternalConfigChanges() {
        var config = PickerConfig(defaultBrowserID: "com.apple.Safari")
        let router = Router(config: config)

        // Mutate original config — router should still use the snapshot
        config.defaultBrowserID = "com.google.Chrome"
        let target = router.route(url: URL(string: "https://example.com")!, from: nil)
        XCTAssertEqual(target.browserID, "com.apple.Safari")
    }
}
