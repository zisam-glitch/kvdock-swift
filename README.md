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

## License

MIT
