import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Brand palette from docs/BRAND.md, use these instead of raw hex values
extension Color {
    static let ground = Color(hex: "#1C1C1B")
    static let surface = Color(hex: "#242424")
    static let surfaceRaised = Color(hex: "#303030")
    static let surfacePressed = Color(hex: "#3A3A3A")
    // Only two text levels: primary for content, secondary for labels, meta lines and hints
    static let textPrimary = Color(hex: "#DDDDDD")
    static let textSecondary = Color(hex: "#DDDDDD").opacity(0.65)
    // Signal orange always means something: the current beat, playback, selection
    static let signal = Color(hex: "#F54206")
    // Symbols and text on signal orange
    static let onSignal = Color(hex: "#1C1C1B")
}