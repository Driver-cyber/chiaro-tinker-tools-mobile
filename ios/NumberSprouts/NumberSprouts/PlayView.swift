//  PlayView.swift — the card loop, for every card deck.
//
//  A card flies in and pops. Answer it the deck's way: drag into the Even or
//  Odd basket, tap the bigger side (the alligator chomps it), or pick one of
//  four. Right: a green glow and a star burst. Miss: a gentle shake, then the
//  Trick card, then one retry. Ten cards, then the stars.

import SwiftUI

struct PlayView: View {
    @EnvironmentObject private var model: AppModel
    let modeID: String
    @State private var roundKey = 0

    var body: some View {
        if let mode = Modes.mode(modeID) {
            switch mode.play {
            case .cards(let deal):
                RoundView(mode: mode, cards: deal()) { roundKey += 1 }.id(roundKey)
            case .draw(let kind):
                DrawView(mode: mode, kind: kind)
            }
        }
    }
}

struct RoundView: View {
    @EnvironmentObject private var model: AppModel
    @StateObject private var round: Round
    let mode: Mode
    let again: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var drag: CGSize = .zero
    @State private var dropped = false
    @State private var hover: Int?                  // which basket the card is over
    @State private var baskets: [Int: CGRect] = [:]
    @State private var cardFrame: CGRect = .zero
    @State private var shakes: CGFloat = 0
    @State private var bursts = 0

    init(mode: Mode, cards: [Card], again: @escaping () -> Void) {
        _round = StateObject(wrappedValue: Round(modeID: mode.id, cards: cards))
        self.mode = mode
        self.again = again
    }

    private var answering: Bool { round.phase == .asking || round.phase == .retrying }
    private var answered: Bool { round.phase == .right }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(count: round.count, index: round.index, done: round.phase == .right || round.phase == .done) { model.screen = .home }
            switch round.card.face {
            case .parity(let n, let dots): parityArea(n, dots)
            case .compare(let a, let b): compareArea(a, b)
            case .choice(let prompt, let options): choiceArea(prompt, options)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .coordinateSpace(name: "play")
        .onPreferenceChange(BasketFrames.self) { baskets = $0 }
        .overlay {
            if !reduceMotion { Burst(trigger: bursts).allowsHitTesting(false) }
        }
        .overlay {
            if round.phase == .missed {
                TrickOverlay(trick: round.card.trick) { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { round.gotIt(); reset() } }
                    .transition(.opacity)
            }
        }
        .overlay {
            if round.phase == .done {
                SummaryView(stars: round.stars, firstTry: round.firstTry, count: round.count, again: again) { model.screen = .home }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: round.phase)
        .onChange(of: round.phase) { _, phase in
            if phase == .right {
                bursts += 1
                Task {
                    try? await Task.sleep(for: .milliseconds(reduceMotion ? 700 : 1000))
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { round.advance(); reset() }
                }
            }
            if phase == .done { model.recordRound(mode: mode.id, stars: round.stars) }
        }
    }

    private var hint: String {
        switch round.phase {
        case .retrying: return "One more try!"
        case .right: return ["Yes!", "You got it!", "Nice!", "Super!"][round.index % 4]
        default:
            switch round.card.face {
            case .parity: return "Drag the card into a basket"
            case .compare: return "Tap the bigger number"
            case .choice: return "Pick the answer"
            }
        }
    }

    private var hintView: some View {
        Text(hint)
            .font(Theme.round(18, .bold))
            .foregroundStyle(round.phase == .retrying ? Theme.odd : (answered ? Theme.right : Theme.muted))
            .frame(minHeight: 30)
    }

    private func pick(_ i: Int) {
        guard answering else { return }
        if !round.answer(i) {
            withAnimation(.linear(duration: 0.45)) { shakes += 1 }
        }
    }

    private func reset() {
        drag = .zero
        dropped = false
        hover = nil
    }

    // MARK: Even or Odd: drag into a basket

    private func parityArea(_ n: Int, _ dots: Bool) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            NumberCard(n: n, dots: dots, glowing: answered)
                .id(round.index)
                .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                .background(GeometryReader { g in Color.clear.onAppear { cardFrame = g.frame(in: .named("play")) } })
                .modifier(Shake(amount: reduceMotion ? 0 : 12, animatableData: shakes))
                .scaleEffect(dropped ? 0.25 : (drag == .zero ? 1 : 1.05))
                .opacity(dropped ? 0 : 1)
                .offset(drag)
                .gesture(dragGesture)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Number \(n)")
            hintView.padding(.top, 18)
            Spacer(minLength: 12)
            HStack(spacing: 16) {
                basket(0)
                basket(1)
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .named("play"))
            .onChanged { v in
                guard answering else { return }
                drag = v.translation
                let over = basketAt(v.location)
                if over != hover { hover = over; if over != nil { Haptics.tick() } }
            }
            .onEnded { v in
                guard answering else { return }
                if let b = basketAt(v.location) { dropInto(b) } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { drag = .zero }
                }
                hover = nil
            }
    }

    private func basketAt(_ p: CGPoint) -> Int? {
        for (i, r) in baskets where r.insetBy(dx: -12, dy: -24).contains(p) { return i }
        return nil
    }

    private func dropInto(_ b: Int) {
        guard answering else { return }
        if round.answer(b) {
            let target = baskets[b] ?? .zero
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                drag = CGSize(width: target.midX - cardFrame.midX, height: target.midY - cardFrame.midY)
                dropped = true
            }
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { drag = .zero }
            withAnimation(.linear(duration: 0.45)) { shakes += 1 }
        }
    }

    private func basket(_ i: Int) -> some View {
        Button { dropInto(i) } label: { BasketView(even: i == 0, highlighted: hover == i) }
            .buttonStyle(.plain)
            .background(GeometryReader { g in Color.clear.preference(key: BasketFrames.self, value: [i: g.frame(in: .named("play"))]) })
            .accessibilityLabel(i == 0 ? "Even" : "Odd")
            .disabled(!answering)
    }

    // MARK: Bigger or Smaller: tap the bigger side

    private func compareArea(_ a: Int, _ b: Int) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            HStack(spacing: 10) {
                compareTile(a, side: 0)
                Mouth(opensToward: answered ? round.card.answer : nil)
                    .frame(width: 64, height: 64)
                compareTile(b, side: 1)
            }
            .id(round.index)
            .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            hintView.padding(.top, 22)
            Spacer(minLength: 12)
        }
    }

    private func compareTile(_ n: Int, side: Int) -> some View {
        let isAnswer = side == round.card.answer
        let wrong = round.wrongPicks.contains(side)
        return Button { pick(side) } label: {
            Text(String(n))
                .font(Theme.round(n >= 100 ? 52 : 64))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity, minHeight: 170)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 30))
                .overlay(RoundedRectangle(cornerRadius: 30).stroke(answered && isAnswer ? Theme.right : Theme.border, lineWidth: answered && isAnswer ? 5 : 2))
                .shadow(color: answered && isAnswer ? Theme.right.opacity(0.5) : .black.opacity(0.06), radius: answered && isAnswer ? 18 : 8)
                .opacity(wrong && round.phase == .retrying ? 0.45 : 1)
                .modifier(Shake(amount: reduceMotion || !wrong ? 0 : 10, animatableData: shakes))
        }
        .buttonStyle(.plain)
        .disabled(!answering)
        .accessibilityLabel("\(n)")
    }

    // MARK: Four choices

    private func choiceArea(_ prompt: String, _ options: [String]) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            PromptCard(prompt: prompt, glowing: answered)
                .id(round.index)
                .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Question \(prompt)")
            hintView.padding(.top, 16)
            Spacer(minLength: 12)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(Array(options.enumerated()), id: \.offset) { i, text in choiceButton(i, text) }
            }
        }
    }

    private func choiceButton(_ i: Int, _ text: String) -> some View {
        let right = answered && i == round.card.answer
        let wrong = round.wrongPicks.contains(i)
        return Button { pick(i) } label: {
            Text(text)
                .font(Theme.round(text.count > 5 ? 28 : 38))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundStyle(right ? Theme.onColor : Theme.text)
                .frame(maxWidth: .infinity, minHeight: 88)
                .background(right ? Theme.right : Theme.card, in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(wrong ? Theme.odd : Theme.border, lineWidth: 2))
                .opacity(wrong && round.phase == .retrying ? 0.4 : 1)
                .modifier(Shake(amount: reduceMotion || !wrong ? 0 : 10, animatableData: shakes))
        }
        .buttonStyle(.plain)
        .disabled(!answering || (wrong && round.phase == .retrying))
        .accessibilityLabel(text)
    }
}

// MARK: - Pieces

struct TopBar: View {
    let count: Int
    let index: Int
    let done: Bool
    let close: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CircleButton(symbol: "xmark", label: "Stop playing", action: close)
            ProgressDots(count: count, index: index, done: done)
            PlayerBadge()
        }
        .padding(.top, 8)
    }
}

struct CircleButton: View {
    let symbol: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 20, weight: .bold)).frame(width: 52, height: 52)
                .background(Theme.card, in: Circle())
                .overlay(Circle().stroke(Theme.border, lineWidth: 2))
        }
        .foregroundStyle(Theme.text)
        .accessibilityLabel(label)
    }
}

private struct BasketFrames: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

struct BasketView: View {
    let even: Bool
    let highlighted: Bool

    var body: some View {
        let color = even ? Theme.even : Theme.odd
        VStack(spacing: 8) {
            Image(systemName: "basket.fill")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(color)
            Text(even ? "Even" : "Odd")
                .font(Theme.round(28))
                .foregroundStyle(Theme.text)
            HStack(spacing: 4) {                      // even: pairs only; odd: pairs and one left over
                ForEach(0..<(even ? 4 : 5), id: \.self) { i in
                    Circle().fill(color.opacity(i == 4 ? 1 : 0.55)).frame(width: 9, height: 9)
                        .padding(.leading, i % 2 == 0 && i > 0 ? 5 : 0)
                }
            }
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, minHeight: 156)
        .background(color.opacity(highlighted ? 0.26 : 0.12), in: RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(color, lineWidth: highlighted ? 5 : 2.5))
        .scaleEffect(highlighted ? 1.05 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: highlighted)
    }
}

struct NumberCard: View {
    let n: Int
    let dots: Bool
    let glowing: Bool
    @State private var popped = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 14) {
            Text(String(n))
                .font(Theme.round(n >= 100 ? 96 : 120))
                .foregroundStyle(Theme.text)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .scaleEffect(popped ? 1 : 0.55)
            if dots { DotGrid(n: n, color: Theme.muted) }
        }
        .padding(.vertical, 26)
        .padding(.horizontal, 22)
        .frame(width: 260)
        .frame(minHeight: dots ? 280 : 220)
        .modifier(CardChrome(glowing: glowing))
        .onAppear {
            if reduceMotion { popped = true } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.5).delay(0.1)) { popped = true }
            }
        }
    }
}

/// The question for a four-choice card: "8 + 5", "? × ? = 24".
struct PromptCard: View {
    let prompt: String
    let glowing: Bool
    @State private var popped = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(prompt)
            .font(Theme.round(prompt.count > 7 ? 56 : 76))
            .foregroundStyle(Theme.text)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .scaleEffect(popped ? 1 : 0.55)
            .padding(.vertical, 40)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, minHeight: 200)
            .modifier(CardChrome(glowing: glowing))
            .onAppear {
                if reduceMotion { popped = true } else {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.5).delay(0.1)) { popped = true }
                }
            }
    }
}

struct CardChrome: ViewModifier {
    let glowing: Bool
    func body(content: Content) -> some View {
        content
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 34))
            .overlay(RoundedRectangle(cornerRadius: 34).stroke(glowing ? Theme.right : Theme.border, lineWidth: glowing ? 5 : 2))
            .shadow(color: glowing ? Theme.right.opacity(0.55) : .black.opacity(0.08), radius: glowing ? 22 : 10, y: glowing ? 0 : 6)
            .animation(.easeOut(duration: 0.2), value: glowing)
    }
}

/// The alligator mouth, built from two jaws. Before the answer it waits with a
/// "?"; on a right answer it swings open toward the bigger number and chomps,
/// becoming the > or < sign.
struct Mouth: View {
    let opensToward: Int?           // 0: left is bigger (">"), 1: right is bigger ("<")
    @State private var chomp = false

    var body: some View {
        ZStack {
            if let side = opensToward {
                Jaws()
                    .stroke(Theme.right, style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
                    .scaleEffect(x: side == 0 ? 1 : -1, y: chomp ? 0.7 : 1)
                    .accessibilityLabel(side == 0 ? "greater than" : "less than")
                    .transition(.scale.combined(with: .opacity))
            } else {
                Text("?")
                    .font(Theme.round(34))
                    .foregroundStyle(Theme.muted)
                    .frame(width: 56, height: 56)
                    .background(Theme.card, in: Circle())
                    .overlay(Circle().stroke(Theme.border, lineWidth: 2))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.45), value: opensToward)
        .onChange(of: opensToward) { _, v in
            guard v != nil else { chomp = false; return }
            withAnimation(.easeInOut(duration: 0.14).repeatCount(3, autoreverses: true)) { chomp = true }
        }
    }
}

/// ">" drawn as two jaws: open on the left, the point on the right.
struct Jaws: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + 6, y: r.minY + 6))
        p.addLine(to: CGPoint(x: r.maxX - 8, y: r.midY))
        p.addLine(to: CGPoint(x: r.minX + 6, y: r.maxY - 6))
        return p
    }
}

/// Dots in rows of five, like a ten-frame: countable, but they don't give the pairs away.
struct DotGrid: View {
    let n: Int
    let color: Color
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(26), spacing: 8), count: 5), spacing: 8) {
            ForEach(0..<n, id: \.self) { _ in Circle().fill(color).frame(width: 24, height: 24) }
        }
        .frame(width: 5 * 26 + 4 * 8)
        .accessibilityHidden(true)
    }
}

struct Shake: GeometryEffect {
    var amount: CGFloat
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * 4), y: 0))
    }
}

/// A ring of stars that flies out on a right answer.
struct Burst: View {
    let trigger: Int
    @State private var out = false

    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                let a = Double(i) / 12 * 2 * .pi
                Image(systemName: i % 3 == 0 ? "star.fill" : "sparkle")
                    .font(.system(size: i % 2 == 0 ? 26 : 18, weight: .bold))
                    .foregroundStyle(i % 2 == 0 ? Theme.star : Theme.right)
                    .offset(x: out ? cos(a) * 170 : 0, y: out ? sin(a) * 170 : 0)
                    .scaleEffect(out ? 1 : 0.2)
                    .opacity(out ? 0 : (trigger == 0 ? 0 : 1))
            }
        }
        .accessibilityHidden(true)
        .onChange(of: trigger) { _, _ in
            out = false
            withAnimation(.easeOut(duration: 0.8)) { out = true }
        }
    }
}

struct ProgressDots: View {
    let count: Int
    let index: Int
    let done: Bool
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                let filled = i < index || (i == index && done)
                Capsule()
                    .fill(filled ? Theme.sprout : (i == index ? Theme.sprout.opacity(0.35) : Theme.border))
                    .frame(height: 10)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement()
        .accessibilityLabel("Card \(min(index + 1, count)) of \(count)")
    }
}
