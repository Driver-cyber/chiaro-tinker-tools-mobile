//  Guide.swift — How to play, then why primes.
//
//  The top is enough to play: the square-root rule, one worked example (91,
//  which looks prime), and what the buttons do. Below it, a short tour of why
//  primes are worth a minute: each beat pins to the screen while you scroll,
//  and the scroll itself drives the math, so you set the pace. Every figure
//  here is checked arithmetic; nothing is decorative data except the digit
//  wall in the last beat, which is labelled as a stand-in.

import SwiftUI

struct GuideView: View {
    let play: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { outer in
            ScrollView {
                VStack(spacing: 0) {
                    HowToPlay()
                        .padding(.horizontal, 24)
                        .padding(.top, 56)
                    WhyIntro()
                        .padding(.horizontal, 24)
                        .padding(.top, 72)
                        .padding(.bottom, 24)
                    Pinned(beats: 5, page: outer.size.height) { i, t in
                        switch i {
                        case 0: AtomsBeat(t: t)
                        case 1: EuclidBeat(t: t)
                        case 2: SpiralBeat(t: t)
                        case 3: CicadaBeat(t: t)
                        default: SecretsBeat(t: t)
                        }
                    }
                    Coda(play: play)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 72)
                }
            }
            .coordinateSpace(name: "guide")
        }
        .background(Theme.bg.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 17, weight: .semibold)).frame(width: 48, height: 48)
            }
            .foregroundStyle(Theme.text)
            .background(Theme.bg.opacity(0.85), in: Circle())
            .padding(.top, 10)
            .padding(.trailing, 10)
            .accessibilityLabel("Close")
        }
    }
}

// MARK: - Scroll mechanics

/// 0 before a, 1 after b, linear between.
private func seg(_ t: Double, _ a: Double, _ b: Double) -> Double {
    min(max((t - a) / (b - a), 0), 1)
}

/// A tall block whose content stays pinned to the screen while it scrolls
/// past, one screen of scrolling per beat. Hands each beat its local
/// progress 0…1, and cross-fades between beats.
struct Pinned<Content: View>: View {
    let beats: Int
    let page: CGFloat
    @ViewBuilder let content: (Int, Double) -> Content

    var body: some View {
        GeometryReader { g in
            let travel = page * CGFloat(beats)
            let scrolled = min(max(-g.frame(in: .named("guide")).minY, 0), travel)
            let p = page > 0 ? Double(scrolled / page) : 0       // 0…beats; a first layout pass can report a zero height
            let i = min(Int(p), beats - 1)
            let t = p - Double(i)
            let fadeIn = i == 0 ? 1 : seg(t, 0, 0.12)
            let fadeOut = i == beats - 1 ? 1 : 1 - seg(t, 0.88, 1)
            content(i, t)
                .id(i)
                .frame(width: g.size.width, height: page)
                .opacity(fadeIn * fadeOut)
                .offset(y: scrolled)
        }
        .frame(height: page * CGFloat(beats + 1))
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
            Text(kicker)
                .font(Theme.body(12.5, .semibold))
                .textCase(.uppercase)
                .tracking(1.6)
                .foregroundStyle(Theme.accent)
            Text(title)
                .font(Theme.serif(34))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            visual
                .frame(maxWidth: .infinity, minHeight: 280, maxHeight: 340)
            Text(caption)
                .font(Theme.body(15))
                .foregroundStyle(Theme.muted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
        .frame(maxHeight: .infinity)
    }
}

/// Math with its primes in the accent colour.
private func mathLine(_ parts: [String], size: CGFloat = 20) -> Text {
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

// MARK: - How to play

struct HowToPlay: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("How to play")
                .font(Theme.serif(34))
                .foregroundStyle(Theme.accent)
            Text("A prime has exactly two divisors: 1 and itself. 7 is prime. 8 isn't: it's 2 × 4.")
                .font(Theme.body(16))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Text("To test a number, divide it by each prime up to its square root. If none go in evenly, it's prime.")
                .font(Theme.body(17, .semibold))
                .foregroundStyle(Theme.text)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: Theme.r(12)))
                .overlay(RoundedRectangle(cornerRadius: Theme.r(12)).stroke(Theme.accent, lineWidth: 1))
                .fixedSize(horizontal: false, vertical: true)
            WorkedExample()
            Text("Why stop at the square root? If a number splits as a × b, one of the two is at most its square root. So if nothing that small divides it, nothing does.")
                .font(Theme.body(14))
                .foregroundStyle(Theme.muted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Rule().padding(.vertical, 4)
            VStack(alignment: .leading, spacing: 12) {
                HowRow(symbol: "number", text: "You get a number from 2 to 999. Work it out in your head, then tap Prime or Composite.")
                HowRow(symbol: "text.magnifyingglass", text: "Every answer shows the method, so a miss still teaches you something.")
                HowRow(symbol: "sparkle", text: "Stuck? The ✦ in the corner fans out Roots, Prime tricks and Checklist. Tricks are shortcuts, like adding up the digits to test 3.")
                HowRow(symbol: "dial.medium", text: "Easy, Medium and Hard set how sneaky the numbers get.")
                HowRow(symbol: "lightbulb", text: "Call a prime right and it lights up in your collection. There are 168 under 1,000.")
            }
            HStack(spacing: 8) {
                Image(systemName: "chevron.down")
                Text("Keep scrolling: why primes")
            }
            .font(Theme.body(13, .semibold))
            .textCase(Theme.labelCase)
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
        }
    }
}

private struct Rule: View {
    var body: some View { Theme.border.frame(height: 1) }
}

private struct HowRow: View {
    let symbol: String
    let text: String
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.body(15))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// 91, tested live: the four candidate primes tick off one by one.
struct WorkedExample: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = 0

    private let checks: [(p: Int, why: String, hit: Bool)] = [
        (2, "91 is odd", false),
        (3, "9 + 1 = 10, not a multiple of 3", false),
        (5, "doesn't end in 0 or 5", false),
        (7, "91 = 7 × 13", true),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Try").font(Theme.body(16)).foregroundStyle(Theme.muted)
                Text("91").font(Theme.number(44)).foregroundStyle(Theme.text)
            }
            Text("9² = 81 and 10² = 100, so √91 is between 9 and 10. Check the primes up to 9:")
                .font(Theme.body(15))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Array(checks.enumerated()), id: \.offset) { k, c in
                HStack(spacing: 12) {
                    Text(String(c.p))
                        .font(Theme.mono(17, .bold))
                        .foregroundStyle(c.hit ? Theme.ink : Theme.text)
                        .frame(width: 40, height: 40)
                        .background(c.hit ? Theme.accent : Theme.panel, in: RoundedRectangle(cornerRadius: Theme.r(8)))
                        .overlay(RoundedRectangle(cornerRadius: Theme.r(8)).stroke(c.hit ? Theme.accent : Theme.border, lineWidth: 1))
                    Image(systemName: c.hit ? "checkmark" : "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(c.hit ? Theme.accent : Theme.muted)
                    Text(c.why)
                        .font(Theme.mono(14))
                        .foregroundStyle(c.hit ? Theme.accent : Theme.muted)
                }
                .opacity(k < shown ? 1 : 0.15)
                .offset(x: k < shown ? 0 : 8)
            }
            Text("Composite. It looks prime, which is exactly what makes it a good one.")
                .font(Theme.body(15, .semibold))
                .foregroundStyle(Theme.text)
                .opacity(shown >= checks.count ? 1 : 0)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: Theme.r(12)))
        .overlay(RoundedRectangle(cornerRadius: Theme.r(12)).stroke(Theme.border, lineWidth: 1))
        .task {
            if reduceMotion { shown = checks.count; return }
            for k in 1...checks.count {
                try? await Task.sleep(for: .milliseconds(k == 1 ? 700 : 650))
                withAnimation(.easeOut(duration: 0.35)) { shown = k }
            }
        }
    }
}

// MARK: - Why primes

struct WhyIntro: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why primes")
                .font(Theme.body(12.5, .semibold))
                .textCase(.uppercase)
                .tracking(1.6)
                .foregroundStyle(Theme.accent)
            Text("The atoms of math.")
                .font(Theme.serif(40))
                .foregroundStyle(Theme.text)
            Text("I built this because prime numbers are cool. Every other number is built out of them. A kid can check one by hand, and they still hide questions nobody has answered. Here's a short tour.")
                .font(Theme.body(17))
                .foregroundStyle(Theme.muted)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 360 splits until only primes are left.
struct AtomsBeat: View {
    let t: Double
    private let lines: [[String]] = [
        ["360"],
        ["=", "2", "×", "180"],
        ["=", "2", "×", "2", "×", "90"],
        ["=", "2", "×", "2", "×", "2", "×", "45"],
        ["=", "2", "×", "2", "×", "2", "×", "3", "×", "15"],
        ["=", "2", "×", "2", "×", "2", "×", "3", "×", "3", "×", "5"],
    ]

    var body: some View {
        Beat(kicker: "One", title: "Every number is made of primes.",
             caption: "Keep splitting any number and you always land on primes, the atoms nothing else is made of. And each number has exactly one recipe. Mathematicians call it the Fundamental Theorem of Arithmetic.") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(lines.enumerated()), id: \.offset) { k, parts in
                    let a = seg(t, 0.08 + Double(k) * 0.1, 0.16 + Double(k) * 0.1)
                    mathLine(parts, size: k == 0 ? 34 : 19)
                        .opacity(k == 0 ? 1 : a)
                        .offset(y: (1 - a) * 12)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

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
                    Tag(text: "prime, and new")
                }
                .opacity(seg(t, 0.36, 0.44))
                Reveal(t: t, from: 0.5, to: 0.72, parts: ["2", "×", "3", "×", "5", "×", "7", "×", "11", "×", "13", "+", "1"])
                    .padding(.top, 10)
                mathLine(["=", "30031"], size: 26).opacity(seg(t, 0.73, 0.79))
                HStack(spacing: 10) {
                    mathLine(["=", "59", "×", "509"], size: 26)
                    Tag(text: "not on the list")
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

private struct Tag: View {
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
        Beat(kicker: "Three", title: "They have a pattern nobody has cracked.",
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
        Beat(kicker: "Four", title: "Nature counts in primes, too.",
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
        Beat(kicker: "Five", title: "And they keep your secrets.",
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

// MARK: - Coda

struct Coda: View {
    let play: () -> Void
    var body: some View {
        VStack(spacing: 14) {
            Text("168")
                .font(Theme.number(96))
                .foregroundStyle(Theme.accent)
                .shadow(color: Theme.glow, radius: 12)
            Text("primes under 1,000.")
                .font(Theme.serif(26))
                .foregroundStyle(Theme.text)
            Text("Every one of them can be spotted by hand. Each lights up the first time you call it.")
                .font(Theme.body(15))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
                .fixedSize(horizontal: false, vertical: true)
            Button("Play", action: play)
                .buttonStyle(FilledButtonStyle())
                .padding(.top, 18)
        }
        .frame(maxWidth: .infinity)
    }
}
