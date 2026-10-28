import Foundation

public struct StorageCapabilities: Sendable, Equatable {
    public let batch: Bool
    public let streaming: Bool
    public let ttl: Bool

    public init(batch: Bool = false, streaming: Bool = false, ttl: Bool = false) {
        self.batch = batch
        self.streaming = streaming
        self.ttl = ttl
    }
}

public struct SetOptions: Sendable, Equatable {
    public let ttl: Int?

    public init(ttl: Int? = nil) {
        self.ttl = ttl
    }
}

public struct CacheStats: Sendable, Equatable {
    public var hits: Int = 0
    public var misses: Int = 0
    public var sets: Int = 0
    public var deletes: Int = 0

    public init(hits: Int = 0, misses: Int = 0, sets: Int = 0, deletes: Int = 0) {
        self.hits = hits
        self.misses = misses
        self.sets = sets
        self.deletes = deletes
    }
}

public protocol StorageAdapter: Sendable {
    var capabilities: StorageCapabilities { get }
    func get(key: String) async throws -> Data?
    func set(key: String, value: Data, options: SetOptions?) async throws
    func delete(key: String) async throws -> Bool
    func has(key: String) async throws -> Bool
    func clear() async throws
    func close() async throws
}

public enum KVDockError: Error, Equatable, CustomStringConvertible {
    case invalidTTL(Int)
    case invalidKey(String)
    case serializationError(String)
    case adapterError(String)

    public var description: String {
        switch self {
        case .invalidTTL(let val):
            return "kvdock: invalid ttl \(val), expected positive integer"
        case .invalidKey(let key):
            return "kvdock: invalid key '\(key)', key cannot be empty"
        case .serializationError(let msg):
            return "kvdock: serialization error: \(msg)"
        case .adapterError(let msg):
            return "kvdock: adapter error: \(msg)"
        }
    }
}
