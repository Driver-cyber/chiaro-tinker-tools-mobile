//  Theme.swift — three looks, one game. Lamp is the CTT original (a warm lamp
//  in honored dark, Cream in daylight); Marginalia is a library at night (gilt
//  on green-black, Hoefler Text, ivory paper by day); Phosphor is an 80s
//  terminal (green phosphor, SF Mono, faint scanlines). Each follows the
//  phone's light/dark setting. Built-in fonts only: nothing to bundle or license.
//
//  The chosen look is a static the views read; ContentView rebuilds its tree
//  when it changes (`.id`), so every `Theme.x` below is read fresh.

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

enum Style: String, CaseIterable, Identifiable {
    case lamp, marginalia, phosphor
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct Palette {
    let bg, panel, text, muted, border, accent, ink, success, danger: Color
}

enum Theme {
    static let storeKey = "primes.theme"
    static var style: Style = Style(rawValue: UserDefaults.standard.string(forKey: storeKey) ?? "") ?? .lamp

    private static let lamp = Palette(
        bg:      .dynamic(dark: 0x14100B, light: 0xF4EDDC),
        panel:   .dynamic(dark: 0x1D1710, light: 0xFBF6EA),
        text:    .dynamic(dark: 0xEFE3CC, light: 0x241C12),
        muted:   .dynamic(dark: 0x9C8A6E, light: 0x6E5F4B),
        border:  .dynamic(dark: 0x3A2E1D, light: 0xD8CBB0),
        accent:  .dynamic(dark: 0xF2A24A, light: 0xA86518),
        ink:     .dynamic(dark: 0x201709, light: 0xFBF6EA),   // text on an accent fill
        success: .dynamic(dark: 0x55C97E, light: 0x16A34A),
        danger:  .dynamic(dark: 0xF0705F, light: 0xDC2626))

    private static let marginalia = Palette(                    // one accent: right answers are gilt too
        bg:      .dynamic(dark: 0x11150F, light: 0xF3EEDF),
        panel:   .dynamic(dark: 0x171C14, light: 0xFAF6EA),
        text:    .dynamic(dark: 0xECE4CF, light: 0x1E2219),
        muted:   .dynamic(dark: 0xA39E86, light: 0x5C5A48),
        border:  .dynamic(dark: 0x343A2C, light: 0xCFC6AE),
        accent:  .dynamic(dark: 0xCDA853, light: 0x7A5C14),
        ink:     .dynamic(dark: 0x14170F, light: 0xFAF6EA),
        success: .dynamic(dark: 0xCDA853, light: 0x7A5C14),
        danger:  .dynamic(dark: 0xD4806E, light: 0xA33A2A))

    private static let phosphor = Palette(
        bg:      .dynamic(dark: 0x070A08, light: 0xECF2EA),
        panel:   .dynamic(dark: 0x0C120E, light: 0xF6FAF4),
        text:    .dynamic(dark: 0xCFEAD8, light: 0x0F2016),
        muted:   .dynamic(dark: 0x7FA08A, light: 0x466052),
        border:  .dynamic(dark: 0x23402F, light: 0xBCCDBF),
        accent:  .dynamic(dark: 0x7CF5A6, light: 0x0F7A3D),
        ink:     .dynamic(dark: 0x06130B, light: 0xF6FAF4),
        success: .dynamic(dark: 0x7CF5A6, light: 0x0F7A3D),
        danger:  .dynamic(dark: 0xFF8A65, light: 0xB4441F))

    private static var p: Palette {
        switch style {
        case .lamp: return lamp
        case .marginalia: return marginalia
        case .phosphor: return phosphor
        }
    }

    static var bg: Color { p.bg }
    static var panel: Color { p.panel }
    static var text: Color { p.text }
    static var muted: Color { p.muted }
    static var border: Color { p.border }
    static var accent: Color { p.accent }
    static var ink: Color { p.ink }
    static var success: Color { p.success }
    static var danger: Color { p.danger }

    private static let book = "Hoefler Text"

    /// Running text and labels.
    static func body(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        switch style {
        case .lamp:       return .system(size: size, weight: weight)
        case .marginalia: return .custom(book, size: size * 1.1).weight(weight)
        case .phosphor:   return .system(size: size * 0.92, weight: weight, design: .monospaced)
        }
    }

    /// Worked math and tables. Marginalia sets it like a footnote, in the book face.
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        switch style {
        case .marginalia: return .custom(book, size: size * 1.1).weight(weight)
        default:          return .system(size: size, weight: weight, design: .monospaced)
        }
    }

    /// Headlines: the title and the verdict.
    static func serif(_ size: CGFloat) -> Font {
        switch style {
        case .lamp:       return .system(size: size, weight: .semibold, design: .serif)
        case .marginalia: return .custom(book, size: size * 1.12).italic()
        case .phosphor:   return .system(size: size * 0.78, weight: .bold, design: .monospaced)
        }
    }

    /// The number on the question screen.
    static func number(_ size: CGFloat) -> Font {
        switch style {
        case .lamp:       return .system(size: size, weight: .bold, design: .monospaced)
        case .marginalia: return .custom(book, size: size * 1.2)      // Hoefler's old-style figures
        case .phosphor:   return .system(size: size * 1.05, weight: .bold, design: .monospaced)
        }
    }

    /// Corner radius: rounded lamp-glass, a book's nearly square corners, a terminal's none.
    static func r(_ x: CGFloat) -> CGFloat {
        switch style {
        case .lamp: return x
        case .marginalia: return min(x, 3)
        case .phosphor: return 0
        }
    }

    static var labelCase: Text.Case? { style == .phosphor ? .uppercase : nil }
    static var prompt: String { style == .phosphor ? "> " : "" }
    static var glow: Color { style == .phosphor ? accent.opacity(0.45) : .clear }
}

/// Phosphor's faint CRT lines, laid over the background.
struct Scanlines: View {
    var body: some View {
        Canvas { ctx, size in
            var y: CGFloat = 0
            while y < size.height {
                ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(Theme.accent.opacity(0.035)))
                y += 3
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Accent-filled, full width — Play / Next.
struct FilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body(20, .bold))
            .textCase(Theme.labelCase)
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(Theme.accent.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: Theme.r(14)))
    }
}

/// Bordered — the reference buttons, Back to checklist, Check my work.
struct OutlineButtonStyle: ButtonStyle {
    var accent = false
    var height: CGFloat = 52
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body(15, .semibold))
            .textCase(Theme.labelCase)
            .foregroundStyle(accent ? Theme.accent : Theme.text)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(Theme.accent.opacity(configuration.isPressed ? 0.14 : 0), in: RoundedRectangle(cornerRadius: Theme.r(12)))
            .overlay(RoundedRectangle(cornerRadius: Theme.r(12)).stroke(accent ? Theme.accent : Theme.border, lineWidth: accent ? 1.5 : 1))
    }
}
