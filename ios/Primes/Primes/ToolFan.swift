//  ToolFan.swift — the reference tools, tucked into one thumb-height button.
//
//  A ✦ in the bottom-right corner of the question screen fans out Roots
//  (straight up), Prime tricks (the diagonal) and Checklist (to the left), the
//  native cousin of the web app's pocket FAB. Everything is placed with
//  .position in one fixed frame, so taps land where the buttons are drawn.
//  Each label sits just outside its
//  own button along the fan's direction, offset by the label box's reach along
//  that direction (|ux|·w/2 + |uy|·h/2), so none collide. Tapping anywhere
//  else folds it away.

import SwiftUI

struct ToolFan: View {
    @Binding var sheet: SheetRoute?
    @State private var open = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let size: CGFloat = 60           // the ✦ button; QuestionView keeps this corner clear
    private let radius: CGFloat = 104
    private let dot: CGFloat = 52
    private let area = CGSize(width: 320, height: 200)   // room for the open fan and its labels
    private var hub: CGPoint { CGPoint(x: area.width - Self.size / 2, y: area.height - Self.size / 2) }

    private struct Tool: Identifiable {
        let route: SheetRoute
        let title: String
        let symbol: String
        let angle: Double                  // degrees; 90 is straight up
        var id: String { title }
    }

    private let tools = [
        Tool(route: .roots, title: "Roots", symbol: "x.squareroot", angle: 90),
        Tool(route: .tricks, title: "Prime tricks", symbol: "wand.and.stars", angle: 135),
        Tool(route: .checklist, title: "Checklist", symbol: "checklist", angle: 180),
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if open {
                Theme.bg.opacity(0.72)
                    .contentShape(Rectangle())
                    .onTapGesture { toggle() }
                    .transition(.opacity)
                    .accessibilityHidden(true)
            }
            ZStack {
                ForEach(tools) { tool in toolButton(tool) }
                mainButton.position(hub)
            }
            .frame(width: area.width, height: area.height)
        }
    }

    private var mainButton: some View {
        Button { toggle() } label: {
            Group {
                if open { Image(systemName: "xmark").font(.system(size: 20, weight: .bold)) }
                else { Text("✦").font(.system(size: 26, weight: .semibold)) }
            }
                .foregroundStyle(open ? Theme.ink : Theme.accent)
                .frame(width: Self.size, height: Self.size)
                .background(open ? Theme.accent : Theme.panel, in: RoundedRectangle(cornerRadius: Theme.r(30)))
                .overlay(RoundedRectangle(cornerRadius: Theme.r(30)).stroke(Theme.accent, lineWidth: 1.5))
                .shadow(color: Theme.glow, radius: 8)
        }
        .accessibilityLabel(open ? "Close tools" : "Tools")
        .accessibilityHint("Roots, Prime tricks and Checklist")
    }

    @ViewBuilder private func toolButton(_ tool: Tool) -> some View {
        let ux = cos(tool.angle * .pi / 180), uy = -sin(tool.angle * .pi / 180)
        let label = CGSize(width: CGFloat(tool.title.count) * 8 + 20, height: 28)
        let reach = abs(ux) * label.width / 2 + abs(uy) * label.height / 2
        let out = dot / 2 + 6 + reach
        let at = open ? CGPoint(x: hub.x + ux * radius, y: hub.y + uy * radius) : hub
        Text(tool.title)
            .font(Theme.body(13.5, .semibold))
            .textCase(Theme.labelCase)
            .foregroundStyle(Theme.text)
            .fixedSize()
            .padding(.horizontal, 10)
            .frame(height: label.height)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: Theme.r(14)))
            .overlay(RoundedRectangle(cornerRadius: Theme.r(14)).stroke(Theme.border, lineWidth: 1))
            .position(x: at.x + ux * out, y: at.y + uy * out)
            .opacity(open ? 1 : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        Button {
            sheet = tool.route
            toggle()
        } label: {
            Image(systemName: tool.symbol)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Theme.text)
                .frame(width: dot, height: dot)
                .background(Theme.panel, in: RoundedRectangle(cornerRadius: Theme.r(26)))
                .overlay(RoundedRectangle(cornerRadius: Theme.r(26)).stroke(Theme.border, lineWidth: 1))
        }
        .accessibilityLabel(tool.title)
        .scaleEffect(open || reduceMotion ? 1 : 0.4)
        .position(at)
        .opacity(open ? 1 : 0)
        .allowsHitTesting(open)
        .accessibilityHidden(!open)
    }

    private func toggle() {
        Haptics.tick()
        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.32, dampingFraction: 0.78)) { open.toggle() }
    }
}
