import Foundation

/// Протокол для опционального логирования в TiledMap
public protocol TiledMapLogger {
    func debug(_ message: String, metadata: [String: String]?)
    func info(_ message: String, metadata: [String: String]?)
    func warning(_ message: String, metadata: [String: String]?)
    func error(_ message: String, metadata: [String: String]?)
}

/// Дефолтная реализация логгера, которая ничего не делает
public struct EmptyLogger: TiledMapLogger {
    public init() {}

    public func debug(_ message: String, metadata: [String: String]?) {}
    public func info(_ message: String, metadata: [String: String]?) {}
    public func warning(_ message: String, metadata: [String: String]?) {}
    public func error(_ message: String, metadata: [String: String]?) {}
}
