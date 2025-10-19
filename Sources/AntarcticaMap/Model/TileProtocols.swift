import Foundation
import UIKit

public protocol TileRequest: CustomStringConvertible { }

public protocol TilesSource {
    var tileSize: CGSize { get }
    var imageSize: CGSize { get }
    func request(for origin: CGPoint, scale: CGFloat) -> TileRequest
    func tile(by request: TileRequest) -> UIImage?
}
