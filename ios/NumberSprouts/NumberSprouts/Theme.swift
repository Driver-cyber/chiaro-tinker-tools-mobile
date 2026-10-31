//  Theme.swift — bright, calm, rounded. Follows the phone's light/dark setting.
//
//  Even is blue and Odd is orange everywhere: a pair that stays apart for
//  colour-blind eyes too, and each always comes with its word and its picture.

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
    static let bg      = Color.dynamic(dark: 0x15171E, light: 0xFFF7E8)
    static let card    = Color.dynamic(dark: 0x23262F, light: 0xFFFFFF)
    static let text    = Color.dynamic(dark: 0xF4F1EA, light: 0x1F2333)
    static let muted   = Color.dynamic(dark: 0xA9ACBA, light: 0x5E6275)
    static let border  = Color.dynamic(dark: 0x363A46, light: 0xE9DFC9)
    static let even    = Color.dynamic(dark: 0x6EA8FF, light: 0x2F6FD6)
    static let odd     = Color.dynamic(dark: 0xFFA64D, light: 0xD9700F)
    static let right   = Color.dynamic(dark: 0x4CD483, light: 0x22A45A)
    static let sprout  = Color.dynamic(dark: 0x5FD08A, light: 0x2E9E5B)   // the brand green
    static let star    = Color.dynamic(dark: 0xFFD15C, light: 0xF2B111)
    static let onColor = Color.white

    /// Profile tile colours.
    static let tileColors: [Color] = [
        .dynamic(dark: 0x4C8DFF, light: 0x3E7BEA), .dynamic(dark: 0xFF8A4C, light: 0xEC6F2D),
        .dynamic(dark: 0x45C980, light: 0x2E9E5B), .dynamic(dark: 0xB57BFF, light: 0x8E55E0),
        .dynamic(dark: 0xFF6F91, light: 0xE0466C), .dynamic(dark: 0x2FC6C6, light: 0x16A0A0),
        .dynamic(dark: 0xF2C14E, light: 0xD9A21B), .dynamic(dark: 0x8C93A8, light: 0x6A7189),
    ]
    static func tile(_ i: Int) -> Color { tileColors[((i % tileColors.count) + tileColors.count) % tileColors.count] }

    static func round(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Big, rounded, colour-filled: Play, Got it, Save. Always at least 64 pt tall.
struct BigButtonStyle: ButtonStyle {
    var color: Color = Theme.sprout
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.round(24))
            .foregroundStyle(Theme.onColor)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 22))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Bordered companion: Done, Cancel.
struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.round(22, .bold))
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(Theme.card.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.border, lineWidth: 2))
    }
}

/// The kid's emoji or symbol on its coloured tile.
struct Avatar: View {
    let profile: Profile
    var size: CGFloat = 96

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28).fill(Theme.tile(profile.color))
            if profile.isSymbol {
                Image(systemName: profile.icon).font(.system(size: size * 0.46, weight: .bold)).foregroundStyle(.white)
            } else {
                Text(profile.icon).font(.system(size: size * 0.56))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
