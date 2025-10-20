# AntarcticaMap

Модуль для отрисовки тайловой карты Антарктиды с использованием данных NASA GIBS.

## Описание

`AntarcticaMap` - это независимый Swift Package Manager модуль, который предоставляет возможность отображения тайловой карты Антарктиды. Модуль использует данные из NASA GIBS (Global Imagery Browse Services) для загрузки спутниковых снимков.

## Основные компоненты

### Публичные компоненты

1. **AntarcticaTiledMapContentView** - главный SwiftUI view для отображения карты
2. **EarthDataMapRequest** - модель запроса для загрузки тайлов
3. **EarthDataLayer** - enum с доступными слоями данных
4. **EarthDataTilesSource** - источник тайлов, реализующий протокол TilesSource
5. **TiledMapLogger** - протокол для опционального логирования
6. **MapTiledView** - UIKit компонент для отрисовки тайлов

### Протоколы

- **TilesSource** - протокол для источников тайлов
- **TileRequest** - протокол для запросов тайлов
- **TiledMapLogger** - протокол для логирования

## Установка

Добавьте этот пакет в зависимости вашего проекта в `Package.swift`:

```swift
dependencies: [
    .package(url: "path/to/AntarcticaMap", from: "1.0.0")
]
```

## Использование

### Базовый пример

```swift
import SwiftUI
import AntarcticaMap

struct ContentView: View {
    var body: some View {
        // Создаем запрос с параметрами карты
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
        
        // Отображаем карту
        AntarcticaTiledMapContentView(
            params: params,
            imageSize: CGSize(width: 8192, height: 8192)
        )
    }
}
```

### С логированием

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

AntarcticaTiledMapContentView(
    params: params,
    imageSize: CGSize(width: 8192, height: 8192),
    logger: logger
)
```

### Собственный логгер

```swift
struct MyLogger: TiledMapLogger {
    func debug(_ message: String, metadata: [String: String]?) {
        // Ваша реализация
    }
    
    func info(_ message: String, metadata: [String: String]?) {
        // Ваша реализация
    }
    
    func warning(_ message: String, metadata: [String: String]?) {
        // Ваша реализация
    }
    
    func error(_ message: String, metadata: [String: String]?) {
        // Ваша реализация
    }
}
```

## Модель EarthDataMapRequest

### Параметры

- `minX`, `minY`, `maxX`, `maxY` - координаты bbox в проекции EPSG:3031
- `width`, `height` - размер тайла в пикселях
- `date` - дата для получения снимков
- `layers` - слой данных (enum EarthDataLayer)
- `format` - формат изображения (по умолчанию "image/png")
- `crs` - система координат (по умолчанию "EPSG:3031")

### Вычисляемые свойства

- `bbox` - строка с координатами в формате "minX,minY,maxX,maxY"
- `cacheKey` - уникальный ключ для кэширования

## Доступные слои данных

```swift
public enum EarthDataLayer: String {
    case modisTerraCorrectedReflectance = "MODIS_Terra_CorrectedReflectance_TrueColor"
}
```

## Вспомогательные функции

### DateFormatHelper

```swift
// Форматирование даты для NASA GIBS API (ГГГГ-ММ-ДД)
let dateString = DateFormatHelper.formatDateForEarthData(Date())
```

### Функции для работы с зумом

```swift
// Расчет уровня детализации по масштабу зума
let level = levelByZoomScale(zoomScale, fullSize: imageSize, firstLevelSize: tileSize)

// Максимальный уровень детализации
let maxLvl = maxLevel(fullSize: imageSize, firstLevelSize: tileSize)

// Масштаб зума по уровню детализации
let zoomScale = zoomScaleByLevel(level)
```

## Архитектура

Модуль построен на основе тайловой системы отрисовки:

1. **MapTiledView** - использует `CATiledLayer` для эффективной отрисовки больших изображений
2. **TilesSource** - протокол для источников тайлов, позволяет легко добавлять новые источники данных
3. **EarthDataTilesSource** - конкретная реализация для NASA GIBS API

## Требования

- iOS 17.0+
- Swift 6.2+
- Xcode 16.0+

## Лицензия

[Укажите вашу лицензию]

## Контакты

[Укажите контактную информацию]
