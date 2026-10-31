//  PlayView.swift — the card loop, for every card deck.
//
//  A card flies in and pops. Answer it by picking (a letter, a word or a
//  picture) or by spelling with letter tiles. Right: a green glow and a star
//  burst. Miss: a gentle shake, then the Trick card, then one retry. The 🔊
//  button reads the card; with "Read aloud" on, cards read themselves.

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
            case .storyBuild:
                StoryBuilder()
            case .storyBook:
                StoryBook()
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

    @State private var shakes: CGFloat = 0
    @State private var bursts = 0
    @State private var typed: [Int] = []          // indices into the spelling tiles

    init(mode: Mode, cards: [Card], again: @escaping () -> Void) {
        _round = StateObject(wrappedValue: Round(modeID: mode.id, cards: cards))
        self.mode = mode
        self.again = again
    }

    private var answering: Bool { round.phase == .asking || round.phase == .retrying }
    private var answered: Bool { round.phase == .right }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(count: round.count, index: round.index, done: round.phase == .right || round.phase == .done) {
                Reader.shared.say(round.card.speech)
            } close: { Reader.shared.stop(); model.screen = .home }
            switch round.card.face {
            case .choice(let picture, let prompt, let options, let listen): choiceArea(picture, prompt, options, listen)
            case .spell(let picture, let word, let tiles): spellArea(picture, word, tiles)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .overlay { if !reduceMotion { Burst(trigger: bursts).allowsHitTesting(false) } }
        .overlay {
            if round.phase == .missed {
                TrickOverlay(trick: round.card.trick, readAloud: model.readAloud) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { round.gotIt(); typed = [] }
                }
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
        .onAppear { autoRead() }
        .onChange(of: round.index) { _, _ in autoRead() }
        .onChange(of: round.phase) { _, phase in
            if phase == .right {
                bursts += 1
                Task {
                    try? await Task.sleep(for: .milliseconds(reduceMotion ? 700 : 1000))
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { round.advance(); typed = [] }
                }
            }
            if phase == .done { model.recordRound(mode: mode.id, stars: round.stars) }
        }
    }

    private func autoRead() {
        guard model.readAloud, round.phase != .done else { return }
        Reader.shared.say(round.card.speech)
    }

    private var hint: String {
        switch round.phase {
        case .retrying: return "One more try!"
        case .right: return ["Yes!", "You got it!", "Nice!", "Super!"][round.index % 4]
        default:
            if case .spell = round.card.face { return "Tap the letters in order" }
            return "Pick the answer"
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
        if !round.answer(i) { withAnimation(.linear(duration: 0.45)) { shakes += 1 } }
    }

    // MARK: Choices

    private func choiceArea(_ picture: String, _ prompt: String, _ options: [String], _ listen: Bool) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            PromptCard(picture: picture, prompt: prompt, listen: listen, glowing: answered) { Reader.shared.say(round.card.speech) }
                .id(round.index)
                .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                .modifier(Shake(amount: reduceMotion ? 0 : 10, animatableData: shakes))
            hintView.padding(.top, 14)
            Spacer(minLength: 12)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(Array(options.enumerated()), id: \.offset) { i, text in choiceButton(i, text) }
            }
        }
    }

    private func choiceButton(_ i: Int, _ text: String) -> some View {
        let right = answered && i == round.card.answer
        let wrong = round.wrongPicks.contains(i)
        let pictureOnly = text.unicodeScalars.allSatisfy { $0.properties.isEmojiPresentation || $0.properties.isEmoji || $0.value == 0xFE0F || $0.value == 0x20E3 }
        return Button { pick(i) } label: {
            Text(text)
                .font(pictureOnly ? .system(size: 56) : Theme.round(text.count <= 2 ? 44 : (text.count <= 6 ? 32 : 24)))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(right ? Theme.onColor : Theme.text)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: 88)
                .background(right ? Theme.right : Theme.card, in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(wrong ? Theme.odd : Theme.border, lineWidth: 2))
                .opacity(wrong && round.phase == .retrying ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(!answering || (wrong && round.phase == .retrying))
        .accessibilityLabel(text)
    }

    // MARK: Spelling

    private func spellArea(_ picture: String, _ word: String, _ tiles: [String]) -> some View {
        let letters = word.map(String.init)
        return VStack(spacing: 0) {
            Spacer(minLength: 12)
            VStack(spacing: 16) {
                Text(picture).font(.system(size: 96)).accessibilityLabel("Spell the word for this picture")
                HStack(spacing: 10) {
                    ForEach(0..<letters.count, id: \.self) { k in
                        let t = k < typed.count ? tiles[typed[k]] : ""
                        Text(t)
                            .font(Theme.round(40))
                            .foregroundStyle(Theme.text)
                            .frame(width: 58, height: 68)
                            .background(Theme.bg, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(k == typed.count ? Theme.sprout : Theme.border, lineWidth: k == typed.count ? 3 : 2))
                    }
                }
                .accessibilityElement()
                .accessibilityLabel("Spelled so far: \(typed.map { tiles[$0] }.joined())")
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .modifier(CardChrome(glowing: answered))
            .id(round.index)
            .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            .modifier(Shake(amount: reduceMotion ? 0 : 10, animatableData: shakes))
            hintView.padding(.top, 14)
            Spacer(minLength: 12)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(Array(tiles.enumerated()), id: \.offset) { i, t in
                    let used = typed.contains(i)
                    Button { tap(i, letters: letters, tiles: tiles) } label: {
                        Text(t)
                            .font(Theme.round(38))
                            .foregroundStyle(Theme.text)
                            .frame(maxWidth: .infinity, minHeight: 72)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 2))
                            .opacity(used ? 0.25 : 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(used || !answering)
                    .accessibilityLabel(t)
                }
            }
            Button { if !typed.isEmpty { typed.removeLast(); Haptics.tick() } } label: { Label("Back", systemImage: "delete.left") }
                .buttonStyle(SoftButtonStyle())
                .padding(.top, 12)
                .disabled(typed.isEmpty || !answering)
        }
    }

    private func tap(_ i: Int, letters: [String], tiles: [String]) {
        guard answering, typed.count < letters.count else { return }
        typed.append(i)
        Haptics.tick()
        guard typed.count == letters.count else { return }
        let right = typed.map { tiles[$0] } == letters
        if !round.answer(right ? 0 : -1) {
            withAnimation(.linear(duration: 0.45)) { shakes += 1 }
        }
    }
}

// MARK: - Pieces

struct TopBar: View {
    let count: Int
    let index: Int
    let done: Bool
    let read: () -> Void
    let close: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CircleButton(symbol: "xmark", label: "Stop playing", action: close)
            ProgressDots(count: count, index: index, done: done)
            CircleButton(symbol: "speaker.wave.2.fill", label: "Read the card", action: read)
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

/// The question: a picture, the prompt, and for listening cards a big 🔊.
struct PromptCard: View {
    let picture: String
    let prompt: String
    let listen: Bool
    let glowing: Bool
    let read: () -> Void
    @State private var popped = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 12) {
            if listen {
                Button(action: read) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 54, weight: .bold))
                        .foregroundStyle(Theme.onColor)
                        .frame(width: 120, height: 120)
                        .background(Theme.even, in: Circle())
                }
                .accessibilityLabel("Hear the word")
            } else if !picture.isEmpty {
                Text(picture).font(.system(size: 88)).accessibilityHidden(true)
            }
            Text(prompt)
                .font(Theme.round(listen ? 22 : (prompt.count > 14 ? 30 : 48)))
                .foregroundStyle(listen ? Theme.muted : Theme.text)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .lineLimit(2)
        }
        .scaleEffect(popped ? 1 : 0.6)
        .padding(.vertical, 26)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, minHeight: 230)
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
