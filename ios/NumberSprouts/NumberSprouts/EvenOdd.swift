//  EvenOdd.swift — the Even or Odd deck: pure logic, no UI.
//
//  Makes a round of cards for a level, checks an answer, and words the trick.
//  Randomness comes in through a generator so tests can seed it.

import Foundation

/// Sprout → Grow → Stretch. Every deck has the same three levels.
enum Level: String, Codable, CaseIterable, Identifiable {
    case sprout, grow, stretch
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .sprout: return "leaf.fill"
        case .grow: return "tree.fill"
        case .stretch: return "sparkles"
        }
    }
}

struct EvenOddCard: Equatable {
    let n: Int
    let showDots: Bool
    var isEven: Bool { n % 2 == 0 }
}

enum EvenOdd {
    static let deckID = "evenodd"
    /// Stars are kept per mode: "evenodd.sprout", "evenodd.grow", …
    static func key(_ level: Level) -> String { "\(deckID).\(level.rawValue)" }
    static let roundLength = 10

    /// The numbers each level draws from.
    static func range(_ level: Level) -> ClosedRange<Int> {
        switch level {
        case .sprout: return 1...10
        case .grow: return 1...20
        case .stretch: return 10...999
        }
    }

    /// Sprout shows the dots on the card; the others ask from the numeral alone.
    static func showsDots(_ level: Level) -> Bool { level == .sprout }

    /// A round: no number twice in a row, and at least three of each kind so
    /// guessing one basket every time can't win.
    static func round<G: RandomNumberGenerator>(_ level: Level, count: Int = roundLength, using rng: inout G) -> [EvenOddCard] {
        let r = range(level)
        var cards: [EvenOddCard] = []
        while true {
            cards = []
            var prev: Int? = nil
            for _ in 0..<count {
                var n = Int.random(in: r, using: &rng)
                while n == prev { n = Int.random(in: r, using: &rng) }
                cards.append(EvenOddCard(n: n, showDots: showsDots(level)))
                prev = n
            }
            let evens = cards.filter(\.isEven).count
            let floor = min(3, count / 2)
            if evens >= floor && count - evens >= floor { return cards }
        }
    }

    static func round(_ level: Level, count: Int = roundLength) -> [EvenOddCard] {
        var g = SystemRandomNumberGenerator()
        return round(level, count: count, using: &g)
    }

    static func word(_ even: Bool) -> String { even ? "even" : "odd" }

    /// Past 20, too many dots to count: the trick is the last digit instead.
    static func usesLastDigit(_ card: EvenOddCard) -> Bool { card.n > 20 }

    /// The one-sentence trick shown on the Trick card.
    static func trick(_ card: EvenOddCard) -> String {
        let n = card.n
        if usesLastDigit(card) {
            let last = n % 10
            return "Just look at the last digit: \(last). \(last) is \(word(last % 2 == 0)), so \(n) is \(word(card.isEven))!"
        }
        if n == 1 { return "1 dot can't make a pair, so it's left over. That's odd!" }
        let pairs = n / 2
        let pairWord = pairs == 1 ? "pair" : "pairs"
        if card.isEven {
            return "\(n) dots make \(pairs) \(pairWord), with none left over. That's even!"
        }
        return "\(n) dots make \(pairs) \(pairWord) and 1 left over. That's odd!"
    }

    /// Modes are named by the skill they practise, so a kid can go straight to
    /// the one they need instead of wading through easy cards.
    static func modeTitle(_ level: Level) -> String {
        switch level {
        case .sprout: return "Pair the dots"
        case .grow: return "Numbers to 20"
        case .stretch: return "Last digit"
        }
    }

    static func modeDetail(_ level: Level) -> String {
        switch level {
        case .sprout: return "1 to 10, with dots to pair up"
        case .grow: return "1 to 20, just the number"
        case .stretch: return "Big numbers: look at the last digit"
        }
    }

    /// What the read-aloud button says.
    static func question(_ card: EvenOddCard) -> String { "Is \(card.n) even or odd?" }
}

/// A small seedable generator (SplitMix64), so tests and previews are repeatable.
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
