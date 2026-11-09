//  StoryView.swift — Story mode on screen. A chapter list, then each chapter as
//  scrollytelling: the stage (dots, the sieve, a number, strings, a rhythm) is
//  pinned at the top and changes as each paragraph scrolls into focus. Gates
//  hold the story until they're passed. The script lives in Story.swift.

import SwiftUI

struct StoryView: View {
    @ObservedObject var game: Game
    let play: () -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Story.doneKey) private var doneRaw = ""
    @State private var open: Int?
    @State private var guide: GuideScreen?

    private var done: Set<Int> { Set(doneRaw.split(separator: ",").compactMap { Int($0) }) }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if Theme.style == .phosphor { Scanlines().ignoresSafeArea() }
            if let k = open {
                let c = Story.chapters[k]
                ChapterView(chapter: c, last: k == Story.chapters.count - 1, game: game,
                            close: { go(nil) },
                            next: { go(k + 1) },
                            guide: { guide = c.guide },
                            play: play,
                            finish: { finish(c.id) })
                    .id(k)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)))
            } else {
                StoryHome(done: done, close: { dismiss() }, open: { go($0) })
                    .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.97)),
                                            removal: .opacity.combined(with: .scale(scale: 1.03))))
            }
        }
        .tint(Theme.accent)
        .sheet(item: $guide) { s in
            GuideView(solved: game.solved, start: s, play: { guide = nil; play() })
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.bg)
        }
        .onDisappear { Tones.shared.stop() }
    }

    private func go(_ k: Int?) {
        Tones.shared.stop()
        Haptics.tick()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { open = k }
    }

    private func finish(_ id: Int) {
        var d = done
        d.insert(id)
        doneRaw = d.sorted().map(String.init).joined(separator: ",")
    }
}

// MARK: - Chapter list

private struct StoryHome: View {
    let done: Set<Int>
    let close: () -> Void
    let open: (Int) -> Void
    @State private var shown = false

    var body: some View {
        let next = Story.chapters.firstIndex { !done.contains($0.id) }
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Spacer()
                    CloseButton(action: close)
                }
                Text("1 · 2 · 3 · 2² · 5 · 2·3 · 7")
                    .font(Theme.mono(20, .bold))
                    .foregroundStyle(Theme.accent)
                    .shadow(color: Theme.glow, radius: 10)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityHidden(true)
                Kicker(text: "Story mode").padding(.top, 8)
                Headline(text: "From One\nto forever.", size: 42)
                Text("You begin as a single dot. Grow into the primes, sort a crowd, see through disguises, hear primes in music, and find out whether they ever run out. Scroll to read; solve to move on.")
                    .font(Theme.body(16))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 10) {
                    ForEach(Story.chapters.indices, id: \.self) { k in
                        row(k, done: done.contains(Story.chapters[k].id), next: k == next)
                            .opacity(shown ? 1 : 0)
                            .offset(y: shown ? 0 : 24)
                            .animation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.05 * Double(k)), value: shown)
                    }
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .onAppear { shown = true }
    }

    private func row(_ k: Int, done: Bool, next: Bool) -> some View {
        let c = Story.chapters[k]
        return Button { open(k) } label: {
            HStack(spacing: 14) {
                Text(String(format: "%02d", c.id))
                    .font(Theme.mono(14, .bold))
                    .foregroundStyle(next ? Theme.ink : Theme.accent)
                    .frame(width: 40, height: 40)
                    .background(next ? Theme.accent : Color.clear, in: RoundedRectangle(cornerRadius: Theme.r(10)))
                    .overlay(RoundedRectangle(cornerRadius: Theme.r(10)).stroke(Theme.accent.opacity(next ? 0 : 0.5), lineWidth: 1))
                VStack(alignment: .leading, spacing: 3) {
                    Text(c.title).font(Theme.body(17, .semibold)).foregroundStyle(Theme.text)
                    Text(c.blurb).font(Theme.body(14)).foregroundStyle(Theme.muted).lineLimit(1).minimumScaleFactor(0.85)
                }
                Spacer(minLength: 6)
                if done {
                    Image(systemName: "checkmark").font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.accent)
                } else {
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.muted)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: Theme.r(16)))
            .overlay(RoundedRectangle(cornerRadius: Theme.r(16)).stroke(next ? Theme.accent : Theme.border, lineWidth: next ? 1.5 : 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel("Chapter \(c.id): \(c.title). \(c.blurb)" + (done ? " Read." : ""))
    }
}

private struct CloseButton: View {
    var symbol = "xmark"
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 16, weight: .semibold)).frame(width: 44, height: 44)
        }
        .foregroundStyle(Theme.text)
        .background(Theme.panel, in: Circle())
        .overlay(Circle().stroke(Theme.border, lineWidth: 1))
        .accessibilityLabel(symbol == "xmark" ? "Close" : "Chapters")
    }
}

/// Sinks a little under the finger.
private struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - A chapter

private struct ChapterView: View {
    let chapter: Chapter
    let last: Bool
    @ObservedObject var game: Game
    let close: () -> Void
    let next: () -> Void
    let guide: () -> Void
    let play: () -> Void
    let finish: () -> Void

    @State private var passed: Set<Int> = []
    @State private var active = 0
    @State private var tops: [Int: CGFloat] = [:]
    @State private var target: Int?
    @State private var ended = false

    /// Steps on the page: everything up to and including the first gate not yet passed.
    private var shown: Int {
        for (i, s) in chapter.steps.enumerated() where s.gate != nil && !passed.contains(i) { return i + 1 }
        return chapter.steps.count
    }
    private var complete: Bool { shown == chapter.steps.count && chapter.steps.indices.allSatisfy { chapter.steps[$0].gate == nil || passed.contains($0) } }

    var body: some View {
        GeometryReader { g in
            let stageH = min(max(g.size.height * 0.36, 230), 330)
            let focusLine = stageH + 70 + (g.size.height - stageH) * 0.32
            ZStack(alignment: .top) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Color.clear.frame(height: stageH + 92)
                            ForEach(0..<shown, id: \.self) { i in
                                Color.clear.frame(height: 0).id(i)       // where Continue lands: just under the stage
                                StepView(step: chapter.steps[i], focused: active == i, passed: passed.contains(i), game: game,
                                         pass: { pass(i) }, onward: { target = i + 1 })
                                    .padding(.vertical, 22)
                                    .frame(maxWidth: .infinity, minHeight: (g.size.height - stageH) * 0.42, alignment: .topLeading)
                                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named("story")).minY } action: { y in
                                        tops[i] = y
                                        focus(line: focusLine)
                                    }
                                    .transition(.opacity.combined(with: .offset(y: 40)))
                            }
                            if complete {
                                Color.clear.frame(height: 0).id(chapter.steps.count)
                                ChapterEnd(chapter: chapter, last: last, next: next, guide: guide, play: play)
                                    .padding(.top, 30)
                                    .transition(.opacity.combined(with: .offset(y: 40)))
                                    .onAppear { if !ended { ended = true; finish() } }
                            }
                            Color.clear.frame(height: g.size.height * 0.5)
                        }
                        .padding(.horizontal, 24)
                        .frame(maxWidth: 560)
                        .frame(maxWidth: .infinity)
                    }
                    .coordinateSpace(name: "story")
                    .scrollIndicators(.hidden)
                    .onChange(of: target) { _, t in
                        guard let t else { return }
                        withAnimation(.easeInOut(duration: 0.65)) { proxy.scrollTo(t, anchor: UnitPoint(x: 0.5, y: (stageH + 96) / g.size.height)) }
                        target = nil
                    }
                }
                // The pinned stage, with a fade so paragraphs slide under it.
                VStack(spacing: 0) {
                    topBar
                    StageView(stage: chapter.steps[min(active, shown - 1)].stage)
                        .frame(height: stageH)
                        .padding(.horizontal, 20)
                }
                .background(Theme.bg)
                .overlay(alignment: .bottom) {
                    LinearGradient(colors: [Theme.bg, Theme.bg.opacity(0)], startPoint: .top, endPoint: .bottom)
                        .frame(height: 44)
                        .offset(y: 44)
                        .allowsHitTesting(false)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: active)
    }

    private var topBar: some View {
        let progress = Double(min(active + 1, chapter.steps.count)) / Double(chapter.steps.count)
        return VStack(spacing: 10) {
            HStack {
                CloseButton(symbol: "chevron.left", action: close)
                Spacer()
                VStack(spacing: 2) {
                    Kicker(text: "Chapter \(chapter.id)")
                    Text(chapter.title).font(Theme.serif(19)).foregroundStyle(Theme.text)
                }
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }
            GeometryReader { p in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.border)
                    Capsule().fill(Theme.accent).frame(width: p.size.width * progress)
                        .shadow(color: Theme.accent.opacity(0.5), radius: 4)
                }
            }
            .frame(height: 3)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    /// The step in focus is the last one whose top has crossed the focus line.
    private func focus(line: CGFloat) {
        var a = 0
        for i in 0..<shown { if let y = tops[i], y < line { a = i } }
        if complete, let y = tops[shown - 1], y < line - 400 { a = shown - 1 }
        if a != active { withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { active = a } }
    }

    private func pass(_ i: Int) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { _ = passed.insert(i) }
    }
}

private struct StepView: View {
    let step: Step
    let focused: Bool
    let passed: Bool
    @ObservedObject var game: Game
    let pass: () -> Void
    let onward: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(step.text)
                .font(Theme.body(19))
                .foregroundStyle(Theme.text)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
            if let math = step.math {
                mathLine(math, size: 22)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            switch step.gate {
            case .call(let n): CallGate(n: n, game: game, pass: pass, onward: onward)
            case .choose(let q, let options): ChooseGate(prompt: q, options: options, pass: pass, onward: onward)
            case nil: EmptyView()
            }
        }
        .padding(.leading, 16)
        .overlay(alignment: .leading) {
            Capsule()
                .fill(Theme.accent)
                .frame(width: 3)
                .opacity(focused ? 1 : 0)
                .scaleEffect(y: focused ? 1 : 0.3, anchor: .top)
        }
        .opacity(focused ? 1 : 0.3)
        .blur(radius: focused ? 0 : 0.6)
        .animation(.easeOut(duration: 0.35), value: focused)
    }
}

// MARK: - Gates

/// The game's question, mid-story: Prime or Composite, then the method.
private struct CallGate: View {
    let n: Int
    @ObservedObject var game: Game
    let pass: () -> Void
    let onward: () -> Void
    @State private var said: Bool?
    @State private var fresh = false

    var body: some View {
        let prime = PrimeEngine.isPrime(n)
        VStack(alignment: .leading, spacing: 14) {
            Text(Theme.prompt + "Is \(n) prime?")
                .font(Theme.body(15, .semibold))
                .textCase(Theme.labelCase)
                .foregroundStyle(Theme.muted)
            HStack(spacing: 12) {
                answer("Prime", true, prime: prime)
                answer("Composite", false, prime: prime)
            }
            if let said {
                VStack(alignment: .leading, spacing: 10) {
                    Text(PrimeEngine.verdictLine(saidPrime: said, prime: prime))
                        .font(Theme.serif(22))
                        .foregroundStyle(said == prime ? Theme.success : Theme.danger.opacity(0.85))
                    if fresh {
                        Text("New prime found · \(game.foundCount) of \(PrimeEngine.all.count)")
                            .font(Theme.body(14))
                            .foregroundStyle(Theme.accent)
                    }
                    if prime {
                        let e = PrimeEngine.primeExplanation(n)
                        if let list = e.listNote { Text(list).font(Theme.body(15)).foregroundStyle(Theme.text) }
                        if let root = e.rootLine { MathBox(lines: [root]) }
                        if let v = e.verdict { Text(v).font(Theme.body(15)).foregroundStyle(Theme.text) }
                    } else {
                        let p = PrimeEngine.spf(n)
                        Text(PrimeEngine.equation(n)).font(Theme.mono(24, .bold)).foregroundStyle(Theme.text)
                        MathBox(header: "\(p) trick", subheader: PrimeEngine.tricks[p]!.trick, lines: PrimeEngine.apply(p, n).steps)
                    }
                    OnwardButton(action: onward)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func answer(_ title: String, _ value: Bool, prime: Bool) -> some View {
        let picked = said == value, right = value == prime
        let ring: Color = said == nil ? Theme.accent : right ? Theme.success : picked ? Theme.danger : Theme.border
        return Button {
            guard said == nil else { return }
            Haptics.result(right)
            if right && prime { fresh = game.markFound(n) }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { said = value }
            pass()
        } label: {
            Text(title)
                .font(Theme.body(19, .bold))
                .textCase(Theme.labelCase)
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity, minHeight: 72)
                .background((said != nil && right ? Theme.success.opacity(0.12) : Theme.panel), in: RoundedRectangle(cornerRadius: Theme.r(16)))
                .overlay(RoundedRectangle(cornerRadius: Theme.r(16)).stroke(ring, lineWidth: 1.5))
                .opacity(said != nil && !right && !picked ? 0.5 : 1)
        }
        .buttonStyle(PressStyle())
        .disabled(said != nil)
    }
}

/// A choice. Wrong answers explain themselves and step aside; the right one opens the way.
private struct ChooseGate: View {
    let prompt: String
    let options: [Option]
    let pass: () -> Void
    let onward: () -> Void
    @State private var tried: Set<Int> = []
    @State private var picked: Int?
    @State private var last: Int?
    @State private var shakes = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(prompt)
                .font(Theme.body(17, .semibold))
                .foregroundStyle(Theme.accent)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(options.indices, id: \.self) { k in
                option(k)
            }
            if let last {
                let o = options[last]
                Text(o.reply)
                    .font(Theme.body(15))
                    .foregroundStyle(o.right ? Theme.text : Theme.danger)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .id(last)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .keyframeAnimator(initialValue: 0.0, trigger: shakes) { v, x in v.offset(x: x) } keyframes: { _ in
                        KeyframeTrack {
                            SpringKeyframe(-7, duration: 0.07); SpringKeyframe(6, duration: 0.07)
                            SpringKeyframe(-3, duration: 0.07); SpringKeyframe(0, duration: 0.1)
                        }
                    }
            }
            if picked != nil { OnwardButton(action: onward).transition(.opacity) }
        }
    }

    private func option(_ k: Int) -> some View {
        let o = options[k]
        let isPicked = picked == k, wrong = tried.contains(k) && !o.right
        let label: Text = o.text.first?.isNumber == true ? mathLine(o.text.split(separator: " ").map(String.init), size: 18)
                                                         : Text(o.text).font(Theme.body(17, .medium))
        return Button {
            guard picked == nil, !tried.contains(k) else { return }
            Haptics.result(o.right)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                tried.insert(k)
                last = k
                if o.right { picked = k } else { shakes += 1 }
            }
            if o.right { pass() }
        } label: {
            HStack {
                label.foregroundStyle(Theme.text).strikethrough(wrong, color: Theme.muted)
                Spacer()
                if isPicked { Image(systemName: "checkmark").font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.ink) }
                if wrong { Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.muted) }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 54)
            .background(isPicked ? Theme.accent.opacity(0.9) : Theme.panel, in: RoundedRectangle(cornerRadius: Theme.r(14)))
            .overlay(RoundedRectangle(cornerRadius: Theme.r(14)).stroke(isPicked ? Theme.accent : Theme.border, lineWidth: 1))
            .opacity(wrong || (picked != nil && !isPicked) ? 0.45 : 1)
        }
        .buttonStyle(PressStyle())
        .disabled(picked != nil || wrong)
    }
}

private struct OnwardButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("Continue")
                Image(systemName: "arrow.down")
            }
            .font(Theme.body(15, .semibold))
            .textCase(Theme.labelCase)
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .overlay(Capsule().stroke(Theme.accent.opacity(0.6), lineWidth: 1))
        }
        .buttonStyle(PressStyle())
        .padding(.top, 4)
    }
}

private struct ChapterEnd: View {
    let chapter: Chapter
    let last: Bool
    let next: () -> Void
    let guide: () -> Void
    let play: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Kicker(text: last ? "The end" : "Chapter \(chapter.id) complete")
            Headline(text: last ? "From One to forever." : "Next: \(Story.chapters[chapter.id].title)", size: 28)
            if last {
                Button("Play Prime or Composite", action: play).buttonStyle(FilledButtonStyle())
            } else {
                Button("Next chapter", action: next).buttonStyle(FilledButtonStyle())
            }
            Button("In the guide: \(chapter.guideTitle) ›", action: guide)
                .buttonStyle(OutlineButtonStyle(accent: true))
        }
        .padding(18)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: Theme.r(18)))
        .overlay(RoundedRectangle(cornerRadius: Theme.r(18)).stroke(Theme.accent.opacity(0.6), lineWidth: 1))
    }
}

// MARK: - The stage

struct StageView: View {
    let stage: Stage

    var body: some View {
        ZStack {
            switch stage {
            case .dots(let n, let shape): DotsStage(n: n, shape: shape).transition(.blurReplace)
            case .sieve(let by, let done): SieveStage(by: by, done: done).transition(.blurReplace)
            case .number(let n): NumberStage(n: n).transition(.blurReplace)
            case .atoms(let a): AtomsStage(atoms: a).transition(.blurReplace)
            case .ratio(let a, let b, let name): RatioStage(a: a, b: b, name: name).transition(.blurReplace)
            case .rhythm(let a, let b): RhythmStage(a: a, b: b).transition(.blurReplace)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.6, dampingFraction: 0.74), value: stage)
    }
}

/// "6 = 2 × 3", "7 · prime", with the primes lit.
func recipe(_ n: Int) -> [String] {
    if n == 1 { return ["1", "·", "not", "prime,", "not", "composite"] }
    if PrimeEngine.isPrime(n) { return [String(n), "·", "prime"] }
    var out = [String(n), "="], m = n, p = 2
    while m > 1 {
        while m % p == 0 { out += out.count > 2 ? ["×", String(p)] : [String(p)]; m /= p }
        p += 1
    }
    return out
}

struct DotsStage: View {
    let n: Int
    let shape: DotShape

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { g in
                let (pts, d) = Self.layout(n, shape, g.size)
                ZStack {
                    ForEach(Array(0..<n), id: \.self) { k in
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: d, height: d)
                            .shadow(color: Theme.accent.opacity(0.55), radius: d * 0.32)
                            .position(pts[k])
                            .transition(.scale(scale: 0.05).combined(with: .opacity))
                    }
                }
            }
            mathLine(recipe(n), size: 20)
                .contentTransition(.numericText(value: Double(n)))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(caption)
                .font(Theme.body(13, .semibold))
                .textCase(.uppercase)
                .tracking(1)
                .foregroundStyle(Theme.muted)
        }
        .padding(.vertical, 8)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.8), trigger: n)
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.5), trigger: shape)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(n) dots, \(caption)")
    }

    private var caption: String {
        switch shape {
        case .row: return n == 1 ? "one dot" : "one row"
        case .ring: return "no rows fit"
        case .grid(let r, let c): return "\(r) rows of \(c)"
        }
    }

    static func layout(_ n: Int, _ shape: DotShape, _ size: CGSize) -> ([CGPoint], CGFloat) {
        let cx = size.width / 2, cy = size.height / 2
        switch shape {
        case .row:
            let d: CGFloat = min(46, size.width / CGFloat(n * 2))
            let gap = d * 1.7
            return ((0..<n).map { CGPoint(x: cx + (CGFloat($0) - CGFloat(n - 1) / 2) * gap, y: cy) }, d)
        case .ring:
            let r = min(size.width, size.height) * 0.36
            let d: CGFloat = min(42, 2 * .pi * r / CGFloat(n) * 0.5)
            return ((0..<n).map {
                let a = -Double.pi / 2 + 2 * .pi * Double($0) / Double(n)
                return CGPoint(x: cx + r * cos(a), y: cy + r * sin(a))
            }, d)
        case .grid(let rows, let cols):
            let across: CGFloat = size.width / CGFloat(cols + 1)
            let down: CGFloat = size.height / (CGFloat(rows) + 0.6)
            let s: CGFloat = min(across, down, 74)
            let d = s * 0.56
            return ((0..<n).map { k in
                let row = k / cols, col = k % cols
                return CGPoint(x: cx + (CGFloat(col) - CGFloat(cols - 1) / 2) * s,
                               y: cy + (CGFloat(row) - CGFloat(rows - 1) / 2) * s)
            }, d)
        }
    }
}

/// 1 to 30 in rows of six, crossed out prime by prime.
struct SieveStage: View {
    let by: [Int]
    let done: Bool

    var body: some View {
        let crossed = (1...30).filter { k in by.contains { k != $0 && k % $0 == 0 } }.count
        VStack(spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                ForEach(1...30, id: \.self) { k in cell(k) }
            }
            .frame(maxWidth: 330)
            Text(by.isEmpty ? "the crowd" : "sifted by " + by.map(String.init).joined(separator: ", "))
                .font(Theme.body(13, .semibold))
                .textCase(.uppercase)
                .tracking(1)
                .foregroundStyle(Theme.muted)
                .contentTransition(.opacity)
        }
        .frame(maxHeight: .infinity)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: crossed)
    }

    private func cell(_ k: Int) -> some View {
        let out = by.contains { k != $0 && k % $0 == 0 }
        let sifter = by.contains(k)
        let lit = sifter || (done && !out && k > 1)
        return Text("\(k)")
            .font(Theme.mono(15, .semibold))
            .monospacedDigit()
            .foregroundStyle(lit ? Theme.ink : out || k == 1 ? Theme.muted.opacity(0.45) : Theme.text)
            .frame(maxWidth: .infinity, minHeight: 34)
            .background(lit ? Theme.accent : Theme.panel.opacity(out ? 0.3 : 1), in: RoundedRectangle(cornerRadius: Theme.r(8)))
            .overlay(RoundedRectangle(cornerRadius: Theme.r(8)).stroke(out ? Color.clear : Theme.border, lineWidth: 1))
            .overlay {
                Rectangle().fill(Theme.danger.opacity(0.7)).frame(height: 1.5)
                    .rotationEffect(.degrees(-24))
                    .scaleEffect(x: out ? 0.75 : 0.01)
                    .opacity(out ? 1 : 0)
            }
            .scaleEffect(out ? 0.9 : 1)
            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(k) * 0.018), value: out)
            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(k) * 0.018), value: lit)
    }
}

/// The question screen's number, with the square-root bound under it.
struct NumberStage: View {
    let n: Int
    var body: some View {
        VStack(spacing: 8) {
            Text(String(n))
                .font(Theme.number(104))
                .monospacedDigit()
                .foregroundStyle(Theme.text)
                .shadow(color: Theme.glow, radius: 10)
                .contentTransition(.numericText(value: Double(n)))
                .minimumScaleFactor(0.5)
            Text("√\(n) ≈ " + String(format: "%.1f", Double(n).squareRoot()))
                .font(Theme.mono(16))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxHeight: .infinity)
    }
}

struct AtomsStage: View {
    let atoms: [Int]
    @State private var shown = false
    var body: some View {
        HStack(spacing: 14) {
            ForEach(Array(atoms.enumerated()), id: \.offset) { i, p in
                Text("\(p)")
                    .font(Theme.mono(22, .bold))
                    .foregroundStyle(MoleculesScreen.atomInk)
                    .frame(width: 58 + CGFloat(p) * 1.5, height: 58 + CGFloat(p) * 1.5)
                    .background(MoleculesScreen.color(p), in: Circle())
                    .shadow(color: MoleculesScreen.color(p).opacity(0.5), radius: 12)
                    .scaleEffect(shown ? 1 : 0.2)
                    .opacity(shown ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.08 * Double(i)), value: shown)
            }
        }
        .frame(maxHeight: .infinity)
        .onAppear { shown = true }
    }
}

/// Two strings, a : b. They line up again every b cycles of the lower one.
struct RatioStage: View {
    let a: Int
    let b: Int
    let name: String
    @State private var playing = false

    var body: some View {
        VStack(spacing: 10) {
            TimelineView(.animation(paused: !playing)) { tl in
                let t = playing ? tl.date.timeIntervalSinceReferenceDate : 0
                Canvas { ctx, size in
                    let w = size.width, mid = size.height / 2
                    let loops = 2.0                                      // show the pattern twice
                    func wave(_ cycles: Double, _ y0: CGFloat, _ amp: CGFloat, _ color: Color) {
                        var p = Path()
                        for x in stride(from: 0, through: w, by: 2) {
                            let ph = 2 * Double.pi * (cycles * loops * Double(x / w) - t * cycles * 0.35)
                            let y = y0 + amp * CGFloat(sin(ph))
                            x == 0 ? p.move(to: CGPoint(x: x, y: y)) : p.addLine(to: CGPoint(x: x, y: y))
                        }
                        ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    }
                    for k in 0...Int(loops) {                             // where the two meet again
                        let x = w * CGFloat(k) / CGFloat(loops)
                        ctx.stroke(Path { $0.move(to: CGPoint(x: x, y: 8)); $0.addLine(to: CGPoint(x: x, y: size.height - 8)) },
                                   with: .color(Theme.accent.opacity(0.35)), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                    }
                    wave(Double(b), mid - size.height * 0.2, size.height * 0.14, Theme.muted)
                    wave(Double(a), mid + size.height * 0.2, size.height * 0.14, Theme.accent)
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                mathLine([String(a), ":", String(b)], size: 30)
                Text(name).font(Theme.body(14, .semibold)).textCase(.uppercase).tracking(1).foregroundStyle(Theme.muted)
                Spacer()
                PlayButton(playing: playing) {
                    Tones.shared.play(Tones.interval(a, b))
                    withAnimation { playing = true }
                    Task { try? await Task.sleep(for: .seconds(3.6)); withAnimation { playing = false } }
                }
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Two strings in the ratio \(a) to \(b), a \(name)")
    }
}

/// a beats against b on one loop; a ring marks where they land together.
struct RhythmStage: View {
    let a: Int
    let b: Int
    @State private var start: Date?
    static let bar = 2.4

    var body: some View {
        let n = a * b / gcd(a, b)
        VStack(spacing: 12) {
            TimelineView(.animation(paused: start == nil)) { tl in
                let pos = start.map { (tl.date.timeIntervalSince($0) / Self.bar).truncatingRemainder(dividingBy: 1) }
                VStack(spacing: 14) {
                    track(a, of: n, pos: pos)
                    track(b, of: n, pos: pos)
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                mathLine([String(a), "against", String(b)], size: 24)
                Text("together every \(n)").font(Theme.body(13, .semibold)).textCase(.uppercase).tracking(1).foregroundStyle(Theme.muted)
                Spacer()
                PlayButton(playing: start != nil) { play(n) }
            }
        }
        .frame(maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(a) beats against \(b). They land together every \(n).")
    }

    private func track(_ beats: Int, of n: Int, pos: Double?) -> some View {
        let every = n / beats
        let cur = pos.map { Int($0 * Double(n)) }
        return HStack(spacing: 4) {
            ForEach(0..<n, id: \.self) { k in
                let hit = k % every == 0, both = k == 0
                let now = cur == k
                RoundedRectangle(cornerRadius: Theme.r(4))
                    .fill(hit ? (both ? Theme.accent : Theme.text.opacity(0.8)) : Theme.border.opacity(0.6))
                    .frame(height: hit ? 26 : 10)
                    .scaleEffect(now && hit ? 1.25 : 1)
                    .overlay(alignment: .bottom) {
                        if now { Capsule().fill(Theme.accent).frame(width: 4, height: 4).offset(y: 10) }
                    }
            }
        }
        .frame(height: 36)
    }

    private func play(_ n: Int) {
        Tones.shared.play(Tones.rhythm(a, b, bar: Self.bar))
        let t0 = Date()
        start = t0
        Task {
            // Feel it too: a tap on every beat, a harder one where they meet.
            let hits = Set((0..<a).map { $0 * n / a }).union((0..<b).map { $0 * n / b })
            for loop in 0..<2 {
                for k in 0..<n where hits.contains(k) {
                    let at = Double(loop) * Self.bar + Self.bar * Double(k) / Double(n)
                    let wait = at - Date().timeIntervalSince(t0)
                    if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
                    UIImpactFeedbackGenerator(style: k == 0 ? .heavy : .light).impactOccurred()
                }
            }
            try? await Task.sleep(for: .seconds(Self.bar / Double(n)))
            if start == t0 { start = nil }
        }
    }

    private func gcd(_ x: Int, _ y: Int) -> Int { y == 0 ? x : gcd(y, x % y) }
}

private struct PlayButton: View {
    let playing: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: playing ? "waveform" : "play.fill")
                .font(.system(size: 17, weight: .semibold))
                .symbolEffect(.variableColor.iterative, isActive: playing)
                .foregroundStyle(Theme.ink)
                .frame(width: 48, height: 48)
                .background(Theme.accent, in: Circle())
                .shadow(color: Theme.accent.opacity(0.5), radius: playing ? 12 : 4)
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel("Play it")
    }
}
