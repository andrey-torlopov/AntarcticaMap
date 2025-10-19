import UIKit

public final class MapTiledView: UIView {
    var tilesSource: TilesSource?

    var size: CGSize {
        set {
            guard size != newValue else { return }
            tiledLayer.frame.size = newValue
            tiledLayer.setNeedsDisplay()
        }
        get { tiledLayer.frame.size }
    }

    var tiledLayer: CATiledLayer { layer as! CATiledLayer }

    var tileSize: Int {
        set {
            tiledLayer.tileSize = CGSize(
                width: CGFloat(newValue) * contentScaleFactor,
                height: CGFloat(newValue) * contentScaleFactor
            )
        }
        get { Int(tiledLayer.tileSize.width / contentScaleFactor) }
    }

    var levelsOfDetail: Int {
        set { tiledLayer.levelsOfDetail = newValue }
        get { tiledLayer.levelsOfDetail }
    }

    var levelsOfDetailBias: Int {
        set { tiledLayer.levelsOfDetailBias = newValue }
        get { tiledLayer.levelsOfDetailBias }
    }

    var isDebug = false

    public override class var layerClass: AnyClass { CATiledLayer.self }

    public override var contentScaleFactor: CGFloat {
        get { 1 }
        set { }
    }

    nonisolated(unsafe)
    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let scale = ctx.ctm.a

        guard let source = tilesSource else { return }

        let tileRequest = source.request(for: CGPoint(x: rect.minX, y: rect.minY), scale: scale)
        guard let image = source.tile(by: tileRequest) else {
            return
        }

        image.draw(in: rect)
        if isDebug {
            ctx.setStrokeColor(UIColor.red.cgColor)
            ctx.setLineWidth(5.0)
            ctx.stroke(rect)
            ctx.drawOverlay(text: tileRequest.description, rect: rect, color: UIColor.black.cgColor)
        }
    }
}
