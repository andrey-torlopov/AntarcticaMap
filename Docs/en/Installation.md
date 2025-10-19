# Installation Guide

## Swift Package Manager (Recommended)

### Via Xcode

1. Open your project in Xcode
2. Go to **File → Add Package Dependencies...**
3. Enter the repository URL:
   ```
   https://github.com/yourusername/AntarcticaMap.git
   ```
4. Select version rule (e.g., "Up to Next Major Version" from 1.0.0)
5. Click **Add Package**
6. Select **AntarcticaMap** library and click **Add Package**

### Via Package.swift

Add the following to your `Package.swift` file:

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

## Requirements

- **iOS**: 17.0 or later
- **Swift**: 6.2 or later
- **Xcode**: 16.0 or later

## Verifying Installation

After installation, import the package in your Swift file:

```swift
import AntarcticaMap

// Verify it works
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

print("AntarcticaMap installed successfully!")
```

## Next Steps

- [Quick Start Guide](QuickStart.md)
- [Usage Examples](Examples.md)
- [Network Provider Guide](NetworkProvider.md)
