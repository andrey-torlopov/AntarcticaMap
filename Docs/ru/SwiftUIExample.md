# Пример SwiftUI

Полный пример использования AntarcticaMap в SwiftUI приложении с полным набором элементов управления.

## Продемонстрированные возможности

- ✅ Переключение между Async/Sync загрузкой
- ✅ Выбор даты для исторических снимков
- ✅ Управление зумом
- ✅ Управление панорамированием (кнопки со стрелками)
- ✅ Логирование событий
- ✅ Конфигурация network provider
- ✅ Кастомные стили кнопок

## Полная реализация

```swift
import SwiftUI
import AntarcticaMap

struct ContentView: View {
    @State private var controller: TiledMapViewController
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker: Bool = false
    @State private var useAsyncLoading: Bool = true
    @State private var eventLog: [String] = []
    private let imageSize: CGSize
    private let networkProvider: DefaultNetworkProvider

    init(params: EarthDataMapRequest? = nil, imageSize: CGSize = CGSize(width: 8192, height: 8192)) {
        self.imageSize = imageSize

        // Создаем network provider с настройкой на 6 одновременных запросов
        self.networkProvider = DefaultNetworkProvider(maxConcurrentRequests: 6)

        let defaultParams = EarthDataMapRequest(
            minX: -4_000_000,
            minY: -4_000_000,
            maxX: 4_000_000,
            maxY: 4_000_000,
            width: Int(imageSize.width),
            height: Int(imageSize.height),
            date: Date(),
            layers: .modisTerraCorrectedReflectance
        )

        // По умолчанию используем асинхронную загрузку
        let viewController = TiledMapViewController(
            params: params ?? defaultParams,
            imageSize: imageSize,
            networkProvider: networkProvider
        )

        // Пример подключения обработчика событий с логированием
        viewController.onEvent = { event in
            if let type = event["type"] as? String {
                let mode = (event["mode"] as? String) ?? "unknown"
                let message = "[\(type)] mode: \(mode)"
                print(message, event)

                // Добавляем в лог только ключевые события
                DispatchQueue.main.async {
                    if type == "tile_loaded" || type == "error" {
                        // eventLog можно использовать для отображения статистики
                    }
                }
            }
        }

        _controller = State(wrappedValue: viewController)
        _selectedDate = State(wrappedValue: params?.date ?? Date())
        _useAsyncLoading = State(wrappedValue: true)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TiledMapViewWrapper(controller: controller)
                .id(selectedDate.timeIntervalSince1970)
                .ignoresSafeArea()
            controls
                .padding()
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            // Переключатель режима загрузки
            HStack {
                Button(action: { toggleLoadingMode() }) {
                    HStack {
                        Image(systemName: useAsyncLoading ? "bolt.fill" : "tortoise.fill")
                        Text(useAsyncLoading ? "Async" : "Sync")
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(MapControlButtonStyle(color: useAsyncLoading ? .green : .orange))
            }

            // Выбор даты
            HStack {
                Button(action: { showDatePicker.toggle() }) {
                    HStack {
                        Image(systemName: "calendar")
                        Text(formattedDate)
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(MapControlButtonStyle())
            }

            if showDatePicker {
                DatePicker("Выберите дату", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                    .onChange(of: selectedDate) { oldValue, newValue in
                        updateMapDate(newValue)
                    }
            }

            // Управление зумом
            HStack {
                Button(action: controller.zoomOut) {
                    Image(systemName: "minus")
                }
                .buttonStyle(MapControlButtonStyle())

                Button(action: controller.zoomIn) {
                    Image(systemName: "plus")
                }
                .buttonStyle(MapControlButtonStyle())
            }

            // Управление навигацией
            HStack {
                Button(action: controller.moveUp) {
                    Image(systemName: "arrow.up")
                }
                .buttonStyle(MapControlButtonStyle())

                Button(action: controller.moveDown) {
                    Image(systemName: "arrow.down")
                }
                .buttonStyle(MapControlButtonStyle())

                Button(action: controller.moveLeft) {
                    Image(systemName: "arrow.left")
                }
                .buttonStyle(MapControlButtonStyle())

                Button(action: controller.moveRight) {
                    Image(systemName: "arrow.right")
                }
                .buttonStyle(MapControlButtonStyle())
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }

    private func toggleLoadingMode() {
        useAsyncLoading.toggle()
        updateMapDate(selectedDate)
    }

    private func updateMapDate(_ newDate: Date) {
        let newParams = EarthDataMapRequest(
            minX: -4_000_000,
            minY: -4_000_000,
            maxX: 4_000_000,
            maxY: 4_000_000,
            width: Int(imageSize.width),
            height: Int(imageSize.height),
            date: newDate,
            layers: .modisTerraCorrectedReflectance
        )

        // Используем network provider только если включен async режим
        let viewController = TiledMapViewController(
            params: newParams,
            imageSize: imageSize,
            networkProvider: useAsyncLoading ? networkProvider : nil
        )

        // Пример подключения обработчика событий с логированием режима
        viewController.onEvent = { event in
            if let type = event["type"] as? String {
                let mode = (event["mode"] as? String) ?? "unknown"
                let message = "[\(type)] mode: \(mode)"
                print(message, event)

                DispatchQueue.main.async {
                    if type == "tile_loaded" || type == "error" {
                        // Можно добавить статистику загрузки
                    }
                }
            }
        }

        controller = viewController
    }
}

// MARK: - Обертка UIViewControllerRepresentable

private struct TiledMapViewWrapper: UIViewControllerRepresentable {
    let controller: TiledMapViewController

    func makeUIViewController(context: Context) -> TiledMapViewController {
        controller
    }

    func updateUIViewController(_ uiViewController: TiledMapViewController, context: Context) {}
}

// MARK: - Превью

#Preview {
    ContentView(
        params: EarthDataMapRequest(
            minX: -2700000,
            minY: -2700000,
            maxX: 2700000,
            maxY: 2700000,
            width: 8192,
            height: 8192,
            date: Date(),
            layers: .modisTerraCorrectedReflectance
        )
    )
}

// MARK: - Кастомный стиль кнопок

/// Простой стиль кнопок для управления картой
public struct MapControlButtonStyle: ButtonStyle {
    let color: Color

    public init(color: Color = .blue) {
        self.color = color
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .frame(width: 44.0, height: 44.0)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(configuration.isPressed ? 0.7 : 1.0))
            )
            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
```

## Ключевые детали реализации

### 1. Настройка Network Provider

```swift
private let networkProvider: DefaultNetworkProvider

init(...) {
    self.networkProvider = DefaultNetworkProvider(maxConcurrentRequests: 6)
    // ...
}
```

Network provider создается один раз и переиспользуется для лучшей производительности.

### 2. Переключение Async/Sync

```swift
let viewController = TiledMapViewController(
    params: newParams,
    imageSize: imageSize,
    networkProvider: useAsyncLoading ? networkProvider : nil
)
```

Передача `nil` в качестве `networkProvider` включает sync режим.

### 3. Логирование событий

```swift
viewController.onEvent = { event in
    if let type = event["type"] as? String {
        let mode = (event["mode"] as? String) ?? "unknown"
        print("[\(type)] mode: \(mode)", event)
    }
}
```

Логирует запросы тайлов, загрузки и ошибки с информацией о режиме.

### 4. Обновление даты

```swift
.onChange(of: selectedDate) { oldValue, newValue in
    updateMapDate(newValue)
}
```

Пересоздает контроллер с новыми параметрами при изменении даты.

### 5. Обновление карты

```swift
TiledMapViewWrapper(controller: controller)
    .id(selectedDate.timeIntervalSince1970)
```

Использование `.id()` заставляет SwiftUI пересоздать view при изменении даты.

## Запуск примера

1. Скопируйте код в ваше SwiftUI приложение
2. Импортируйте AntarcticaMap
3. Используйте `ContentView()` как главный view
4. Соберите и запустите

## Элементы управления

- **⚡/🐢 Кнопка** - Переключение между Async/Sync загрузкой
- **📅 Кнопка** - Показать/скрыть выбор даты
- **±** - Увеличение/уменьшение
- **Стрелки** - Панорамирование карты в четырех направлениях

## Советы

- Следите за логами в консоли Xcode
- Сравните производительность async и sync
- Попробуйте разные даты для просмотра исторических снимков
- Настройте `maxConcurrentRequests` под вашу сеть

## См. также

- [Быстрый старт](QuickStart.md)
- [Примеры использования](Examples.md)
- [Руководство по Network Provider](NetworkProvider.md)
