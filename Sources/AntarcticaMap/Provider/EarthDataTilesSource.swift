import UIKit
import Foundation

/// Event handler for tile provider events.
///
/// Receives events from the tile provider as a dictionary with event type and associated metadata.
/// - Parameter event: Dictionary containing event information with keys like "type", "message", "url", etc.
///
/// Example usage:
/// ```swift
/// source.onEvent = { event in
///     if let type = event["type"] as? String {
///         print("Event type: \(type)")
///     }
/// }
/// ```
public typealias TileSourceEventHandler = ([String: Any]) -> Void

/// Tile provider for NASA EarthData imagery using EPSG:3031 projection.
///
/// This class fetches map tiles from NASA GIBS (Global Imagery Browse Services) WMS service
/// for Antarctic region visualization. Supports tiled loading with multiple zoom levels.
///
/// Supports two loading modes:
/// - Synchronous with NetworkProvider: If a network provider is set, tiles are loaded synchronously
///   with semaphore-based concurrency control to limit simultaneous requests
/// - Direct synchronous: If no network provider is set, uses Data(contentsOf:) for direct loading
///
/// Event types emitted via `onEvent`:
/// - `"tile_request"`: Fired when requesting a tile from the server
/// - `"tile_loaded"`: Fired when a tile is successfully loaded
/// - `"warning"`: Fired on validation warnings (invalid scale, non-finite calculations)
/// - `"error"`: Fired on errors (URL creation failure, data loading failure)
public class EarthDataTilesSource: NSObject, TilesSource {
    /// Internal tile request representation
    public struct Request: TileRequest, Sendable {
        public let column: Int
        public let row: Int
        /// Zero-based level index used for tile math
        public let level: Int

        public var description: String { "\(level)_\(column)_\(row)" }

        public init(column: Int, row: Int, level: Int) {
            self.column = column
            self.row = row
            self.level = level
        }
    }

    // MARK: - TilesSource Requirements

    /// Size of individual tile images in pixels
    public let tileSize: CGSize

    /// Total size of the full map image
    public let imageSize: CGSize

    /// Maximum level of detail index (zero-based)
    private let maxLevelIndex: Int

    /// Map request parameters (bounds, date, layer)
    private let params: EarthDataMapRequest

    /// Optional network provider for controlled synchronous tile loading
    ///
    /// When set, tiles will be loaded synchronously using this provider with semaphore-based
    /// concurrency control to limit the number of simultaneous network requests.
    /// When nil, tiles will be loaded directly using Data(contentsOf:).
    public let networkProvider: NetworkProvider?

    /// Optional event handler for tile provider events
    ///
    /// Set this handler to receive notifications about tile requests, loaded tiles, warnings, and errors.
    /// Events are delivered as dictionaries with a "type" key indicating the event type.
    public var onEvent: TileSourceEventHandler?

    // MARK: - Initialization

    /// Initializes the Earth Data tile source.
    ///
    /// - Parameters:
    ///   - params: Map request parameters including geographic bounds, date, and layer selection
    ///   - imageSize: Total size of the full resolution map image. Default is 512×512
    ///   - tileSize: Size of individual tile images. Default is 512×512
    ///   - networkProvider: Optional network provider for controlled synchronous tile loading with concurrency limits. When nil, uses direct Data(contentsOf:) loading
    public init(
        params: EarthDataMapRequest,
        imageSize: CGSize = CGSize(width: 512, height: 512),
        tileSize: CGSize = CGSize(width: 512, height: 512),
        networkProvider: NetworkProvider? = nil
    ) {
        self.params = params
        self.imageSize = imageSize
        self.tileSize = tileSize
        self.networkProvider = networkProvider
        let computedLevels = Int(max(maxLevel(imageSize, firstLevelSize: tileSize), 1))
        self.maxLevelIndex = max(0, computedLevels - 1)

        super.init()
    }

    // MARK: - TilesSource Protocol

    /// Calculates tile request for given viewport origin and zoom scale.
    ///
    /// - Parameters:
    ///   - origin: Top-left corner of the visible viewport in content coordinates
    ///   - scale: Current zoom scale factor (1.0 = maximum zoom, smaller values = zoomed out)
    /// - Returns: Tile request containing the column, row, and zoom level for the tile to load
    ///
    /// Returns a fallback request (0,0,0) if scale is invalid or calculations produce non-finite values.
    /// Emits warning events for invalid inputs.
    public func request(for origin: CGPoint, scale: CGFloat) -> TileRequest {
        let fallbackRequest = Request(column: 0, row: 0, level: 0)

        guard scale.isFinite, scale > 0 else {
            onEvent?([
                "type": "warning",
                "message": "Received invalid scale",
                "scale": Double(scale)
            ])
            return fallbackRequest
        }

        let normalizedScale = max(scale, .leastNonzeroMagnitude)

        let rawLevel = levelByZoomScale(normalizedScale,
                                        fullSize: imageSize,
                                        firstLevelSize: tileSize)
        let levelIndex = clamp(Int(floor(rawLevel - 1)), lower: 0, upper: maxLevelIndex)
        let tilesPerEdge = max(1, 1 << levelIndex)

        let rawColumnPosition = Double(origin.x / tileSize.width * normalizedScale)
        guard rawColumnPosition.isFinite else {
            onEvent?([
                "type": "warning",
                "message": "Column calculation produced non-finite value",
                "origin_x": Double(origin.x)
            ])
            return fallbackRequest
        }

        let rawRowPosition = Double(origin.y / tileSize.height * normalizedScale)
        guard rawRowPosition.isFinite else {
            onEvent?([
                "type": "warning",
                "message": "Row calculation produced non-finite value",
                "origin_y": Double(origin.y)
            ])
            return fallbackRequest
        }

        let rawColumn = Int(floor(rawColumnPosition))
        let rawRow = Int(floor(rawRowPosition))
        let column = clamp(rawColumn, lower: 0, upper: tilesPerEdge - 1)
        let row = clamp(rawRow, lower: 0, upper: tilesPerEdge - 1)

        return Request(column: column, row: row, level: levelIndex)
    }

    /// Fetches the actual tile image for a given tile request.
    ///
    /// - Parameter request: Tile request containing column, row, and level information
    /// - Returns: Loaded tile image, or nil if request type is invalid or loading fails
    ///
    /// This method supports two loading modes:
    /// - If networkProvider is set: Uses synchronous loading with concurrency control (semaphore-based)
    /// - If networkProvider is nil: Uses Data(contentsOf:) for direct synchronous loading
    ///
    /// This method:
    /// 1. Calculates geographic bounding box for the tile in EPSG:3031 coordinates
    /// 2. Constructs WMS request URL to NASA GIBS service
    /// 3. Downloads the tile data synchronously
    /// 4. Decodes the image from PNG data
    ///
    /// The NetworkProvider manages request concurrency using semaphores to limit
    /// the number of simultaneous requests, preventing thread exhaustion.
    ///
    /// Emits events for tile requests, successful loads, and errors.
    public func tile(by request: TileRequest) -> UIImage? {
        guard let request = request as? Request else { return nil }

        // If we have a network provider, use it (with semaphore-based concurrency control)
        if let networkProvider = networkProvider {
            return tileWithNetworkProvider(by: request, provider: networkProvider)
        }

        // Legacy synchronous loading
        return tileSynchronous(by: request)
    }

    /// Loads tile using the synchronous network provider with concurrency control.
    ///
    /// - Parameters:
    ///   - request: Tile request containing column, row, and level information
    ///   - provider: The network provider to use for fetching
    /// - Returns: Loaded tile image, or nil if loading fails
    ///
    /// This method uses the NetworkProvider's synchronous API, which internally
    /// manages concurrency using semaphores and prevents duplicate requests.
    private func tileWithNetworkProvider(by request: Request, provider: NetworkProvider) -> UIImage? {
        guard let imageURL = constructTileURL(for: request) else {
            return nil
        }

        onEvent?([
            "type": "tile_request",
            "url": imageURL.absoluteString,
            "level": request.level,
            "column": request.column,
            "row": request.row,
            "request_description": request.description,
            "mode": "network_provider"
        ])

        guard let data = try? provider.fetchData(from: imageURL) else {
            onEvent?([
                "type": "error",
                "message": "Failed to load tile data via network provider",
                "url": imageURL.absoluteString,
                "request_description": request.description
            ])
            return nil
        }

        guard let image = UIImage(data: data) else {
            onEvent?([
                "type": "error",
                "message": "Failed to decode tile image",
                "url": imageURL.absoluteString
            ])
            return nil
        }

        onEvent?([
            "type": "tile_loaded",
            "request_description": request.description,
            "data_size": data.count,
            "mode": "network_provider"
        ])

        return image
    }

    /// Synchronously fetches tile image (legacy mode).
    ///
    /// - Parameter request: Tile request containing column, row, and level information
    /// - Returns: Loaded tile image, or nil if loading fails
    ///
    /// This is the legacy synchronous loading method used when no network provider is set.
    private func tileSynchronous(by request: Request) -> UIImage? {
        guard let imageURL = constructTileURL(for: request) else {
            return nil
        }

        onEvent?([
            "type": "tile_request",
            "url": imageURL.absoluteString,
            "level": request.level,
            "column": request.column,
            "row": request.row,
            "request_description": request.description,
            "mode": "sync"
        ])

        guard let data = try? Data(contentsOf: imageURL) else {
            onEvent?([
                "type": "error",
                "message": "Failed to load tile data",
                "url": imageURL.absoluteString
            ])
            return nil
        }

        onEvent?([
            "type": "tile_loaded",
            "request_description": request.description,
            "data_size": data.count,
            "mode": "sync"
        ])

        return UIImage(data: data)
    }

    /// Constructs the WMS tile URL for a given request.
    ///
    /// - Parameter request: Tile request containing column, row, and level information
    /// - Returns: Constructed URL, or nil if URL creation fails
    private func constructTileURL(for request: Request) -> URL? {
        let tilesPerEdge = max(1, 1 << request.level)
        let worldWidth = Double(params.maxX - params.minX)
        let worldHeight = Double(params.maxY - params.minY)
        let tileWidthGeo = worldWidth / Double(tilesPerEdge)
        let tileHeightGeo = worldHeight / Double(tilesPerEdge)

        let minX = Int(Double(params.minX) + Double(request.column) * tileWidthGeo)
        let maxX = Int(Double(params.minX) + Double(request.column + 1) * tileWidthGeo)

        // In EPSG:3031 projection, the Y-axis points "down", so tile rows coming from the engine
        // (where row 0 is at the top) must be inverted relative to the geographic coordinate system.
        // Otherwise, the first (top) tile on the map would correspond to the bottom part of Antarctica.
        let minY = Int(Double(params.maxY) - Double(request.row + 1) * tileHeightGeo)
        let maxY = Int(Double(params.maxY) - Double(request.row) * tileHeightGeo)
        let width = Int(tileSize.width)
        let height = Int(tileSize.height)

        let dateString = DateFormatHelper.formatDateForEarthData(params.date)
        let urlString = "https://gibs.earthdata.nasa.gov/wms/epsg3031/best/wms.cgi?" +
            "version=1.3.0&service=WMS&request=GetMap" +
            "&format=image/png" +
            "&STYLE=default" +
            "&bbox=\(minX),\(minY),\(maxX),\(maxY)" +
            "&CRS=EPSG:3031" +
            "&HEIGHT=\(height)" +
            "&WIDTH=\(width)" +
            "&TIME=\(dateString)" +
            "&layers=\(params.layers.rawValue)"

        guard let url = URL(string: urlString) else {
            onEvent?([
                "type": "error",
                "message": "Failed to create URL",
                "url_string": urlString
            ])
            return nil
        }

        return url
    }
}

// MARK: - Tile Loading Errors

/// Errors that can occur during tile loading
public enum TileLoadError: Error {
    case noNetworkProvider
    case invalidURL
    case imageDecodingFailed
}

// MARK: - Helper Functions

/// Clamps a value between lower and upper bounds.
///
/// - Parameters:
///   - value: The value to clamp
///   - lower: The minimum allowed value
///   - upper: The maximum allowed value
/// - Returns: The clamped value within [lower, upper] range
private func clamp<T: Comparable>(_ value: T, lower: T, upper: T) -> T {
    min(max(value, lower), upper)
}
