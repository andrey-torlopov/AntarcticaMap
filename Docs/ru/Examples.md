# Примеры использования AntarcticaMap

## Пример 1: Базовое использование

```swift
import SwiftUI
import AntarcticaMap

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            AntarcticaMapView()
        }
    }
}

struct AntarcticaMapView: View {
    var body: some View {
        // Создаем параметры запроса для карты Антарктиды
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
        
        AntarcticaTiledMapContentView(
            params: params,
            imageSize: CGSize(width: 8192, height: 8192)
        )
    }
}
```

## Пример 2: С выбором даты

```swift
import SwiftUI
import AntarcticaMap

struct AntarcticaMapWithDatePicker: View {
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack {
            DatePicker("Выберите дату", selection: $selectedDate, displayedComponents: .date)
                .padding()
            
            mapView
        }
    }
    
    var mapView: some View {
        let params = EarthDataMapRequest(
            minX: -4_000_000,
            minY: -4_000_000,
            maxX: 4_000_000,
            maxY: 4_000_000,
            width: 512,
            height: 512,
            date: selectedDate,
            layers: .modisTerraCorrectedReflectance
        )
        
        return AntarcticaTiledMapContentView(
            params: params,
            imageSize: CGSize(width: 8192, height: 8192)
        )
        .id(selectedDate) // Пересоздаем view при изменении даты
    }
}
```

## Пример 3: С кастомным логгером

```swift
import AntarcticaMap
import OSLog

// Создаем кастомный логгер на основе OSLog
struct OSLogLogger: TiledMapLogger {
    private let logger = Logger(subsystem: "com.myapp.antarctica", category: "map")
    
    func debug(_ message: String, metadata: [String: String]?) {
        logger.debug("\(message) \(metadataString(metadata))")
    }
    
    func info(_ message: String, metadata: [String: String]?) {
        logger.info("\(message) \(metadataString(metadata))")
    }
    
    func warning(_ message: String, metadata: [String: String]?) {
        logger.warning("\(message) \(metadataString(metadata))")
    }
    
    func error(_ message: String, metadata: [String: String]?) {
        logger.error("\(message) \(metadataString(metadata))")
    }
    
    private func metadataString(_ metadata: [String: String]?) -> String {
        guard let metadata = metadata else { return "" }
        return "[\(metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", "))]"
    }
}

struct MapViewWithLogging: View {
    var body: some View {
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
        
        AntarcticaTiledMapContentView(
            params: params,
            imageSize: CGSize(width: 8192, height: 8192),
            logger: OSLogLogger()
        )
    }
}
```

## Пример 4: Кастомный источник тайлов

```swift
import UIKit
import AntarcticaMap

// Создаем свой источник тайлов
class CustomTilesSource: NSObject, TilesSource {
    struct Request: TileRequest {
        let x: Int
        let y: Int
        let level: Int
        var description: String { "\(level)/\(x)/\(y)" }
    }
    
    let tileSize: CGSize
    let imageSize: CGSize
    
    init(tileSize: CGSize, imageSize: CGSize) {
        self.tileSize = tileSize
        self.imageSize = imageSize
        super.init()
    }
    
    func request(for origin: CGPoint, scale: CGFloat) -> TileRequest {
        // Ваша логика расчета запроса
        let level = Int(log2(scale))
        let x = Int(origin.x / tileSize.width)
        let y = Int(origin.y / tileSize.height)
        return Request(x: x, y: y, level: level)
    }
    
    func tile(by request: TileRequest) -> UIImage? {
        guard let req = request as? Request else { return nil }
        // Ваша логика загрузки/генерации тайла
        // Например, загрузка с другого API или генерация процедурно
        return generateTile(x: req.x, y: req.y, level: req.level)
    }
    
    private func generateTile(x: Int, y: Int, level: Int) -> UIImage? {
        // Пример генерации простого тайла
        UIGraphicsBeginImageContextWithOptions(tileSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Рисуем простой паттерн
        context.setFillColor(UIColor.blue.cgColor)
        context.fill(CGRect(origin: .zero, size: tileSize))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
```

## Пример 5: Использование cache key

```swift
import AntarcticaMap

// Cache key можно использовать для кэширования изображений
class TileCache {
    private var cache: [String: UIImage] = [:]
    
    func cachedTile(for request: EarthDataMapRequest) -> UIImage? {
        return cache[request.cacheKey]
    }
    
    func cacheTile(_ image: UIImage, for request: EarthDataMapRequest) {
        cache[request.cacheKey] = image
    }
}

// Использование
let cache = TileCache()
let request = EarthDataMapRequest(
    minX: -4_000_000,
    minY: -4_000_000,
    maxX: 4_000_000,
    maxY: 4_000_000,
    width: 512,
    height: 512,
    date: Date(),
    layers: .modisTerraCorrectedReflectance
)

// Проверяем кэш
if let cachedImage = cache.cachedTile(for: request) {
    print("Используем кэшированное изображение")
} else {
    print("Загружаем новое изображение")
    // Загружаем и кэшируем
    // cache.cacheTile(image, for: request)
}
```

## Пример 6: Отладка с debug()

```swift
import AntarcticaMap

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

// Выводим отладочную информацию
print(params.debug())

/*
Вывод:
EarthDataMapRequest Debug Info:
├─ Coordinates: (-4000000, -4000000) → (4000000, 4000000)
├─ Dimensions: 512×512
├─ BBOX: -4000000,-4000000,4000000,4000000
├─ Area: 64000000000000 sq units
├─ Date: 2025-10-19
├─ Layers: MODIS_Terra_CorrectedReflectance_TrueColor
├─ Format: image/png
├─ CRS: EPSG:3031
└─ Cache Key: MODIS_Terra_CorrectedReflectance_TrueColor_2025-10-19_-4000000_-4000000_4000000_4000000_512x512
*/
```

## Советы по использованию

### 1. Выбор размера imageSize

- Для полного отображения Антарктиды: `CGSize(width: 8192, height: 8192)`
- Для более детального просмотра конкретной области: можно использовать больший размер
- Для быстрой загрузки при тестировании: `CGSize(width: 2048, height: 2048)`

### 2. Оптимизация производительности

```swift
// Используйте NoOpLogger в production для лучшей производительности
let params = EarthDataMapRequest(/* ... */)
AntarcticaTiledMapContentView(
    params: params,
    logger: NoOpLogger() // Логирование отключено
)
```

### 3. Работа с датами

```swift
// Форматирование даты для отладки
let dateString = DateFormatHelper.formatDateForEarthData(Date())
print("Запрашиваем данные за: \(dateString)") // 2025-10-19

// Использование конкретной даты
let calendar = Calendar.current
let components = DateComponents(year: 2023, month: 11, day: 11)
if let specificDate = calendar.date(from: components) {
    let params = EarthDataMapRequest(
        // ...
        date: specificDate,
        // ...
    )
}
```
