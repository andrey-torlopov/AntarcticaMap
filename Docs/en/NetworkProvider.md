# Network Provider Guide

## Overview

`EarthDataTilesSource` supports an optional network provider for controlled synchronous tile loading. This enables:

- Control over concurrent network requests
- Automatic request deduplication for identical URLs
- Thread-safe synchronous loading
- Better performance with multiple tiles

## Architecture

### NetworkProvider Protocol

```swift
public protocol NetworkProvider: Sendable {
    func fetchData(from url: URL) throws -> Data
}
```

The protocol requires a single method that synchronously fetches data from a URL. Implementations should handle:
- Thread safety
- Concurrency limits
- Error handling

### DefaultNetworkProvider

The library includes a default implementation based on URLSession:

```swift
let provider = DefaultNetworkProvider(maxConcurrentRequests: 6)
```

**Features:**
- Semaphore-based concurrency limiting (default: 6 concurrent requests)
- Automatic request deduplication (multiple requests to the same URL share one fetch)
- Thread-safe operation using locks and dispatch groups
- Proper error handling and timeout support

## Usage

### Basic Usage

```swift
import AntarcticaMap

// Create network provider
let networkProvider = DefaultNetworkProvider(maxConcurrentRequests: 6)

// Create parameters
let params = EarthDataMapRequest(
    minX: -4_000_000,
    minY: -4_000_000,
    maxX: 4_000_000,
    maxY: 4_000_000,
    width: 512,
    height: 512,
    date: Date(),
    layers: .modisTerraCorrectedReflectance
)

// Create map view controller with network provider
let mapVC = TiledMapViewController(
    params: params,
    imageSize: CGSize(width: 8192, height: 8192),
    networkProvider: networkProvider
)
```

### Without Network Provider (Legacy Mode)

```swift
// Omit networkProvider for direct synchronous loading
let mapVC = TiledMapViewController(
    params: params,
    imageSize: CGSize(width: 8192, height: 8192)
    // networkProvider: nil (default)
)
```

## How It Works

### With Network Provider

1. Tile loading request is made
2. Network provider checks for existing requests to the same URL
3. If duplicate request exists, waits for its completion and shares the result
4. If new request, acquires semaphore slot (waits if limit reached)
5. Performs synchronous network fetch
6. Releases semaphore and shares result with waiting threads
7. Cleans up cached results after a short delay

### Without Network Provider

1. Tile loading request is made
2. Direct synchronous fetch using `Data(contentsOf:)`
3. No concurrency control or deduplication

## Request Deduplication

When multiple threads request the same URL simultaneously:

```swift
// 3 tiles request the same URL:
Thread 1: fetchData(from: url) → Creates network request
Thread 2: fetchData(from: url) → Waits for Thread 1, shares result
Thread 3: fetchData(from: url) → Waits for Thread 1, shares result

// Result: 1 network request instead of 3
```

This significantly reduces network traffic and improves performance.

## Concurrency Control

The `maxConcurrentRequests` parameter limits simultaneous network requests:

```swift
let provider = DefaultNetworkProvider(maxConcurrentRequests: 6)

// First 6 requests execute in parallel
// Requests 7+ wait for earlier requests to complete
```

### Recommended Settings

```swift
// For mobile devices or slow connections
DefaultNetworkProvider(maxConcurrentRequests: 2-4)

// For normal Wi-Fi (default)
DefaultNetworkProvider(maxConcurrentRequests: 6)

// For fast connections
DefaultNetworkProvider(maxConcurrentRequests: 8-10)
```

## Event Monitoring

Monitor network activity using the `onEvent` handler:

```swift
mapViewController.onEvent = { event in
    guard let type = event["type"] as? String else { return }
    
    switch type {
    case "tile_request":
        if let url = event["url"] as? String,
           let mode = event["mode"] as? String {
            print("📥 [\(mode)] Requesting: \(url)")
        }
        
    case "tile_loaded":
        if let desc = event["request_description"] as? String,
           let mode = event["mode"] as? String,
           let size = event["data_size"] as? Int {
            print("✅ [\(mode)] Loaded: \(desc) (\(size) bytes)")
        }
        
    case "error":
        if let message = event["message"] as? String {
            print("❌ Error: \(message)")
        }
        
    default:
        break
    }
}
```

The `mode` field indicates the loading method:
- `"network_provider"`: Using network provider
- `"sync"`: Direct synchronous loading

## Custom Network Provider

You can implement your own network provider for specific needs:

```swift
final class CustomNetworkProvider: NetworkProvider {
    private let session: URLSession
    private let cache: URLCache
    
    init(cache: URLCache) {
        self.cache = cache
        
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.requestCachePolicy = .returnCacheDataElseLoad
        
        self.session = URLSession(configuration: config)
    }
    
    func fetchData(from url: URL) throws -> Data {
        // Custom caching logic
        // Custom retry logic
        // Custom authentication
        // etc.
        
        var fetchedData: Data?
        var fetchError: Error?
        let group = DispatchGroup()
        
        group.enter()
        let task = session.dataTask(with: url) { data, response, error in
            defer { group.leave() }
            
            if let error = error {
                fetchError = error
                return
            }
            
            fetchedData = data
        }
        
        task.resume()
        group.wait()
        
        if let error = fetchError {
            throw error
        }
        
        guard let data = fetchedData else {
            throw URLError(.unknown)
        }
        
        return data
    }
}

// Usage
let customProvider = CustomNetworkProvider(cache: URLCache.shared)
let mapVC = TiledMapViewController(
    params: params,
    imageSize: imageSize,
    networkProvider: customProvider
)
```

## Performance Comparison

| Feature | With NetworkProvider | Without NetworkProvider |
|---------|---------------------|------------------------|
| Concurrency Control | ✅ Configurable limit | ❌ Unlimited |
| Request Deduplication | ✅ Automatic | ❌ None |
| Thread Safety | ✅ Built-in | ⚠️ Manual |
| Performance | ⚡ Optimized | 🐢 Basic |
| Memory Usage | ✅ Controlled | ⚠️ Higher |

## Best Practices

1. **Reuse the Provider**
   ```swift
   // Good: Single instance
   class MapManager {
       static let networkProvider = DefaultNetworkProvider(maxConcurrentRequests: 6)
   }
   
   // Bad: Creating new instances
   func createMap() {
       let provider = DefaultNetworkProvider() // Don't do this repeatedly
   }
   ```

2. **Tune Concurrency**
   ```swift
   // Monitor network activity and adjust
   let provider = DefaultNetworkProvider(maxConcurrentRequests: optimalValue)
   ```

3. **Handle Events**
   ```swift
   // Use events to track loading progress
   mapVC.onEvent = { event in
       // Log, update UI, collect metrics, etc.
   }
   ```

4. **Test Both Modes**
   ```swift
   // Ensure your app works with and without network provider
   #if DEBUG
   let provider: NetworkProvider? = useNetworkProvider ? DefaultNetworkProvider() : nil
   #else
   let provider = DefaultNetworkProvider(maxConcurrentRequests: 6)
   #endif
   ```

## Error Handling

The `TileLoadError` enum defines possible errors:

```swift
public enum TileLoadError: Error {
    case noNetworkProvider      // Network provider required but not set
    case invalidURL             // Invalid tile URL
    case imageDecodingFailed    // Failed to decode image data
}
```

Network provider errors (URLError, etc.) are propagated from the underlying implementation.

## Migration Guide

### Updating Existing Code

**Before:**
```swift
let mapVC = TiledMapViewController(
    params: params,
    imageSize: imageSize
)
```

**After (with network provider):**
```swift
let networkProvider = DefaultNetworkProvider(maxConcurrentRequests: 6)
let mapVC = TiledMapViewController(
    params: params,
    imageSize: imageSize,
    networkProvider: networkProvider
)
```

**After (backward compatible, no changes):**
```swift
let mapVC = TiledMapViewController(
    params: params,
    imageSize: imageSize
    // networkProvider defaults to nil
)
```

## Testing

Create a mock provider for unit tests:

```swift
final class MockNetworkProvider: NetworkProvider {
    var mockData: [URL: Data] = [:]
    var shouldFail = false
    
    func fetchData(from url: URL) throws -> Data {
        if shouldFail {
            throw URLError(.timedOut)
        }
        
        guard let data = mockData[url] else {
            throw URLError(.fileDoesNotExist)
        }
        
        return data
    }
}

// Usage in tests
func testTileLoading() {
    let mockProvider = MockNetworkProvider()
    mockProvider.mockData[tileURL] = testImageData
    
    let mapVC = TiledMapViewController(
        params: testParams,
        imageSize: testSize,
        networkProvider: mockProvider
    )
    
    // Test tile loading...
}
```

## Conclusion

The network provider system offers:
- ✅ Better performance through concurrency control
- ✅ Reduced network traffic via deduplication
- ✅ Thread-safe operation
- ✅ Backward compatibility
- ✅ Extensibility for custom implementations

Choose the mode that best fits your app's requirements.
