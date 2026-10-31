//  Round.swift — the card every deck deals, and one round of ten.
//
//  A Card is asked one of two ways: pick from a few choices (letters, words or
//  pictures), or spell a word with letter tiles. It knows its right answer,
//  what the speaker button says, and its trick. A round: a right answer
//  celebrates and moves on; a miss always opens the Trick card, then the same
//  card comes back for one retry; a second miss shows the trick again and
//  moves on. Stars count first-try answers only. No lives, no timer.

import Foundation
import UIKit

struct Card: Equatable {
    enum Face: Equatable {
        /// `listen`: the question is a word to hear (sight words), so the
        /// speaker button is the main event rather than a helper.
        case choice(picture: String, prompt: String, options: [String], listen: Bool)
        case spell(picture: String, word: String, tiles: [String])
    }
    let face: Face
    let answer: Int            // index of the right option; 0 for spell
    let speech: String         // what the speaker button says
    let trick: Trick
}

struct Trick: Equatable {
    let headline: String       // "dog starts with d"
    let sentence: String       // one short sentence
    let visual: TrickVisual
}

enum TrickVisual: Equatable {
    case letters(word: String, picture: String, lit: [Int])   // the word, some letters glowing
    case blend(letters: [String], word: String, picture: String)
    case rhyme(words: [Word], ending: String)                  // a family, endings glowing
    case syllables([String], picture: String)                  // one clap per part
    case compound(String, String, Word)                        // two words slide together
    case magicE(base: String, word: String)                    // the e jumps on
    case sentence(String, word: String, picture: String)       // the right word in its sentence
}

final class Round: ObservableObject {
    enum Phase: Equatable { case asking, right, missed, retrying, done }

    let modeID: String
    @Published private(set) var cards: [Card]
    @Published private(set) var index = 0
    @Published private(set) var phase: Phase = .asking
    @Published private(set) var firstTry = 0
    @Published private(set) var wrongPicks: Set<Int> = []    // dimmed on the retry
    private var retryUsed = false
    private var missedThis = false

    init(modeID: String, cards: [Card]) {
        self.modeID = modeID
        self.cards = cards
    }

    var card: Card { cards[index] }
    var count: Int { cards.count }

    /// 1–3 stars from first-try answers: 9–10 → 3, 6–8 → 2, else 1. Finishing always earns one.
    var stars: Int { Round.stars(firstTry: firstTry, of: count) }
    static func stars(firstTry: Int, of count: Int) -> Int {
        let share = Double(firstTry) / Double(max(count, 1))
        return share >= 0.9 ? 3 : share >= 0.6 ? 2 : 1
    }

    /// Returns whether the pick was right; ignored unless a card is waiting.
    /// A wrong spelling answers with -1.
    @discardableResult
    func answer(_ pick: Int) -> Bool {
        guard phase == .asking || phase == .retrying else { return false }
        if pick == card.answer {
            if !missedThis { firstTry += 1 }
            phase = .right
            Haptics.right()
            return true
        }
        missedThis = true
        if pick >= 0 { wrongPicks.insert(pick) }
        phase = .missed
        Haptics.miss()
        return false
    }

    /// "Got it" on the Trick card: one retry of the same card, then onward.
    func gotIt() {
        guard phase == .missed else { return }
        if retryUsed { advance() } else { retryUsed = true; phase = .retrying }
    }

    /// After the celebration, or after a second miss.
    func advance() {
        guard phase == .right || phase == .missed else { return }
        retryUsed = false
        missedThis = false
        wrongPicks = []
        if index + 1 < count { index += 1; phase = .asking } else { phase = .done }
    }
}

enum Dealer {
    /// Ten cards, never the same question twice in a row (choices get shuffled,
    /// so the headline is what tells two cards apart).
    static func round<G: RandomNumberGenerator>(count: Int = 10, using rng: inout G, _ deal: (inout G) -> Card) -> [Card] {
        var out: [Card] = []
        while out.count < count {
            let c = deal(&rng)
            if c.trick.headline != out.last?.trick.headline { out.append(c) }
        }
        return out
    }

    /// The answer plus up to `count - 1` distinct wrong choices from `near`
    /// (in order of preference, shuffled within), placed at a random spot.
    static func choices<G: RandomNumberGenerator>(answer: String, near: [String], count: Int = 4, using rng: inout G) -> (options: [String], index: Int) {
        var pool: [String] = []
        for o in near where o != answer && !pool.contains(o) { pool.append(o) }
        var picked = Array(pool.prefix(count - 1)).shuffled(using: &rng)
        let at = Int.random(in: 0...picked.count, using: &rng)
        picked.insert(answer, at: at)
        return (picked, at)
    }
}

enum Haptics {
    static func right() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func miss() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func tick() { UISelectionFeedbackGenerator().selectionChanged() }
}

/// A small seedable generator (SplitMix64), so tests are repeatable.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
