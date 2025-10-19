import SwiftUI
import Mazun
import Letopis

public struct AntarcticaTiledMapContentView: View {
    @State private var controller: TiledMapViewController
    private let logger: Letopis

    public init(logger: Letopis) {
        self.logger = logger
        _controller = State(initialValue: TiledMapViewController(logger: logger))
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            TiledMapViewWrapper(controller: controller)
                .ignoresSafeArea()
            controls
                .padding()
        }
    }

    private var controls: some View {
        VStack {
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
            .padding(.bottom, 8)

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
}

private struct TiledMapViewWrapper: UIViewControllerRepresentable {
    let controller: TiledMapViewController

    func makeUIViewController(context: Context) -> TiledMapViewController {
        controller
    }

    func updateUIViewController(_ uiViewController: TiledMapViewController, context: Context) {}
}

private final class TiledMapViewController: UIViewController {
    private var didSetupZoom = false
    private let logger: Letopis

    private lazy var tiledView: MapTiledView = {
        let view = MapTiledView()
        return view
    }()
    
    lazy var tilesSource: EarthDataTilesSource = EarthDataTilesSource(
        imageSize: CGSize(width: 8192, height: 8192),
        tileSize: CGSize(width: 512, height: 512),
        logger: logger
    )

    let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    
    init(logger: Letopis) {
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        logger.info(
            "TiledMapViewController viewDidLoad",
            eventType: DevelopmentEventType.debug,
            eventAction: DevelopmentAction.breakpoint,
            includeSource: true
        )

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

        // Настройка в том же стиле что и ContentView5
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
        
        logger
            .event(DevelopmentEventType.debug)
            .action(DevelopmentAction.breakpoint)
            .source()
            .payload(["size": "\(size)", "tileSize": "\(tileSize)", "levels": "\(levels)"])
            .debug("Load map init")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didSetupZoom {
            didSetupZoom = true
            scaleToFit()
        }
    }

    func scaleToFit() {
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

        logger
            .event(DevelopmentEventType.debug)
            .source()
            .payload(["minZoomScale": "\(minZoomScale)"])
            .debug("Scale to fit")
    }

    func zoomIn() {
        let newScale = min(scrollView.zoomScale * 2, scrollView.maximumZoomScale)
        logger
            .event(DevelopmentEventType.debug)
            .source()
            .payload(["\(scrollView.zoomScale)": "\(newScale)"])
            .debug("Zoom in")
        scrollView.setZoomScale(newScale, animated: true)
    }

    func zoomOut() {
        let newScale = max(scrollView.zoomScale / 2, scrollView.minimumZoomScale)
        logger
            .event(DevelopmentEventType.debug)
            .source()
            .payload(["\(scrollView.zoomScale)": "\(newScale)"])
            .debug("Zoom out")
        scrollView.setZoomScale(newScale, animated: true)
    }

    private func move(dx: CGFloat, dy: CGFloat) {
        var offset = scrollView.contentOffset
        offset.x += dx
        offset.y += dy
        logger.debug("Move: offset=(\(offset.x), \(offset.y))")
        scrollView.setContentOffset(offset, animated: true)
    }

    func moveUp() { move(dx: 0, dy: -20) }
    func moveDown() { move(dx: 0, dy: 20) }
    func moveLeft() { move(dx: -20, dy: 0) }
    func moveRight() { move(dx: 20, dy: 0) }
}

extension TiledMapViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { tiledView }
}
