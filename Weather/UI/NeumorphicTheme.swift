import SwiftUI

struct NeuButtonStyle: ButtonStyle {
    var shape: AnyShape = .card
    var depth: CGFloat = 6

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(shape)
            .neuSurface(configuration.isPressed ? .inset : .raised, in: shape, depth: depth)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

