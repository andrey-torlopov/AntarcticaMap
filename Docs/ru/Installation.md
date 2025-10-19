# Руководство по установке

## Swift Package Manager (рекомендуется)

### Через Xcode

1. Откройте ваш проект в Xcode
2. Перейдите в **File → Add Package Dependencies...**
3. Введите URL репозитория:
   ```
   https://github.com/yourusername/AntarcticaMap.git
   ```
4. Выберите правило версии (например, "Up to Next Major Version" начиная с 1.0.0)
5. Нажмите **Add Package**
6. Выберите библиотеку **AntarcticaMap** и нажмите **Add Package**

### Через Package.swift

Добавьте следующее в ваш файл `Package.swift`:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "YourProject",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(url: "https://github.com/yourusername/AntarcticaMap.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourProject",
            dependencies: ["AntarcticaMap"]
        )
    ]
)
```

## Требования

- **iOS**: 17.0 или новее
- **Swift**: 6.2 или новее
- **Xcode**: 16.0 или новее

## Проверка установки

После установки импортируйте пакет в ваш Swift файл:

```swift
import AntarcticaMap

// Проверяем, что все работает
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

print("AntarcticaMap установлен успешно!")
```

## Следующие шаги

- [Быстрый старт](QuickStart.md)
- [Примеры использования](Examples.md)
- [Руководство по Network Provider](NetworkProvider.md)
