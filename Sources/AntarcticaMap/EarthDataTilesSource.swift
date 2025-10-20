import UIKit
import Foundation

public class EarthDataTilesSource: NSObject, TilesSource {
    struct Request: TileRequest {
        let column: Int
        let row: Int
        /// Zero-based level index used for tile math
        let level: Int
        var description: String { "\(level)_\(column)_\(row)" }
    }

    // TilesSource requirements
    public let tileSize: CGSize
    public let imageSize: CGSize
    private let maxLevelIndex: Int
    private let params: EarthDataMapRequest
    private let logger: TiledMapLogger

    public init(
        params: EarthDataMapRequest,
        imageSize: CGSize = CGSize(width: 512, height: 512),
        tileSize: CGSize = CGSize(width: 512, height: 512),
        logger: TiledMapLogger = EmptyLogger()
    ) {
        self.params = params
        self.imageSize = imageSize
        self.tileSize = tileSize
        let computedLevels = Int(max(maxLevel(imageSize, firstLevelSize: tileSize), 1))
        self.maxLevelIndex = max(0, computedLevels - 1)
        self.logger = logger

        super.init()
    }

    public func request(for origin: CGPoint, scale: CGFloat) -> TileRequest {
        let fallbackRequest = Request(column: 0, row: 0, level: 0)

        guard scale.isFinite, scale > 0 else {
            logger.warning("Received invalid scale: \(Double(scale)). Returning fallback tile request.", metadata: nil)
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
            logger.warning("Column calculation produced non-finite value for origin.x: \(Double(origin.x)). Returning fallback tile request.", metadata: nil)
            return fallbackRequest
        }

        let rawRowPosition = Double(origin.y / tileSize.height * normalizedScale)
        guard rawRowPosition.isFinite else {
            logger.warning("Row calculation produced non-finite value for origin.y: \(Double(origin.y)). Returning fallback tile request.", metadata: nil)
            return fallbackRequest
        }

        let rawColumn = Int(floor(rawColumnPosition))
        let rawRow = Int(floor(rawRowPosition))
        let column = clamp(rawColumn, lower: 0, upper: tilesPerEdge - 1)
        let row = clamp(rawRow, lower: 0, upper: tilesPerEdge - 1)

        return Request(column: column, row: row, level: levelIndex)
    }

    public func tile(by request: TileRequest) -> UIImage? {
        guard let request = request as? Request else { return nil }

        let tilesPerEdge = max(1, 1 << request.level)
        let worldWidth = Double(params.maxX - params.minX)
        let worldHeight = Double(params.maxY - params.minY)
        let tileWidthGeo = worldWidth / Double(tilesPerEdge)
        let tileHeightGeo = worldHeight / Double(tilesPerEdge)

        let minX = Int(Double(params.minX) + Double(request.column) * tileWidthGeo)
        let maxX = Int(Double(params.minX) + Double(request.column + 1) * tileWidthGeo)
        // В проекции EPSG:3031 ось Y направлена "вниз", поэтому строки тайлов, которые
        // приходят из движка (где нулевая строка находится сверху), необходимо инвертировать
        // относительно географической системы координат. Иначе первый (верхний) тайл на карте
        // будет соответствовать нижней части Антарктиды.
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

        logger.debug("Requesting tile", metadata: ["url": urlString, "requestDescription": request.description])

        guard let imageURL = URL(string: urlString) else {
            return nil
        }

        guard let data = try? Data(contentsOf: imageURL) else {
            return nil
        }

        return UIImage(data: data)
    }
}

private func clamp<T: Comparable>(_ value: T, lower: T, upper: T) -> T {
    min(max(value, lower), upper)
}
