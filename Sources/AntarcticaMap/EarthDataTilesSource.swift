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
/// Event types emitted via `onEvent`:
/// - `"tile_request"`: Fired when requesting a tile from the server
/// - `"tile_loaded"`: Fired when a tile is successfully loaded
/// - `"warning"`: Fired on validation warnings (invalid scale, non-finite calculations)
/// - `"error"`: Fired on errors (URL creation failure, data loading failure)
public class EarthDataTilesSource: NSObject, TilesSource {
    /// Internal tile request representation
    struct Request: TileRequest {
        let column: Int
        let row: Int
        /// Zero-based level index used for tile math
        let level: Int
        var description: String { "\(level)_\(column)_\(row)" }
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
    public init(
        params: EarthDataMapRequest,
        imageSize: CGSize = CGSize(width: 512, height: 512),
        tileSize: CGSize = CGSize(width: 512, height: 512)
    ) {
        self.params = params
        self.imageSize = imageSize
        self.tileSize = tileSize
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
    /// This method:
    /// 1. Calculates geographic bounding box for the tile in EPSG:3031 coordinates
    /// 2. Constructs WMS request URL to NASA GIBS service
    /// 3. Synchronously downloads the tile data
    /// 4. Decodes the image from PNG data
    ///
    /// Emits events for tile requests, successful loads, and errors.
    public func tile(by request: TileRequest) -> UIImage? {
        guard let request = request as? Request else { return nil }

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

        onEvent?([
            "type": "tile_request",
            "url": urlString,
            "level": request.level,
            "column": request.column,
            "row": request.row,
            "request_description": request.description
        ])

        guard let imageURL = URL(string: urlString) else {
            onEvent?([
                "type": "error",
                "message": "Failed to create URL",
                "url_string": urlString
            ])
            return nil
        }

        guard let data = try? Data(contentsOf: imageURL) else {
            onEvent?([
                "type": "error",
                "message": "Failed to load tile data",
                "url": urlString
            ])
            return nil
        }

        onEvent?([
            "type": "tile_loaded",
            "request_description": request.description,
            "data_size": data.count
        ])

        return UIImage(data: data)
    }
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
