<p align="center">
  <img src="Docs/banner.png" alt="AntarcticaMap" width="600"/>
</p>

<p align="center">
  <a href="https://swift.org">
    <img src="https://img.shields.io/badge/Swift-6.2+-orange.svg?logo=swift" />
  </a>
  <a href="https://swift.org/package-manager/">
    <img src="https://img.shields.io/badge/SPM-compatible-green.svg" />
  </a>
  <img src="https://img.shields.io/badge/platforms-iOS%2017.0+-blue.svg" />
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-lightgrey.svg" />
  </a>
</p>

<p align="center">
  <b>A Swift Package for rendering tiled maps of Antarctica using NASA GIBS satellite imagery.</b>
</p>

<p align="center">
  <a href="README-ru.md">Русская версия</a>
</p>

---

## Features

- 🗺️ **Tiled Map Rendering** - Efficient rendering of large satellite images using `CATiledLayer`
- 🛰️ **NASA GIBS Integration** - Direct access to NASA's Global Imagery Browse Services
- 🌍 **EPSG:3031 Projection** - Antarctic Polar Stereographic projection support
- ⚡ **Concurrent Loading** - Configurable network provider with request deduplication
- 📱 **SwiftUI & UIKit** - Support for both modern and traditional iOS development
- 🔍 **Zoom & Pan** - Smooth multi-level zoom with gesture support

## Quick Start

```swift
import AntarcticaMap

// Create map parameters
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

// Create view controller with network provider
let networkProvider = DefaultNetworkProvider(maxConcurrentRequests: 6)
let mapViewController = TiledMapViewController(
    params: params,
    imageSize: CGSize(width: 8192, height: 8192),
    networkProvider: networkProvider
)
```

For a complete SwiftUI example with controls, see the [SwiftUI Example](Docs/en/SwiftUIExample.md).

## Demo
> **Note:** The demo shows map controls, zoom, pan, date selection, and async/sync loading comparison. In debug mode, you can see tile borders and indices of currently loading tiles.

<p align="center">
  <img src="Docs/demo.gif" alt="AntarcticaMap Demo" width="100%"/>
</p>


## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/andrey-torlopov/AntarcticaMap.git", from: "0.0.1")
]
```

Or via Xcode: **File → Add Package Dependencies...**

## Documentation

- 📦 [Installation Guide](Docs/en/Installation.md)
- 🚀 [Quick Start Guide](Docs/en/QuickStart.md)
- 💡 [SwiftUI Example](Docs/en/SwiftUIExample.md)
- 📖 [Usage Examples](Docs/en/Examples.md)
- 🌐 [Network Provider Guide](Docs/en/NetworkProvider.md)

## Requirements

- iOS 17.0+
- Swift 6.2+
- Xcode 16.0+

## Architecture

```
AntarcticaMap/
├── Model/              # Data structures (EarthDataMapRequest, protocols)
├── Provider/           # Tile source implementations (EarthDataTilesSource)
├── View/               # UI components (TiledMapViewController, MapTiledView)
└── Helper/             # Utilities (zoom calculations, date formatting)
```

## Data Source

This library uses satellite imagery provided by NASA's **Global Imagery Browse Services (GIBS)**.

**GIBS** provides full-resolution satellite imagery from various NASA missions, available within hours of observation. The imagery is served via standard protocols (WMS, WMTS) for easy integration.

🔗 **NASA GIBS API Documentation**: [https://www.earthdata.nasa.gov/engage/open-data-services-software/earthdata-developer-portal/gibs-api](https://www.earthdata.nasa.gov/engage/open-data-services-software/earthdata-developer-portal/gibs-api)

### Available Layers

Currently supported:
- **MODIS Terra Corrected Reflectance** - True color imagery from Terra satellite

More layers can be added by extending the `EarthDataLayer` enum.

## Example App

Run the `AntarcticaMapDemo` target to see:
- Date selection for historical imagery
- Zoom and pan controls
- Async/Sync loading comparison

## License

This project is licensed under the MIT License.

## Acknowledgments

- **NASA GIBS** for providing free, high-resolution satellite imagery
- Built with Swift 6 concurrency features

## Support

- 📖 [Documentation](Docs/en/)
- 🐛 [Issues](https://github.com/andrey-torlopov/AntarcticaMap/issues)
