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
    /// BESLUT B14: the menu sheet.
    static let sheet = Color(dark: 0x1C1C1E, light: 0xFFFFFF)

    /// BESLUT B16, METOD M10: the ten colour steps of the trail, slow to fast (docs/FORM.md).
    static let trail: [Color] = zip(
        [0x525255, 0x636263, 0x757372, 0x878481, 0x9A9590, 0xACA192, 0xBFA585, 0xD1AA77, 0xE4AE65, 0xF6B14F] as [UInt32],
        [0xCCCBCE, 0xC2BFBF, 0xB8B3B0, 0xAEA7A2, 0xA59C93, 0xA49383, 0xAD8E70, 0xB5885C, 0xBC8244, 0xC47B24] as [UInt32]
    ).map { Color(dark: $0, light: $1) }
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
