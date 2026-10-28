import Foundation

public actor KVDock {
    private let adapter: any StorageAdapter
    private let prefix: String
    private let defaultTTL: Int?
    private(set) public var stats = CacheStats()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        adapter: any StorageAdapter,
        prefix: String = "",
        defaultTTL: Int? = nil
    ) throws {
        if let ttl = defaultTTL, ttl <= 0 {
            throw KVDockError.invalidTTL(ttl)
        }
        self.adapter = adapter
        self.prefix = prefix
        self.defaultTTL = defaultTTL
    }

    private func resolveKey(_ key: String) throws -> String {
        guard !key.isEmpty else {
            throw KVDockError.invalidKey(key)
        }
        return prefix.isEmpty ? key : "\(prefix):\(key)"
    }

    private func validateTTL(_ ttl: Int?) throws {
        if let ttl = ttl, ttl <= 0 {
            throw KVDockError.invalidTTL(ttl)
        }
    }

    public func get<T: Decodable>(_ key: String) async throws -> T? {
        let resolved = try resolveKey(key)
        guard let data = try await adapter.get(key: resolved) else {
            stats.misses += 1
            return nil
        }
        do {
            let decoded = try decoder.decode(T.self, from: data)
            stats.hits += 1
            return decoded
        } catch {
            throw KVDockError.serializationError(error.localizedDescription)
        }
    }

    public func set<T: Encodable>(_ key: String, _ value: T, options: SetOptions? = nil) async throws {
        let resolved = try resolveKey(key)
        let ttl = options?.ttl ?? defaultTTL
        try validateTTL(ttl)

        do {
            let data = try encoder.encode(value)
            try await adapter.set(key: resolved, value: data, options: SetOptions(ttl: ttl))
            stats.sets += 1
        } catch let err as KVDockError {
            throw err
        } catch {
            throw KVDockError.serializationError(error.localizedDescription)
        }
    }

    public func getOrSet<T: Codable>(
        _ key: String,
        options: SetOptions? = nil,
        fetcher: () async throws -> T
    ) async throws -> T {
        if let cached: T = try await get(key) {
            return cached
        }
        let fresh = try await fetcher()
        try await set(key, fresh, options: options)
        return fresh
    }

    public func delete(_ key: String) async throws -> Bool {
        let resolved = try resolveKey(key)
        let deleted = try await adapter.delete(key: resolved)
        if deleted {
            stats.deletes += 1
        }
        return deleted
    }

    public func has(_ key: String) async throws -> Bool {
        let resolved = try resolveKey(key)
        return try await adapter.has(key: resolved)
    }

    public func clear() async throws {
        try await adapter.clear()
    }
}
