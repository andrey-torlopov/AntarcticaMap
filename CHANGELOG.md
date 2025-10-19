# Changelog

All notable changes to the AntarcticaMap project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2025-10-20

### Initial Release

First public release of AntarcticaMap - a Swift Package for rendering tiled maps of Antarctica using NASA GIBS satellite imagery.

#### Features

- **Tiled Map Rendering** - Efficient rendering of large satellite images using CATiledLayer
- **NASA GIBS Integration** - Direct access to NASA's Global Imagery Browse Services
- **EPSG:3031 Projection** - Antarctic Polar Stereographic projection support
- **Network Provider** - Configurable network provider with request deduplication and concurrency control
- **SwiftUI & UIKit Support** - Components for both modern and traditional iOS development
- **Multi-level Zoom** - Smooth zoom and pan gestures with multiple detail levels

#### Components

**Models**
- `EarthDataMapRequest` - Request model for map parameters (bounds, date, layer)
- `EarthDataLayer` - Enum for available NASA GIBS data layers
- `TileRequest` & `TilesSource` - Protocols for tile source implementations

**Views**
- `TiledMapViewController` - UIKit view controller for displaying the map
- `MapTiledView` - Custom UIView with CATiledLayer for efficient tile rendering

**Providers**
- `EarthDataTilesSource` - Tile source implementation for NASA GIBS API
- `NetworkProvider` - Protocol for network data loading
- `DefaultNetworkProvider` - Default URLSession-based implementation with concurrency control

**Helpers**
- `DateFormatHelper` - Date formatting utilities for NASA GIBS API
- Zoom calculation functions - Level and scale calculations for tile loading

#### Requirements

- iOS 17.0+
- Swift 6.2+
- Xcode 16.0+

#### Documentation

- English documentation in `Docs/en/`
- Russian documentation in `Docs/ru/`
- Comprehensive examples and guides

---

## Future Plans

- Additional NASA GIBS layers support
- Offline caching capabilities
- SwiftUI native view wrapper
- Advanced tile loading strategies

[0.0.1]: https://github.com/yourusername/AntarcticaMap/releases/tag/0.0.1
