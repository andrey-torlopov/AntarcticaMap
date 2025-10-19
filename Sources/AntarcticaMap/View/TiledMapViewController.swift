import UIKit

public final class TiledMapViewController: UIViewController {
    private var didSetupZoom = false

    /// Optional event handler for tile provider events
    public var onEvent: TileSourceEventHandler? {
        didSet {
            tilesSource.onEvent = onEvent
        }
    }

    private lazy var tiledView: MapTiledView = {
        let view = MapTiledView()
        return view
    }()

    var tilesSource: EarthDataTilesSource

    public let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    public init(params: EarthDataMapRequest, imageSize: CGSize, networkProvider: NetworkProvider? = nil) {
        self.tilesSource = EarthDataTilesSource(
            params: params,
            imageSize: imageSize,
            tileSize: CGSize(width: 512, height: 512),
            networkProvider: networkProvider
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: scrollView.topAnchor),
            view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
        ])

        tiledView.tilesSource = tilesSource
        tiledView.isDebug = true
        scrollView.addSubview(tiledView)
        scrollView.delegate = self

        let size = tilesSource.imageSize
        let tileSize = tilesSource.tileSize

        guard size != .zero, tileSize != .zero else { return }

        let levels = Int(maxLevel(size, firstLevelSize: tileSize))
        tiledView.size = size
        tiledView.tileSize = Int(tileSize.width)
        tiledView.levelsOfDetail = levels
        tiledView.levelsOfDetailBias = 0

        scrollView.minimumZoomScale = zoomScaleByLevel(levels)
        scrollView.maximumZoomScale = 1.0
        scrollView.contentSize = tiledView.frame.size
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didSetupZoom {
            didSetupZoom = true
            scaleToFit()
        }
    }

    public func scaleToFit() {
        let scrollViewSize = scrollView.bounds.size
        let contentSize = tiledView.bounds.size

        guard contentSize.width > 0 && contentSize.height > 0 &&
              scrollViewSize.width > 0 && scrollViewSize.height > 0 else {
            return
        }

        let widthScale = scrollViewSize.width / contentSize.width
        let heightScale = scrollViewSize.height / contentSize.height
        let minZoomScale = min(widthScale, heightScale)

        scrollView.minimumZoomScale = minZoomScale
        scrollView.setZoomScale(minZoomScale, animated: false)
    }

    public func zoomIn() {
        let newScale = min(scrollView.zoomScale * 2, scrollView.maximumZoomScale)
        scrollView.setZoomScale(newScale, animated: true)
    }

    public func zoomOut() {
        let newScale = max(scrollView.zoomScale / 2, scrollView.minimumZoomScale)
        scrollView.setZoomScale(newScale, animated: true)
    }

    private func move(dx: CGFloat, dy: CGFloat) {
        var offset = scrollView.contentOffset
        offset.x += dx
        offset.y += dy
        scrollView.setContentOffset(offset, animated: true)
    }

    public func moveUp() { move(dx: 0, dy: -20) }
    public func moveDown() { move(dx: 0, dy: 20) }
    public func moveLeft() { move(dx: -20, dy: 0) }
    public func moveRight() { move(dx: 20, dy: 0) }
}

extension TiledMapViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? { tiledView }
}
