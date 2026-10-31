//  TrickCard.swift — after a miss, the trick that cracks it; after a round, the stars.
//
//  The Trick card shows the answer, one short sentence, and a small animation:
//  letters glowing, sounds sliding together, a rhyme family's endings lighting
//  up, one clap per syllable, two words joining, the magic e hopping on, or
//  the right word dropping into its sentence. 🔊 reads it.

import SwiftUI

struct TrickOverlay: View {
    let trick: Trick
    let readAloud: Bool
    let gotIt: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35).ignoresSafeArea().accessibilityHidden(true)
            VStack(spacing: 18) {
                HStack {
                    Text(trick.headline)
                        .font(Theme.round(30))
                        .foregroundStyle(Theme.text)
                        .minimumScaleFactor(0.5)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    CircleButton(symbol: "speaker.wave.2.fill", label: "Read the trick") { Reader.shared.say(trick.headline + ". " + trick.sentence) }
                }
                TrickVisualView(visual: trick.visual)
                    .frame(maxWidth: .infinity, minHeight: 120)
                Text(trick.sentence)
                    .font(Theme.round(20, .semibold))
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Got it", action: gotIt).buttonStyle(BigButtonStyle())
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 34))
            .padding(12)
            .transition(.move(edge: .bottom))
        }
        .onAppear { if readAloud { Reader.shared.say(trick.sentence) } }
    }
}

struct TrickVisualView: View {
    let visual: TrickVisual
    var body: some View {
        switch visual {
        case .letters(let word, let picture, let lit): LettersVisual(word: word, picture: picture, lit: lit)
        case .blend(let letters, let word, let picture): BlendVisual(letters: letters, word: word, picture: picture)
        case .rhyme(let words, let ending): RhymeVisual(words: words, ending: ending)
        case .syllables(let parts, let picture): SyllablesVisual(parts: parts, picture: picture)
        case .compound(let a, let b, let w): CompoundVisual(a: a, b: b, word: w)
        case .magicE(let base, let word): MagicEVisual(base: base, word: word)
        case .sentence(let s, let word, let picture): SentenceVisual(sentence: s, word: word, picture: picture)
        }
    }
}

/// Starts false; flips true shortly after appearing (at once with Reduce Motion).
private struct Reveal: ViewModifier {
    @Binding var on: Bool
    var delay: Double = 0.4
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func body(content: Content) -> some View {
        content.onAppear {
            if reduceMotion { on = true; return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) { on = true }
        }
    }
}

/// Letter tiles for a word; some glow.
struct LetterTiles: View {
    let word: String
    let lit: Set<Int>
    var size: CGFloat = 44
    var color: Color = Theme.even

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(word.enumerated()), id: \.offset) { k, ch in
                let on = lit.contains(k)
                Text(String(ch))
                    .font(Theme.round(size))
                    .foregroundStyle(on ? Theme.onColor : Theme.text)
                    .frame(minWidth: size * 0.8)
                    .padding(.horizontal, 4)
                    .background(on ? color : Color.clear, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

struct LettersVisual: View {
    let word: String
    let picture: String
    let lit: [Int]
    @State private var on = false
    var body: some View {
        HStack(spacing: 16) {
            if !picture.isEmpty { Text(picture).font(.system(size: 64)) }
            LetterTiles(word: word, lit: on ? Set(lit) : [], size: word.count > 5 ? 40 : 52)
                .minimumScaleFactor(0.5)
        }
        .modifier(Reveal(on: $on))
        .accessibilityElement()
        .accessibilityLabel(word)
    }
}

/// Separate letter sounds slide together into the word, then the picture pops in.
struct BlendVisual: View {
    let letters: [String]
    let word: String
    let picture: String
    @State private var joined = false
    var body: some View {
        HStack(spacing: joined ? 0 : 22) {
            ForEach(Array(letters.enumerated()), id: \.offset) { _, l in
                Text(l).font(Theme.round(52)).foregroundStyle(joined ? Theme.even : Theme.text)
            }
            if joined { Text(" " + picture).font(.system(size: 56)).transition(.scale) }
        }
        .modifier(Reveal(on: $joined, delay: 0.7))
        .accessibilityElement()
        .accessibilityLabel(letters.joined(separator: ", ") + " makes " + word)
    }
}

/// A family of words stacked, endings glowing. With no shared ending (not a
/// rhyme), each word's own ending glows instead.
struct RhymeVisual: View {
    let words: [Word]
    let ending: String
    @State private var on = false
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ForEach(words, id: \.self) { w in
                let end = ending.isEmpty ? (Rhymes.ending(of: w) ?? "") : ending
                HStack(spacing: 10) {
                    Text(w.pic).font(.system(size: 34))
                    LetterTiles(word: w.text, lit: on ? Set((w.text.count - end.count)..<w.text.count) : [], size: 34,
                                color: ending.isEmpty && w != words.first ? Theme.odd : Theme.even)
                }
            }
        }
        .modifier(Reveal(on: $on))
        .accessibilityElement()
        .accessibilityLabel(words.map(\.text).joined(separator: ", "))
    }
}

/// One chip per syllable, each arriving with a clap.
struct SyllablesVisual: View {
    let parts: [String]
    let picture: String
    @State private var shown = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        VStack(spacing: 10) {
            Text(picture).font(.system(size: 52))
            HStack(spacing: 8) {
                ForEach(Array(parts.enumerated()), id: \.offset) { k, p in
                    VStack(spacing: 4) {
                        Text(k < shown ? "👏" : " ").font(.system(size: 26))
                        Text(p).font(Theme.round(30)).foregroundStyle(k < shown ? Theme.onColor : Theme.muted)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(k < shown ? Theme.even : Theme.bg, in: Capsule())
                    }
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(parts.joined(separator: ", ") + ": \(parts.count) claps")
        .task {
            if reduceMotion { shown = parts.count; return }
            for k in 1...parts.count {
                try? await Task.sleep(for: .milliseconds(k == 1 ? 450 : 550))
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { shown = k }
                Haptics.tick()
            }
        }
    }
}

/// Two words slide together and become one.
struct CompoundVisual: View {
    let a: String
    let b: String
    let word: Word
    @State private var joined = false
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: joined ? 0 : 18) {
                Text(a).font(Theme.round(42)).foregroundStyle(Theme.even)
                if !joined { Text("+").font(Theme.round(36)).foregroundStyle(Theme.muted).transition(.opacity) }
                Text(b).font(Theme.round(42)).foregroundStyle(Theme.odd)
            }
            .minimumScaleFactor(0.5)
            Text(word.pic).font(.system(size: 54)).scaleEffect(joined ? 1 : 0.1).opacity(joined ? 1 : 0)
        }
        .modifier(Reveal(on: $joined, delay: 0.6))
        .accessibilityElement()
        .accessibilityLabel("\(a) and \(b) make \(word.text)")
    }
}

/// The e hops onto the end; the vowel lights up and says its name.
struct MagicEVisual: View {
    let base: String
    let word: String
    @State private var on = false
    var body: some View {
        let vowel = base.firstIndex { "aeiou".contains($0) }.map { base.distance(from: base.startIndex, to: $0) } ?? 0
        HStack(spacing: 4) {
            LetterTiles(word: base, lit: on ? [vowel] : [], size: 52, color: Theme.odd)
            Text("e")
                .font(Theme.round(52))
                .foregroundStyle(Theme.star)
                .offset(y: on ? 0 : -60)
                .opacity(on ? 1 : 0)
                .overlay(alignment: .top) { Text("✨").font(.system(size: 20)).offset(y: -26).opacity(on ? 1 : 0) }
        }
        .modifier(Reveal(on: $on, delay: 0.5))
        .accessibilityElement()
        .accessibilityLabel("\(base) plus e makes \(word)")
    }
}

/// The sentence with the right word dropped into the blank.
struct SentenceVisual: View {
    let sentence: String
    let word: String
    let picture: String
    @State private var on = false
    var body: some View {
        let parts = sentence.components(separatedBy: "___")
        VStack(spacing: 10) {
            Text(picture).font(.system(size: 48))
            (Text(parts.first ?? "") + Text(on ? word : "___").foregroundColor(on ? Theme.even : Theme.muted).bold() + Text(parts.count > 1 ? parts[1] : ""))
                .font(Theme.round(26, .semibold))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
        }
        .modifier(Reveal(on: $on, delay: 0.5))
        .accessibilityElement()
        .accessibilityLabel(sentence.replacingOccurrences(of: "___", with: word))
    }
}

// MARK: - End of round

struct SummaryView: View {
    let stars: Int
    let firstTry: Int
    let count: Int
    let again: () -> Void
    let done: () -> Void
    @State private var shown = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 26) {
                Text("Round done!")
                    .font(Theme.round(40))
                    .foregroundStyle(Theme.text)
                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < shown ? "star.fill" : "star")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundStyle(i < shown ? Theme.star : Theme.border)
                            .scaleEffect(i < shown ? 1 : 0.8)
                            .rotationEffect(.degrees(i < shown ? 0 : -20))
                    }
                }
                .accessibilityElement()
                .accessibilityLabel("\(stars) of 3 stars")
                Text("\(firstTry) of \(count) on the first try")
                    .font(Theme.round(22, .bold))
                    .foregroundStyle(Theme.muted)
                VStack(spacing: 12) {
                    Button(action: again) { Label("Play again", systemImage: "arrow.clockwise") }
                        .buttonStyle(BigButtonStyle())
                    Button("Done", action: done).buttonStyle(SoftButtonStyle())
                }
                .padding(.top, 10)
            }
            .padding(24)
        }
        .task {
            if reduceMotion { shown = stars; return }
            for i in 1...stars {
                try? await Task.sleep(for: .milliseconds(i == 1 ? 350 : 380))
                withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) { shown = i }
                Haptics.tick()
            }
        }
    }
}
