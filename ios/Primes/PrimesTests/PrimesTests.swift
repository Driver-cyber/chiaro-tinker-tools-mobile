//  PrimesTests.swift — run with ⌘U in Xcode.
//
//  1. The handoff's acceptance checklist, re-run natively.
//  2. Web parity: every output of the Swift engine compared with fixtures
//     generated from the web game's engine (web-fixture.json), so the native
//     port and chiaromobile can never drift silently. If the web game changes,
//     regenerate the fixture (see ios/Primes/README.md).
//  3. The found-primes meter: what writes, what doesn't, and that it persists.

import XCTest
@testable import Primes

final class AcceptanceTests: XCTestCase {
    func testExactly168Primes() {
        XCTAssertEqual(PrimeEngine.all.count, 168)
        for n in PrimeEngine.all {   // independent trial division
            var d = 2, prime = true
            while d * d <= n { if n % d == 0 { prime = false; break }; d += 1 }
            XCTAssertTrue(prime, "\(n) reported prime")
        }
    }

    func testEveryCompositeGetsACorrectWorkedExample() {
        for n in 4...999 where !PrimeEngine.isPrime(n) {
            let p = PrimeEngine.spf(n)
            let w = PrimeEngine.apply(p, n)
            XCTAssertEqual(n % p, 0)
            XCTAssertTrue(w.ok, "\(n)")
            XCTAssertTrue(w.lines.last!.hasSuffix("✓"), "\(n): \(w.lines)")
            XCTAssertEqual(PrimeEngine.equation(n), "\(n) = \(p) × \(n / p)")
        }
    }

    func testEveryTrickAgreesWithRealDivisibility() {
        for p in PrimeEngine.small {
            for n in 2...999 {
                let w = PrimeEngine.apply(p, n)
                XCTAssertEqual(w.ok, n % p == 0, "\(p) on \(n)")
                XCTAssertEqual(w.lines.last!.hasSuffix("✓"), w.ok, "\(p) on \(n)")
                XCTAssertLessThanOrEqual(w.lines.count, 3, "\(p) on \(n) settles within 3 chops")
            }
        }
    }

    func testSpotChecks() {
        XCTAssertEqual(PrimeEngine.equation(221), "221 = 13 × 17")
        XCTAssertEqual(PrimeEngine.equation(377), "377 = 13 × 29")
        XCTAssertEqual(PrimeEngine.equation(403), "403 = 13 × 31")
        XCTAssertEqual(PrimeEngine.equation(961), "961 = 31 × 31")
        XCTAssertTrue(PrimeEngine.isPrime(997))
        XCTAssertEqual(PrimeEngine.primeExplanation(997).rootLine, "997: 31² = 961 and 32² = 1024, so check primes up to 31.")
        XCTAssertEqual(PrimeEngine.apply(13, 221).lines, ["chop → 22 and 1, 1 × 4 = 4, 22 + 4 = 26 = 2 × 13 ✓"])
        XCTAssertTrue(PrimeEngine.apply(7, 119).lines[0].hasSuffix("11 − 18 = −7 ✓"))
        XCTAssertEqual(PrimeEngine.primeExplanation(2).listNote, "2 is on the prime list. Nothing to check.")
    }

    func testBucketsAndDraws() {
        for tier in [Tier.medium, .hard] {
            XCTAssertFalse(PrimeEngine.buckets[tier]![.primes]!.contains { $0 <= 5 }, "\(tier) drops 2, 3, 5")
        }
        XCTAssertTrue([2, 3, 5].allSatisfy { PrimeEngine.buckets[.easy]![.primes]!.contains($0) })
        for tier in Tier.allCases {
            let w = PrimeEngine.config[tier]!.weights
            var counts: [Bucket: Int] = [:]
            var prev: Int? = nil
            for _ in 0..<1000 {
                let d = PrimeEngine.draw(tier, prev: prev)
                XCTAssertNotEqual(d.n, prev, "never repeats")
                XCTAssertTrue((2...999).contains(d.n))
                if tier == .hard {
                    XCTAssertGreaterThanOrEqual(d.n, 100)
                    XCTAssertTrue(d.n % 2 != 0 && d.n % 3 != 0 && d.n % 5 != 0, "Hard drew \(d.n)")
                }
                counts[d.bucket, default: 0] += 1
                prev = d.n
            }
            for b in Bucket.allCases {
                let pct = Double(counts[b] ?? 0) / 10
                XCTAssertLessThanOrEqual(abs(pct - Double(w[b] ?? 0)), 5, "\(tier) \(b): \(pct)% vs \(w[b] ?? 0)%")
            }
        }
    }
}

final class WebParityTests: XCTestCase {
    struct NumberCase: Decodable {
        let prime: Bool
        let spf: Int
        let eq: String?
        let lines: [String]?
        let list: String?
        let root: String?
        let verdict: String?
        let checked: [Int]?
    }
    struct ApplyCase: Decodable { let ok: Bool; let lines: [String] }
    struct TrickCase: Decodable { let trick: String; let example: String }
    struct Fixture: Decodable {
        let numbers: [String: NumberCase]
        let apply: [String: ApplyCase]
        let tricks: [String: TrickCase]
        let buckets: [String: [String: [Int]]]
    }

    static let fixture: Fixture = {
        let url = Bundle(for: WebParityTests.self).url(forResource: "web-fixture", withExtension: "json")!
        return try! JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    }()

    func testNumbersMatchTheWebGame() {
        XCTAssertEqual(Self.fixture.numbers.count, 998)
        for (key, c) in Self.fixture.numbers {
            let n = Int(key)!
            XCTAssertEqual(PrimeEngine.isPrime(n), c.prime, "\(n) prime?")
            XCTAssertEqual(PrimeEngine.spf(n), c.spf, "\(n) smallest factor")
            if c.prime {
                let e = PrimeEngine.primeExplanation(n)
                XCTAssertEqual(e.listNote, c.list, "\(n) list note")
                XCTAssertEqual(e.rootLine, c.root, "\(n) root line")
                XCTAssertEqual(e.verdict, c.verdict, "\(n) verdict")
                XCTAssertEqual(e.checked, c.checked ?? [], "\(n) checked primes")
            } else {
                XCTAssertEqual(PrimeEngine.equation(n), c.eq, "\(n) equation")
                XCTAssertEqual(PrimeEngine.apply(c.spf, n).lines, c.lines, "\(n) worked lines")
            }
        }
    }

    func testEveryTrickOnEveryNumberMatchesTheWebGame() {
        XCTAssertEqual(Self.fixture.apply.count, 10_978)
        for (key, c) in Self.fixture.apply {
            let parts = key.split(separator: ":").map { Int($0)! }
            let w = PrimeEngine.apply(parts[0], parts[1])
            XCTAssertEqual(w.ok, c.ok, key)
            XCTAssertEqual(w.lines, c.lines, key)
        }
    }

    func testTrickTextAndBucketsMatchTheWebGame() {
        for p in PrimeEngine.small {
            XCTAssertEqual(PrimeEngine.tricks[p]!.trick, Self.fixture.tricks[String(p)]!.trick)
            XCTAssertEqual(PrimeEngine.tricks[p]!.example, Self.fixture.tricks[String(p)]!.example)
        }
        for tier in Tier.allCases {
            for b in Bucket.allCases {
                XCTAssertEqual(PrimeEngine.buckets[tier]![b]!, Self.fixture.buckets[tier.rawValue]![b.rawValue]!, "\(tier) \(b)")
            }
        }
    }
}

final class GameTests: XCTestCase {
    private func freshStore() -> UserDefaults {
        let name = "PrimesTests-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    /// Deal until the number is (or isn't) prime.
    private func deal(_ g: Game, prime: Bool) {
        repeat { g.deal() } while g.isPrime != prime
    }

    func testHomeSetsTheNumberDownUnanswered() {
        let g = Game(store: freshStore())
        deal(g, prime: true); g.checked = [2, 3]
        g.home()
        XCTAssertEqual(g.screen, .welcome); XCTAssertTrue(g.checked.isEmpty)
        g.answer(saidPrime: true)
        XCTAssertEqual(g.screen, .welcome, "no answer from the welcome screen"); XCTAssertEqual(g.foundCount, 0)
    }

    func testFoundPrimesWriteOnlyOnFirstCorrectPrimeCall() {
        let store = freshStore()
        let g = Game(store: store)
        XCTAssertEqual(g.foundCount, 0)

        deal(g, prime: false); g.answer(saidPrime: false)
        XCTAssertTrue(g.wasRight); XCTAssertEqual(g.foundCount, 0, "a correct composite records nothing")

        deal(g, prime: true); let p = g.n; g.answer(saidPrime: false)
        XCTAssertFalse(g.wasRight); XCTAssertEqual(g.foundCount, 0, "a missed prime records nothing"); XCTAssertEqual(g.streak, 0)

        deal(g, prime: true); let q = g.n; g.answer(saidPrime: true)
        XCTAssertTrue(g.freshFind); XCTAssertEqual(g.foundCount, 1); XCTAssertNotNil(g.solved[q]); XCTAssertEqual(g.streak, 1)
        _ = p

        // the same prime again: no second "new"
        while g.n != q || g.screen != .question { g.deal() }
        g.answer(saidPrime: true)
        XCTAssertFalse(g.freshFind); XCTAssertEqual(g.foundCount, 1)

        // a later miss never un-finds it
        while g.n != q || g.screen != .question { g.deal() }
        g.answer(saidPrime: false)
        XCTAssertNotNil(g.solved[q])

        // persists across launches
        XCTAssertEqual(Game(store: store).solved[q], g.solved[q])
    }

    func testCheckedResetsOnDealAndAnswerIsOneShot() {
        let g = Game(store: freshStore())
        g.deal(); g.checked = [7, 13]
        g.answer(saidPrime: true)
        let streak = g.streak
        g.answer(saidPrime: true)   // ignored: already answered
        XCTAssertEqual(g.streak, streak)
        g.deal()
        XCTAssertTrue(g.checked.isEmpty)
    }
}
