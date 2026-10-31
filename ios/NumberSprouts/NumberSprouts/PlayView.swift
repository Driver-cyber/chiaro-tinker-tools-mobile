//  PlayView.swift — the Even or Odd card loop.
//
//  A card flies in and its number pops. Drag it into the Even or Odd basket
//  (or tap a basket). Right: a green glow, a star burst, the card drops in.
//  Miss: a gentle shake, then the Trick card, then one retry. Ten cards, then
//  the stars.

import SwiftUI

struct PlayView: View {
    @EnvironmentObject private var model: AppModel
    let deck: String
    @State private var roundKey = 0

    var body: some View {
        RoundView(level: model.current?.level(deck) ?? .sprout) { roundKey += 1 }
            .id(roundKey)
    }
}

struct RoundView: View {
    @EnvironmentObject private var model: AppModel
    @StateObject var round: Round
    let again: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var drag: CGSize = .zero
    @State private var dropped = false
    @State private var hover: Bool?                 // over the Even (true) or Odd (false) basket
    @State private var baskets: [Bool: CGRect] = [:]
    @State private var cardFrame: CGRect = .zero
    @State private var shakes: CGFloat = 0
    @State private var bursts = 0

    init(level: Level, again: @escaping () -> Void) {
        _round = StateObject(wrappedValue: Round(level: level))
        self.again = again
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: 12)
            cardArea
            Text(hint)
                .font(Theme.round(18, .bold))
                .foregroundStyle(round.phase == .retrying ? Theme.odd : Theme.muted)
                .padding(.top, 18)
                .frame(minHeight: 30)
            Spacer(minLength: 12)
            HStack(spacing: 16) {
                basket(even: true)
                basket(even: false)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .coordinateSpace(name: "play")
        .onPreferenceChange(BasketFrames.self) { baskets = $0 }
        .overlay {
            if round.phase == .missed {
                TrickOverlay(card: round.card) { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { round.gotIt(); reset() } }
                    .transition(.opacity)
            }
        }
        .overlay {
            if round.phase == .done {
                SummaryView(stars: round.stars, firstTry: round.firstTry, count: round.count, again: again) {
                    model.screen = .home
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: round.phase)
        .onChange(of: round.phase) { _, phase in
            if phase == .right {
                bursts += 1
                Task {
                    try? await Task.sleep(for: .milliseconds(reduceMotion ? 700 : 950))
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { round.advance(); reset() }
                }
            }
            if phase == .done { model.recordRound(deck: EvenOdd.key(round.level), stars: round.stars) }
        }
        .onAppear { Haptics.tick() }
    }

    private var hint: String {
        switch round.phase {
        case .retrying: return "One more try!"
        case .right: return ["Yes!", "You got it!", "Nice!", "Super!"][round.index % 4]
        default: return "Drag the card into a basket"
        }
    }

    // MARK: top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button { model.screen = .home } label: {
                Image(systemName: "xmark").font(.system(size: 20, weight: .bold)).frame(width: 52, height: 52)
                    .background(Theme.card, in: Circle())
                    .overlay(Circle().stroke(Theme.border, lineWidth: 2))
            }
            .foregroundStyle(Theme.text)
            .accessibilityLabel("Stop playing")
            ProgressDots(count: round.count, index: round.index, done: round.phase == .right || round.phase == .done)
            Button { Speech.say(EvenOdd.question(round.card)) } label: {
                Image(systemName: "speaker.wave.2.fill").font(.system(size: 20, weight: .bold)).frame(width: 52, height: 52)
                    .background(Theme.card, in: Circle())
                    .overlay(Circle().stroke(Theme.border, lineWidth: 2))
            }
            .foregroundStyle(Theme.text)
            .accessibilityLabel("Read the question")
            PlayerBadge()
        }
        .padding(.top, 8)
    }

    // MARK: the card

    private var cardArea: some View {
        ZStack {
            NumberCard(card: round.card, glowing: round.phase == .right)
                .id(round.index)
                .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                .background(GeometryReader { g in Color.clear.onAppear { cardFrame = g.frame(in: .named("play")) } })
                .modifier(Shake(amount: reduceMotion ? 0 : 12, animatableData: shakes))
                .scaleEffect(dropped ? 0.25 : (drag == .zero ? 1 : 1.05))
                .opacity(dropped ? 0 : 1)
                .offset(drag)
                .gesture(dragGesture)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Number \(round.card.n)")
            if !reduceMotion { Burst(trigger: bursts) }
        }
    }

    private var answering: Bool { round.phase == .asking || round.phase == .retrying }

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
                if let even = basketAt(v.location) { choose(even) } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { drag = .zero }
                }
                hover = nil
            }
    }

    private func basketAt(_ p: CGPoint) -> Bool? {
        for (even, r) in baskets where r.insetBy(dx: -12, dy: -24).contains(p) { return even }
        return nil
    }

    private func choose(_ even: Bool) {
        guard answering else { return }
        if round.answer(even: even) {
            let target = baskets[even] ?? .zero
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                drag = CGSize(width: target.midX - cardFrame.midX, height: target.midY - cardFrame.midY)
                dropped = true
            }
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { drag = .zero }
            withAnimation(.linear(duration: 0.45)) { shakes += 1 }
        }
    }

    private func reset() {
        drag = .zero
        dropped = false
        hover = nil
    }

    // MARK: baskets

    private func basket(even: Bool) -> some View {
        Button { choose(even) } label: {
            BasketView(even: even, highlighted: hover == even)
        }
        .buttonStyle(.plain)
        .background(GeometryReader { g in Color.clear.preference(key: BasketFrames.self, value: [even: g.frame(in: .named("play"))]) })
        .accessibilityLabel(even ? "Even" : "Odd")
        .disabled(!answering)
    }
}

private struct BasketFrames: PreferenceKey {
    static var defaultValue: [Bool: CGRect] = [:]
    static func reduce(value: inout [Bool: CGRect], nextValue: () -> [Bool: CGRect]) {
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

// MARK: - The card

struct NumberCard: View {
    let card: EvenOddCard
    let glowing: Bool
    @State private var popped = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 14) {
            Text(String(card.n))
                .font(Theme.round(card.n >= 100 ? 96 : 120))
                .foregroundStyle(Theme.text)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .scaleEffect(popped ? 1 : 0.55)
            if card.showDots {
                DotGrid(n: card.n, color: Theme.muted)
            }
        }
        .padding(.vertical, 26)
        .padding(.horizontal, 22)
        .frame(width: 260)
        .frame(minHeight: card.showDots ? 280 : 220)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 34))
        .overlay(RoundedRectangle(cornerRadius: 34).stroke(glowing ? Theme.right : Theme.border, lineWidth: glowing ? 5 : 2))
        .shadow(color: glowing ? Theme.right.opacity(0.55) : .black.opacity(0.08), radius: glowing ? 22 : 10, y: glowing ? 0 : 6)
        .animation(.easeOut(duration: 0.2), value: glowing)
        .onAppear {
            if reduceMotion { popped = true } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.5).delay(0.1)) { popped = true }
            }
        }
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

/// A ring of stars that flies out from the card on a right answer.
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
        .allowsHitTesting(false)
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
