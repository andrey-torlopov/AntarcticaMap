import Foundation

public struct EarthDataMapRequest: Codable, Equatable, Sendable {
    public let minX: Int
    public let minY: Int
    public let maxX: Int
    public let maxY: Int
    public let width: Int
    public let height: Int
    public let time: String
    public let layers: String
    public let format: String
    public let crs: String

    public init(
        minX: Int,
        minY: Int,
        maxX: Int,
        maxY: Int,
        width: Int,
        height: Int,
        time: String,
        layers: String,
        format: String = "image/png",
        crs: String = "EPSG:3031"
    ) {
        self.minX = minX
        self.minY = minY
        self.maxX = maxX
        self.maxY = maxY
        self.width = width
        self.height = height
        self.time = time
        self.layers = layers
        self.format = format
        self.crs = crs
    }

    public var bbox: String {
        "\(minX),\(minY),\(maxX),\(maxY)"
    }
}

// MARK: - Debug Extension
public extension EarthDataMapRequest {
    func debug() -> String {
        """
        EarthDataMapRequest Debug Info:
        ├─ Coordinates: (\(minX), \(minY)) → (\(maxX), \(maxY))
        ├─ Dimensions: \(width)×\(height)
        ├─ BBOX: \(bbox)
        ├─ Area: \((maxX - minX) * (maxY - minY)) sq units
        ├─ Time: \(time)
        ├─ Layers: \(layers)
        ├─ Format: \(format)
        └─ CRS: \(crs)
        """
    }
}
