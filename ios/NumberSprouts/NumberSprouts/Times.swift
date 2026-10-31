//  Times.swift — Times Tables: four choices.
//
//  Modes: ×2 ×5 ×10, ×3 ×4, ×9 tricks, Mixed (1–10), and What times what?
//  Tricks: ×10 adds a zero, ×5 ends in 0 or 5, ×2 is a double, ×4 is double
//  double, ×3 is a double plus one more, ×9's digits add to 9 (and the finger
//  trick). Wrong choices are neighbouring facts and the added-instead mistake.

import Foundation

enum Times {
    enum Kind { case twoFiveTen, threeFour, nines, mixed, whatTimesWhat }

    static func card<G: RandomNumberGenerator>(_ k: Kind, using rng: inout G) -> Card {
        switch k {
        case .twoFiveTen: return fact([2, 5, 10].randomElement(using: &rng)!, Int.random(in: 1...10, using: &rng), using: &rng)
        case .threeFour: return fact([3, 4].randomElement(using: &rng)!, Int.random(in: 1...10, using: &rng), using: &rng)
        case .nines: return fact(9, Int.random(in: 1...10, using: &rng), using: &rng)
        case .mixed: return fact(Int.random(in: 1...10, using: &rng), Int.random(in: 1...10, using: &rng), using: &rng)
        case .whatTimesWhat: return whatTimesWhat(using: &rng)
        }
    }

    /// f × b, asked in either order.
    static func fact<G: RandomNumberGenerator>(_ f: Int, _ b: Int, using rng: inout G) -> Card {
        let (x, y) = Bool.random(using: &rng) ? (f, b) : (b, f)
        let p = x * y
        let near = [x * (y + 1), x * (y - 1), (x + 1) * y, (x - 1) * y, x + y, p + 1, p - 1]
        let (opts, at) = Dealer.choices(answer: p, near: near.filter { $0 > 0 }, using: &rng)
        return Card(face: .choice(prompt: "\(x) × \(y)", options: opts), answer: at,
                    speech: "What is \(x) times \(y)?",
                    trick: Trick(headline: "\(x) × \(y) = \(p)", sentence: trick(x, y),
                                 visual: (x == 9 || y == 9) && x != y ? .nines(x == 9 ? y : x) : .array(min(x, y), max(x, y))))
    }

    /// The trick for a fact, using the friendliest factor it has.
    static func trick(_ x: Int, _ y: Int) -> String {
        let p = x * y
        func other(_ f: Int) -> Int { x == f ? y : x }
        if x == 10 || y == 10 { let n = other(10); return "Times 10 adds a zero: \(n) becomes \(p)." }
        if x == 1 || y == 1 { return "Times 1 keeps a number the same: \(p)." }
        if x == 5 || y == 5 {
            let n = other(5)
            let counts = (1...n).map { String($0 * 5) }.joined(separator: ", ")
            return "Count by fives \(n) times: \(counts). Times 5 always ends in 0 or 5."
        }
        if x == 2 || y == 2 { let n = other(2); return "Times 2 is a double: \(n) + \(n) = \(p)." }
        if x == 9 || y == 9 {
            let n = other(9)
            return "Times 9: the first digit is one less than \(n), and the digits add to 9. \(n - 1) and \(10 - n) make \(p)."
        }
        if x == 4 || y == 4 { let n = other(4); return "Times 4 is double, then double again: \(n) → \(2 * n) → \(p)." }
        if x == 3 || y == 3 { let n = other(3); return "Times 3 is a double plus one more: \(2 * n) + \(n) = \(p)." }
        return "Use one you know: \(x) × \(y - 1) = \(x * (y - 1)), plus one more \(x) is \(p)."
    }

    /// "? × ? = 24": pick the pair that makes it. Only one choice is right.
    static func whatTimesWhat<G: RandomNumberGenerator>(using rng: inout G) -> Card {
        let a = Int.random(in: 2...10, using: &rng)
        let b = Int.random(in: 2...10, using: &rng)
        let p = a * b
        var wrong: [(Int, Int)] = []
        let neighbours: [(Int, Int)] = [(a, b + 1), (a + 1, b), (a, b - 1), (a - 1, b), (a + 1, b + 1), (a - 1, b + 1), (a + 2, b)]
        for pair in neighbours.shuffled(using: &rng) {
            let (x, y) = pair
            let inTable = (1...10).contains(x) && (1...10).contains(y)
            let seen = wrong.contains { $0 == (x, y) || $0 == (y, x) }
            if inTable && x * y != p && !seen { wrong.append(pair) }
        }
        if wrong.count < 3 {                                  // at the edges of the table: the closest other products
            var others: [(Int, Int)] = []
            for x in 2...10 {
                for y in x...10 where x * y != p { others.append((x, y)) }
            }
            others.sort { (l: (Int, Int), r: (Int, Int)) -> Bool in abs(l.0 * l.1 - p) < abs(r.0 * r.1 - p) }
            for o in others where wrong.count < 3 {
                let seen = wrong.contains { $0 == o || $0 == (o.1, o.0) }
                if !seen { wrong.append(o) }
            }
        }
        var options = Array(wrong.prefix(3)).map { "\($0.0) × \($0.1)" }
        let at = Int.random(in: 0...3, using: &rng)
        options.insert("\(a) × \(b)", at: at)
        return Card(face: .choice(prompt: "? × ? = \(p)", options: options), answer: at,
                    speech: "What times what makes \(p)?",
                    trick: Trick(headline: "\(a) × \(b) = \(p)", sentence: "\(a) rows of \(b) make \(p).", visual: .array(a, b)))
    }

    static func round<G: RandomNumberGenerator>(_ k: Kind, count: Int = 10, using rng: inout G) -> [Card] {
        Dealer.round(count: count, using: &rng) { g in card(k, using: &g) }
    }
}
