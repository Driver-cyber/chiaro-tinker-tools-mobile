//  EvenOdd.swift — Even or Odd: drag the number into a basket.
//
//  Modes: Pair the dots (1–10, dots on the card), Numbers to 20, Last digit
//  (10–999). Up to 20 the trick is pairing the dots; past 20, the last digit.

import Foundation

enum EvenOdd {
    enum Kind { case dots, toTwenty, lastDigit }

    static func range(_ k: Kind) -> ClosedRange<Int> {
        switch k {
        case .dots: return 1...10
        case .toTwenty: return 1...20
        case .lastDigit: return 10...999
        }
    }

    static func word(_ even: Bool) -> String { even ? "even" : "odd" }

    static func card(_ n: Int, dots: Bool) -> Card {
        let even = n % 2 == 0
        return Card(face: .parity(n: n, dots: dots), answer: even ? 0 : 1,
                    speech: "Is \(n) even or odd?",
                    trick: Trick(headline: "\(n) is \(word(even))", sentence: trick(n), visual: n > 20 ? .lastDigit(n) : .pairs(n)))
    }

    /// The one-sentence trick.
    static func trick(_ n: Int) -> String {
        let even = n % 2 == 0
        if n > 20 {
            let last = n % 10
            return "Just look at the last digit: \(last). \(last) is \(word(last % 2 == 0)), so \(n) is \(word(even))!"
        }
        if n == 1 { return "1 dot can't make a pair, so it's left over. That's odd!" }
        let pairs = n / 2
        let pairWord = pairs == 1 ? "pair" : "pairs"
        return even ? "\(n) dots make \(pairs) \(pairWord), with none left over. That's even!"
                    : "\(n) dots make \(pairs) \(pairWord) and 1 left over. That's odd!"
    }

    /// A round: no number twice in a row, and at least three of each kind so
    /// guessing one basket every time can't win.
    static func round<G: RandomNumberGenerator>(_ k: Kind, count: Int = 10, using rng: inout G) -> [Card] {
        while true {
            let cards = Dealer.round(count: count, using: &rng) { g in card(Int.random(in: range(k), using: &g), dots: k == .dots) }
            let evens = cards.filter { $0.answer == 0 }.count
            let floor = min(3, count / 2)
            if evens >= floor && count - evens >= floor { return cards }
        }
    }
}
