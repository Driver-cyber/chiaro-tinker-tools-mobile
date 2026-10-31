//  Round.swift — the card every deck deals, and one round of ten.
//
//  A Card knows how it's asked (baskets, two sides, or four choices), which
//  answer is right, what to say aloud, and its trick. A round: a right answer
//  celebrates and moves on; a miss always opens the Trick card, then the same
//  card comes back for one retry; a second miss shows the trick again and
//  moves on. Stars count first-try answers only. No lives, no timer.

import Foundation
import UIKit

struct Card: Equatable {
    enum Face: Equatable {
        case parity(n: Int, dots: Bool)          // drag into Even (0) or Odd (1)
        case compare(Int, Int)                   // tap the bigger: left (0) or right (1)
        case choice(prompt: String, options: [String])   // pick one of four
    }
    let face: Face
    let answer: Int
    let speech: String
    let trick: Trick
}

struct Trick: Equatable {
    let headline: String       // "8 + 5 = 13"
    let sentence: String       // one short sentence, read aloud too
    let visual: TrickVisual
}

enum TrickVisual: Equatable {
    case pairs(Int)                    // dots slide into pairs
    case lastDigit(Int)                // the last digit lights up
    case placeValue(Int, Int)          // hundreds, tens and ones blocks for two numbers
    case tenFrame(Int, Int)            // fill a ten, then the rest
    case doubles(Int, Int)             // two rows that match, plus one
    case hops(from: Int, to: Int)      // count up along a number line
    case array(Int, Int)               // rows × columns of dots, filling row by row
    case nines(Int)                    // ten fingers, one folded down
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
        wrongPicks.insert(pick)
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

/// Deal a round from a one-card dealer: ten cards, never the same card twice in a row.
enum Dealer {
    static func round<G: RandomNumberGenerator>(count: Int = 10, using rng: inout G, _ deal: (inout G) -> Card) -> [Card] {
        var out: [Card] = []
        while out.count < count {
            let c = deal(&rng)
            if c.face != out.last?.face { out.append(c) }
        }
        return out
    }

    /// Four choices: the answer plus three plausible wrong ones (off by one, off
    /// by ten, the wrong operation, the neighbouring fact), never negative and
    /// never repeated. Returns the options as text and where the answer landed.
    static func choices<G: RandomNumberGenerator>(answer: Int, near: [Int], using rng: inout G) -> (options: [String], index: Int) {
        var pool: [Int] = []
        for n in near.shuffled(using: &rng) where n >= 0 && n != answer && !pool.contains(n) { pool.append(n) }
        var step = 1
        while pool.count < 3 {                               // pad with close numbers if the plausible ones ran out
            for n in [answer + step, answer - step] where n >= 0 && n != answer && !pool.contains(n) && pool.count < 3 { pool.append(n) }
            step += 1
        }
        var nums = Array(pool.prefix(3))
        let at = Int.random(in: 0...3, using: &rng)
        nums.insert(answer, at: at)
        return (nums.map(String.init), at)
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
