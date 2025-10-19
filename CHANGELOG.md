# Changelog

Все значимые изменения в проекте AntarcticaMap будут документироваться в этом файле.

## [1.0.0] - 2025-10-19

### Добавлено

#### Модели и типы данных
- Добавлен `EarthDataLayer` enum для типобезопасной работы со слоями данных
  - `modisTerraCorrectedReflectance` - MODIS Terra Corrected Reflectance True Color
- Добавлено вычисляемое свойство `cacheKey` в `EarthDataMapRequest` для кэширования
- Добавлен `DateFormatHelper` для форматирования дат в формат NASA GIBS API (ГГГГ-ММ-ДД)

#### Логирование
- Создан протокол `TiledMapLogger` для опционального логирования
- Реализован `NoOpLogger` - дефолтный логгер без вывода
- Реализован `ConsoleLogger` - простой консольный логгер для отладки

#### UI компоненты
- Создан `MapControlButtonStyle` - встроенный стиль для кнопок управления картой
- Все основные компоненты сделаны публичными для использования в других модулях

#### Документация
- Добавлен README.md с полным описанием модуля
- Добавлен USAGE_EXAMPLE.md с 6 примерами использования
- Добавлен CHANGELOG.md для отслеживания изменений

### Изменено

#### EarthDataMapRequest
- Заменено поле `time: String` на `date: Date` для типобезопасности
- Заменено поле `layers: String` на `layers: EarthDataLayer` enum
- Обновлен метод `debug()` для вывода информации о `cacheKey`

#### EarthDataTilesSource
- Удалены зависимости от внешних модулей (Models, Services, Nevod, Core, Letopis)
- Использует новый протокол `TiledMapLogger` вместо `Letopis`
- Обновлена генерация URL для использования `Date` вместо `String`
- Использует `DateFormatHelper` для форматирования дат

#### AntarcticaTiledMapContentView
- Удалена зависимость от `Letopis`
- Принимает `params: EarthDataMapRequest` в конструкторе
- Принимает `imageSize: CGSize` в конструкторе
- Использует `TiledMapLogger` вместо `Letopis`
- Упрощено логирование во всех методах

#### AntarcticaMapViewModel
- Помечен как `@available(*, deprecated)` с рекомендацией использовать `AntarcticaTiledMapContentView`
- Удалена зависимость от `EarthDataMapServicing`
- Метод `load()` теперь возвращает deprecation warning

#### TilesSupport
- Все основные функции сделаны публичными (`public`)
- Все протоколы сделаны публичными
- Добавлен `DateFormatHelper` в начало файла

#### MapTiledView
- Класс сделан публичным (`public final class`)

### Удалено
- Удалены все импорты внешних зависимостей:
  - `import Models`
  - `import Services`
  - `import Nevod`
  - `import Core`
  - `import Letopis`
  - `import Mazun`
- Удалена зависимость от `MapControlButtonStyle` из Mazun (создана локальная версия)

### Исправлено
- Исправлена типобезопасность при работе с датами
- Исправлена типобезопасность при работе со слоями данных
- Упрощена система логирования

## Архитектурные улучшения

### Независимость модуля
Модуль теперь полностью независим и не требует внешних зависимостей, кроме стандартных iOS фреймворков (UIKit, SwiftUI, Foundation).

### Типобезопасность
- Использование `Date` вместо `String` для дат
- Использование `EarthDataLayer` enum вместо `String` для слоев
- Строгая типизация через протоколы

### Расширяемость
- Протокол `TiledMapLogger` позволяет легко добавить свою систему логирования
- Протокол `TilesSource` позволяет создавать собственные источники тайлов
- Публичные API для всех основных компонентов

### Кэширование
- Добавлено свойство `cacheKey` для эффективного кэширования тайлов
- Уникальный ключ на основе всех параметров запроса

## Миграция с предыдущих версий

### Если вы использовали EarthDataMapRequest

```swift
// Было:
EarthDataMapRequest(
    minX: -4_000_000,
    minY: -4_000_000,
    maxX: 4_000_000,
    maxY: 4_000_000,
    width: 512,
    height: 512,
    time: "2022-11-11",
    layers: "MODIS_Terra_CorrectedReflectance_TrueColor"
)

// Стало:
EarthDataMapRequest(
    minX: -4_000_000,
    minY: -4_000_000,
    maxX: 4_000_000,
    maxY: 4_000_000,
    width: 512,
    height: 512,
    date: Date(), // Используем Date вместо String
    layers: .modisTerraCorrectedReflectance // Используем enum
)
```

### Если вы использовали AntarcticaTiledMapContentView

```swift
// Было:
AntarcticaTiledMapContentView(logger: letopis)

// Стало:
let params = EarthDataMapRequest(/* параметры */)
AntarcticaTiledMapContentView(
    params: params,
    imageSize: CGSize(width: 8192, height: 8192),
    logger: ConsoleLogger() // или NoOpLogger()
)
```

### Логирование

```swift
// Было:
import Letopis
let logger: Letopis = ...

// Стало:
import AntarcticaMap
let logger: TiledMapLogger = ConsoleLogger()
// или создайте свою реализацию TiledMapLogger
```
