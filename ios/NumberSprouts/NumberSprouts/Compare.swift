//  Compare.swift — Bigger or Smaller: tap the bigger number; the alligator chomps it.
//
//  Modes: Within 20, Tens first (to 100), Look-alikes (68 vs 86, 47 vs 45), and
//  To 1,000. The trick is place value: compare the biggest place first.

import Foundation

enum Compare {
    enum Kind { case within20, tensFirst, lookAlikes, toThousand }

    static func pair<G: RandomNumberGenerator>(_ k: Kind, using rng: inout G) -> (Int, Int) {
        switch k {
        case .within20:
            let a = Int.random(in: 0...20, using: &rng)
            var b = Int.random(in: 0...20, using: &rng)
            while b == a { b = Int.random(in: 0...20, using: &rng) }
            return (a, b)
        case .tensFirst:
            let a = Int.random(in: 10...99, using: &rng)
            var b = Int.random(in: 10...99, using: &rng)
            while b / 10 == a / 10 { b = Int.random(in: 10...99, using: &rng) }
            return (a, b)
        case .lookAlikes:
            let t = Int.random(in: 1...9, using: &rng)
            var o = Int.random(in: 1...9, using: &rng)
            while o == t { o = Int.random(in: 1...9, using: &rng) }
            if Bool.random(using: &rng) { return (10 * t + o, 10 * o + t) }          // swapped digits
            var o2 = Int.random(in: 0...9, using: &rng)                              // same tens, close ones
            while o2 == o { o2 = Int.random(in: 0...9, using: &rng) }
            return (10 * t + o, 10 * t + o2)
        case .toThousand:
            let a = Int.random(in: 100...999, using: &rng)
            var b: Int
            if Bool.random(using: &rng) {                                            // same hundreds half the time
                b = (a / 100) * 100 + Int.random(in: 0...99, using: &rng)
            } else {
                b = Int.random(in: 100...999, using: &rng)
            }
            while b == a { b = Int.random(in: 100...999, using: &rng) }
            return (a, b)
        }
    }

    static func card(_ a: Int, _ b: Int) -> Card {
        let sign = a > b ? ">" : "<"
        return Card(face: .compare(a, b), answer: a > b ? 0 : 1,
                    speech: "Which is bigger, \(a) or \(b)?",
                    trick: Trick(headline: "\(a) \(sign) \(b)", sentence: trick(a, b), visual: .placeValue(a, b)))
    }

    /// Biggest place first: hundreds, then tens, then ones.
    static func trick(_ a: Int, _ b: Int) -> String {
        let big = max(a, b), small = min(a, b)
        if big < 10 { return "\(big) comes after \(small) when you count, so \(big) is bigger." }
        let places: [(name: String, unit: Int)] = [("hundreds", 100), ("tens", 10), ("ones", 1)].filter { big >= $0.1 || $0.1 == 1 }
        var previous: String?
        for place in places {
            let x = big / place.unit % 10, y = small / place.unit % 10
            if x != y {
                let lead = previous.map { "Same \($0), so compare the \(place.name)" } ?? "Compare the \(place.name) first"
                return "\(lead): \(x) is more than \(y), so \(big) is bigger than \(small)."
            }
            previous = place.name
        }
        return "\(big) is bigger than \(small)."
    }

    static func round<G: RandomNumberGenerator>(_ k: Kind, count: Int = 10, using rng: inout G) -> [Card] {
        Dealer.round(count: count, using: &rng) { g in let (a, b) = pair(k, using: &g); return card(a, b) }
    }
}
