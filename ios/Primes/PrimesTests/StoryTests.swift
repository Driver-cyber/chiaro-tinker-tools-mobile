//  StoryTests.swift — Story mode's arithmetic is checked, not trusted: every
//  picture matches its number, every equation is true, every choice has a way
//  through, and the music chapter's ratios and rhythms add up.

import XCTest
@testable import Primes

final class StoryTests: XCTestCase {
    private var steps: [Step] { Story.chapters.flatMap(\.steps) }

    func testChaptersAreNumberedInOrder() {
        XCTAssertEqual(Story.chapters.map(\.id), Array(1...Story.chapters.count))
    }

    func testEveryDotPictureMatchesItsNumber() {
        for s in steps {
            guard case .dots(let n, let shape) = s.stage else { continue }
            switch shape {
            case .row: XCTAssertLessThanOrEqual(n, 3, s.text)
            case .ring: XCTAssertTrue(PrimeEngine.isPrime(n), "a ring means no rows fit: \(n)")
            case .grid(let r, let c):
                XCTAssertEqual(r * c, n, s.text)
                XCTAssertGreaterThan(r, 1); XCTAssertGreaterThan(c, 1)
            }
            let (pts, _) = DotsStage.layout(n, shape, CGSize(width: 340, height: 240))
            XCTAssertEqual(pts.count, n)
        }
    }

    func testEveryEquationIsTrue() {
        for s in steps {
            guard let m = s.math, let eq = m.firstIndex(of: "=") else { continue }
            XCTAssertEqual(eval(Array(m[..<eq])), eval(Array(m[(eq + 1)...])), m.joined(separator: " "))
        }
    }

    func testEveryChoiceHasAWayThrough() {
        for s in steps {
            guard case .choose(_, let options) = s.gate else { continue }
            XCTAssertFalse(options.filter(\.right).isEmpty, s.text)
            XCTAssertEqual(Set(options.map(\.text)).count, options.count, s.text)
        }
    }

    func testCallsAreInTheGamesRange() {
        for s in steps {
            guard case .call(let n) = s.gate else { continue }
            XCTAssertTrue((2...999).contains(n))
        }
    }

    func testTheSieveLeavesThePrimes() {
        let left = (2...30).filter { k in ![2, 3, 5].contains { k != $0 && k % $0 == 0 } }
        XCTAssertEqual(left, (2...30).filter { PrimeEngine.isPrime($0) })
        XCTAssertEqual(steps.last { if case .sieve(_, true) = $0.stage { return true }; return false }?.math,
                       left.map(String.init))
    }

    func testEuclidAndThePythagoreanComma() {
        XCTAssertEqual(2 * 3 * 5 * 7 + 1, 211)
        XCTAssertTrue(PrimeEngine.isPrime(211))
        for p in [2, 3, 5, 7] { XCTAssertEqual(211 % p, 1) }
        XCTAssertEqual(Int(pow(3.0, 12)), 531_441)
        XCTAssertEqual(1 << 19, 524_288)
    }

    func testTheMusicAddsUp() {
        let notes = Tones.interval(3, 2, base: 200)
        XCTAssertEqual(notes[1].freq / notes[0].freq, 1.5, accuracy: 1e-9)
        let r = Tones.rhythm(5, 3, bar: 1)
        XCTAssertEqual(r.count, 2 * (5 + 3))
        for s in steps {
            if case .ratio(let a, let b, _) = s.stage { XCTAssertGreaterThan(a, b) }
        }
    }

    func testRecipes() {
        XCTAssertEqual(recipe(12), ["12", "=", "2", "×", "2", "×", "3"])
        XCTAssertEqual(recipe(7), ["7", "·", "prime"])
    }

    func testAStoryPrimeCountsTowardTheMeter() {
        let store = UserDefaults(suiteName: "story-test")!
        store.removePersistentDomain(forName: "story-test")
        let g = Game(store: store)
        XCTAssertTrue(g.markFound(97))
        XCTAssertFalse(g.markFound(97))
        XCTAssertFalse(g.markFound(91))
        XCTAssertEqual(Game(store: store).foundCount, 1)
    }

    /// × before +, whole numbers only.
    private func eval(_ parts: [String]) -> Int {
        var sum = 0, prod = 1
        for p in parts {
            if p == "+" { sum += prod; prod = 1 } else if p != "×" { prod *= Int(p)! }
        }
        return sum + prod
    }
}
