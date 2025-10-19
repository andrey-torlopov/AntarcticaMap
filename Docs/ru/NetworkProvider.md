# Network Provider Usage Guide

## Overview

`EarthDataTilesSource` теперь поддерживает опциональный сетевой провайдер для асинхронной загрузки тайлов. Это позволяет:

- Контролировать количество одновременных сетевых запросов
- Автоматически дедуплицировать запросы к одним и тем же URL
- Использовать асинхронную загрузку для лучшей производительности
- Сохранить обратную совместимость со синхронной загрузкой

## Архитектура

### NetworkProvider Protocol

```swift
public protocol NetworkProvider: Sendable {
    func fetchData(from url: URL) async throws -> Data
}
```

### URLSessionNetworkProvider

Реализация на основе URLSession с управлением конкурентностью:

```swift
let provider = URLSessionNetworkProvider(maxConcurrentRequests: 6)
```

**Ключевые возможности:**
- Ограничение одновременных запросов (по умолчанию 6)
- Автоматическая дедупликация запросов (множественные запросы к одному URL используют один сетевой запрос)
- Actor-based thread safety
- Proper error handling

## Usage Examples

### 1. Синхронная загрузка (Legacy Mode)

```swift
// Без network provider - используется синхронная загрузка
let tilesSource = EarthDataTilesSource(
    params: params,
    imageSize: imageSize,
    tileSize: CGSize(width: 512, height: 512),
    networkProvider: nil  // или просто не указывать
)
```

### 2. Асинхронная загрузка с Network Provider

```swift
// Создаём network provider
let networkProvider = URLSessionNetworkProvider(maxConcurrentRequests: 6)

// Используем его в tile source
let tilesSource = EarthDataTilesSource(
    params: params,
    imageSize: imageSize,
    tileSize: CGSize(width: 512, height: 512),
    networkProvider: networkProvider
)
```

### 3. В TiledMapViewController

```swift
let networkProvider = URLSessionNetworkProvider(maxConcurrentRequests: 6)

let viewController = TiledMapViewController(
    params: params,
    imageSize: imageSize,
    networkProvider: networkProvider
)
```

### 4. Demo приложение с переключением режимов

В Demo приложении реализован переключатель между синхронным и асинхронным режимами:

```swift
struct ContentView: View {
    @State private var useAsyncLoading: Bool = true
    private let networkProvider: URLSessionNetworkProvider
    
    init() {
        self.networkProvider = URLSessionNetworkProvider(maxConcurrentRequests: 6)
        // ...
    }
    
    private func updateMapDate(_ newDate: Date) {
        let viewController = TiledMapViewController(
            params: newParams,
            imageSize: imageSize,
            networkProvider: useAsyncLoading ? networkProvider : nil
        )
    }
}
```

**Кнопка переключения:**
- Зелёная кнопка "Async" с иконкой молнии - асинхронный режим
- Оранжевая кнопка "Sync" с иконкой черепахи - синхронный режим

## How It Works

### Синхронный режим (networkProvider == nil)

1. `tile(by:)` вызывается движком тайлов
2. Выполняется синхронная загрузка через `Data(contentsOf:)`
3. Изображение декодируется и возвращается
4. Блокирует поток до завершения загрузки

### Асинхронный режим (networkProvider != nil)

1. `tile(by:)` вызывается движком тайлов
2. Запускается async Task с вызовом `tileAsync(by:)`
3. Сразу возвращается `nil`
4. Network provider управляет очередью запросов
5. При достижении лимита конкурентности запросы ожидают
6. Дедупликация: одинаковые URL используют один запрос
7. Изображение загружается асинхронно

### Request Deduplication

```swift
// Если 3 тайла запрашивают один URL:
Task 1: fetchData(from: url) -> создаёт сетевой запрос
Task 2: fetchData(from: url) -> использует запрос Task 1
Task 3: fetchData(from: url) -> использует запрос Task 1

// Результат: 1 сетевой запрос вместо 3
```

### Concurrency Control

```swift
let provider = URLSessionNetworkProvider(maxConcurrentRequests: 6)

// Первые 6 запросов выполняются параллельно
// Запросы 7+ ожидают завершения предыдущих
```

## Performance Considerations

### Рекомендуемые настройки

```swift
// Для мобильных устройств
URLSessionNetworkProvider(maxConcurrentRequests: 4-6)

// Для быстрого Wi-Fi
URLSessionNetworkProvider(maxConcurrentRequests: 8-10)

// Для медленного соединения
URLSessionNetworkProvider(maxConcurrentRequests: 2-3)
```

### Преимущества асинхронного режима

1. **Неблокирующий UI**: загрузка не блокирует основной поток
2. **Контроль ресурсов**: ограничение одновременных запросов
3. **Эффективность**: дедупликация одинаковых запросов
4. **Масштабируемость**: лучше работает при большом количестве тайлов

### Когда использовать синхронный режим

1. Простое тестирование
2. Обратная совместимость со старым кодом
3. Очень простые случаи с малым количеством тайлов

## Event Logging

События включают информацию о режиме загрузки:

```swift
tilesSource.onEvent = { event in
    if let type = event["type"] as? String,
       let mode = event["mode"] as? String {
        print("[\(type)] mode: \(mode)")
        // mode: "async" или "sync"
    }
}
```

## Custom Network Provider

Можно создать собственную реализацию для специфических задач:

```swift
actor CustomNetworkProvider: NetworkProvider {
    private let cache: URLCache
    
    func fetchData(from url: URL) async throws -> Data {
        // Своя логика кэширования
        // Своя логика retry
        // Своя логика приоритезации
        // и т.д.
    }
}
```

## Migration Guide

### Обновление существующего кода

**До:**
```swift
let tilesSource = EarthDataTilesSource(
    params: params,
    imageSize: imageSize,
    tileSize: tileSize
)
```

**После (с async loading):**
```swift
let networkProvider = URLSessionNetworkProvider(maxConcurrentRequests: 6)
let tilesSource = EarthDataTilesSource(
    params: params,
    imageSize: imageSize,
    tileSize: tileSize,
    networkProvider: networkProvider
)
```

**После (без изменений, backward compatible):**
```swift
let tilesSource = EarthDataTilesSource(
    params: params,
    imageSize: imageSize,
    tileSize: tileSize
    // networkProvider по умолчанию nil
)
```

## Error Handling

```swift
public enum TileLoadError: Error {
    case noNetworkProvider      // Попытка async загрузки без провайдера
    case invalidURL             // Некорректный URL
    case imageDecodingFailed    // Ошибка декодирования изображения
}
```

## Testing

Для тестирования можно создать mock provider:

```swift
actor MockNetworkProvider: NetworkProvider {
    var mockData: [URL: Data] = [:]
    
    func fetchData(from url: URL) async throws -> Data {
        guard let data = mockData[url] else {
            throw URLError(.fileDoesNotExist)
        }
        return data
    }
}
```

## Demo App Features

Запустите Demo приложение для просмотра:

1. **Переключатель Async/Sync** - верхняя кнопка с иконкой
2. **Date picker** - выбор даты для снимков
3. **Zoom controls** - приближение/отдаление
4. **Pan controls** - навигация по карте

Наблюдайте в консоли:
```
[tile_request] mode: async
[tile_loaded] mode: async
```

## Best Practices

1. **Переиспользуйте NetworkProvider** - создавайте один экземпляр для всего приложения
2. **Настраивайте concurrency** - подберите оптимальное значение для вашего случая
3. **Обрабатывайте события** - используйте `onEvent` для мониторинга
4. **Тестируйте оба режима** - убедитесь, что синхронный fallback работает
5. **Используйте URLSession.shared или свою конфигурацию** - для кэширования и политик

## Conclusion

Добавление NetworkProvider позволяет гибко управлять загрузкой тайлов, при этом сохраняя обратную совместимость с существующим кодом. Выбирайте режим в зависимости от ваших требований к производительности и сложности приложения.
