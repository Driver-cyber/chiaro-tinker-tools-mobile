//  Guide.swift — How to play, then why primes, one screen at a time.
//
//  A vertical pager: swipe up for the next screen. Three screens teach the
//  game (what the buttons do, the square-root test, the prime tricks); then a
//  chapter list and one idea per screen on why primes are worth a minute; the
//  168 you've found; and a bonus way to see a prime. The screens themselves
//  live in GuideScreens.swift. Every figure here is checked arithmetic; nothing
//  is decorative data except the digit walls, which are labelled stand-ins.

import SwiftUI

enum GuideScreen: Int, CaseIterable {
    case buttons, roots, tricks
    case chapters, elements, molecules, euclid, sieve, spiral, cicadas, unsolved, secrets, biggest
    case coda, rectangle
}

struct GuideView: View {
    let solved: [Int: String]
    let play: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var current: Int?
    private let start: GuideScreen

    /// `start` opens the guide at a screen: Story mode links to the one each chapter is about.
    init(solved: [Int: String], start: GuideScreen = .buttons, play: @escaping () -> Void) {
        self.solved = solved
        self.play = play
        self.start = start
        _current = State(initialValue: start.rawValue)
    }

    var body: some View {
        GeometryReader { g in
            let inset = g.safeAreaInsets
            let size = CGSize(width: g.size.width + inset.leading + inset.trailing, height: g.size.height + inset.top + inset.bottom)
            ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    ForEach(GuideScreen.allCases, id: \.rawValue) { s in
                        screen(s)
                            .padding(.top, inset.top)
                            .padding(.bottom, inset.bottom)
                            .padding(.leading, inset.leading)
                            .padding(.trailing, inset.trailing)
                            .frame(width: size.width, height: size.height)
                            .id(s.rawValue)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $current)
            .scrollIndicators(.hidden)
            .ignoresSafeArea()
            .task { if start != .buttons { proxy.scrollTo(start.rawValue, anchor: .top) } }
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .overlay(alignment: .trailing) { PageDots(count: GuideScreen.allCases.count, current: current ?? 0) }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 17, weight: .semibold)).frame(width: 48, height: 48)
            }
            .foregroundStyle(Theme.text)
            .background(Theme.panel, in: Circle())
            .overlay(Circle().stroke(Theme.border, lineWidth: 1))
            .padding(.top, 10)
            .padding(.trailing, 14)
            .accessibilityLabel("Close")
        }
    }

    private func go(_ s: GuideScreen) {
        Haptics.tick()
        withAnimation(.easeInOut(duration: 0.4)) { current = s.rawValue }
    }

    @ViewBuilder private func screen(_ s: GuideScreen) -> some View {
        let active = current == s.rawValue
        switch s {
        case .buttons:   ButtonsScreen()
        case .roots:     RootsScreen()
        case .tricks:    TricksScreen()
        case .chapters:  ChaptersScreen(go: go)
        case .elements:  ElementsScreen()
        case .molecules: MoleculesScreen()
        case .euclid:    Driven(active: active, seconds: 5) { EuclidBeat(t: $0) }
        case .sieve:     SieveScreen()
        case .spiral:    Driven(active: active, seconds: 4) { SpiralBeat(t: $0) }
        case .cicadas:   Driven(active: active, seconds: 6) { CicadaBeat(t: $0) }
        case .unsolved:  UnsolvedScreen()
        case .secrets:   Driven(active: active, seconds: 6) { SecretsBeat(t: $0) }
        case .biggest:   BiggestScreen()
        case .coda:      CodaScreen(solved: solved, play: play)
        case .rectangle: RectangleScreen()
        }
    }
}

/// Where you are in the pager: a thin column of dots on the right edge.
private struct PageDots: View {
    let count: Int
    let current: Int
    var body: some View {
        VStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { k in
                Circle()
                    .fill(k == current ? Theme.accent : Theme.border)
                    .frame(width: k == current ? 6 : 4, height: k == current ? 6 : 4)
            }
        }
        .frame(width: 10)
        .padding(.trailing, 5)
        .animation(.easeOut(duration: 0.2), value: current)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Beat mechanics

/// 0 before a, 1 after b, linear between.
func seg(_ t: Double, _ a: Double, _ b: Double) -> Double {
    min(max((t - a) / (b - a), 0), 1)
}

/// Plays a beat's 0…1 timeline once each time its screen comes into view.
/// Reduce Motion shows the finished state.
struct Driven<Content: View>: View {
    let active: Bool
    let seconds: Double
    @ViewBuilder let content: (Double) -> Content
    @State private var t = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GuidePage { content(t) }
            .task(id: active) {
                guard active else { return }
                if reduceMotion { t = 1; return }
                let steps = Int(seconds * 30)
                for k in 0...steps {
                    if Task.isCancelled { return }
                    t = Double(k) / Double(steps)
                    try? await Task.sleep(for: .milliseconds(33))
                }
            }
    }
}

/// One beat's layout: kicker, headline, the visual, a short caption.
struct Beat<Visual: View>: View {
    let kicker: String
    let title: String
    let caption: String
    @ViewBuilder let visual: Visual

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Kicker(text: kicker)
            Headline(text: title)
            visual
                .frame(maxWidth: .infinity, minHeight: 280, maxHeight: 340)
            Text(caption)
                .font(Theme.body(15))
                .foregroundStyle(Theme.muted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

/// Math with its primes in the accent colour.
func mathLine(_ parts: [String], size: CGFloat = 20) -> Text {
    var s = AttributedString()
    for (k, part) in parts.enumerated() {
        var a = AttributedString((k == 0 ? "" : " ") + part)
        if let n = Int(part), Sieve.isPrime(n) { a.foregroundColor = Theme.accent } else { a.foregroundColor = Theme.text }
        s += a
    }
    return Text(s).font(Theme.mono(size, .semibold))
}

/// Primality for the guide's larger numbers (the spiral goes past 999).
enum Sieve {
    static let limit = 40_000
    static let flags: [Bool] = {
        var f = [Bool](repeating: true, count: limit + 1)
        f[0] = false; f[1] = false
        var i = 2
        while i * i <= limit {
            if f[i] { var j = i * i; while j <= limit { f[j] = false; j += i } }
            i += 1
        }
        return f
    }()
    static func isPrime(_ n: Int) -> Bool { n >= 0 && n <= limit && flags[n] }
}

// MARK: - Why primes

/// Multiply every prime you know, add one.
struct EuclidBeat: View {
    let t: Double

    var body: some View {
        Beat(kicker: "Two", title: "They never run out.",
             caption: "Euclid proved it around 300 BC. Multiply every prime on your list and add 1. Nothing on the list divides the result (each leaves a remainder of 1), so a prime is always missing. From every list. Forever.") {
            VStack(alignment: .leading, spacing: 14) {
                Reveal(t: t, from: 0.05, to: 0.35, parts: ["2", "×", "3", "×", "5", "×", "7", "+", "1"])
                HStack(spacing: 10) {
                    mathLine(["=", "211"], size: 30)
                    Tag(text: "prime")
                }
                .opacity(seg(t, 0.36, 0.44))
                Reveal(t: t, from: 0.5, to: 0.72, parts: ["2", "×", "3", "×", "5", "×", "7", "×", "11", "×", "13", "+", "1"])
                    .padding(.top, 10)
                mathLine(["=", "30031"], size: 26).opacity(seg(t, 0.73, 0.79))
                HStack(spacing: 10) {
                    mathLine(["=", "59", "×", "509"], size: 26)
                    Tag(text: "both prime")
                }
                .opacity(seg(t, 0.8, 0.86))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// A sum written term by term as the scroll moves.
private struct Reveal: View {
    let t: Double
    let from: Double
    let to: Double
    let parts: [String]
    var body: some View {
        let n = Int((seg(t, from, to) * Double(parts.count)).rounded(.up))
        return mathLine(Array(parts.prefix(max(n, 1))), size: 20)
            .opacity(seg(t, from - 0.03, from))
    }
}

struct Tag: View {
    let text: String
    var body: some View {
        Text(text)
            .font(Theme.body(12, .semibold))
            .textCase(.uppercase)
            .tracking(0.8)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.r(6)))
    }
}

/// The Ulam spiral, drawn outward as you scroll.
struct SpiralBeat: View {
    let t: Double
    static let side = 51
    static let cells: [(x: Int, y: Int)] = {
        var out = [(x: Int, y: Int)](), x = 0, y = 0, step = 1
        out.append((0, 0))
        let dirs = [(1, 0), (0, -1), (-1, 0), (0, 1)]
        var d = 0
        while out.count < side * side {
            for _ in 0..<2 {
                for _ in 0..<step where out.count < side * side {
                    x += dirs[d].0; y += dirs[d].1
                    out.append((x, y))
                }
                d = (d + 1) % 4
            }
            step += 1
        }
        return out
    }()

    var body: some View {
        let shown = Int(seg(t, 0.05, 0.8) * Double(Self.cells.count))
        Beat(kicker: "Four", title: "They have a pattern nobody has cracked.",
             caption: "In 1963 Stanisław Ulam, stuck in a dull talk, wrote the numbers in a spiral and circled the primes. They lined up along diagonals. Mathematicians can explain some of it. Nobody has proved all of it.") {
            Canvas { ctx, size in
                let cell = min(size.width, size.height) / CGFloat(Self.side)
                let cx = size.width / 2, cy = size.height / 2
                for k in 0..<shown {
                    let c = Self.cells[k]
                    let prime = Sieve.isPrime(k + 1)
                    let r = prime ? cell * 0.42 : cell * 0.12
                    let rect = CGRect(x: cx + CGFloat(c.x) * cell - r, y: cy + CGFloat(c.y) * cell - r, width: r * 2, height: r * 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(prime ? Theme.accent : Theme.muted.opacity(0.25)))
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .accessibilityLabel("The numbers 1 to 2,601 in a square spiral, with the primes lit. They gather along diagonal lines.")
        }
    }
}

/// Prime life cycles against a six-year predator.
struct CicadaBeat: View {
    let t: Double

    var body: some View {
        let year = seg(t, 0.08, 0.8) * 102
        Beat(kicker: "Five", title: "Nature counts in primes, too.",
             caption: "Some cicadas live 13 or 17 years underground, then all come up at once. One theory for why: a prime cycle rarely lines up with the shorter cycles of predators.") {
            VStack(alignment: .leading, spacing: 26) {
                Timeline(cycle: 12, year: year)
                Timeline(cycle: 17, year: year)
                HStack(spacing: 8) {
                    Circle().fill(Theme.danger).frame(width: 9, height: 9)
                    Text("a meal for a 6-year predator")
                        .font(Theme.body(13))
                        .foregroundStyle(Theme.muted)
                }
                Text("Year \(Int(year))")
                    .font(Theme.mono(15, .semibold))
                    .foregroundStyle(Theme.muted)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct Timeline: View {
    let cycle: Int
    let year: Double

    var body: some View {
        let ups = Array(stride(from: cycle, through: 102, by: cycle))
        let met = ups.filter { $0 % 6 == 0 && Double($0) <= year }.count
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(cycle)-year cycle").font(Theme.body(15, .semibold)).foregroundStyle(Theme.text)
                Spacer()
                Text("met \(met)×").font(Theme.mono(14)).foregroundStyle(met > 1 ? Theme.danger : Theme.accent).monospacedDigit()
            }
            GeometryReader { g in
                let w = g.size.width
                ZStack(alignment: .leading) {
                    Theme.border.frame(height: 1)
                    Theme.accent.opacity(0.6).frame(width: w * CGFloat(year / 102), height: 1)
                    ForEach(ups, id: \.self) { y in
                        let on = Double(y) <= year
                        Circle()
                            .fill(y % 6 == 0 ? Theme.danger : Theme.accent)
                            .frame(width: 11, height: 11)
                            .scaleEffect(on ? 1 : 0.2)
                            .opacity(on ? 1 : 0)
                            .offset(x: w * CGFloat(y) / 102 - 5.5)
                    }
                }
            }
            .frame(height: 12)
        }
    }
}

/// Easy one way, hopeless the other.
struct SecretsBeat: View {
    let t: Double
    private let trial = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53]

    var body: some View {
        let k = min(Int(seg(t, 0.3, 0.62) * Double(trial.count)), trial.count - 1)
        let found = seg(t, 0.3, 0.62) >= 1
        Beat(kicker: "Seven", title: "And they keep your secrets.",
             caption: "Multiplying two huge primes takes a computer an instant. Splitting the answer back into them, when each prime is hundreds of digits long, would take longer than anyone can wait. That one-way street is RSA, part of what keeps messages and payments private.") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    mathLine(["61", "×", "53", "=", "3233"], size: 24)
                    Tag(text: "instant")
                }
                .opacity(seg(t, 0.04, 0.12))
                HStack(spacing: 10) {
                    mathLine(["3233", "=", "?", "×", "?"], size: 24)
                }
                .opacity(seg(t, 0.18, 0.26))
                HStack(spacing: 10) {
                    Text("÷ \(trial[k])")
                        .font(Theme.mono(22, .bold))
                        .foregroundStyle(found ? Theme.accent : Theme.text)
                        .monospacedDigit()
                    Image(systemName: found ? "checkmark" : "xmark")
                        .foregroundStyle(found ? Theme.accent : Theme.muted)
                    if found { mathLine(["→", "53", "×", "61"], size: 20) }
                }
                .opacity(seg(t, 0.28, 0.32))
                VStack(alignment: .leading, spacing: 6) {
                    Text(DigitWall.text)
                        .font(Theme.mono(9))
                        .foregroundStyle(Theme.muted.opacity(0.7))
                        .lineLimit(5)
                    Text("A real key is a number like this, 617 digits long. Try all the primes on that.")
                        .font(Theme.body(13, .semibold))
                        .foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(seg(t, 0.66, 0.76))
                .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// A stand-in wall of digits, for size only. Not a real key.
enum DigitWall {
    static let text: String = {
        var s = "", x: UInt32 = 2_654_435_761
        for _ in 0..<617 { x = x &* 1_103_515_245 &+ 12_345; s.append(Character(String((x >> 16) % 10))) }
        return s
    }()
}
