import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}

struct AppColors {
    let background: Color
    let surface: Color
    let border: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color

    static let success = Color(hex: 0x22C55E)
    static let warning = Color(hex: 0xF59E0B)
    static let danger = Color(hex: 0xEF4444)
    static let neutral = Color(hex: 0x888888)

    static func forScheme(_ scheme: ColorScheme) -> AppColors {
        scheme == .dark ? dark : light
    }

    private static let light = AppColors(
        background: Color(hex: 0xFFFFFF),
        surface: Color(hex: 0xF5F5F5),
        border: Color.black.opacity(0.08),
        textPrimary: Color(hex: 0x0A0A0A),
        textSecondary: Color(hex: 0x6B6B6B),
        textTertiary: Color(hex: 0xABABAB)
    )

    private static let dark = AppColors(
        background: Color(hex: 0x141414),
        surface: Color(hex: 0x1E1E1E),
        border: Color.white.opacity(0.07),
        textPrimary: Color(hex: 0xF0F0F0),
        textSecondary: Color(hex: 0x888888),
        textTertiary: Color(hex: 0x555555)
    )
}
