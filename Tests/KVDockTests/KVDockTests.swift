import Testing
import Foundation
@testable import KVDock

struct KVDockTests {
    @Test func basicSetAndGet() async throws {
        let adapter = MemoryAdapter()
        let dock = try KVDock(adapter: adapter)

        try await dock.set("user:1", "alice")
        let cached: String? = try await dock.get("user:1")
        #expect(cached == "alice")

        let stats = await dock.stats
        #expect(stats.sets == 1)
        #expect(stats.hits == 1)
    }

    @Test func cacheMissTracking() async throws {
        let adapter = MemoryAdapter()
        let dock = try KVDock(adapter: adapter)

        let missing: String? = try await dock.get("unknown")
        #expect(missing == nil)

        let stats = await dock.stats
        #expect(stats.misses == 1)
    }

    @Test func getOrSetEvaluatesOnlyOnMiss() async throws {
        let adapter = MemoryAdapter()
        let dock = try KVDock(adapter: adapter)

        var calls = 0
        let val1 = try await dock.getOrSet("calc") {
            calls += 1
            return 42
        }
        #expect(val1 == 42)
        #expect(calls == 1)

        let val2 = try await dock.getOrSet("calc") {
            calls += 1
            return 99
        }
        #expect(val2 == 42)
        #expect(calls == 1)

        let stats = await dock.stats
        #expect(stats.hits == 1)
        #expect(stats.misses == 1)
    }

    @Test func ttlExpiration() async throws {
        let adapter = MemoryAdapter()
        let dock = try KVDock(adapter: adapter)

        try await dock.set("short", "lived", options: SetOptions(ttl: 20))
        let immediate: String? = try await dock.get("short")
        #expect(immediate == "lived")

        try await Task.sleep(for: .milliseconds(50))
        let expired: String? = try await dock.get("short")
        #expect(expired == nil)
    }

    @Test func rejectsInvalidTTL() async throws {
        let adapter = MemoryAdapter()
        let dock = try KVDock(adapter: adapter)

        await #expect(throws: KVDockError.self) {
            try await dock.set("k", "v", options: SetOptions(ttl: 0))
        }

        await #expect(throws: KVDockError.self) {
            try await dock.set("k", "v", options: SetOptions(ttl: -10))
        }
    }

    @Test func lruEviction() async throws {
        let adapter = MemoryAdapter(maxEntries: 2)
        let dock = try KVDock(adapter: adapter)

        try await dock.set("a", 1)
        try await dock.set("b", 2)
        // access a so b becomes LRU
        let _: Int? = try await dock.get("a")
        try await dock.set("c", 3)

        let valA: Int? = try await dock.get("a")
        let valB: Int? = try await dock.get("b")
        let valC: Int? = try await dock.get("c")

        #expect(valA == 1)
        #expect(valB == nil) // evicted!
        #expect(valC == 3)
    }
}
