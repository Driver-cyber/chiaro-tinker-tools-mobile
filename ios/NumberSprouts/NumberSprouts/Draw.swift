//  Draw.swift — the Draw concept: pick a picture, then finish it.
//
//  Color by Number: every region shows a little problem; the key says which
//  answer goes with which colour. Pick a colour, tap the regions whose answer
//  matches, and the picture fills in. A mismatch never scolds: it says what the
//  problem makes and asks for that colour. A finished picture names its shapes
//  ("1 rectangle, 3 triangles and 3 circles") and is kept on the player's
//  profile. Dot to Dot and Explore live in DotToDot.swift.

import SwiftUI

enum ColorByNumber {
    /// One distinct number per paint, from 2 up to `max`.
    static func key<G: RandomNumberGenerator>(paints: Int, max: Int, using rng: inout G) -> [Int] {
        Array((2...max).shuffled(using: &rng).prefix(paints))
    }

    /// A problem whose answer is `t`, staying within `max`: "3 + 4" or "9 − 2".
    static func problem<G: RandomNumberGenerator>(for t: Int, max: Int, using rng: inout G) -> String {
        if t < max && Bool.random(using: &rng) {
            let c = Int.random(in: (t + 1)...max, using: &rng)
            return "\(c) − \(c - t)"
        }
        let a = Int.random(in: 1...(t - 1), using: &rng)
        return "\(a) + \(t - a)"
    }
}

/// Pick a picture (finished ones carry a check), or go straight to Explore.
struct DrawView: View {
    @EnvironmentObject private var model: AppModel
    let mode: Mode
    let kind: DrawKind
    @State private var picture: String?

    var body: some View {
        if kind == .explore {
            ExploreView { model.screen = .home }
        } else if let id = picture {
            switch kind {
            case .color(let max):
                if let p = Pictures.color.first(where: { $0.id == id }) {
                    ColorByNumberView(picture: p, max: max, done: { finish(id) }, next: { advance(id) }, close: { picture = nil }).id(id)
                }
            default:
                if let p = Pictures.dots.first(where: { $0.id == id }) {
                    DotToDotView(picture: p, steps: kind == .dotSteps, done: { finish(id) }, next: { advance(id) }, close: { picture = nil }).id(id)
                }
            }
        } else {
            picker
        }
    }

    private var ids: [(id: String, name: String)] {
        if case .color = kind { return Pictures.color.map { ($0.id, $0.name) } }
        return Pictures.dots.map { ($0.id, $0.name) }
    }

    private func finish(_ id: String) { model.recordPicture("\(mode.id)/\(id)") }

    private func advance(_ id: String) {
        let list = ids.map(\.id)
        let i = list.firstIndex(of: id) ?? 0
        picture = list[(i + 1) % list.count]
    }

    private var picker: some View {
        let done = model.current?.pictures ?? []
        return VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                CircleButton(symbol: "xmark", label: "Back") { model.screen = .home }
                Text(mode.title).font(Theme.round(26)).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.6)
                Spacer()
                PlayerBadge()
            }
            .padding(.top, 8)
            Text("Pick a picture").font(Theme.round(18, .bold)).foregroundStyle(Theme.muted)
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(ids, id: \.id) { item in
                        let finished = done.contains("\(mode.id)/\(item.id)")
                        Button { picture = item.id; Haptics.tick() } label: {
                            VStack(spacing: 10) {
                                PictureThumb(kind: kind, id: item.id, finished: finished)
                                    .frame(width: 120, height: 120)
                                Text(finished ? item.name.capitalized : "?")
                                    .font(Theme.round(20))
                                    .foregroundStyle(Theme.text)
                            }
                            .frame(maxWidth: .infinity, minHeight: 176)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 26))
                            .overlay(RoundedRectangle(cornerRadius: 26).stroke(finished ? Theme.sprout : Theme.border, lineWidth: finished ? 3 : 2))
                            .overlay(alignment: .topTrailing) {
                                if finished {
                                    Image(systemName: "checkmark.circle.fill").font(.system(size: 28)).foregroundStyle(Theme.sprout).padding(10)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(finished ? "\(item.name), finished" : "A mystery picture")
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

/// A finished picture shows itself; an unfinished one stays a mystery outline.
private struct PictureThumb: View {
    let kind: DrawKind
    let id: String
    let finished: Bool

    var body: some View {
        GeometryReader { g in
            let side = min(g.size.width, g.size.height)
            ZStack {
                if case .color = kind, let p = Pictures.color.first(where: { $0.id == id }) {
                    ForEach(Array(p.regions.enumerated()), id: \.offset) { _, r in
                        r.path(side).fill(finished ? r.paint.color : Theme.border.opacity(0.35))
                        r.path(side).stroke(Theme.muted.opacity(finished ? 0 : 0.5), lineWidth: 1)
                    }
                } else if let p = Pictures.dots.first(where: { $0.id == id }) {
                    let path = DotGeometry.path(p.points.map { CGPoint(x: $0.x, y: $0.y) }, side: side, closed: true)
                    if finished { path.fill(p.paint.color.opacity(0.85)); path.stroke(Theme.text, lineWidth: 2) }
                    else {
                        ForEach(0..<p.points.count, id: \.self) { i in
                            let pt = DotGeometry.point(CGPoint(x: p.points[i].x, y: p.points[i].y), side: side)
                            Circle().fill(Theme.muted.opacity(0.6)).frame(width: 7, height: 7).position(pt)
                        }
                    }
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityHidden(true)
    }
}

struct ColorByNumberView: View {
    let picture: ColorPicture
    let max: Int
    let done: () -> Void
    let next: () -> Void
    let close: () -> Void

    @State private var key: [Int] = []                 // number for each paint, same order as picture.paints
    @State private var problems: [String] = []         // one per region
    @State private var labels: [CGPoint] = []          // where each problem sits, 10-unit square
    @State private var filled: Set<Int> = []
    @State private var selected: Int?                  // index into paints
    @State private var hint: String?
    @State private var shakeRegion: Int?
    @State private var shakes: CGFloat = 0
    @State private var finished = false
    @State private var bursts = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var paints: [Paint] { picture.paints }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                CircleButton(symbol: "xmark", label: "Back to pictures", action: close)
                Text(finished ? "You made a \(picture.name)!" : "Color by Number")
                    .font(Theme.round(24)).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.6)
                Spacer()
                PlayerBadge()
            }
            .padding(.top, 8)
            canvas
            if finished { finishedPanel } else { keyPanel }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .overlay { if !reduceMotion { Burst(trigger: bursts).allowsHitTesting(false) } }
        .onAppear(perform: setUp)
    }

    private func setUp() {
        var g = SystemRandomNumberGenerator()
        key = ColorByNumber.key(paints: paints.count, max: max, using: &g)
        labels = picture.regions.indices.map { picture.labelPoint($0) }
        problems = picture.regions.map { r in
            let t = key[paints.firstIndex(of: r.paint)!]
            return ColorByNumber.problem(for: t, max: max, using: &g)
        }
    }

    private var canvas: some View {
        GeometryReader { g in
            let side = min(g.size.width, g.size.height)
            ZStack(alignment: .topLeading) {
                ForEach(Array(picture.regions.enumerated()), id: \.offset) { i, r in
                    let isFilled = filled.contains(i)
                    r.path(side)
                        .fill(isFilled ? r.paint.color : Theme.card)
                        .animation(.easeOut(duration: 0.35), value: isFilled)
                    r.path(side).stroke(Theme.muted.opacity(finished ? 0 : 0.7), lineWidth: 1.5)
                    if !isFilled && i < problems.count {
                        Text(problems[i])
                            .font(Theme.round(Swift.max(10, Swift.min(18, r.room * side / 10 / 3.4)), .bold))
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)
                            .fixedSize()
                            .position(i < labels.count ? CGPoint(x: labels[i].x * side / 10, y: labels[i].y * side / 10) : r.center(side))
                            .modifier(Shake(amount: shakeRegion == i && !reduceMotion ? 6 : 0, animatableData: shakes))
                    }
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.border, lineWidth: 2))
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .local) { p in tap(p, side: side) }
            .frame(maxWidth: .infinity)
            .accessibilityElement()
            .accessibilityLabel("A picture to color. \(picture.regions.count - filled.count) parts left.")
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func tap(_ p: CGPoint, side: CGFloat) {
        guard !finished else { return }
        guard let i = picture.regions.indices.reversed().first(where: { picture.regions[$0].path(side).contains(p) }),
              !filled.contains(i) else { return }
        guard let s = selected else { hint = "First pick a color from the key."; return }
        let r = picture.regions[i]
        let answer = key[paints.firstIndex(of: r.paint)!]
        if paints[s] == r.paint {
            withAnimation { filled.insert(i) }
            hint = nil
            Haptics.tick()
            if filled.count == picture.regions.count { complete() }
        } else {
            Haptics.miss()
            shakeRegion = i
            withAnimation(.linear(duration: 0.4)) { shakes += 1 }
            hint = "\(problems[i]) makes \(answer). That one is \(r.paint.name)!"
        }
    }

    private func complete() {
        finished = true
        bursts += 1
        Haptics.right()
        done()
    }

    private var keyPanel: some View {
        VStack(spacing: 10) {
            Text(hint ?? "Pick a color, then tap every part that makes its number.")
                .font(Theme.round(16, .bold))
                .foregroundStyle(hint == nil ? Theme.muted : Theme.odd)
                .multilineTextAlignment(.center)
                .frame(minHeight: 44)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(Array(paints.enumerated()), id: \.offset) { i, paint in
                    let on = selected == i
                    Button { selected = i; hint = nil; Haptics.tick() } label: {
                        HStack(spacing: 8) {
                            Circle().fill(paint.color).frame(width: 30, height: 30)
                                .overlay(Circle().stroke(Theme.border, lineWidth: 1.5))
                            Text(i < key.count ? String(key[i]) : "").font(Theme.round(28)).foregroundStyle(Theme.text)
                        }
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .background(on ? paint.color.opacity(0.25) : Theme.card, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(on ? Theme.text : Theme.border, lineWidth: on ? 3 : 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(paint.name) is \(i < key.count ? key[i] : 0)")
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
        }
    }

    private var finishedPanel: some View {
        VStack(spacing: 12) {
            Text("Your \(picture.name) has \(picture.shapeSummary).")
                .font(Theme.round(18, .bold))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: next) { Label("Next picture", systemImage: "arrow.right") }.buttonStyle(BigButtonStyle())
            Button("Done", action: close).buttonStyle(SoftButtonStyle())
        }
    }
}
