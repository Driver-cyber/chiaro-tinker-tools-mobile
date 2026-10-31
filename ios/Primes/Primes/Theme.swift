//  Theme.swift — chiaroscuro: a warm lamp in honored dark, Cream in daylight.
//  Same tokens as the web app; follows the phone's light/dark setting.

import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

extension Color {
    static func dynamic(dark: UInt32, light: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

enum Theme {
    static let bg      = Color.dynamic(dark: 0x14100B, light: 0xF4EDDC)
    static let panel   = Color.dynamic(dark: 0x1D1710, light: 0xFBF6EA)
    static let text    = Color.dynamic(dark: 0xEFE3CC, light: 0x241C12)
    static let muted   = Color.dynamic(dark: 0x9C8A6E, light: 0x6E5F4B)
    static let border  = Color.dynamic(dark: 0x3A2E1D, light: 0xD8CBB0)
    static let accent  = Color.dynamic(dark: 0xF2A24A, light: 0xA86518)
    static let ink     = Color.dynamic(dark: 0x201709, light: 0xFBF6EA)   // text on an accent fill
    static let success = Color.dynamic(dark: 0x55C97E, light: 0x16A34A)
    static let danger  = Color.dynamic(dark: 0xF0705F, light: 0xDC2626)

    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    static func serif(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .serif) }
}

/// Accent-filled, full width — Play / Next.
struct FilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(Theme.accent.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 14))
    }
}

/// Bordered — the reference buttons, Back to checklist, Check my work.
struct OutlineButtonStyle: ButtonStyle {
    var accent = false
    var height: CGFloat = 52
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(accent ? Theme.accent : Theme.text)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(Theme.accent.opacity(configuration.isPressed ? 0.14 : 0), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent ? Theme.accent : Theme.border, lineWidth: accent ? 1.5 : 1))
    }
}
