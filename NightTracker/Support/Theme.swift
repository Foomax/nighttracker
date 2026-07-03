import SwiftUI

/// Central dark-mode design tokens. Tuned for low eye-strain at night:
/// near-black backgrounds, soft muted text, a single calm violet accent.
enum Theme {
    static let accent = Color(red: 0.545, green: 0.545, blue: 0.965)      // soft violet
    static let accentSoft = Color(red: 0.66, green: 0.66, blue: 0.98)

    static let background = Color(red: 0.04, green: 0.04, blue: 0.06)     // near-black
    static let card = Color(red: 0.094, green: 0.094, blue: 0.125)        // raised surface
    static let cardElevated = Color(red: 0.13, green: 0.13, blue: 0.17)

    static let textPrimary = Color(red: 0.92, green: 0.92, blue: 0.96)
    static let textSecondary = Color(red: 0.62, green: 0.62, blue: 0.70)
    static let hairline = Color.white.opacity(0.06)

    static let cornerLarge: CGFloat = 22
    static let cornerMedium: CGFloat = 16
    static let cornerSmall: CGFloat = 12
}

/// A reusable rounded "material" card surface.
struct CardBackground: ViewModifier {
    var corner: CGFloat = Theme.cornerLarge
    var fill: Color = Theme.card

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func cardSurface(corner: CGFloat = Theme.cornerLarge, fill: Color = Theme.card) -> some View {
        modifier(CardBackground(corner: corner, fill: fill))
    }
}
