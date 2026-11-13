import SwiftUI

/// Shared colors and surfaces keep the app and its widgets on the same theme.
enum Neu {
    static let background = Color(light: 0xE0E5EC, dark: 0x2B2F36)
    static let shadowDark = Color(light: 0xA3B1C6, dark: 0x1B1E23)
    static let shadowLight = Color(light: 0xFFFFFF, dark: 0x3A3F49)
    static let textPrimary = Color(light: 0x2D3748, dark: 0xE8ECF2)
    static let textSecondary = Color(light: 0x4A5568, dark: 0xA9B2C0)
    static let accent = Color(light: 0x2F5BC0, dark: 0x7FA3FF)
    static let sun = Color(light: 0xC46A00, dark: 0xFFB347)
    static let cloud = Color(light: 0x4A6FB5, dark: 0x8FB0F0)
}

extension Font {
    static func ubuntu(_ style: UbuntuStyle, size: CGFloat) -> Font {
        .custom(style.filename, size: size)
    }

    enum UbuntuStyle {
        case regular, medium, bold
        var filename: String {
            switch self {
            case .regular: "Ubuntu-Regular"
            case .medium: "Ubuntu-Medium"
            case .bold: "Ubuntu-Bold"
            }
        }
    }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

extension AnyShape {
    static var card: AnyShape { AnyShape(RoundedRectangle(cornerRadius: 20, style: .continuous)) }
    static var circle: AnyShape { AnyShape(Circle()) }
    static var capsule: AnyShape { AnyShape(Capsule()) }
}

enum NeuStyle { case raised, inset }

struct NeuSurface: View {
    var style: NeuStyle
    var shape: AnyShape
    var depth: CGFloat = 8

    var body: some View {
        switch style {
        case .raised:
            shape.fill(Neu.background)
                .shadow(color: Neu.shadowDark, radius: depth, x: depth, y: depth)
                .shadow(color: Neu.shadowLight, radius: depth, x: -depth, y: -depth)
        case .inset:
            shape.fill(Neu.background)
                .overlay(innerShadow(Neu.shadowDark, direction: 1))
                .overlay(innerShadow(Neu.shadowLight, direction: -1))
        }
    }

    private func innerShadow(_ color: Color, direction: CGFloat) -> some View {
        shape.stroke(color, lineWidth: depth)
            .blur(radius: depth * 0.6)
            .offset(x: direction * depth * 0.6, y: direction * depth * 0.6)
            .mask(shape)
    }
}

extension View {
    func neuSurface(_ style: NeuStyle, in shape: AnyShape = .card, depth: CGFloat = 8) -> some View {
        background { NeuSurface(style: style, shape: shape, depth: depth) }
    }
}
