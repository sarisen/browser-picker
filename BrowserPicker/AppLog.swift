import Foundation
import os.log

enum LogLevel: Int, Comparable, Sendable {
    case debug = 0
    case info = 1
    case warn = 2
    case error = 3

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .debug: return "DEBUG"
        case .info:  return "INFO"
        case .warn:  return "WARN"
        case .error: return "ERROR"
        }
    }
}

enum AppLog {
    private static let subsystem = "com.browserpicker.app"
    private static let osLog = os.Logger(subsystem: subsystem, category: "main")
    private static let formatter: ISO8601DateFormatter = ISO8601DateFormatter()

    static var minimumLevel: LogLevel = .info
    static var writeToFile = true

    private static var logFileURL: URL {
        ConfigStore.shared.directoryURL.appendingPathComponent("browserpicker.log")
    }

    static func debug(_ msg: String) { emit(msg, level: .debug) }
    static func info(_ msg: String)  { emit(msg, level: .info) }
    static func warn(_ msg: String)  { emit(msg, level: .warn) }
    static func error(_ msg: String) { emit(msg, level: .error) }

    private static func emit(_ msg: String, level: LogLevel) {
        guard level >= minimumLevel else { return }

        let line = "[\(formatter.string(from: Date()))] [\(level.label)] \(msg)"
        print(line)

        switch level {
        case .debug: osLog.debug("\(msg)")
        case .info:  osLog.info("\(msg)")
        case .warn:  osLog.warning("\(msg)")
        case .error: osLog.error("\(msg)")
        }

        if writeToFile { appendToFile(line + "\n") }
    }

    private static func appendToFile(_ line: String) {
        guard let data = line.data(using: .utf8) else { return }
        let dir = logFileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        if FileManager.default.fileExists(atPath: logFileURL.path) {
            guard let handle = try? FileHandle(forWritingTo: logFileURL) else { return }
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            _ = try? handle.write(contentsOf: data)
        } else {
            try? data.write(to: logFileURL)
        }
    }

    static func clearLog() {
        try? FileManager.default.removeItem(at: logFileURL)
    }
}
