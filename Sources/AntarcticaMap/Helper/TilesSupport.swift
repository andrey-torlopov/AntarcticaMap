import UIKit
import Foundation

// MARK: - Date Formatting Helper
public struct DateFormatHelper {
    public static func formatDateForEarthData(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }
}

public func levelByZoomScale(
    _ zoomScale: CGFloat,
    fullSize: CGSize,
    firstLevelSize: CGSize = CGSize(width: 1, height: 1)
) -> CGFloat {
    log2(zoomScale * fullSize.width / firstLevelSize.width) + 1
}

public func maxLevel(_ fullSize: CGSize, firstLevelSize: CGSize = CGSize(width: 1, height: 1)) -> CGFloat {
    levelByZoomScale(1.0, fullSize: fullSize, firstLevelSize: firstLevelSize)
}

public func zoomScaleByLevel(_ level: Int) -> CGFloat {
    pow(2, -CGFloat(level))
}

extension CGContext {
    func drawOverlay(text: String, rect: CGRect, color: CGColor = UIColor.black.cgColor) {
        let scale = self.ctm.a
        self.setStrokeColor(color)
        self.setLineWidth(2.0 / scale)
        self.stroke(rect)
        UIGraphicsPushContext(self)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 50 / scale),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor(cgColor: color)
        ]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.size()
        let textPoint = rect.origin.applying(.init(translationX: (rect.width - textSize.width) / 2.0,
                                                   y: (rect.height - textSize.height) / 2.0))
        attributedText.draw(at: textPoint)
        UIGraphicsPopContext()
    }
}
