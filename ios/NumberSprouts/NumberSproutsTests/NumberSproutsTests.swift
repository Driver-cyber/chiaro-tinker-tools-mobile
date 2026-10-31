//  NumberSproutsTests.swift — every engine (answers right, choices valid and
//  unique, numbers in range), a round's rules, the Draw puzzles, and profiles.

import XCTest
@testable import NumberSprouts

/// Checks every card's answer against real arithmetic, by parsing its face.
private func check(_ c: Card, file: StaticString = #filePath, line: UInt = #line) {
    switch c.face {
    case .parity(let n, _):
        XCTAssertEqual(c.answer, n % 2 == 0 ? 0 : 1, file: file, line: line)
    case .compare(let a, let b):
        XCTAssertNotEqual(a, b, file: file, line: line)
        XCTAssertEqual(c.answer, a > b ? 0 : 1, file: file, line: line)
    case .choice(let prompt, let options):
        XCTAssertEqual(options.count, 4, prompt, file: file, line: line)
        XCTAssertEqual(Set(options).count, 4, "choices are unique: \(prompt) \(options)", file: file, line: line)
        XCTAssertTrue((0..<4).contains(c.answer), file: file, line: line)
        let right = options[c.answer]
        if prompt.hasPrefix("? × ? = ") {
            let p = Int(prompt.dropFirst(8))!
            func product(_ s: String) -> Int { s.components(separatedBy: " × ").map { Int($0)! }.reduce(1, *) }
            XCTAssertEqual(product(right), p, prompt, file: file, line: line)
            for (i, o) in options.enumerated() where i != c.answer { XCTAssertNotEqual(product(o), p, "only one pair works: \(prompt) \(options)", file: file, line: line) }
            return
        }
        for o in options { XCTAssertGreaterThanOrEqual(Int(o)!, 0, "never negative: \(prompt) \(options)", file: file, line: line) }
        let value = Int(right)!
        let parts = prompt.components(separatedBy: " ")
        switch parts.count {
        case 3:                                           // "a + b", "a − b", "a × b"
            let a = Int(parts[0])!, b = Int(parts[2])!
            let expect = parts[1] == "+" ? a + b : parts[1] == "−" ? a - b : a * b
            XCTAssertEqual(value, expect, prompt, file: file, line: line)
        case 5:                                           // "a + ? = c"
            XCTAssertEqual(Int(parts[0])! + value, Int(parts[4])!, prompt, file: file, line: line)
        default:
            XCTFail("unexpected prompt \(prompt)", file: file, line: line)
        }
    }
    XCTAssertFalse(c.trick.sentence.isEmpty, file: file, line: line)
}

final class EngineTests: XCTestCase {
    func testEveryCardModeDealsTenValidCards() {
        for mode in Modes.all {
            guard case .cards(let deal) = mode.play else { continue }
            for _ in 0..<60 {
                let cards = deal()
                XCTAssertEqual(cards.count, 10, mode.id)
                for k in cards.indices { check(cards[k]) }
                for k in 1..<cards.count { XCTAssertNotEqual(cards[k].face, cards[k - 1].face, "\(mode.id): no card twice in a row") }
            }
        }
    }

    func testEvenOddRangesAndFairness() {
        for (kind, range) in [(EvenOdd.Kind.dots, 1...10), (.toTwenty, 1...20), (.lastDigit, 10...999)] {
            for seed in 1...200 {
                var g = SeededGenerator(seed: UInt64(seed))
                let cards = EvenOdd.round(kind, using: &g)
                let evens = cards.filter { $0.answer == 0 }.count
                XCTAssertGreaterThanOrEqual(evens, 3); XCTAssertGreaterThanOrEqual(10 - evens, 3)
                for c in cards { if case .parity(let n, let dots) = c.face { XCTAssertTrue(range.contains(n)); XCTAssertEqual(dots, kind == .dots) } }
            }
        }
        XCTAssertEqual(EvenOdd.trick(7), "7 dots make 3 pairs and 1 left over. That's odd!")
        XCTAssertEqual(EvenOdd.trick(1), "1 dot can't make a pair, so it's left over. That's odd!")
        XCTAssertEqual(EvenOdd.trick(348), "Just look at the last digit: 8. 8 is even, so 348 is even!")
    }

    func testCompareRangesAndTricks() {
        var g = SeededGenerator(seed: 3)
        for _ in 0..<500 {
            let (a, b) = Compare.pair(.within20, using: &g); XCTAssertTrue((0...20).contains(a) && (0...20).contains(b))
            let (c, d) = Compare.pair(.tensFirst, using: &g); XCTAssertNotEqual(c / 10, d / 10); XCTAssertTrue((10...99).contains(c) && (10...99).contains(d))
            let (e, f) = Compare.pair(.lookAlikes, using: &g); XCTAssertTrue((10...99).contains(e) && (10...99).contains(f)); XCTAssertNotEqual(e, f)
            let (h, i) = Compare.pair(.toThousand, using: &g); XCTAssertTrue((100...999).contains(h) && (100...999).contains(i)); XCTAssertNotEqual(h, i)
        }
        XCTAssertEqual(Compare.trick(68, 86), "Compare the tens first: 8 is more than 6, so 86 is bigger than 68.")
        XCTAssertEqual(Compare.trick(47, 45), "Same tens, so compare the ones: 7 is more than 5, so 47 is bigger than 45.")
        XCTAssertEqual(Compare.trick(7, 15), "Compare the tens first: 1 is more than 0, so 15 is bigger than 7.")
        XCTAssertEqual(Compare.trick(3, 8), "8 comes after 3 when you count, so 8 is bigger.")
        XCTAssertEqual(Compare.trick(452, 437), "Same hundreds, so compare the tens: 5 is more than 3, so 452 is bigger than 437.")
    }

    func testAddSubStaysInBounds() {
        var g = SeededGenerator(seed: 11)
        for _ in 0..<400 {
            if case .choice(let p, _) = AddSub.card(.makeTen, using: &g).face {
                let ab = p.components(separatedBy: " + ").map { Int($0)! }
                XCTAssertTrue((11...18).contains(ab[0] + ab[1]), "make 10 crosses ten: \(p)")
            }
            if case .choice(let p, _) = AddSub.card(.within20, using: &g).face {
                let n = p.components(separatedBy: CharacterSet(charactersIn: "+−")).map { Int($0.trimmingCharacters(in: .whitespaces))! }
                if p.contains("+") { XCTAssertLessThanOrEqual(n[0] + n[1], 20, p) } else { XCTAssertLessThanOrEqual(n[0], 20, p) }
            }
            if case .choice(let p, _) = AddSub.card(.twoDigit, using: &g).face {
                let n = p.components(separatedBy: CharacterSet(charactersIn: "+−")).map { Int($0.trimmingCharacters(in: .whitespaces))! }
                XCTAssertTrue(n.allSatisfy { (10...99).contains($0) }, p)
                if p.contains("+") { XCTAssertLessThanOrEqual(n[0] % 10 + n[1] % 10, 9, "no carrying: \(p)") }
                else { XCTAssertGreaterThanOrEqual(n[0] % 10, n[1] % 10, "no borrowing: \(p)") }
            }
        }
        XCTAssertEqual(AddSub.makeTen(8, 5), "8 needs 2 to make 10. Take 2 from 5, and 10 + 3 = 13.")
        for _ in 0..<300 {
            if case .choice(let p, _) = AddSub.card(.onesTwos, using: &g).face {
                let n = p.components(separatedBy: CharacterSet(charactersIn: "+−")).map { Int($0.trimmingCharacters(in: .whitespaces))! }
                XCTAssertTrue([1, 2].contains(n[1]), "only ones and twos: \(p)")
            }
        }
    }

    func testTimesTricks() {
        XCTAssertEqual(Times.trick(10, 7), "Times 10 adds a zero: 7 becomes 70.")
        XCTAssertEqual(Times.trick(0, 10), "Times 0 is always 0: zero groups of anything is nothing.")
        XCTAssertEqual(Times.trick(9, 0), "Times 0 is always 0: zero groups of anything is nothing.")
        XCTAssertEqual(Times.trick(1, 7), "Times 1 keeps a number the same: 7.")
        var g = SeededGenerator(seed: 2)
        for _ in 0..<300 {
            if case .choice(let p, _) = Times.card(.table(3), using: &g).face { XCTAssertTrue(p.contains("3"), p) }
            let c = Times.card(.zeroOne, using: &g)
            if case .choice(let p, _) = c.face { XCTAssertTrue(p.hasPrefix("0 ") || p.hasPrefix("1 ") || p.hasSuffix(" 0") || p.hasSuffix(" 1"), p) }
            if case .nines(let n) = c.trick.visual { XCTAssertGreaterThan(n, 0, "no finger trick for ×0") }
        }
        XCTAssertEqual(Times.trick(9, 7), "Times 9: the first digit is one less than 7, and the digits add to 9. 6 and 3 make 63.")
        XCTAssertEqual(Times.trick(4, 6), "Times 4 is double, then double again: 6 → 12 → 24.")
        XCTAssertEqual(Times.trick(7, 8), "Use one you know: 7 × 7 = 49, plus one more 7 is 56.")
        for b in 1...9 { let p = 9 * b; XCTAssertEqual(p / 10 + p % 10, 9, "×9 digits add to 9"); XCTAssertEqual(p / 10, b - 1) }
    }

    func testChoicesAreAlwaysValid() {
        var g = SeededGenerator(seed: 5)
        for answer in 0...100 {
            let (opts, at) = Dealer.choices(answer: answer, near: [answer - 1, answer + 1, answer, -3, answer + 10], using: &g)
            XCTAssertEqual(opts[at], String(answer)); XCTAssertEqual(Set(opts).count, 4)
            XCTAssertTrue(opts.allSatisfy { Int($0)! >= 0 })
        }
    }
}

final class RoundTests: XCTestCase {
    private func cards(_ ns: [Int]) -> [Card] { ns.map { EvenOdd.card($0, dots: false) } }

    func testRightAnswersScoreAndAdvance() {
        let r = Round(modeID: "t", cards: cards([2, 3]))
        XCTAssertTrue(r.answer(0)); XCTAssertEqual(r.phase, .right); XCTAssertEqual(r.firstTry, 1)
        r.advance(); XCTAssertEqual(r.index, 1); XCTAssertEqual(r.phase, .asking)
        XCTAssertTrue(r.answer(1)); r.advance()
        XCTAssertEqual(r.phase, .done); XCTAssertEqual(r.firstTry, 2)
    }

    func testAMissShowsTheTrickThenOneRetry() {
        let r = Round(modeID: "t", cards: cards([4, 5]))
        XCTAssertFalse(r.answer(1)); XCTAssertEqual(r.phase, .missed); XCTAssertEqual(r.wrongPicks, [1])
        r.gotIt(); XCTAssertEqual(r.phase, .retrying); XCTAssertEqual(r.index, 0, "same card again")
        XCTAssertTrue(r.answer(0)); XCTAssertEqual(r.firstTry, 0, "a retry isn't a first try")
        r.advance(); XCTAssertEqual(r.index, 1); XCTAssertTrue(r.wrongPicks.isEmpty)
        r.answer(0); r.gotIt(); r.answer(0)
        XCTAssertEqual(r.phase, .missed); r.gotIt()
        XCTAssertEqual(r.phase, .done)
    }

    func testAnswersAreIgnoredOutsideAsking() {
        let r = Round(modeID: "t", cards: cards([4, 6]))
        r.answer(0)
        XCTAssertFalse(r.answer(0), "no double-scoring while celebrating")
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

final class DrawTests: XCTestCase {
    func testColorProblemsMakeTheirNumbers() {
        var g = SeededGenerator(seed: 9)
        for max in [10, 20] {
            for _ in 0..<300 {
                let key = ColorByNumber.key(paints: 6, max: max, using: &g)
                XCTAssertEqual(Set(key).count, 6); XCTAssertTrue(key.allSatisfy { (2...max).contains($0) })
                for t in key {
                    let p = ColorByNumber.problem(for: t, max: max, using: &g)
                    let n = p.components(separatedBy: CharacterSet(charactersIn: "+−")).map { Int($0.trimmingCharacters(in: .whitespaces))! }
                    XCTAssertEqual(p.contains("+") ? n[0] + n[1] : n[0] - n[1], t, p)
                    XCTAssertTrue(n.allSatisfy { (1...max).contains($0) }, p)
                }
            }
        }
    }

    func testPicturesAreSound() {
        for p in Pictures.color {
            XCTAssertLessThanOrEqual(p.paints.count, 6, p.id)
            XCTAssertFalse(p.shapeSummary.isEmpty)
        }
        XCTAssertEqual(Pictures.color[0].shapeSummary, "1 rectangle, 4 triangles and 3 circles")
        for p in Pictures.dots {
            XCTAssertTrue(p.points.allSatisfy { (0...10).contains($0.x) && (0...10).contains($0.y) }, p.id)
            let t = DotToDot.targets(p)
            XCTAssertEqual(t.first, t.last, "\(p.id) closes back to the start")
            for k in 1..<t.count { XCTAssertNotEqual(t[k], t[k - 1], "\(p.id): every step moves") }
        }
    }

    func testEveryLabelIsVisible() {
        for pic in Pictures.color {
            for i in pic.regions.indices {
                let p = pic.labelPoint(i)
                XCTAssertTrue(pic.regions[i].path(10).contains(p), "\(pic.id) region \(i): label inside its region")
                for j in pic.regions.indices where j > i {
                    XCTAssertFalse(pic.regions[j].path(10).contains(p), "\(pic.id) region \(i): label not hidden by region \(j)")
                }
            }
        }
    }

    func testDotInstructionsAndShapeNames() {
        XCTAssertEqual(DotToDot.stepText(from: GridPoint(x: 2, y: 1), to: GridPoint(x: 5, y: 3)), "Go 3 right and 2 up")
        XCTAssertEqual(DotToDot.stepText(from: GridPoint(x: 5, y: 9), to: GridPoint(x: 2, y: 9)), "Go 3 left")
        XCTAssertEqual(DotToDot.pairText(GridPoint(x: 3, y: 5)), "Pin (3, 5)")
        XCTAssertEqual(DotGeometry.name([.init(x: 0, y: 0), .init(x: 3, y: 0), .init(x: 1, y: 2)]), "a triangle")
        XCTAssertEqual(DotGeometry.name([.init(x: 1, y: 1), .init(x: 4, y: 1), .init(x: 4, y: 4), .init(x: 1, y: 4)]), "a square")
        XCTAssertEqual(DotGeometry.name([.init(x: 1, y: 1), .init(x: 6, y: 1), .init(x: 6, y: 4), .init(x: 1, y: 4)]), "a rectangle")
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
        m.save(Profile(name: "  Ada ", icon: "🦊"))
        m.save(Profile(name: "Ben", icon: "rocket", isSymbol: true, color: 3))
        XCTAssertEqual(m.profiles.map(\.name), ["Ada", "Ben"], "names are trimmed")

        m.choose(m.profiles[0])
        m.recordRound(mode: "eo.last", stars: 3)
        m.recordRound(mode: "eo.last", stars: 2)
        m.recordPicture("dr.steps/boat")
        m.choose(m.profiles[1])
        m.recordRound(mode: "eo.dots", stars: 1)

        let again = AppModel(store: store)
        let ada = again.profiles[0], ben = again.profiles[1]
        XCTAssertEqual(ada.stars["eo.last"], 5); XCTAssertEqual(ada.rounds["eo.last"], 2); XCTAssertNil(ada.stars["eo.dots"])
        XCTAssertEqual(ada.pictures, ["dr.steps/boat"])
        XCTAssertEqual(ben.stars["eo.dots"], 1); XCTAssertTrue(ben.pictures.isEmpty, "progress never mixes")
        XCTAssertEqual(ben.icon, "rocket"); XCTAssertTrue(ben.isSymbol); XCTAssertEqual(ben.color, 3)
    }

    func testOlderSavesStillLoad() throws {
        let store = freshStore()
        let old = #"[{"id":"\#(UUID().uuidString)","name":"Ada","icon":"🦊","isSymbol":false,"color":2}]"#
        store.set(old.data(using: .utf8), forKey: AppModel.storeKey)
        let m = AppModel(store: store)
        XCTAssertEqual(m.profiles.first?.name, "Ada"); XCTAssertEqual(m.profiles.first?.color, 2)
        XCTAssertTrue(m.profiles.first?.pictures.isEmpty ?? false)
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
