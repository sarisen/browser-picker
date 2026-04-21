import XCTest
@testable import BrowserPicker

final class URLMatcherTests: XCTestCase {

    // MARK: - Exact match

    func testExactMatchHits() {
        let m = URLMatcher(exact: "github.com")
        XCTAssertTrue(m.matches(url: URL(string: "https://github.com/user/repo")!))
    }

    func testExactMatchMisses() {
        let m = URLMatcher(exact: "github.com")
        XCTAssertFalse(m.matches(url: URL(string: "https://api.github.com")!))
    }

    func testExactMatchIsCaseInsensitive() {
        let m = URLMatcher(exact: "GitHub.com")
        XCTAssertTrue(m.matches(url: URL(string: "https://github.com")!))
    }

    func testExactMatchIgnoresPath() {
        let m = URLMatcher(exact: "example.com")
        XCTAssertTrue(m.matches(url: URL(string: "https://example.com/some/path?q=1")!))
    }

    // MARK: - Wildcard pattern

    func testWildcardSubdomainHits() {
        let m = URLMatcher(pattern: "*.github.com")
        XCTAssertTrue(m.matches(url: URL(string: "https://gist.github.com")!))
        XCTAssertTrue(m.matches(url: URL(string: "https://api.github.com")!))
    }

    func testWildcardDoesNotMatchBase() {
        let m = URLMatcher(pattern: "*.github.com")
        XCTAssertFalse(m.matches(url: URL(string: "https://github.com")!))
    }

    func testWildcardMatchesRootDomain() {
        let m = URLMatcher(pattern: "github.com")
        XCTAssertTrue(m.matches(url: URL(string: "https://github.com")!))
    }

    func testWildcardDotEscaping() {
        let m = URLMatcher(pattern: "example.com")
        XCTAssertFalse(m.matches(url: URL(string: "https://exampleXcom")!))
    }

    func testWildcardFullGlob() {
        let m = URLMatcher(pattern: "*.google.*")
        XCTAssertTrue(m.matches(url: URL(string: "https://mail.google.com")!))
        XCTAssertTrue(m.matches(url: URL(string: "https://maps.google.de")!))
    }

    func testRawRegexInPattern() {
        let m = URLMatcher(pattern: "^(dev|staging)\\.example\\.com$")
        XCTAssertTrue(m.matches(url: URL(string: "https://dev.example.com")!))
        XCTAssertTrue(m.matches(url: URL(string: "https://staging.example.com")!))
        XCTAssertFalse(m.matches(url: URL(string: "https://prod.example.com")!))
    }

    func testInvalidPatternReturnsFalse() {
        let m = URLMatcher(pattern: "[invalid(")
        XCTAssertFalse(m.matches(url: URL(string: "https://example.com")!))
    }

    // MARK: - Contains match

    func testContainsHits() {
        let m = URLMatcher(contains: "google")
        XCTAssertTrue(m.matches(url: URL(string: "https://mail.google.com")!))
        XCTAssertTrue(m.matches(url: URL(string: "https://googleapis.com")!))
    }

    func testContainsMisses() {
        let m = URLMatcher(contains: "google")
        XCTAssertFalse(m.matches(url: URL(string: "https://bing.com")!))
    }

    func testContainsIsCaseInsensitive() {
        let m = URLMatcher(contains: "GOOGLE")
        XCTAssertTrue(m.matches(url: URL(string: "https://google.com")!))
    }

    // MARK: - Edge cases

    func testNoHostReturnsFalse() {
        let m = URLMatcher(exact: "github.com")
        XCTAssertFalse(m.matches(url: URL(string: "file:///local.html")!))
    }

    func testEmptyMatcherReturnsFalse() {
        let m = URLMatcher()
        XCTAssertTrue(m.isEmpty)
        XCTAssertFalse(m.matches(url: URL(string: "https://example.com")!))
    }

    func testLocalhostExact() {
        let m = URLMatcher(exact: "localhost")
        XCTAssertTrue(m.matches(url: URL(string: "http://localhost:3000")!))
    }

    func testIPAddressExact() {
        let m = URLMatcher(exact: "192.168.1.1")
        XCTAssertTrue(m.matches(url: URL(string: "http://192.168.1.1:8080/api")!))
    }
}
