import SwiftUI
import UIKit

// BESLUT B5: the colours of the approved sketch (docs/FORM.md), dark and light.
enum Theme {
    static let background = Color(dark: 0x000000, light: 0xFFFFFF)
    /// Text, needle, major ticks.
    static let primary = Color(dark: 0xFFFFFF, light: 0x000000)
    static let minorTick = Color(dark: 0x636366, light: 0xAEAEB2)
    /// Labels, scale numbers, units.
    static let label = Color(dark: 0x8E8E93, light: 0x6E6E73)
    /// The dimmed big number (paused, finding GPS).
    static let dimmed = Color(dark: 0x6E6E73, light: 0x8E8E93)
    /// Max marker and PAUSED.
    static let accent = Color(dark: 0xFFB340, light: 0xC77700)
    /// The line above the numbers.
    static let separator = Color(dark: 0x1C1C1E, light: 0xE5E5EA)
}

extension Color {
    init(dark: UInt32, light: UInt32) {
        self.init(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
