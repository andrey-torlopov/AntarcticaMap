import Foundation

public enum EarthDataLayer: String, Codable, Equatable, Sendable {
    case modisTerraCorrectedReflectance = "MODIS_Terra_CorrectedReflectance_TrueColor"
}

public struct EarthDataMapRequest: Codable, Equatable, Sendable {
    public let minX: Int
    public let minY: Int
    public let maxX: Int
    public let maxY: Int
    public let width: Int
    public let height: Int
    public let date: Date
    public let layers: EarthDataLayer
    public let format: String
    public let crs: String
    public let dateString: String
    
    public init(
        minX: Int,
        minY: Int,
        maxX: Int,
        maxY: Int,
        width: Int,
        height: Int,
        date: Date,
        layers: EarthDataLayer,
        format: String = "image/png",
        crs: String = "EPSG:3031"
    ) {
        self.minX = minX
        self.minY = minY
        self.maxX = maxX
        self.maxY = maxY
        self.width = width
        self.height = height
        self.date = date
        self.layers = layers
        self.format = format
        self.crs = crs
        self.dateString = DateFormatHelper.formatDateForEarthData(date)
    }

    public var bbox: String {
        "\(minX),\(minY),\(maxX),\(maxY)"
    }

    public var cacheKey: String {
        return "\(layers.rawValue)_\(dateString)_\(minX)_\(minY)_\(maxX)_\(maxY)_\(width)x\(height)"
    }
}

// MARK: - Debug Extension
public extension EarthDataMapRequest {
    func debug() -> String {
        return """
        EarthDataMapRequest Debug Info:
        ├─ Coordinates: (\(minX), \(minY)) → (\(maxX), \(maxY))
        ├─ Dimensions: \(width)×\(height)
        ├─ BBOX: \(bbox)
        ├─ Area: \((maxX - minX) * (maxY - minY)) sq units
        ├─ Date: \(dateString)
        ├─ Layers: \(layers.rawValue)
        ├─ Format: \(format)
        ├─ CRS: \(crs)
        └─ Cache Key: \(cacheKey)
        """
    }
}
