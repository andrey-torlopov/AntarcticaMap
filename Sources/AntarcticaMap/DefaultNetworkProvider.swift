import Foundation
import UIKit

/// Protocol for synchronous network data loading with concurrency control.
///
/// Defines a contract for network providers that can fetch data from URLs synchronously.
/// Implementations should handle thread safety and limit concurrent requests using semaphores or similar mechanisms.
public protocol NetworkProvider: Sendable {
    /// Synchronously fetches data from the specified URL.
    ///
    /// This method blocks the calling thread until the data is fetched.
    /// The provider internally manages concurrency limits.
    ///
    /// - Parameter url: The URL to fetch data from
    /// - Returns: The fetched data
    /// - Throws: An error if the fetch operation fails
    func fetchData(from url: URL) throws -> Data
}

/// Example implementation of a network provider based on URLSession with semaphore-based concurrency control.
///
/// This implementation uses URLSession for network requests and includes:
/// - Synchronous blocking API (safe to call from any thread)
/// - Semaphore-based concurrency limiting (prevents overwhelming the system)
/// - Thread-safe request deduplication (multiple threads requesting the same URL share one fetch)
/// - Proper error handling and timeout support
///
/// Example usage:
/// ```swift
/// let provider = DefaultNetworkProvider(maxConcurrentRequests: 6)
/// let data = try provider.fetchData(from: url)
/// ```
public final class DefaultNetworkProvider: NetworkProvider {
    private let session: URLSession
    private let semaphore: DispatchSemaphore
    private let queue = DispatchQueue(label: "com.antarctica.network.provider", attributes: .concurrent)

    // Thread-safe task tracking for deduplication
    // Using a class wrapper to make the mutable state isolated
    private final class TaskStorage: @unchecked Sendable {
        var activeTasks: [URL: DispatchGroup] = [:]
        var taskResults: [URL: Result<Data, Error>] = [:]
        let lock = NSLock()

        func getActiveTask(for url: URL) -> DispatchGroup? {
            lock.lock()
            defer { lock.unlock() }
            return activeTasks[url]
        }

        func setActiveTask(_ group: DispatchGroup, for url: URL) {
            lock.lock()
            defer { lock.unlock() }
            activeTasks[url] = group
        }

        func getResult(for url: URL) -> Result<Data, Error>? {
            lock.lock()
            defer { lock.unlock() }
            return taskResults[url]
        }

        func setResult(_ result: Result<Data, Error>, for url: URL) {
            lock.lock()
            defer { lock.unlock() }
            taskResults[url] = result
        }

        func removeActiveTask(for url: URL) {
            lock.lock()
            defer { lock.unlock() }
            activeTasks.removeValue(forKey: url)
        }

        func removeResult(for url: URL) {
            lock.lock()
            defer { lock.unlock() }
            taskResults.removeValue(forKey: url)
        }
    }

    private let storage = TaskStorage()

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
        self.semaphore = DispatchSemaphore(value: maxConcurrentRequests)
    }

    /// Synchronously fetches data from the specified URL with automatic request deduplication.
    ///
    /// If multiple threads request the same URL simultaneously, they will wait for and share
    /// the same underlying network request to avoid duplicate fetches.
    ///
    /// This method blocks the calling thread until the data is fetched or an error occurs.
    ///
    /// - Parameter url: The URL to fetch data from
    /// - Returns: The fetched data
    /// - Throws: URLError or other network-related errors
    public func fetchData(from url: URL) throws -> Data {
        // Check if there's already an active request for this URL
        if let existingGroup = storage.getActiveTask(for: url) {
            // Wait for the existing request to complete
            existingGroup.wait()

            // Retrieve the result
            guard let result = storage.getResult(for: url) else {
                throw URLError(.unknown)
            }

            return try result.get()
        }

        // Create a new group for this request
        let group = DispatchGroup()
        group.enter()
        storage.setActiveTask(group, for: url)

        // Wait for semaphore (limits concurrent requests)
        semaphore.wait()

        // Perform the actual fetch
        let result: Result<Data, Error>
        do {
            let data = try fetchDataInternal(from: url)
            result = .success(data)
        } catch {
            result = .failure(error)
        }

        // Signal semaphore
        semaphore.signal()

        // Store result and notify waiting threads
        storage.setResult(result, for: url)
        storage.removeActiveTask(for: url)

        group.leave()

        // Clean up result after a short delay to avoid memory bloat
        queue.asyncAfter(deadline: .now() + 1.0) { [storage] in
            storage.removeResult(for: url)
        }

        return try result.get()
    }

    /// Internal synchronous fetch implementation using URLSession.
    ///
    /// - Parameter url: The URL to fetch data from
    /// - Returns: The fetched data
    /// - Throws: URLError or other network-related errors
    private func fetchDataInternal(from url: URL) throws -> Data {
        var fetchedData: Data?
        var fetchError: Error?
        let fetchGroup = DispatchGroup()

        fetchGroup.enter()
        let task = session.dataTask(with: url) { data, response, error in
            defer { fetchGroup.leave() }

            if let error = error {
                fetchError = error
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                fetchError = URLError(.badServerResponse)
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                fetchError = URLError(.badServerResponse)
                return
            }

            fetchedData = data
        }

        task.resume()
        fetchGroup.wait()

        if let error = fetchError {
            throw error
        }

        guard let data = fetchedData else {
            throw URLError(.unknown)
        }

        return data
    }
}
