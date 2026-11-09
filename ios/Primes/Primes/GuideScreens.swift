//  GuideScreens.swift — the guide's screens, one per page of the pager.
//
//  Each is laid out for a 390 × 844 phone. GuidePage scales a screen down as
//  a whole when the phone is shorter than the screen's design height, so a
//  small phone shows the same layout, slightly smaller, instead of clipping.

import SwiftUI
import UIKit

// MARK: - Page frame and parts

struct GuidePage<Content: View>: View {
    var design: CGFloat = 720
    var dots: Int? = nil              // How to play progress, 0…2
    var spacing: CGFloat = 14
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { g in
            let s = min(1, g.size.height / design)
            VStack(alignment: .leading, spacing: spacing) {
                HStack {
                    if let dots { ProgressDots(current: dots) }
                    Spacer()
                }
                .frame(height: 48)
                content
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 24)
            .frame(width: g.size.width / s, height: g.size.height / s, alignment: .top)
            .scaleEffect(s)
            .frame(width: g.size.width, height: g.size.height)
        }
    }
}

private struct ProgressDots: View {
    let current: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { k in
                Capsule()
                    .fill(k <= current ? Theme.accent : Theme.border)
                    .frame(width: k == current ? 22 : 10, height: 4)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("How to play, \(current + 1) of 3")
    }
}

struct Kicker: View {
    let text: String
    var color: Color = Theme.accent
    var body: some View {
        Text(text)
            .font(Theme.body(12.5, .semibold))
            .textCase(.uppercase)
            .tracking(1.6)
            .foregroundStyle(color)
    }
}

struct Headline: View {
    let text: String
    var size: CGFloat = 34
    var body: some View {
        Text(text)
            .font(Theme.serif(size))
            .foregroundStyle(Theme.text)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct Lede: View {
    let text: String
    var size: CGFloat = 15
    var body: some View {
        Text(text)
            .font(Theme.body(size))
            .foregroundStyle(Theme.muted)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A row of choices: the picked one filled with the accent.
private struct PillStyle: ButtonStyle {
    let selected: Bool
    var height: CGFloat = 40
    var size: CGFloat = 16
    var mono = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(mono ? Theme.mono(size, .bold) : Theme.body(size, .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(selected ? Theme.ink : Theme.text)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(selected ? Theme.accent : Theme.panel, in: RoundedRectangle(cornerRadius: Theme.r(10)))
            .overlay(RoundedRectangle(cornerRadius: Theme.r(10)).stroke(selected ? Theme.accent : Theme.border, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

private extension View {
    func guideCard(_ radius: CGFloat = 16, stroke: Color? = nil) -> some View {
        background(Theme.panel, in: RoundedRectangle(cornerRadius: Theme.r(radius)))
            .overlay(RoundedRectangle(cornerRadius: Theme.r(radius)).stroke(stroke ?? Theme.border, lineWidth: 1))
    }
}

private func sup(_ n: Int) -> String {
    n == 1 ? "" : String(String(n).map { Array("⁰¹²³⁴⁵⁶⁷⁸⁹")[Int(String($0))!] })
}

/// Prime factors with their counts, smallest first.
private func factor(_ n: Int) -> [(p: Int, k: Int)] {
    var out: [(p: Int, k: Int)] = [], m = n, p = 2
    while m > 1 {
        var k = 0
        while m % p == 0 { m /= p; k += 1 }
        if k > 0 { out.append((p, k)) }
        p += 1
    }
    return out
}

// MARK: - How to play · 1 · What the buttons do

struct ButtonsScreen: View {
    var body: some View {
        GuidePage(design: 800, dots: 0) {
            Kicker(text: "How to play · 1")
            Headline(text: "Call it. Then see why.")
            MockGame().frame(height: 400)
            VStack(alignment: .leading, spacing: 9) {
                legend(1, "Easy, Medium, Hard", " set how sneaky the numbers get.")
                legend(2, "Your number", ", 2 to 999. Work it out in your head.")
                legend(3, "Call it.", " Right or wrong, you see the method.")
                legend(4, "Stuck? Tap the ✦", " in the corner for Roots, Prime tricks and a Checklist. Try it.")
            }
            .padding(.top, 4)
            Spacer(minLength: 0)
            SwipeHint()
        }
    }

    private func legend(_ n: Int, _ bold: String, _ rest: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(n)").font(Theme.mono(15, .bold)).foregroundStyle(Theme.accent).frame(width: 14)
            (Text(bold).bold() + Text(rest))
                .font(Theme.body(14.5))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SwipeHint: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "chevron.up")
            Text("Swipe up for the next one")
        }
        .font(Theme.body(13, .semibold))
        .textCase(Theme.labelCase)
        .foregroundStyle(Theme.muted)
        .frame(maxWidth: .infinity)
    }
}

/// The question screen in miniature, with a working ✦ that fans out the same
/// three tools as the real one.
private struct MockGame: View {
    @State private var open = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let tools: [(title: String, symbol: String, angle: Double)] = [
        ("Roots", "x.squareroot", 90), ("Prime tricks", "wand.and.stars", 135), ("Checklist", "checklist", 180),
    ]

    var body: some View {
        GeometryReader { g in
            let hub = CGPoint(x: g.size.width - 14 - 25, y: g.size.height - 14 - 25)
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.muted).frame(width: 28)
                        HStack(spacing: 0) {
                            segment("Easy", on: true)
                            Theme.border.frame(width: 1)
                            segment("Medium", on: false)
                            Theme.border.frame(width: 1)
                            segment("Hard", on: false)
                        }
                        .frame(height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.r(10)))
                        .overlay(RoundedRectangle(cornerRadius: Theme.r(10)).stroke(Theme.border, lineWidth: 1))
                        .overlay(alignment: .topLeading) { Badge(n: 1).offset(x: 6, y: -12) }
                        Color.clear.frame(width: 28, height: 1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 14)
                    Text("Streak 3").font(Theme.body(11)).foregroundStyle(Theme.muted).padding(.top, 8)
                    Text("391")
                        .font(Theme.number(84))
                        .foregroundStyle(Theme.text)
                        .shadow(color: Theme.glow, radius: 10)
                        .padding(.top, 12)
                        .overlay(alignment: .leading) { Badge(n: 2).offset(x: -34) }
                    Text("Is it prime?").font(Theme.body(13)).foregroundStyle(Theme.muted).padding(.top, 8)
                    HStack(spacing: 10) {
                        answer("Prime")
                        answer("Composite")
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 22)
                    .overlay(alignment: .topLeading) { Badge(n: 3).offset(x: 4, y: 12) }
                    Spacer(minLength: 0)
                }
                .frame(width: g.size.width, height: g.size.height, alignment: .top)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("The question screen: Easy, Medium, Hard at the top, the number 391, Prime and Composite buttons, and the ✦ in the bottom-right corner.")

                if open {
                    Theme.bg.opacity(0.72)
                        .contentShape(Rectangle())
                        .onTapGesture { toggle() }
                        .transition(.opacity)
                        .accessibilityHidden(true)
                }
                ForEach(tools, id: \.title) { t in
                    let ux = cos(t.angle * .pi / 180), uy = -sin(t.angle * .pi / 180)
                    let at = open ? CGPoint(x: hub.x + ux * 92, y: hub.y + uy * 92) : hub
                    let labelW = CGFloat(t.title.count) * 7.5 + 18
                    let out = 21 + 6 + abs(ux) * labelW / 2 + abs(uy) * 13
                    Image(systemName: t.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.text)
                        .frame(width: 42, height: 42)
                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: Theme.r(21)))
                        .overlay(RoundedRectangle(cornerRadius: Theme.r(21)).stroke(Theme.border, lineWidth: 1))
                        .scaleEffect(open || reduceMotion ? 1 : 0.4)
                        .position(at)
                        .opacity(open ? 1 : 0)
                    Text(t.title)
                        .font(Theme.body(12, .semibold))
                        .textCase(Theme.labelCase)
                        .foregroundStyle(Theme.text)
                        .fixedSize()
                        .padding(.horizontal, 9)
                        .frame(height: 26)
                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: Theme.r(13)))
                        .overlay(RoundedRectangle(cornerRadius: Theme.r(13)).stroke(Theme.border, lineWidth: 1))
                        .position(x: at.x + ux * out, y: at.y + uy * out)
                        .opacity(open ? 1 : 0)
                }
                .allowsHitTesting(false)
                .accessibilityHidden(!open)
                Button { toggle() } label: {
                    Group {
                        if open { Image(systemName: "xmark").font(.system(size: 17, weight: .bold)) }
                        else { Text("✦").font(.system(size: 22, weight: .semibold)) }
                    }
                    .foregroundStyle(open ? Theme.ink : Theme.accent)
                    .frame(width: 50, height: 50)
                    .background(open ? Theme.accent : Theme.panel, in: RoundedRectangle(cornerRadius: Theme.r(25)))
                    .overlay(RoundedRectangle(cornerRadius: Theme.r(25)).stroke(Theme.accent, lineWidth: 1.5))
                    .shadow(color: Theme.glow, radius: 8)
                }
                .accessibilityLabel(open ? "Fold the tools away" : "Try the tools button")
                .position(hub)
                Badge(n: 4).position(x: hub.x + 22, y: hub.y - 34)
            }
        }
        .background(Theme.bg)
        .clipShape(RoundedRectangle(cornerRadius: Theme.r(22)))
        .overlay(RoundedRectangle(cornerRadius: Theme.r(22)).stroke(Theme.border, lineWidth: 1))
        .padding(6)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: Theme.r(26)))
    }

    private func segment(_ t: String, on: Bool) -> some View {
        Text(t)
            .font(Theme.body(12.5, .semibold))
            .textCase(Theme.labelCase)
            .foregroundStyle(on ? Theme.accent : Theme.muted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(on ? Theme.accent.opacity(0.14) : .clear)
    }

    private func answer(_ t: String) -> some View {
        Text(t)
            .font(Theme.body(17, .bold))
            .textCase(Theme.labelCase)
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: Theme.r(14)))
            .overlay(RoundedRectangle(cornerRadius: Theme.r(14)).stroke(Theme.accent, lineWidth: 1.5))
    }

    private func toggle() {
        Haptics.tick()
        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.32, dampingFraction: 0.78)) { open.toggle() }
    }
}

private struct Badge: View {
    let n: Int
    var body: some View {
        Text("\(n)")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Theme.bg)
            .frame(width: 20, height: 20)
            .background(Theme.text, in: Circle())
            .accessibilityHidden(true)
    }
}

// MARK: - How to play · 2 · The square-root test

struct RootsScreen: View {
    @State private var i = 0
    @State private var shown = 0
    private let nums = [91, 97, 143, 211]

    var body: some View {
        let n = nums[i]
        let r = Int(Double(n).squareRoot())
        let primes = [2, 3, 5, 7, 11, 13].filter { $0 <= r }
        let hitAt = primes.firstIndex { n % $0 == 0 }
        let last = hitAt ?? primes.count - 1
        let done = shown > last
        GuidePage(dots: 1) {
            Kicker(text: "How to play · 2")
            Headline(text: "Only check up to the square root.")
            Lede(text: "If a number splits as a × b, the smaller of the two is never bigger than its square root. So check the primes up to the square root. If none go in, nothing will.")
            HStack(spacing: 8) {
                ForEach(nums.indices, id: \.self) { k in
                    Button(String(nums[k])) { i = k; shown = 0; Haptics.tick() }
                        .buttonStyle(PillStyle(selected: k == i))
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(n)").font(Theme.number(44)).foregroundStyle(Theme.text)
                    Text("\(r)² = \(r * r) ≤ \(n) < \((r + 1) * (r + 1)) = \(r + 1)²")
                        .font(Theme.mono(13))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                ForEach(primes.indices, id: \.self) { k in
                    let p = primes[k], on = k < shown, hit = n % p == 0
                    HStack(spacing: 12) {
                        Text("\(p)")
                            .font(Theme.mono(16, .bold))
                            .foregroundStyle(on && hit ? Theme.ink : Theme.text)
                            .frame(width: 40, height: 36)
                            .background(on && hit ? Theme.accent : Theme.bg, in: RoundedRectangle(cornerRadius: Theme.r(8)))
                            .overlay(RoundedRectangle(cornerRadius: Theme.r(8)).stroke(on && hit ? Theme.accent : Theme.border, lineWidth: 1))
                        Text(!on ? "÷ \(p) ?" : hit ? "\(n) = \(p) × \(n / p)" : "leaves \(n % p), no")
                            .font(Theme.mono(14))
                            .foregroundStyle(on && hit ? Theme.accent : Theme.muted)
                    }
                    .opacity(on ? 1 : (k <= last ? 0.25 : 0.1))
                }
                Spacer(minLength: 0)
                Text(!done ? "Check the primes up to \(r)."
                     : hitAt.map { "Composite. \(primes[$0]) goes in evenly." } ?? "Prime. Nothing up to \(r) goes in, so nothing does.")
                    .font(Theme.body(16, .semibold))
                    .foregroundStyle(done ? Theme.accent : Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .guideCard()
            .animation(.easeOut(duration: 0.25), value: shown)
            Button(done ? "Try another" : "Check \(primes[shown])") {
                Haptics.tick()
                if done { i = (i + 1) % nums.count; shown = 0 } else { shown += 1 }
            }
            .buttonStyle(FilledButtonStyle())
        }
    }
}

// MARK: - How to play · 3 · Prime tricks

struct TricksScreen: View {
    @State private var p = 3

    private struct Shortcut {
        let name, rule, why: String
        let steps: [(String, Bool)]       // (line, lands on the answer)
    }

    private let tricks: [Int: Shortcut] = [
        3: Shortcut(name: "The 3 trick · add the digits", rule: "If the digits add up to a multiple of 3, the number is one too.",
                    why: "Works for 9 as well. It's the quickest check after 2 and 5, so do it first.",
                    steps: [("471", false), ("4 + 7 + 1 = 12", false), ("12 = 4 × 3 ✓", true), ("471 = 3 × 157", true)]),
        11: Shortcut(name: "The 11 trick · alternate", rule: "Go across the digits: plus, minus, plus. If you land on 0 or a multiple of 11, it divides.",
                     why: "Three-digit numbers that look prime, like 143 and 187, often fall to this one.",
                     steps: [("506", false), ("5 − 0 + 6 = 11 ✓", true), ("506 = 11 × 46", true)]),
        7: Shortcut(name: "The 7 trick · chop, double, subtract", rule: "Chop off the last digit. Double it, and take it from what's left.",
                    why: "13, 17, 19, 23, 29 and 31 use the same chop. Only the multiplier and the plus or minus change.",
                    steps: [("161 → 16 | 1", false), ("16 − 2 × 1 = 14", false), ("14 = 2 × 7 ✓", true), ("161 = 7 × 23", true)]),
        13: Shortcut(name: "The 13 trick · chop, ×4, add", rule: "Chop off the last digit. Times it by 4, and add it to what's left.",
                     why: "Same chop as 7, different recipe. If the result is still big, chop again.",
                     steps: [("182 → 18 | 2", false), ("18 + 4 × 2 = 26", false), ("26 = 2 × 13 ✓", true), ("182 = 13 × 14", true)]),
    ]

    var body: some View {
        let cur = tricks[p]!
        GuidePage(dots: 2) {
            Kicker(text: "How to play · 3")
            Headline(text: "Shortcuts, so you don't have to divide.")
            (Text("Each prime has a trick that tests it without long division. Two you already know: ")
             + Text("2").bold().foregroundColor(Theme.text) + Text(" if it ends in an even digit, ")
             + Text("5").bold().foregroundColor(Theme.text) + Text(" if it ends in 0 or 5."))
                .font(Theme.body(15))
                .foregroundStyle(Theme.muted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                ForEach([3, 11, 7, 13], id: \.self) { q in
                    Button(String(q)) { p = q; Haptics.tick() }
                        .buttonStyle(PillStyle(selected: q == p, height: 44, size: 18))
                        .accessibilityLabel("Trick for \(q)")
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                Kicker(text: cur.name)
                Text(cur.rule)
                    .font(Theme.body(17, .semibold))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(cur.steps.indices, id: \.self) { k in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(k + 1)").font(Theme.mono(12)).foregroundStyle(Theme.muted).frame(width: 14)
                            Text(cur.steps[k].0).font(Theme.mono(17)).foregroundStyle(cur.steps[k].1 ? Theme.accent : Theme.text)
                        }
                    }
                }
                .padding(.top, 6)
                Spacer(minLength: 0)
                Text(cur.why)
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .guideCard()
            HStack(spacing: 12) {
                Text("✦")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 40, height: 40)
                    .overlay(RoundedRectangle(cornerRadius: Theme.r(20)).stroke(Theme.accent, lineWidth: 1.5))
                (Text("All eleven tricks, 2 to 31, are under ") + Text("✦ → Prime tricks").bold() + Text(" while you play."))
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: Theme.r(14)).stroke(Theme.border, lineWidth: 1))
        }
    }
}

// MARK: - Why primes · chapters

struct ChaptersScreen: View {
    let go: (GuideScreen) -> Void

    private let chapters: [(title: String, hint: String, to: GuideScreen)] = [
        ("Every number is made of them", "360", .elements),
        ("They never run out", "Euclid", .euclid),
        ("Sift them out by hand", "sieve", .sieve),
        ("A pattern nobody has cracked", "spiral", .spiral),
        ("Nature counts in primes", "13, 17", .cicadas),
        ("Problems nobody has solved", "$1M", .unsolved),
        ("They keep your secrets", "RSA", .secrets),
        ("The biggest one we know", "41M digits", .biggest),
    ]

    var body: some View {
        GuidePage(design: 840) {
            Text("2 3 5 7 11 13 17 19 23 29 31")
                .font(Theme.mono(22, .bold))
                .tracking(1)
                .foregroundStyle(Theme.accent)
                .shadow(color: Theme.glow, radius: 10)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityHidden(true)
            Kicker(text: "Why primes").padding(.top, 8)
            Headline(text: "The atoms\nof math.", size: 44)
            Text("Prime numbers are the fundamental building blocks of all math. The next few screens are some of my favorite facts about prime numbers and why they are fascinating.")
                .font(Theme.serif(18).weight(.regular))
                .italic()
                .foregroundStyle(Theme.muted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 0) {
                Theme.border.frame(height: 1)
                ForEach(chapters.indices, id: \.self) { k in
                    let c = chapters[k]
                    Button { go(c.to) } label: {
                        HStack(spacing: 14) {
                            Text(String(format: "%02d", k + 1)).font(Theme.mono(13)).foregroundStyle(Theme.accent).frame(width: 22, alignment: .leading)
                            Text(c.title).font(Theme.body(16, .medium)).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.8)
                            Spacer(minLength: 8)
                            Text(c.hint).font(Theme.mono(13)).foregroundStyle(Theme.muted)
                        }
                        .frame(height: 46)
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Chapter \(k + 1): \(c.title)")
                    Theme.border.frame(height: 1)
                }
            }
            .padding(.top, 6)
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Image(systemName: "chevron.up")
                Text("Swipe up, or tap a chapter")
            }
            .font(Theme.body(13, .semibold))
            .textCase(Theme.labelCase)
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - One · the atoms of math

struct ElementsScreen: View {
    private let first25 = Array(PrimeEngine.all.prefix(25))
    private let molecules = [12, 100, 360, 1001]

    var body: some View {
        GuidePage(design: 840) {
            Kicker(text: "One · the atoms of math")
            Headline(text: "Everything is made of these.", size: 32)
            Lede(text: "Matter is atoms in different combinations. Numbers are primes in different combinations. Here are the first 25 elements.")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                ForEach(first25.indices, id: \.self) { i in
                    let p = first25[i], hot = p <= 5
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(i + 1)").font(Theme.mono(9.5)).foregroundStyle(hot ? Theme.ink.opacity(0.65) : Theme.muted)
                        Spacer(minLength: 0)
                        Text("\(p)").font(Theme.mono(20, .bold)).foregroundStyle(hot ? Theme.ink : Theme.text)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 6)
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, 4)
                    .frame(height: 52)
                    .background(hot ? Theme.accent : Theme.panel, in: RoundedRectangle(cornerRadius: Theme.r(8)))
                    .overlay(RoundedRectangle(cornerRadius: Theme.r(8)).stroke(hot ? Theme.accent : Theme.border, lineWidth: 1))
                    .accessibilityElement()
                    .accessibilityLabel("Prime number \(i + 1): \(p)")
                }
            }
            Kicker(text: "Some molecules", color: Theme.muted).padding(.top, 4)
            VStack(spacing: 8) {
                ForEach(molecules, id: \.self) { n in
                    VStack(spacing: 6) {
                        HStack {
                            Text(String(n)).font(Theme.mono(16, .bold)).foregroundStyle(Theme.text)
                            Spacer()
                            Text(factor(n).map { "\($0.p)\(sup($0.k))" }.joined(separator: " · ")).font(Theme.mono(16)).foregroundStyle(Theme.accent)
                        }
                        Theme.border.frame(height: 1)
                    }
                }
            }
            Spacer(minLength: 0)
            (Text("Why isn't 1 an atom? ").bold().foregroundColor(Theme.text)
             + Text("Because it would ruin the recipes: 6 would be 2·3, and 1·2·3, and 1·1·2·3, forever. Leaving 1 out gives every number exactly one recipe."))
                .font(Theme.body(14))
                .foregroundStyle(Theme.muted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct MoleculesScreen: View {
    @State private var atoms = [2, 2, 3]
    @State private var target = 12

    static func color(_ p: Int) -> Color {
        switch p {
        case 2: return Color(UIColor(hex: 0xF2A24A))
        case 3: return .dynamic(dark: 0xEFE3CC, light: 0xDCC9A2)
        case 5: return Color(UIColor(hex: 0xC9744A))
        case 7: return Color(UIColor(hex: 0x8DB8A4))
        case 11: return Color(UIColor(hex: 0xB39DDB))
        default: return Color(UIColor(hex: 0xE9C46A))
        }
    }
    static let atomInk = Color(UIColor(hex: 0x201709))      // the atoms keep their own colours in every look
    private static let size: [Int: CGFloat] = [2: 32, 3: 36, 5: 40, 7: 44, 11: 48, 13: 52]

    var body: some View {
        let sorted = atoms.sorted()
        let product = atoms.reduce(1, *)
        let hit = product == target, fits = target % product == 0
        let note = atoms.isEmpty ? "Every number above 1 has a recipe. \(target)’s is waiting."
            : hit ? "That’s \(target). Same atoms in any order, always the same number, and no other recipe makes it."
            : fits ? "Keep going. \(target) needs more."
            : "Not in \(target)’s recipe. Undo and try another atom."
        GuidePage {
            Kicker(text: "One · the atoms of math")
            Headline(text: "Build a number from atoms.", size: 32)
            HStack(spacing: 8) {
                ForEach([12, 30, 360, 1001], id: \.self) { t in
                    Button("Make " + String(t)) { target = t; atoms = []; Haptics.tick() }
                        .buttonStyle(PillStyle(selected: t == target, height: 38, size: 13, mono: false))
                }
            }
            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    if atoms.isEmpty {
                        Text("Tap an atom below to start.").font(Theme.body(15)).foregroundStyle(Theme.muted)
                    }
                    ForEach(Array(stride(from: 0, to: sorted.count, by: 6)), id: \.self) { start in
                        HStack(spacing: 4) {
                            ForEach(start..<min(start + 6, sorted.count), id: \.self) { i in
                                if i > start { Capsule().fill(Theme.border).frame(width: 10, height: 3) }
                                Text("\(sorted[i])")
                                    .font(Theme.mono(14, .bold))
                                    .foregroundStyle(Self.atomInk)
                                    .frame(width: Self.size[sorted[i]], height: Self.size[sorted[i]])
                                    .background(Self.color(sorted[i]), in: Circle())
                                    .overlay(Circle().strokeBorder(.black.opacity(0.12), lineWidth: 2))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(atoms.isEmpty ? "No atoms yet" : "Atoms: " + sorted.map(String.init).joined(separator: ", "))
                Theme.border.frame(height: 1)
                HStack(alignment: .firstTextBaseline) {
                    Text(atoms.isEmpty ? "·" : String(product)).font(Theme.mono(40, .bold)).foregroundStyle(hit ? Theme.accent : Theme.text)
                    Spacer()
                    Text(atoms.isEmpty
                         ? factor(target).map { _ in "?" }.joined(separator: " · ")
                         : factor(product).map { "\($0.p)\(sup($0.k))" }.joined(separator: " · "))
                        .font(Theme.mono(17))
                        .foregroundStyle(Theme.accent)
                }
                Text(note)
                    .font(Theme.body(14))
                    .foregroundStyle(hit ? Theme.accent : fits ? Theme.muted : Theme.danger)
                    .frame(maxWidth: .infinity, minHeight: 40, alignment: .topLeading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .frame(maxHeight: .infinity)
            .guideCard(18)
            HStack(spacing: 8) {
                ForEach([2, 3, 5, 7, 11, 13], id: \.self) { p in
                    Button {
                        if atoms.count < 12 { atoms.append(p) }
                        Haptics.tick()
                    } label: {
                        Text("\(p)")
                            .font(Theme.mono(20, .bold))
                            .foregroundStyle(Self.atomInk)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(Self.color(p), in: RoundedRectangle(cornerRadius: Theme.r(12)))
                    }
                    .accessibilityLabel("Add a \(p)")
                }
            }
            HStack(spacing: 10) {
                Button("Undo") { if !atoms.isEmpty { atoms.removeLast() } }.buttonStyle(OutlineButtonStyle(height: 48))
                Button("Clear") { atoms = [] }.buttonStyle(OutlineButtonStyle(height: 48))
            }
        }
    }
}

// MARK: - Three · the sieve

struct SieveScreen: View {
    @State private var k = 0
    private let sieve = [2, 3, 5, 7]

    var body: some View {
        let used = Array(sieve.prefix(k)), done = k >= sieve.count
        let cells = (1...100).map { n -> (n: Int, lit: Bool, crossed: Bool, fresh: Bool) in
            let crossed = n == 1 || used.contains { n != $0 && n % $0 == 0 }
            let fresh = k > 0 && n != sieve[k - 1] && n % sieve[k - 1] == 0 && !used.dropLast().contains { n % $0 == 0 }
            return (n, done ? PrimeEngine.isPrime(n) : used.contains(n), crossed, fresh)
        }
        let left = cells.filter { $0.n > 1 && !$0.crossed }.count
        GuidePage(design: 800) {
            Kicker(text: "Three · about 240 BC")
            Headline(text: "Sift them out by hand.")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 10), spacing: 4) {
                ForEach(cells, id: \.n) { c in
                    Text("\(c.n)")
                        .font(Theme.mono(12.5, c.lit ? .bold : .medium))
                        .strikethrough(c.crossed && c.n != 1)
                        .foregroundStyle(c.lit ? Theme.ink : c.crossed ? (c.fresh ? Theme.danger : Theme.muted.opacity(0.45)) : Theme.text)
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .background(c.lit ? Theme.accent : c.crossed ? .clear : Theme.panel, in: RoundedRectangle(cornerRadius: Theme.r(6)))
                }
            }
            .padding(.top, 4)
            .animation(.easeOut(duration: 0.3), value: k)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(done ? "The 25 primes under 100 are lit." : "The numbers 1 to 100, \(left) not yet crossed out.")
            HStack(alignment: .firstTextBaseline) {
                Text(done ? "The 25 primes under 100" : k == 0 ? "Start with 2 to 100" : "Multiples of " + used.map(String.init).joined(separator: ", ") + " gone")
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.muted)
                Spacer()
                Text("\(left) left").font(Theme.mono(22, .bold)).foregroundStyle(Theme.accent)
            }
            Lede(text: "Eratosthenes, who also measured the size of the Earth, crossed out every multiple of each prime in turn. Whatever survives is prime. Past 7 there's nothing left to do below 100, because 11 × 11 is already 121.")
            Spacer(minLength: 0)
            Button(done ? "Start again" : "Cross out multiples of \(sieve[k])") {
                Haptics.tick()
                k = done ? 0 : k + 1
            }
            .buttonStyle(FilledButtonStyle())
        }
    }
}

// MARK: - Six · still open

struct UnsolvedScreen: View {
    var body: some View {
        GuidePage(design: 740) {
            Kicker(text: "Six · still open")
            Headline(text: "Questions a kid can ask, and nobody can answer.")
            problem("Twin primes", since: "asked since the 1800s",
                    math: Text("3·5   11·13   17·19   41·43   71·73").font(Theme.mono(15)).foregroundColor(Theme.accent),
                    text: "Primes two apart. Do they go on forever? Probably. Nobody has proved it.")
            problem("Goldbach", since: "since 1742",
                    math: mathLine(["28", "=", "5", "+", "23", "  100", "=", "3", "+", "97"], size: 15),
                    text: "Every even number above 2 is two primes added together. Computers have checked it past 4 quintillion. Still not proved.")
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("The Riemann hypothesis").font(Theme.body(16, .semibold)).foregroundStyle(Theme.text)
                    Spacer()
                    Tag(text: "$1,000,000")
                }
                Text("A precise guess about how the primes thin out as numbers grow. Prove it and the Clay Mathematics Institute pays you a million dollars. It's been open since 1859.")
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .guideCard(stroke: Theme.accent)
            Spacer(minLength: 0)
            Text("Easy enough to check with your fingers. Hard enough to stump everyone, so far.")
                .font(Theme.serif(18).weight(.regular))
                .italic()
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func problem(_ title: String, since: String, math: Text, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(Theme.body(16, .semibold)).foregroundStyle(Theme.text)
                Spacer()
                Text(since).font(Theme.body(12)).foregroundStyle(Theme.muted)
            }
            math.lineLimit(1).minimumScaleFactor(0.7)
            Text(text)
                .font(Theme.body(14))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .guideCard()
    }
}

// MARK: - Eight · the record

struct BiggestScreen: View {
    /// A stand-in wall of digits behind the screen, for texture only. Not the prime.
    private static let wall: String = {
        var s = "", x: UInt32 = 2_654_435_761
        for _ in 0..<2600 { x = x &* 1_103_515_245 &+ 12_345; s.append(Character(String((x >> 16) % 10))) }
        return s
    }()

    var body: some View {
        GuidePage(design: 740) {
            Kicker(text: "Eight · the record")
            Headline(text: "The biggest prime anyone has found.")
            HStack(alignment: .top, spacing: 0) {
                Text(verbatim: "2").font(Theme.number(64)).foregroundStyle(Theme.accent)
                Text("136,279,841").font(Theme.mono(20, .bold)).foregroundStyle(Theme.accent).padding(.top, 2)
                Text(verbatim: "−1").font(Theme.number(64)).padding(.leading, 10).foregroundStyle(Theme.text)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .shadow(color: Theme.glow, radius: 12)
            .frame(maxWidth: .infinity)
            .padding(.top, 30)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("2 to the power 136,279,841, minus 1")
            HStack(spacing: 10) {
                stat("41,024,320", "digits long")
                stat("8,200", "pages, at 5,000 digits a page")
            }
            .padding(.top, 22)
            Lede(text: "Found in October 2024 by Luke Durant, a volunteer with GIMPS, on cloud graphics chips. It's a Mersenne prime: double 1 over and over, 136,279,841 times, then take away 1.")
            Spacer(minLength: 0)
            Text("And Euclid says there's a bigger one, waiting.")
                .font(Theme.serif(18).weight(.regular))
                .italic()
                .foregroundStyle(Theme.text)
        }
        .background {
            Text(Self.wall)
                .font(Theme.mono(9))
                .foregroundStyle(Theme.muted.opacity(0.13))
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .clipped()
                .accessibilityHidden(true)
        }
    }

    private func stat(_ n: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(n).font(Theme.mono(22, .bold)).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(Theme.body(13)).foregroundStyle(Theme.muted).fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .guideCard(14)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Coda · your 168

struct CodaScreen: View {
    let solved: [Int: String]
    let play: () -> Void

    var body: some View {
        let found = PrimeEngine.all.filter { solved[$0] != nil }.count
        GuidePage {
            VStack(spacing: 12) {
                Text("168")
                    .font(Theme.number(96))
                    .foregroundStyle(Theme.accent)
                    .shadow(color: Theme.glow, radius: 12)
                Text("primes under 1,000.")
                    .font(Theme.serif(26))
                    .foregroundStyle(Theme.text)
                Text("Every one can be spotted by hand. Each lights up the first time you call it.")
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
                    .fixedSize(horizontal: false, vertical: true)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 12), spacing: 4) {
                    ForEach(PrimeEngine.all, id: \.self) { p in
                        // Unfound primes stay dark, so the grid can't spoil a question.
                        let lit = solved[p] != nil
                        RoundedRectangle(cornerRadius: Theme.r(4))
                            .fill(lit ? Theme.accent : Theme.panel)
                            .overlay(RoundedRectangle(cornerRadius: Theme.r(4)).stroke(lit ? Theme.accent : Theme.border, lineWidth: 1))
                            .frame(height: 18)
                    }
                }
                .padding(.top, 14)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(found) of 168 primes found")
                HStack {
                    Text("2")
                    Spacer()
                    Text("\(found) of 168 found").font(Theme.mono(13)).foregroundStyle(Theme.text)
                    Spacer()
                    Text("997")
                }
                .font(Theme.body(13))
                .foregroundStyle(Theme.muted)
                .accessibilityHidden(true)
            }
            .padding(.top, 4)
            Spacer(minLength: 0)
            Button("Play", action: play).buttonStyle(FilledButtonStyle())
        }
    }
}

// MARK: - Bonus · a prime can't make a rectangle

struct RectangleScreen: View {
    @State private var n = 12

    var body: some View {
        var a = 1
        for d in 2...max(2, Int(Double(n).squareRoot())) where d * d <= n && n % d == 0 { a = d }
        let prime = a == 1
        let pairs = (2...max(2, Int(Double(n).squareRoot()))).filter { $0 * $0 <= n && n % $0 == 0 }.map { "\($0) × \(n / $0)" }
        let rows = prime ? 1 : a, cols = prime ? n : n / a
        let size = CGFloat(max(5, min(26, 300 / cols - 6, 300 / rows - 6)))
        let gap = max(3, (size / 3).rounded())
        return GuidePage(spacing: 18) {
            Kicker(text: "Bonus · a way to see it")
            Headline(text: "A prime can't make a rectangle.")
            Lede(text: "Line up that many dots. If they fit into a rectangle, the number is composite. If they only fit in a line, it's prime.", size: 16)
            VStack(spacing: gap) {
                ForEach(0..<rows, id: \.self) { _ in
                    HStack(spacing: gap) {
                        ForEach(0..<cols, id: \.self) { _ in
                            Circle()
                                .fill(prime ? Theme.accent : Theme.text)
                                .frame(width: size, height: size)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 20)
            .guideCard()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(prime ? "\(n) dots in a single line" : "\(n) dots in \(rows) rows of \(cols)")
            HStack(alignment: .firstTextBaseline) {
                Text("\(n)").font(Theme.mono(44, .bold)).foregroundStyle(Theme.text)
                Text("dots").font(Theme.body(15)).foregroundStyle(Theme.muted)
                Spacer()
                Text(prime ? "prime" : "composite")
                    .font(Theme.body(12, .semibold))
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .foregroundStyle(prime ? Theme.ink : Theme.accent)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(prime ? Theme.accent : .clear, in: RoundedRectangle(cornerRadius: Theme.r(6)))
                    .overlay(RoundedRectangle(cornerRadius: Theme.r(6)).stroke(Theme.accent, lineWidth: 1))
            }
            Text(prime ? "Only 1 × \(n). No rectangle." : "\(n) = " + pairs.joined(separator: " = "))
                .font(Theme.mono(15))
                .foregroundStyle(Theme.text)
                .frame(minHeight: 22)
            HStack(spacing: 10) {
                Button("−") { n = max(2, n - 1); Haptics.tick() }
                    .buttonStyle(OutlineButtonStyle(height: 52)).frame(width: 56)
                    .accessibilityLabel("One fewer dot")
                Button("+") { n = min(36, n + 1); Haptics.tick() }
                    .buttonStyle(OutlineButtonStyle(height: 52)).frame(width: 56)
                    .accessibilityLabel("One more dot")
                Button("Next") { n = min(36, n + 1); Haptics.tick() }
                    .buttonStyle(FilledButtonStyle())
            }
        }
    }
}
