# Usage Examples

## Example 1: Basic Usage with UIKit

```swift
import UIKit
import AntarcticaMap

class MapViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        // Create network provider
        let networkProvider = DefaultNetworkProvider(maxConcurrentRequests: 6)
        
        // Create map view controller
        let mapVC = TiledMapViewController(
            params: params,
            imageSize: CGSize(width: 8192, height: 8192),
            networkProvider: networkProvider
        )
        
        // Add as child view controller
        addChild(mapVC)
        view.addSubview(mapVC.view)
        mapVC.view.frame = view.bounds
        mapVC.didMove(toParent: self)
    }
}
```

## Example 2: With Date Selection

```swift
import UIKit
import AntarcticaMap

class DateSelectableMapViewController: UIViewController {
    private let datePicker = UIDatePicker()
    private var mapViewController: TiledMapViewController?
    private let networkProvider = DefaultNetworkProvider(maxConcurrentRequests: 6)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup date picker
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        
        // Add to navigation bar
        navigationItem.titleView = datePicker
        
        // Show map for current date
        updateMap(for: Date())
    }
    
    @objc func dateChanged() {
        updateMap(for: datePicker.date)
    }
    
    private func updateMap(for date: Date) {
        // Remove old map
        mapViewController?.removeFromParent()
        mapViewController?.view.removeFromSuperview()
        
        // Create new parameters with selected date
        let params = EarthDataMapRequest(
            minX: -4_000_000,
            minY: -4_000_000,
            maxX: 4_000_000,
            maxY: 4_000_000,
            width: 512,
            height: 512,
            date: date,
            layers: .modisTerraCorrectedReflectance
        )
        
        // Create new map
        let mapVC = TiledMapViewController(
            params: params,
            imageSize: CGSize(width: 8192, height: 8192),
            networkProvider: networkProvider
        )
        
        // Add as child
        addChild(mapVC)
        view.addSubview(mapVC.view)
        mapVC.view.frame = view.bounds
        mapVC.didMove(toParent: self)
        
        mapViewController = mapVC
    }
}
```

## Example 3: With Event Logging

```swift
import AntarcticaMap
import OSLog

class LoggingMapViewController: UIViewController {
    private let logger = Logger(subsystem: "com.myapp.antarctica", category: "map")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        let networkProvider = DefaultNetworkProvider(maxConcurrentRequests: 6)
        let mapVC = TiledMapViewController(
            params: params,
            imageSize: CGSize(width: 8192, height: 8192),
            networkProvider: networkProvider
        )
        
        // Setup event handler
        mapVC.onEvent = { [weak self] event in
            self?.handleEvent(event)
        }
        
        addChild(mapVC)
        view.addSubview(mapVC.view)
        mapVC.view.frame = view.bounds
        mapVC.didMove(toParent: self)
    }
    
    private func handleEvent(_ event: [String: Any]) {
        guard let type = event["type"] as? String else { return }
        
        switch type {
        case "tile_request":
            if let url = event["url"] as? String {
                logger.debug("📥 Tile request: \(url)")
            }
            
        case "tile_loaded":
            if let desc = event["request_description"] as? String,
               let size = event["data_size"] as? Int {
                logger.info("✅ Tile loaded: \(desc) (\(size) bytes)")
            }
            
        case "error":
            if let message = event["message"] as? String {
                logger.error("❌ Error: \(message)")
            }
            
        case "warning":
            if let message = event["message"] as? String {
                logger.warning("⚠️ Warning: \(message)")
            }
            
        default:
            logger.debug("Unknown event type: \(type)")
        }
    }
}
```

## Example 4: With Zoom Controls

```swift
import UIKit
import AntarcticaMap

class ControlledMapViewController: UIViewController {
    private var mapViewController: TiledMapViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        let networkProvider = DefaultNetworkProvider(maxConcurrentRequests: 6)
        let mapVC = TiledMapViewController(
            params: params,
            imageSize: CGSize(width: 8192, height: 8192),
            networkProvider: networkProvider
        )
        
        addChild(mapVC)
        view.addSubview(mapVC.view)
        mapVC.view.frame = view.bounds
        mapVC.didMove(toParent: self)
        
        mapViewController = mapVC
        
        setupControls()
    }
    
    private func setupControls() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Zoom In button
        let zoomInBtn = createButton(title: "➕", action: #selector(zoomIn))
        
        // Zoom Out button
        let zoomOutBtn = createButton(title: "➖", action: #selector(zoomOut))
        
        // Direction buttons
        let upBtn = createButton(title: "⬆️", action: #selector(moveUp))
        let downBtn = createButton(title: "⬇️", action: #selector(moveDown))
        let leftBtn = createButton(title: "⬅️", action: #selector(moveLeft))
        let rightBtn = createButton(title: "➡️", action: #selector(moveRight))
        
        stackView.addArrangedSubview(zoomInBtn)
        stackView.addArrangedSubview(zoomOutBtn)
        stackView.addArrangedSubview(upBtn)
        stackView.addArrangedSubview(downBtn)
        stackView.addArrangedSubview(leftBtn)
        stackView.addArrangedSubview(rightBtn)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 24)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }
    
    @objc func zoomIn() { mapViewController?.zoomIn() }
    @objc func zoomOut() { mapViewController?.zoomOut() }
    @objc func moveUp() { mapViewController?.moveUp() }
    @objc func moveDown() { mapViewController?.moveDown() }
    @objc func moveLeft() { mapViewController?.moveLeft() }
    @objc func moveRight() { mapViewController?.moveRight() }
}
```

## Example 5: Using Debug Info

```swift
import AntarcticaMap

func printMapRequestInfo() {
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
    
    // Print debug information
    print(params.debug())
    
    // Use cache key for tracking
    print("Cache Key: \(params.cacheKey)")
    
    // Use formatted date
    print("Date String: \(params.dateString)")
}

/*
Output:
EarthDataMapRequest Debug Info:
├─ Coordinates: (-4000000, -4000000) → (4000000, 4000000)
├─ Dimensions: 512×512
├─ BBOX: -4000000,-4000000,4000000,4000000
├─ Area: 64000000000000 sq units
├─ Date: 2025-10-20
├─ Layers: MODIS_Terra_CorrectedReflectance_TrueColor
├─ Format: image/png
├─ CRS: EPSG:3031
└─ Cache Key: MODIS_Terra_CorrectedReflectance_TrueColor_2025-10-20_-4000000_-4000000_4000000_4000000_512x512
*/
```

## Example 6: Custom Date Range

```swift
import AntarcticaMap

func createMapForSpecificDate(year: Int, month: Int, day: Int) -> TiledMapViewController {
    let calendar = Calendar.current
    let components = DateComponents(year: year, month: month, day: day)
    
    guard let date = calendar.date(from: components) else {
        fatalError("Invalid date")
    }
    
    let params = EarthDataMapRequest(
        minX: -4_000_000,
        minY: -4_000_000,
        maxX: 4_000_000,
        maxY: 4_000_000,
        width: 512,
        height: 512,
        date: date,
        layers: .modisTerraCorrectedReflectance
    )
    
    let networkProvider = DefaultNetworkProvider(maxConcurrentRequests: 6)
    
    return TiledMapViewController(
        params: params,
        imageSize: CGSize(width: 8192, height: 8192),
        networkProvider: networkProvider
    )
}

// Usage
let mapVC = createMapForSpecificDate(year: 2023, month: 11, day: 11)
```

## Performance Tips

### 1. Choose Appropriate Image Size

```swift
// For quick preview
let params = EarthDataMapRequest(/* ... */)
let mapVC = TiledMapViewController(
    params: params,
    imageSize: CGSize(width: 2048, height: 2048)  // Fast loading
)

// For high detail
let mapVC = TiledMapViewController(
    params: params,
    imageSize: CGSize(width: 8192, height: 8192)  // High quality
)
```

### 2. Adjust Concurrent Requests

```swift
// For slow connections
let networkProvider = DefaultNetworkProvider(maxConcurrentRequests: 2)

// For fast connections
let networkProvider = DefaultNetworkProvider(maxConcurrentRequests: 10)
```

### 3. Reuse Network Provider

```swift
class MapManager {
    static let shared = MapManager()
    let networkProvider = DefaultNetworkProvider(maxConcurrentRequests: 6)
    
    private init() {}
    
    func createMapViewController(for date: Date) -> TiledMapViewController {
        let params = EarthDataMapRequest(
            minX: -4_000_000,
            minY: -4_000_000,
            maxX: 4_000_000,
            maxY: 4_000_000,
            width: 512,
            height: 512,
            date: date,
            layers: .modisTerraCorrectedReflectance
        )
        
        return TiledMapViewController(
            params: params,
            imageSize: CGSize(width: 8192, height: 8192),
            networkProvider: networkProvider  // Reuse provider
        )
    }
}
```

## Next Steps

- [Network Provider Guide](NetworkProvider.md) - Advanced network configuration
