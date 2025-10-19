import Foundation

/// Протокол для опционального логирования в TiledMap
public protocol TiledMapLogger {
    func debug(_ message: String, metadata: [String: String]?)
    func info(_ message: String, metadata: [String: String]?)
    func warning(_ message: String, metadata: [String: String]?)
    func error(_ message: String, metadata: [String: String]?)
}

/// Дефолтная реализация логгера, которая ничего не делает
public struct NoOpLogger: TiledMapLogger {
    public init() {}

    public func debug(_ message: String, metadata: [String: String]?) {}
    public func info(_ message: String, metadata: [String: String]?) {}
    public func warning(_ message: String, metadata: [String: String]?) {}
    public func error(_ message: String, metadata: [String: String]?) {}
}

/// Простой консольный логгер для отладки
public struct ConsoleLogger: TiledMapLogger {
    public init() {}

    public func debug(_ message: String, metadata: [String: String]?) {
        log("DEBUG", message, metadata)
    }

    public func info(_ message: String, metadata: [String: String]?) {
        log("INFO", message, metadata)
    }

    public func warning(_ message: String, metadata: [String: String]?) {
        log("WARNING", message, metadata)
    }

    public func error(_ message: String, metadata: [String: String]?) {
        log("ERROR", message, metadata)
    }

    private func log(_ level: String, _ message: String, _ metadata: [String: String]?) {
        var output = "[\(level)] \(message)"
        if let metadata = metadata, !metadata.isEmpty {
            output += " | \(metadata)"
        }
        print(output)
    }
}
