# kvdock-swift

Actor-isolated, high-performance key-value caching layer for Swift with zero external dependencies.

## Architecture

- **`KVDock`**: Swift 6 actor ensuring data race safety under concurrent access.
- **`StorageAdapter`**: Protocol decoupling storage backends from cache operations.
- **`MemoryAdapter`**: In-memory storage with LRU eviction and monotonic `ContinuousClock` TTL enforcement.
- **Cache-Aside Pattern**: `getOrSet` evaluates async fetchers only on misses.
- **Telemetry**: Hit, miss, set, and delete counters.

## Usage

```swift
import KVDock

let adapter = MemoryAdapter(maxEntries: 10_000)
let dock = try KVDock(adapter: adapter, prefix: "app", defaultTTL: 60_000)

// set with 60s TTL
try await dock.set("session:abc", user, options: SetOptions(ttl: 60_000))

// cache-aside
let profile = try await dock.getOrSet("user:123") {
    try await database.fetchUser(id: 123)
}
```

## Testing

```sh
swift test
```

## Ecosystem & Other Languages

KVDock is also available natively across multiple languages with matching design principles and zero external dependencies:

- **TypeScript / Node.js**: [`kvdock` on npm](https://www.npmjs.com/package/kvdock) | [`zisam-glitch/kvdock`](https://github.com/zisam-glitch/kvdock) — Reference implementation with Tiered Caching, SQLite, S3, Redis, and Cloudflare KV adapters.
- **Rust**: [`zisam-glitch/kvdock-rs`](https://github.com/zisam-glitch/kvdock-rs) — Thread-safe caching layer with monotonic `Instant` TTL.
- **Go**: [`zisam-glitch/kvdock-go`](https://github.com/zisam-glitch/kvdock-go) — Generic key-value cache engine with atomic telemetry.
- **Kotlin**: [`zisam-glitch/kvdock-kt`](https://github.com/zisam-glitch/kvdock-kt) — Thread-safe $O(1)$ LRU key-value cache for the JVM.

## License

MIT
