import Foundation

final class ConfigStore {
    static let shared = ConfigStore()

    let configURL: URL

    private init() {
        configURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/browserpicker/config.json")
    }

    static func __testing(url: URL) -> ConfigStore { ConfigStore(url: url) }

    private init(url: URL) { configURL = url }

    var directoryURL: URL { configURL.deletingLastPathComponent() }

    func prepare() {
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    func load() throws -> PickerConfig {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return PickerConfig()
        }
        let data = try Data(contentsOf: configURL)
        return try JSONDecoder().decode(PickerConfig.self, from: data)
    }

    func save(_ config: PickerConfig) throws {
        prepare()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(config).write(to: configURL)
    }

    func loadOrDefault() -> PickerConfig {
        do {
            return try load()
        } catch {
            AppLog.error("Config load failed: \(error.localizedDescription)")
            return PickerConfig()
        }
    }
}
