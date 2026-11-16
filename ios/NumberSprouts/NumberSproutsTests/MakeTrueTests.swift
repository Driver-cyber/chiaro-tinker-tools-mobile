//  MakeTrueTests.swift — Make It True: sides add up right (× and ÷ first,
//  fractions exact), the ways are counted fairly, and every puzzle can be solved.

import XCTest
@testable import NumberSprouts

final class MakeTrueTests: XCTestCase {
    func testSidesFollowTheOrderOfSigns() {
        XCTAssertEqual(Side(nums: [2, 3, 4], ops: [.plus, .times]).value, Q(14))
        XCTAssertEqual(Side(nums: [2, 3, 4], ops: [.times, .plus]).value, Q(10))
        XCTAssertEqual(Side(nums: [9, 3, 2], ops: [.minus, .minus]).value, Q(4))
        XCTAssertEqual(Side(nums: [6, 4, 2], ops: [.divide, .times]).value, Q(3))
        XCTAssertEqual(Side(nums: [8, 3], ops: [.divide]).value?.whole, nil)
        XCTAssertEqual(Side(nums: [2, 5], ops: [.minus]).value, Q(-3))
        XCTAssertNil(Side(nums: [2, 5], ops: []).value, "a missing sign isn't a number")
        XCTAssertEqual(Side(nums: [12, 3, 4], ops: [.minus, .times]).text, "12 − 3 × 4")
    }

    func testWaysCountOrdersButNotSides() {
        XCTAssertEqual(MakeTrue.ways([1, 1, 2], ops: MTLevel.easy.ops), ["1 + 1 = 2", "1 = 2 − 1"])
        XCTAssertEqual(MakeTrue.ways([3, 5, 15], ops: MTLevel.medium.ops).count, 4)   // the fact family
        XCTAssertEqual(MakeTrue.ways([3, 5, 15], ops: MTLevel.easy.ops), [])
        XCTAssertEqual(MakeTrue.key(Side(nums: [2], ops: []), Side(nums: [1, 1], ops: [.plus])),
                       MakeTrue.key(Side(nums: [1, 1], ops: [.plus]), Side(nums: [2], ops: [])))
    }

    func testEveryPuzzleCanBeSolved() {
        var g = SeededGenerator(seed: 7)
        for level in MTLevel.allCases {
            for _ in 0..<300 {
                let nums = MakeTrue.puzzle(level, using: &g)
                XCTAssertEqual(nums.count, level.count)
                XCTAssertTrue(nums.allSatisfy { $0 >= 1 }, "\(nums)")
                XCTAssertFalse(MakeTrue.ways(nums, ops: level.ops).isEmpty, "\(level) \(nums)")
                switch level {
                case .easy: XCTAssertTrue(nums.allSatisfy { $0 <= 9 }, "\(nums)")
                case .medium: XCTAssertEqual(nums.filter { $0 >= 10 }.count, 1, "one double digit: \(nums)")
                case .hard:
                    XCTAssertTrue(nums.allSatisfy { $0 <= 30 }, "\(nums)")
                    XCTAssertTrue(hasThreeAndOne(nums, ops: level.ops), "the Machine can solve it: \(nums)")
                }
            }
        }
    }

    /// Some way puts three numbers in the machine and one in the bin.
    private func hasThreeAndOne(_ nums: [Int], ops: [Op]) -> Bool {
        for order in MakeTrue.permutations(Array(0..<4)) {
            let v = order.map { nums[$0] }
            for a in ops { for b in ops where Side(nums: Array(v[..<3]), ops: [a, b]).value == Q(v[3]) { return true } }
        }
        return false
    }

    func testGameCountsNewWaysAndSaysWhy() {
        let g = MakeTrueGame(level: .easy, numbers: [1, 1, 2])
        XCTAssertEqual(g.total, 2)
        XCTAssertEqual(g.submit(Side(nums: [1, 2], ops: [.plus]), Side(nums: [1], ops: [])), .miss)
        XCTAssertEqual(g.message, "1 + 2 makes 3, not 1")
        XCTAssertEqual(g.submit(Side(nums: [1, 1], ops: [.plus]), Side(nums: [2], ops: [])), .newWay)
        XCTAssertEqual(g.submit(Side(nums: [2], ops: []), Side(nums: [1, 1], ops: [.plus])), .again, "the same way, sides swapped")
        XCTAssertFalse(g.allFound)
        XCTAssertEqual(g.submit(Side(nums: [2, 1], ops: [.minus]), Side(nums: [1], ops: [])), .newWay)
        XCTAssertTrue(g.allFound)
        XCTAssertEqual(g.found, ["1 + 1 = 2", "2 − 1 = 1"])
        XCTAssertEqual(g.wins, 2)

        let h = MakeTrueGame(level: .hard, numbers: [2, 3, 4, 7])
        h.submit(Side(nums: [2, 3, 4], ops: [.plus, .times]), Side(nums: [7], ops: []))
        XCTAssertEqual(h.message, "2 + 3 × 4 makes 14 (× and ÷ go first), not 7")
        h.submit(Side(nums: [2, 7], ops: [.divide]), Side(nums: [3, 4], ops: [.minus]))
        XCTAssertEqual(h.message, "2 ÷ 7 doesn't share evenly, but 3 − 4 goes below zero")
    }

    func testNewPuzzleKeepsTheLevelAndStartsFresh() {
        let g = MakeTrueGame(level: .medium, seed: 3)
        let first = g.puzzleID
        g.newPuzzle(.hard)
        XCTAssertEqual(g.level, .hard)
        XCTAssertEqual(g.numbers.count, 4)
        XCTAssertEqual(g.found, [])
        XCTAssertEqual(g.puzzleID, first + 1)
    }

    func testStarsForWaysAreSavedPerPlayer() {
        let name = "mt-\(UUID())"
        let d = UserDefaults(suiteName: name)!
        let m = AppModel(store: d)
        m.save(Profile(name: "A", icon: "🦊")); m.save(Profile(name: "B", icon: "🐢"))
        m.choose(m.profiles[0])
        m.addStars(mode: MTLevel.hard.starKey, 1); m.addStars(mode: MTLevel.hard.starKey, 1)
        let again = AppModel(store: d)
        XCTAssertEqual(again.profiles[0].stars["mt.hard"], 2)
        XCTAssertNil(again.profiles[1].stars["mt.hard"])
        d.removePersistentDomain(forName: name)
    }
}
