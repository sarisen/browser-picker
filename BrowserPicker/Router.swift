import Foundation

struct SourceApp: Sendable {
    let name: String
    let bundleID: String
}

protocol Routing: Sendable {
    func route(url: URL, from source: SourceApp?) -> LaunchTarget
}

final class Router: Routing {
    private let config: PickerConfig
    private let sortedRules: [RoutingRule]

    init(config: PickerConfig) {
        self.config = config
        self.sortedRules = config.rules.sorted { $0.priority > $1.priority }
    }

    func route(url: URL, from source: SourceApp?) -> LaunchTarget {
        for rule in sortedRules where evaluate(rule: rule, url: url, source: source) {
            AppLog.debug("Rule '\(rule.id)' matched → \(rule.browserID)")
            return LaunchTarget(browserID: rule.browserID, incognito: rule.incognito, newWindow: rule.newWindow)
        }
        AppLog.debug("No rule matched, using default → \(config.defaultBrowserID)")
        return LaunchTarget.plain(browserID: config.defaultBrowserID)
    }

    private func evaluate(rule: RoutingRule, url: URL, source: SourceApp?) -> Bool {
        guard rule.app != nil || rule.url != nil else { return false }
        if rule.app != nil && source == nil { return false }

        if let matcher = rule.app, let source {
            guard matcher.matches(appName: source.name, bundleID: source.bundleID) else { return false }
        }

        if let matcher = rule.url {
            guard matcher.matches(url: url) else { return false }
        }

        return true
    }
}
