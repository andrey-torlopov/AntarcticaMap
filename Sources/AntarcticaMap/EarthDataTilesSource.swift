import UIKit
import Models
import Services
import Nevod
import Core
import Letopis

class EarthDataTilesSource: NSObject, TilesSource {
    struct Request: TileRequest {
        let column: Int
        let row: Int
        /// Zero-based level index used for tile math
        let level: Int
        var description: String { "\(level)_\(column)_\(row)" }
    }

    // TilesSource requirements
    let tileSize: CGSize
    let imageSize: CGSize
    private let maxLevelIndex: Int
    private let params: EarthDataMapRequest
    private let logger: Letopis

    // Пустой поток для совместимости с AsyncStream API
    let updates: AsyncStream<Void>

    init(
        params: EarthDataMapRequest = EarthDataMapRequest(
            minX: -4_000_000,
            minY: -4_000_000,
            maxX: 4_000_000,
            maxY: 4_000_000,
            width: 512,
            height: 512,
            time: "2022-11-11",
            layers: "MODIS_Terra_CorrectedReflectance_TrueColor"
        ),
        imageSize: CGSize = CGSize(width: 512, height: 512),
        tileSize: CGSize = CGSize(width: 512, height: 512),
        logger: Letopis
    ) {
        self.params = params
        self.imageSize = imageSize
        self.tileSize = tileSize
        let computedLevels = Int(max(maxLevel(imageSize, firstLevelSize: tileSize), 1))
        self.maxLevelIndex = max(0, computedLevels - 1)
        self.logger = logger

        // Пустой поток, так как у нас синхронная загрузка
        self.updates = AsyncStream<Void> { _ in }

        super.init()
    }

    func request(for origin: CGPoint, scale: CGFloat) -> TileRequest {
        let fallbackRequest = Request(column: 0, row: 0, level: 0)

        guard scale.isFinite, scale > 0 else {
            logger
                .event(DevelopmentEventType.debug)
                .source()
                .warning("Received invalid scale: \(Double(scale)). Returning fallback tile request.")

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
            logger
                .event(DevelopmentEventType.debug)
                .source()
                .warning("Column calculation produced non-finite value for origin.x: \(Double(origin.x)). Returning fallback tile request.")
            return fallbackRequest
        }

        let rawRowPosition = Double(origin.y / tileSize.height * normalizedScale)
        guard rawRowPosition.isFinite else {
            logger
                .event(DevelopmentEventType.debug)
                .source()
                .warning("Row calculation produced non-finite value for origin.y: \(Double(origin.y)). Returning fallback tile request.")
            return fallbackRequest
        }

        let rawColumn = Int(floor(rawColumnPosition))
        let rawRow = Int(floor(rawRowPosition))
        let column = clamp(rawColumn, lower: 0, upper: tilesPerEdge - 1)
        let row = clamp(rawRow, lower: 0, upper: tilesPerEdge - 1)

        return Request(column: column, row: row, level: levelIndex)
    }

    func tile(by request: TileRequest) -> UIImage? {
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

        let urlString = "https://gibs.earthdata.nasa.gov/wms/epsg3031/best/wms.cgi?" +
            "version=1.3.0&service=WMS&request=GetMap" +
            "&format=image/png" +
            "&STYLE=default" +
            "&bbox=\(minX),\(minY),\(maxX),\(maxY)" +
            "&CRS=EPSG:3031" +
            "&HEIGHT=\(height)" +
            "&WIDTH=\(width)" +
            "&TIME=\(params.time)" +
            "&layers=\(params.layers)"

        logger
            .event(DevelopmentEventType.debug)
            .action(DevelopmentAction.dump)
            .source()
            .payload(["url": urlString, "requestDescription": request.description])
            .debug("Requesting tile")

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
