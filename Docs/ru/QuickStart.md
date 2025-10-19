# Quick Start: Network Provider

## Базовое использование

### 1. Асинхронная загрузка (рекомендуется)

```swift
import AntarcticaMap

// Создаём network provider
let networkProvider = URLSessionNetworkProvider(maxConcurrentRequests: 6)

// Создаём параметры запроса
let params = EarthDataMapRequest(
    minX: -4_000_000,
    minY: -4_000_000,
    maxX: 4_000_000,
    maxY: 4_000_000,
    width: 8192,
    height: 8192,
    date: Date(),
    layers: .modisTerraCorrectedReflectance
)

// Используем в view controller
let viewController = TiledMapViewController(
    params: params,
    imageSize: CGSize(width: 8192, height: 8192),
    networkProvider: networkProvider  // ← добавляем network provider
)
```

### 2. Синхронная загрузка (legacy)

```swift
// Просто не передаём network provider
let viewController = TiledMapViewController(
    params: params,
    imageSize: CGSize(width: 8192, height: 8192)
    // networkProvider: nil по умолчанию
)
```

## Demo приложение

В Demo приложении есть переключатель между режимами:

- **🔋 Async** (зелёная кнопка) - асинхронная загрузка
- **🐢 Sync** (оранжевая кнопка) - синхронная загрузка

Переключайте режимы и наблюдайте разницу в производительности в консоли Xcode.

## Мониторинг событий

```swift
viewController.onEvent = { event in
    if let type = event["type"] as? String,
       let mode = event["mode"] as? String {
        print("[\(type)] mode: \(mode)")
    }
}
```

Типы событий:
- `tile_request` - запрос тайла
- `tile_loaded` - тайл загружен
- `error` - ошибка загрузки
- `warning` - предупреждение

## Настройка конкурентности

```swift
// Для медленного соединения
URLSessionNetworkProvider(maxConcurrentRequests: 2)

// Для обычного Wi-Fi (по умолчанию)
URLSessionNetworkProvider(maxConcurrentRequests: 6)

// Для быстрого соединения
URLSessionNetworkProvider(maxConcurrentRequests: 10)
```

## Ключевые преимущества async режима

1. ✅ Не блокирует UI
2. ✅ Автоматическая дедупликация запросов
3. ✅ Контроль количества одновременных запросов
4. ✅ Лучшая производительность при множестве тайлов
5. ✅ Обратная совместимость (можно не использовать)

---

Подробности: [NETWORK_PROVIDER_USAGE.md](./NETWORK_PROVIDER_USAGE.md)
