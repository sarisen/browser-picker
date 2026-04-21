import Foundation

struct PickerConfig: Codable, Sendable {
    var defaultBrowserID: String
    var rules: [RoutingRule]

    init(defaultBrowserID: String = "", rules: [RoutingRule] = []) {
        self.defaultBrowserID = defaultBrowserID
        self.rules = rules
    }

    enum CodingKeys: String, CodingKey {
        case defaultBrowserID = "default_browser"
        case rules
    }
}

struct RoutingRule: Codable, Identifiable, Sendable {
    var id: String
    var priority: Int
    var app: AppMatcher?
    var url: URLMatcher?
    var browserID: String
    var incognito: Bool
    var newWindow: Bool

    init(
        id: String = UUID().uuidString,
        priority: Int = 0,
        app: AppMatcher? = nil,
        url: URLMatcher? = nil,
        browserID: String,
        incognito: Bool = false,
        newWindow: Bool = false
    ) {
        self.id = id
        self.priority = priority
        self.app = app
        self.url = url
        self.browserID = browserID
        self.incognito = incognito
        self.newWindow = newWindow
    }

    enum CodingKeys: String, CodingKey {
        case id, priority, app, url
        case browserID = "browser_id"
        case incognito
        case newWindow = "new_window"
    }
}

struct LaunchTarget: Sendable {
    let browserID: String
    let incognito: Bool
    let newWindow: Bool

    static func plain(browserID: String) -> LaunchTarget {
        LaunchTarget(browserID: browserID, incognito: false, newWindow: false)
    }
}

struct AppMatcher: Codable, Sendable {
    var name: String?
    var bundleID: String?
    var pattern: String?

    enum CodingKeys: String, CodingKey {
        case name
        case bundleID = "bundle_id"
        case pattern
    }

    init(name: String? = nil, bundleID: String? = nil, pattern: String? = nil) {
        self.name = name
        self.bundleID = bundleID
        self.pattern = pattern
    }

    var isEmpty: Bool { name == nil && bundleID == nil && pattern == nil }

    func matches(appName: String, bundleID: String) -> Bool {
        if let name, name == appName { return true }
        if let id = self.bundleID, id == bundleID { return true }
        if let pattern { return regexTest(pattern: pattern, in: appName) }
        return false
    }
}

struct URLMatcher: Codable, Sendable {
    var exact: String?
    var pattern: String?
    var contains: String?

    init(exact: String? = nil, pattern: String? = nil, contains: String? = nil) {
        self.exact = exact
        self.pattern = pattern
        self.contains = contains
    }

    var isEmpty: Bool { exact == nil && pattern == nil && contains == nil }

    func matches(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        if let exact { return exact.lowercased() == host }
        if let pattern { return wildcardTest(pattern: pattern.lowercased(), against: host) }
        if let contains { return host.contains(contains.lowercased()) }
        return false
    }
}

private func regexTest(pattern: String, in text: String) -> Bool {
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
    return regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
}

private func wildcardTest(pattern: String, against host: String) -> Bool {
    let regexPattern: String
    if pattern.hasPrefix("^") {
        regexPattern = pattern
    } else {
        regexPattern = "^" + pattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*") + "$"
    }
    guard let regex = try? NSRegularExpression(pattern: regexPattern) else { return false }
    return regex.firstMatch(in: host, range: NSRange(host.startIndex..., in: host)) != nil
}
