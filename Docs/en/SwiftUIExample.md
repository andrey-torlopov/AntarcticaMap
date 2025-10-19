# SwiftUI Example

Complete example of using AntarcticaMap in a SwiftUI application with full controls.

## Features Demonstrated

- ✅ Async/Sync loading mode toggle
- ✅ Date picker for historical imagery
- ✅ Zoom controls
- ✅ Pan controls (arrow buttons)
- ✅ Event logging
- ✅ Network provider configuration
- ✅ Custom button styles

## Complete Implementation

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

        // Create network provider with 6 concurrent requests
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

        // Use async loading by default
        let viewController = TiledMapViewController(
            params: params ?? defaultParams,
            imageSize: imageSize,
            networkProvider: networkProvider
        )

        // Example event handler with logging
        viewController.onEvent = { event in
            if let type = event["type"] as? String {
                let mode = (event["mode"] as? String) ?? "unknown"
                let message = "[\(type)] mode: \(mode)"
                print(message, event)

                // Add only key events to log
                DispatchQueue.main.async {
                    if type == "tile_loaded" || type == "error" {
                        // Can be used for statistics display
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
            // Loading mode toggle
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

            // Date selector
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
                DatePicker("Select Date", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
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

            // Zoom controls
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

            // Navigation controls
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

        // Use network provider only if async mode is enabled
        let viewController = TiledMapViewController(
            params: newParams,
            imageSize: imageSize,
            networkProvider: useAsyncLoading ? networkProvider : nil
        )

        // Example event handler with mode logging
        viewController.onEvent = { event in
            if let type = event["type"] as? String {
                let mode = (event["mode"] as? String) ?? "unknown"
                let message = "[\(type)] mode: \(mode)"
                print(message, event)

                DispatchQueue.main.async {
                    if type == "tile_loaded" || type == "error" {
                        // Can add loading statistics
                    }
                }
            }
        }

        controller = viewController
    }
}

// MARK: - UIViewControllerRepresentable Wrapper

private struct TiledMapViewWrapper: UIViewControllerRepresentable {
    let controller: TiledMapViewController

    func makeUIViewController(context: Context) -> TiledMapViewController {
        controller
    }

    func updateUIViewController(_ uiViewController: TiledMapViewController, context: Context) {}
}

// MARK: - Preview

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

// MARK: - Custom Button Style

/// Simple button style for map controls
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

## Key Implementation Details

### 1. Network Provider Setup

```swift
private let networkProvider: DefaultNetworkProvider

init(...) {
    self.networkProvider = DefaultNetworkProvider(maxConcurrentRequests: 6)
    // ...
}
```

The network provider is created once and reused for better performance.

### 2. Async/Sync Toggle

```swift
let viewController = TiledMapViewController(
    params: newParams,
    imageSize: imageSize,
    networkProvider: useAsyncLoading ? networkProvider : nil
)
```

Passing `nil` as `networkProvider` enables sync mode.

### 3. Event Logging

```swift
viewController.onEvent = { event in
    if let type = event["type"] as? String {
        let mode = (event["mode"] as? String) ?? "unknown"
        print("[\(type)] mode: \(mode)", event)
    }
}
```

Logs tile requests, loads, and errors with mode information.

### 4. Date Updates

```swift
.onChange(of: selectedDate) { oldValue, newValue in
    updateMapDate(newValue)
}
```

Recreates the controller with new parameters when date changes.

### 5. Map Refresh

```swift
TiledMapViewWrapper(controller: controller)
    .id(selectedDate.timeIntervalSince1970)
```

Using `.id()` forces SwiftUI to recreate the view when date changes.

## Running the Example

1. Copy the code into your SwiftUI app
2. Import AntarcticaMap
3. Use `ContentView()` as your main view
4. Build and run

## Controls

- **⚡/🐢 Button** - Toggle between Async/Sync loading
- **📅 Button** - Show/hide date picker
- **±** - Zoom in/out
- **Arrows** - Pan map in four directions

## Tips

- Watch Xcode console for event logs
- Compare async vs sync performance
- Try different dates to see historical imagery
- Adjust `maxConcurrentRequests` for your network

## See Also

- [Quick Start Guide](QuickStart.md)
- [Usage Examples](Examples.md)
- [Network Provider Guide](NetworkProvider.md)
