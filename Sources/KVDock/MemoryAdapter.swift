import Foundation

public actor MemoryAdapter: StorageAdapter {
    private struct Entry: Sendable {
        let value: Data
        let expiresAt: ContinuousClock.Instant?
    }

    public nonisolated let capabilities = StorageCapabilities(batch: false, streaming: false, ttl: true)

    private var storage: [String: Entry] = [:]
    private var order: [String] = []
    private let maxEntries: Int
    private let clock = ContinuousClock()

    public init(maxEntries: Int = 10_000) {
        self.maxEntries = maxEntries
    }

    private func pruneExpired(key: String, entry: Entry) -> Bool {
        if let expiresAt = entry.expiresAt, clock.now >= expiresAt {
            storage.removeValue(forKey: key)
            if let idx = order.firstIndex(of: key) {
                order.remove(at: idx)
            }
            return true
        }
        return false
    }

    public func get(key: String) async throws -> Data? {
        guard let entry = storage[key] else { return nil }
        if pruneExpired(key: key, entry: entry) {
            return nil
        }
        // move to end (MRU)
        if let idx = order.firstIndex(of: key) {
            order.remove(at: idx)
        }
        order.append(key)
        return entry.value
    }

    public func set(key: String, value: Data, options: SetOptions?) async throws {
        let expiresAt: ContinuousClock.Instant? = options?.ttl.map { ttl in
            clock.now.advanced(by: .milliseconds(ttl))
        }

        if storage[key] == nil && storage.count >= maxEntries {
            // evict LRU
            if !order.isEmpty {
                let lruKey = order.removeFirst()
                storage.removeValue(forKey: lruKey)
            }
        }

        storage[key] = Entry(value: value, expiresAt: expiresAt)
        if let idx = order.firstIndex(of: key) {
            order.remove(at: idx)
        }
        order.append(key)
    }

    public func delete(key: String) async throws -> Bool {
        let existed = storage.removeValue(forKey: key) != nil
        if let idx = order.firstIndex(of: key) {
            order.remove(at: idx)
        }
        return existed
    }

    public func has(key: String) async throws -> Bool {
        guard let entry = storage[key] else { return false }
        return !pruneExpired(key: key, entry: entry)
    }

    public func clear() async throws {
        storage.removeAll()
        order.removeAll()
    }

    public func close() async throws {
        storage.removeAll()
        order.removeAll()
    }
}
