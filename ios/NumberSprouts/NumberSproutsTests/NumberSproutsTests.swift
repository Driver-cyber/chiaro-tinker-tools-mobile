//  NumberSproutsTests.swift — the Even or Odd engine, a round's rules, and profiles.

import XCTest
@testable import NumberSprouts

final class EvenOddTests: XCTestCase {
    func testRoundsStayInRangeAndAreFair() {
        for level in Level.allCases {
            for seed in 1...300 {
                var g = SeededGenerator(seed: UInt64(seed))
                let cards = EvenOdd.round(level, using: &g)
                XCTAssertEqual(cards.count, 10)
                XCTAssertTrue(cards.allSatisfy { EvenOdd.range(level).contains($0.n) }, "\(level) seed \(seed)")
                XCTAssertTrue(cards.allSatisfy { $0.showDots == (level == .sprout) })
                for k in 1..<cards.count { XCTAssertNotEqual(cards[k].n, cards[k - 1].n, "no number twice in a row") }
                let evens = cards.filter(\.isEven).count
                XCTAssertGreaterThanOrEqual(evens, 3); XCTAssertGreaterThanOrEqual(10 - evens, 3)
            }
        }
    }

    func testStretchReachesTwoAndThreeDigits() {
        var g = SeededGenerator(seed: 7)
        let ns = (0..<40).flatMap { _ in EvenOdd.round(.stretch, using: &g) }.map(\.n)
        XCTAssertTrue(ns.contains { $0 >= 100 }); XCTAssertTrue(ns.contains { (10...99).contains($0) })
    }

    func testParityAndTricks() {
        for n in 1...999 {
            let c = EvenOddCard(n: n, showDots: n <= 10)
            XCTAssertEqual(c.isEven, n % 2 == 0)
            let t = EvenOdd.trick(c)
            XCTAssertTrue(t.hasSuffix(c.isEven ? "even!" : "odd!"), "\(n): \(t)")
            if n > 20 { XCTAssertTrue(t.contains("last digit: \(n % 10)")) } else if n > 1 { XCTAssertTrue(t.contains("\(n / 2) pair")) }
        }
        XCTAssertEqual(EvenOdd.trick(EvenOddCard(n: 7, showDots: true)), "7 dots make 3 pairs and 1 left over. That's odd!")
        XCTAssertEqual(EvenOdd.trick(EvenOddCard(n: 2, showDots: true)), "2 dots make 1 pair, with none left over. That's even!")
        XCTAssertEqual(EvenOdd.trick(EvenOddCard(n: 1, showDots: true)), "1 dot can't make a pair, so it's left over. That's odd!")
    }
}

final class RoundTests: XCTestCase {
    private func cards(_ ns: [Int]) -> [EvenOddCard] { ns.map { EvenOddCard(n: $0, showDots: false) } }

    func testRightAnswersScoreAndAdvance() {
        let r = Round(level: .grow, cards: cards([2, 3]))
        XCTAssertTrue(r.answer(even: true)); XCTAssertEqual(r.phase, .right); XCTAssertEqual(r.firstTry, 1)
        r.advance(); XCTAssertEqual(r.index, 1); XCTAssertEqual(r.phase, .asking)
        XCTAssertTrue(r.answer(even: false)); r.advance()
        XCTAssertEqual(r.phase, .done); XCTAssertEqual(r.firstTry, 2)
    }

    func testAMissShowsTheTrickThenOneRetry() {
        let r = Round(level: .grow, cards: cards([4, 5]))
        XCTAssertFalse(r.answer(even: false)); XCTAssertEqual(r.phase, .missed)
        r.gotIt(); XCTAssertEqual(r.phase, .retrying); XCTAssertEqual(r.index, 0, "same card again")
        XCTAssertTrue(r.answer(even: true)); XCTAssertEqual(r.firstTry, 0, "a retry isn't a first try")
        r.advance(); XCTAssertEqual(r.index, 1)
        // second miss on the retry: trick again, then onward
        r.answer(even: true); r.gotIt(); r.answer(even: true)
        XCTAssertEqual(r.phase, .missed); r.gotIt()
        XCTAssertEqual(r.phase, .done)
    }

    func testAnswersAreIgnoredOutsideAsking() {
        let r = Round(level: .grow, cards: cards([4, 6]))
        r.answer(even: true)
        XCTAssertFalse(r.answer(even: true), "no double-scoring while celebrating")
        XCTAssertEqual(r.firstTry, 1)
    }

    func testStars() {
        XCTAssertEqual(Round.stars(firstTry: 10, of: 10), 3)
        XCTAssertEqual(Round.stars(firstTry: 9, of: 10), 3)
        XCTAssertEqual(Round.stars(firstTry: 8, of: 10), 2)
        XCTAssertEqual(Round.stars(firstTry: 6, of: 10), 2)
        XCTAssertEqual(Round.stars(firstTry: 5, of: 10), 1)
        XCTAssertEqual(Round.stars(firstTry: 0, of: 10), 1, "finishing always earns a star")
    }
}

final class ProfileTests: XCTestCase {
    private func freshStore() -> UserDefaults {
        let name = "NSTests-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    func testProfilesPersistAndKeepTheirOwnProgress() {
        let store = freshStore()
        let m = AppModel(store: store)
        XCTAssertTrue(m.profiles.isEmpty)
        let a = Profile(name: "  Ada ", icon: "🦊")
        let b = Profile(name: "Ben", icon: "rocket", isSymbol: true, color: 3)
        m.save(a); m.save(b)
        XCTAssertEqual(m.profiles.map(\.name), ["Ada", "Ben"], "names are trimmed")

        m.choose(m.profiles[0])
        m.setLevel(.stretch, deck: EvenOdd.deckID)
        m.recordRound(deck: EvenOdd.key(.stretch), stars: 3)
        m.recordRound(deck: EvenOdd.key(.stretch), stars: 2)
        m.choose(m.profiles[1])
        m.recordRound(deck: EvenOdd.key(.sprout), stars: 1)

        let again = AppModel(store: store)
        let ada = again.profiles[0], ben = again.profiles[1]
        XCTAssertEqual(ada.level(EvenOdd.deckID), .stretch); XCTAssertEqual(ada.stars[EvenOdd.key(.stretch)], 5); XCTAssertEqual(ada.rounds[EvenOdd.key(.stretch)], 2)
        XCTAssertNil(ada.stars[EvenOdd.key(.sprout)], "stars are kept per mode")
        XCTAssertEqual(ben.level(EvenOdd.deckID), .sprout, "levels never mix"); XCTAssertEqual(ben.stars[EvenOdd.key(.sprout)], 1)
        XCTAssertEqual(ben.icon, "rocket"); XCTAssertTrue(ben.isSymbol); XCTAssertEqual(ben.color, 3)
    }

    func testEditKeepsIdentityAndBlankNamesAreRefused() {
        let m = AppModel(store: freshStore())
        var a = Profile(name: "Ada", icon: "🦊")
        m.save(a)
        a.name = "Ada Grace"; a.icon = "🦄"
        m.save(a)
        XCTAssertEqual(m.profiles.count, 1); XCTAssertEqual(m.profiles[0].name, "Ada Grace"); XCTAssertEqual(m.profiles[0].icon, "🦄")
        m.save(Profile(name: "   ", icon: "🐢"))
        XCTAssertEqual(m.profiles.count, 1)
    }
}
