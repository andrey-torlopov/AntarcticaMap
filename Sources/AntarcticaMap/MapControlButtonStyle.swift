import SwiftUI

/// Простой стиль кнопок для управления картой
public struct MapControlButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(configuration.isPressed ? 0.7 : 1.0))
            )
            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
