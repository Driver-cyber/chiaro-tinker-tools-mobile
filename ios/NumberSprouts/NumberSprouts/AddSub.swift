//  AddSub.swift — Add & Subtract: four choices.
//
//  Modes: Make 10 (8 + 5 → 8 + 2 + 3), Doubles (6 + 6, 6 + 7), Within 20 (add
//  and take away), Missing number (7 + ? = 12), Two-digit (no regrouping).
//  Wrong choices are the mistakes kids really make: off by one, off by ten,
//  the wrong operation.

import Foundation

enum AddSub {
    enum Kind { case makeTen, doubles, within20, missing, twoDigit }

    static func card<G: RandomNumberGenerator>(_ k: Kind, using rng: inout G) -> Card {
        switch k {
        case .makeTen:
            let big = Int.random(in: 6...9, using: &rng)
            let small = Int.random(in: (11 - big)...9, using: &rng)          // crosses 10: sum 11…18
            let (a, b) = Bool.random(using: &rng) ? (big, small) : (small, big)
            return add(a, b, near: [a + b - 1, a + b + 1, a + b - 10, a + b + 10, abs(a - b)],
                       sentence: makeTen(a, b), visual: .tenFrame(max(a, b), min(a, b)), using: &rng)
        case .doubles:
            let a = Int.random(in: 1...9, using: &rng)
            let b = Bool.random(using: &rng) ? a : a + 1
            let s = a == b ? "\(a) + \(a) is a double: \(2 * a)."
                           : "\(a) + \(b) is \(a) + \(a) + 1. Double \(a) is \(2 * a), plus 1 is \(a + b)."
            return add(a, b, near: [a + b - 1, a + b + 1, 2 * b, 2 * a, a + b + 10], sentence: s, visual: .doubles(a, b), using: &rng)
        case .within20:
            if Bool.random(using: &rng) {
                let a = Int.random(in: 1...19, using: &rng)
                let b = Int.random(in: 1...(20 - a), using: &rng)
                let crosses = a < 10 && b < 10 && a + b > 10
                let s = crosses ? makeTen(a, b) : "Start at \(max(a, b)) and count on \(min(a, b)): \(a + b)."
                return add(a, b, near: [a + b - 1, a + b + 1, a + b + 10, abs(a - b)], sentence: s,
                           visual: crosses ? .tenFrame(max(a, b), min(a, b)) : .hops(from: max(a, b), to: a + b), using: &rng)
            }
            let c = Int.random(in: 2...20, using: &rng)
            let d = Int.random(in: 1...(c - 1), using: &rng)
            return subtract(c, d, using: &rng)
        case .missing:
            let c = Int.random(in: 3...20, using: &rng)
            let a = Int.random(in: 1...(c - 1), using: &rng)
            let x = c - a
            let (opts, at) = Dealer.choices(answer: x, near: [x - 1, x + 1, c, c + a], using: &rng)
            return Card(face: .choice(prompt: "\(a) + ? = \(c)", options: opts), answer: at,
                        speech: "\(a) plus what makes \(c)?",
                        trick: Trick(headline: "\(a) + \(x) = \(c)",
                                     sentence: "Count up from \(a) to \(c): that's \(x) \(x == 1 ? "hop" : "hops").",
                                     visual: .hops(from: a, to: c)))
        case .twoDigit:
            if Bool.random(using: &rng) {
                let a = Int.random(in: 10...88, using: &rng)
                let bt = Int.random(in: 1...max(1, (99 - a) / 10), using: &rng)
                let bo = Int.random(in: 0...(9 - a % 10), using: &rng)       // ones don't carry
                let b = min(10 * bt + bo, 99 - a)
                guard b >= 10, (a % 10) + (b % 10) <= 9 else { return card(k, using: &rng) }
                let s = "Tens, then ones: \(a / 10 * 10) + \(b / 10 * 10) = \((a / 10 + b / 10) * 10), and \(a % 10) + \(b % 10) = \(a % 10 + b % 10). That's \(a + b)."
                return add(a, b, near: [a + b - 1, a + b + 1, a + b - 10, a + b + 10, abs(a - b)], sentence: s, visual: .placeValue(a, b), using: &rng)
            }
            let a = Int.random(in: 20...99, using: &rng)
            let bt = Int.random(in: 1...(a / 10), using: &rng)
            let bo = Int.random(in: 0...(a % 10), using: &rng)               // ones don't borrow
            let b = 10 * bt + bo
            guard a - b >= 0 else { return card(k, using: &rng) }
            let s = "Tens, then ones: \(a / 10 * 10) − \(bt * 10) = \((a / 10 - bt) * 10), and \(a % 10) − \(bo) = \(a % 10 - bo). That's \(a - b)."
            let (opts, at) = Dealer.choices(answer: a - b, near: [a - b - 1, a - b + 1, a - b + 10, a - b - 10, a + b], using: &rng)
            return Card(face: .choice(prompt: "\(a) − \(b)", options: opts), answer: at,
                        speech: "What is \(a) minus \(b)?",
                        trick: Trick(headline: "\(a) − \(b) = \(a - b)", sentence: s, visual: .placeValue(a, b)))
        }
    }

    static func makeTen(_ a: Int, _ b: Int) -> String {
        let big = max(a, b), small = min(a, b), need = 10 - big
        return "\(big) needs \(need) to make 10. Take \(need) from \(small), and 10 + \(small - need) = \(a + b)."
    }

    private static func add<G: RandomNumberGenerator>(_ a: Int, _ b: Int, near: [Int], sentence: String, visual: TrickVisual, using rng: inout G) -> Card {
        let (opts, at) = Dealer.choices(answer: a + b, near: near, using: &rng)
        return Card(face: .choice(prompt: "\(a) + \(b)", options: opts), answer: at,
                    speech: "What is \(a) plus \(b)?",
                    trick: Trick(headline: "\(a) + \(b) = \(a + b)", sentence: sentence, visual: visual))
    }

    private static func subtract<G: RandomNumberGenerator>(_ c: Int, _ d: Int, using rng: inout G) -> Card {
        let x = c - d
        let (opts, at) = Dealer.choices(answer: x, near: [x - 1, x + 1, c + d, x + 10], using: &rng)
        return Card(face: .choice(prompt: "\(c) − \(d)", options: opts), answer: at,
                    speech: "What is \(c) minus \(d)?",
                    trick: Trick(headline: "\(c) − \(d) = \(x)",
                                 sentence: "Count up from \(d) to \(c): that's \(x) \(x == 1 ? "hop" : "hops").",
                                 visual: .hops(from: d, to: c)))
    }

    static func round<G: RandomNumberGenerator>(_ k: Kind, count: Int = 10, using rng: inout G) -> [Card] {
        Dealer.round(count: count, using: &rng) { g in card(k, using: &g) }
    }
}
