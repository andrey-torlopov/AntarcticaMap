import Foundation
import UIKit

/// Protocol for asynchronous network data loading.
///
/// Defines a contract for network providers that can fetch data from URLs asynchronously.
/// This allows for custom implementations with different caching, retry, or concurrency strategies.
public protocol NetworkProvider: Sendable {
    /// Asynchronously fetches data from the specified URL.
    ///
    /// - Parameter url: The URL to fetch data from
    /// - Returns: The fetched data
    /// - Throws: An error if the fetch operation fails
    func fetchData(from url: URL) async throws -> Data
}

/// URLSession-based implementation of NetworkProvider with concurrent request management.
///
/// This implementation uses URLSession for network requests and includes:
/// - Automatic request deduplication (multiple requests for the same URL share a single fetch)
/// - Configurable maximum concurrent requests
/// - Proper error handling and timeout support
///
/// Example usage:
/// ```swift
/// let provider = URLSessionNetworkProvider(maxConcurrentRequests: 6)
/// let data = try await provider.fetchData(from: url)
/// ```
public actor URLSessionNetworkProvider: NetworkProvider {
    private let session: URLSession
    private let maxConcurrentRequests: Int
    private var activeTasks: [URL: Task<Data, Error>] = [:]
    private var activeRequestCount: Int = 0

    /// Initializes the network provider.
    ///
    /// - Parameters:
    ///   - session: URLSession to use for requests. Default is `.shared`
    ///   - maxConcurrentRequests: Maximum number of concurrent network requests. Default is 6
    public init(
        session: URLSession = .shared,
        maxConcurrentRequests: Int = 6
    ) {
        self.session = session
        self.maxConcurrentRequests = maxConcurrentRequests
    }

    /// Fetches data from the specified URL with automatic request deduplication.
    ///
    /// If multiple callers request the same URL simultaneously, they will share
    /// the same underlying network request to avoid duplicate fetches.
    ///
    /// - Parameter url: The URL to fetch data from
    /// - Returns: The fetched data
    /// - Throws: URLError or other network-related errors
    public func fetchData(from url: URL) async throws -> Data {
        // Check if there's already an active task for this URL
        if let existingTask = activeTasks[url] {
            return try await existingTask.value
        }

        // Create a new task for this URL
        let task = Task<Data, Error> {
            // Wait if we've reached the concurrent request limit
            while activeRequestCount >= maxConcurrentRequests {
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }

            activeRequestCount += 1

            defer {
                activeRequestCount -= 1
                activeTasks.removeValue(forKey: url)
            }

            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }

            return data
        }

        activeTasks[url] = task
        return try await task.value
    }
}
