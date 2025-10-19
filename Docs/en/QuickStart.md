# Quick Start Guide

## Basic Usage

### Step 1: Import the Package

```swift
import AntarcticaMap
```

### Step 2: Create Map Parameters

```swift
let params = EarthDataMapRequest(
    minX: -4_000_000,      // Left edge in EPSG:3031
    minY: -4_000_000,      // Bottom edge in EPSG:3031
    maxX: 4_000_000,       // Right edge in EPSG:3031
    maxY: 4_000_000,       // Top edge in EPSG:3031
    width: 512,            // Tile width in pixels
    height: 512,           // Tile height in pixels
    date: Date(),          // Date for satellite imagery
    layers: .modisTerraCorrectedReflectance  // NASA GIBS layer
)
```

### Step 3: Create Network Provider (Recommended)

```swift
let networkProvider = DefaultNetworkProvider(maxConcurrentRequests: 6)
```

### Step 4: Create Map View Controller

```swift
let mapViewController = TiledMapViewController(
    params: params,
    imageSize: CGSize(width: 8192, height: 8192),
    networkProvider: networkProvider
)
```

### Step 5: Present the Map

```swift
// In UIKit
present(mapViewController, animated: true)

// Or push in navigation controller
navigationController?.pushViewController(mapViewController, animated: true)
```

## Complete Example

```swift
import UIKit
import AntarcticaMap

class MainViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let showMapButton = UIButton(type: .system)
        showMapButton.setTitle("Show Antarctica Map", for: .normal)
        showMapButton.addTarget(self, action: #selector(showMap), for: .touchUpInside)
        showMapButton.center = view.center
        view.addSubview(showMapButton)
    }
    
    @objc func showMap() {
        // Create parameters
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
        
        // Create network provider
        let networkProvider = DefaultNetworkProvider(maxConcurrentRequests: 6)
        
        // Create map view controller
        let mapVC = TiledMapViewController(
            params: params,
            imageSize: CGSize(width: 8192, height: 8192),
            networkProvider: networkProvider
        )
        
        // Add zoom controls
        let zoomInButton = UIButton(type: .system)
        zoomInButton.setTitle("Zoom In", for: .normal)
        zoomInButton.addTarget(mapVC, action: #selector(mapVC.zoomIn), for: .touchUpInside)
        
        let zoomOutButton = UIButton(type: .system)
        zoomOutButton.setTitle("Zoom Out", for: .normal)
        zoomOutButton.addTarget(mapVC, action: #selector(mapVC.zoomOut), for: .touchUpInside)
        
        // Present
        navigationController?.pushViewController(mapVC, animated: true)
    }
}
```

## Understanding Parameters

### Geographic Bounds (EPSG:3031)

The coordinates use **EPSG:3031** projection (Antarctic Polar Stereographic):
- `minX, minY`: Bottom-left corner
- `maxX, maxY`: Top-right corner
- Values in meters from the South Pole

Common bounds for full Antarctica:
```swift
minX: -4_000_000, minY: -4_000_000
maxX:  4_000_000, maxY:  4_000_000
```

### Image Size

The `imageSize` determines the maximum resolution:
- Small (2048×2048): Fast loading, lower detail
- Medium (4096×4096): Balanced
- Large (8192×8192): High detail, slower loading
- Extra Large (16384×16384): Maximum detail

### Tile Size

Standard is 512×512 pixels. Don't change unless you have specific requirements.

### Date Selection

```swift
// Today's imagery
let params = EarthDataMapRequest(
    // ...
    date: Date(),
    // ...
)

// Specific date
let calendar = Calendar.current
let components = DateComponents(year: 2023, month: 11, day: 11)
let specificDate = calendar.date(from: components)!

let params = EarthDataMapRequest(
    // ...
    date: specificDate,
    // ...
)
```

## Event Logging

Monitor tile loading events:

```swift
mapViewController.onEvent = { event in
    guard let type = event["type"] as? String else { return }
    
    switch type {
    case "tile_request":
        if let url = event["url"] as? String {
            print("📥 Requesting: \(url)")
        }
    case "tile_loaded":
        if let desc = event["request_description"] as? String {
            print("✅ Loaded: \(desc)")
        }
    case "error":
        if let message = event["message"] as? String {
            print("❌ Error: \(message)")
        }
    case "warning":
        if let message = event["message"] as? String {
            print("⚠️ Warning: \(message)")
        }
    default:
        break
    }
}
```

## Next Steps

- [Usage Examples](Examples.md) - More advanced examples
- [Network Provider Guide](NetworkProvider.md) - Optimize network performance
