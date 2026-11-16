//  MakeTrue.swift — Make It True: a few numbers, put them in order with signs
//  between until the math is true. 1, 1, 2 → 1 + 1 = 2, or 2 − 1 = 1.
//
//  Easy is three single digits with + and −; Medium adds one double digit and
//  × ÷; Hard has four numbers, so a side can hold three (2 × 3 + 1 = 7) or the
//  two sides two each (2 + 6 = 4 + 4). Every true arrangement counts as a way
//  (3 × 5 and 5 × 3 are two), but swapping the sides is the same way. The three
//  views (Tiles, Scale, Machine) all hand their two sides to `submit`.

import Foundation
import SwiftUI

enum Op: String, CaseIterable, Codable {
    case plus = "+", minus = "−", times = "×", divide = "÷"
    var word: String {
        switch self {
        case .plus: return "plus"
        case .minus: return "minus"
        case .times: return "times"
        case .divide: return "divided by"
        }
    }
}

enum MTLevel: String, CaseIterable, Identifiable {
    case easy, medium, hard
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var count: Int { self == .hard ? 4 : 3 }
    var ops: [Op] { self == .easy ? [.plus, .minus] : Op.allCases }
    var starKey: String { "mt.\(rawValue)" }
}

/// An exact fraction, so 6 ÷ 4 × 2 is 3 and 8 ÷ 3 is never rounded into a match.
struct Q: Equatable {
    let n: Int, d: Int
    init(_ n: Int, _ d: Int = 1) {
        func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? abs(a) : gcd(b, a % b) }
        let g = max(gcd(n, d), 1) * (d < 0 ? -1 : 1)
        self.n = n / g; self.d = d / g
    }
    var whole: Int? { d == 1 ? n : nil }
    static func + (a: Q, b: Q) -> Q { Q(a.n * b.d + b.n * a.d, a.d * b.d) }
    static func - (a: Q, b: Q) -> Q { Q(a.n * b.d - b.n * a.d, a.d * b.d) }
    static func * (a: Q, b: Q) -> Q { Q(a.n * b.n, a.d * b.d) }
    static func / (a: Q, b: Q) -> Q { Q(a.n * b.d, a.d * b.n) }
    var double: Double { Double(n) / Double(d) }
}

/// One side of the equation: numbers with a sign between each pair.
struct Side: Equatable {
    var nums: [Int]
    var ops: [Op]

    var text: String {
        var s = nums.first.map(String.init) ?? ""
        for (i, op) in ops.enumerated() where i + 1 < nums.count { s += " \(op.rawValue) \(nums[i + 1])" }
        return s
    }

    /// × and ÷ go first, then + and − from left to right. Nil if a sign is missing.
    var value: Q? {
        guard let first = nums.first, ops.count == nums.count - 1 else { return nil }
        var total = Q(0), sign = Q(1), term = Q(first)
        for (i, op) in ops.enumerated() {
            let x = Q(nums[i + 1])
            switch op {
            case .times: term = term * x
            case .divide: term = term / x
            case .plus, .minus:
                total = total + term * sign
                sign = Q(op == .plus ? 1 : -1)
                term = x
            }
        }
        return total + term * sign
    }

    /// A side like 2 + 3 × 4, where the order the signs go in matters.
    var mixes: Bool {
        ops.contains { $0 == .plus || $0 == .minus } && ops.contains { $0 == .times || $0 == .divide }
    }
}

enum MakeTrue {
    /// The same way whichever side it's written on.
    static func key(_ l: Side, _ r: Side) -> String { [l.text, r.text].sorted().joined(separator: " = ") }

    /// Every true arrangement of these numbers with these signs, one key each.
    static func ways(_ numbers: [Int], ops: [Op]) -> Set<String> {
        var out = Set<String>()
        let n = numbers.count
        func signs(_ k: Int) -> [[Op]] {
            k == 0 ? [[]] : signs(k - 1).flatMap { s in ops.map { s + [$0] } }
        }
        for order in permutations(Array(0..<n)) {
            let nums = order.map { numbers[$0] }
            for split in 1..<n {
                let l = Array(nums[..<split]), r = Array(nums[split...])
                for lo in signs(l.count - 1) {
                    let left = Side(nums: l, ops: lo)
                    guard let lv = left.value else { continue }
                    for ro in signs(r.count - 1) {
                        let right = Side(nums: r, ops: ro)
                        if right.value == lv { out.insert(key(left, right)) }
                    }
                }
            }
        }
        return out
    }

    static func permutations(_ a: [Int]) -> [[Int]] {
        guard a.count > 1 else { return [a] }
        return a.indices.flatMap { i -> [[Int]] in
            var rest = a; let x = rest.remove(at: i)
            return permutations(rest).map { [x] + $0 }
        }
    }

    /// A puzzle with at least one way, numbers shuffled. Hard always has a way
    /// with three numbers on one side, so the Machine can solve it too.
    static func puzzle<G: RandomNumberGenerator>(_ level: MTLevel, using g: inout G) -> [Int] {
        var nums: [Int]
        switch level {
        case .easy:
            let c = Int.random(in: 2...9, using: &g)
            let a = Int.random(in: 1...(c - 1), using: &g)
            nums = [a, c - a, c]
        case .medium:
            if Bool.random(using: &g) {
                let a = Int.random(in: 2...9, using: &g)
                let b = Int.random(in: max(2, 10 - a)...9, using: &g)
                nums = [a, b, a + b]
            } else {
                let products = (2...9).flatMap { a in (a...9).map { (a, $0) } }.filter { (10...40).contains($0.0 * $0.1) }
                let p = products.randomElement(using: &g)!
                nums = [p.0, p.1, p.0 * p.1]
            }
        case .hard:
            nums = hard(using: &g)
        }
        nums.shuffle(using: &g)
        return nums
    }

    private static func hard<G: RandomNumberGenerator>(using g: inout G) -> [Int] {
        while true {
            let a = Int.random(in: 1...9, using: &g), b = Int.random(in: 1...9, using: &g)
            let c = Int.random(in: 1...9, using: &g)
            switch Int.random(in: 0..<6, using: &g) {
            case 0 where a + b + c <= 20: return [a, b, c, a + b + c]              // 2 + 3 + 4 = 9
            case 1 where a + b - c >= 1: return [a, b, c, a + b - c]               // 7 + 5 − 3 = 9
            case 2 where a >= 2 && b >= 2 && a * b + c <= 30: return [a, b, c, a * b + c]   // 2 × 4 + 3 = 11
            case 3 where a >= 2 && b >= 2 && a * b - c >= 1 && a * b <= 30: return [a, b, c, a * b - c]
            case 4:                                                                 // 2 + 6 = 5 + 3
                let s = Int.random(in: 6...14, using: &g)
                let x = Int.random(in: max(1, s - 9)...min(9, s - 1), using: &g)
                let y = Int.random(in: max(1, s - 9)...min(9, s - 1), using: &g)
                if x != y && x != s - y { return [x, s - x, y, s - y] }
            case 5:                                                                 // 2 × 6 = 3 × 4
                let pairs = [[2, 6, 3, 4], [2, 9, 3, 6], [3, 8, 4, 6], [1, 8, 2, 4], [1, 6, 2, 3], [2, 8, 4, 4], [4, 9, 6, 6], [2, 10, 4, 5]]
                return pairs.randomElement(using: &g)!
            default: continue
            }
        }
    }
}

/// One game of Make It True: the numbers on screen, the ways found so far, and
/// what to say about the last try. The boards keep where each piece sits.
final class MakeTrueGame: ObservableObject {
    enum Tone { case hint, right, miss }
    enum Result { case newWay, again, miss }

    @Published private(set) var level: MTLevel
    @Published private(set) var numbers: [Int] = []
    @Published private(set) var found: [String] = []      // as the kid wrote them
    @Published private(set) var total = 0
    @Published private(set) var puzzleID = 0
    @Published private(set) var message = ""
    @Published private(set) var tone = Tone.hint
    /// Counts up on every new way, so a view can burst on it.
    @Published private(set) var wins = 0
    private var keys = Set<String>()
    private var all = Set<String>()
    private var seeded: SeededGenerator?       // tests only

    init(level: MTLevel, numbers: [Int]? = nil, seed: UInt64? = nil) {
        self.level = level
        seeded = seed.map(SeededGenerator.init)
        if let numbers { load(numbers) } else { newPuzzle() }
    }

    var allFound: Bool { !all.isEmpty && keys.count == all.count }

    func newPuzzle(_ level: MTLevel? = nil) {
        if let level { self.level = level }
        if var g = seeded {
            load(MakeTrue.puzzle(self.level, using: &g)); seeded = g
        } else {
            var g = SystemRandomNumberGenerator()
            load(MakeTrue.puzzle(self.level, using: &g))
        }
    }

    private func load(_ nums: [Int]) {
        numbers = nums
        all = MakeTrue.ways(nums, ops: level.ops)
        total = all.count
        keys = []; found = []
        puzzleID += 1
        say("Make the math true with all \(level.count) numbers", .hint)
    }

    func say(_ text: String, _ tone: Tone) { message = text; self.tone = tone }

    /// Checks a finished equation and says why when it isn't true.
    @discardableResult
    func submit(_ l: Side, _ r: Side) -> Result {
        guard let lv = l.value, let rv = r.value else { say("Every space needs a sign", .miss); return .miss }
        if lv == rv {
            let k = MakeTrue.key(l, r)
            if keys.contains(k) {
                say("True! You found that one already. Try another way", .right)
                return .again
            }
            keys.insert(k)
            found.append("\(l.text) = \(r.text)")
            wins += 1
            say(allFound ? "You found every way!" : "True! \(l.text) = \(r.text)", .right)
            return .newWay
        }
        say(why(l, lv, r, rv), .miss)
        return .miss
    }

    func why(_ l: Side, _ lv: Q, _ r: Side, _ rv: Q) -> String {
        func makes(_ s: Side, _ v: Q) -> String {
            if s.nums.count == 1 { return "\(s.text)" }
            if v.whole == nil { return "\(s.text) doesn't share evenly" }
            if v.n < 0 { return "\(s.text) goes below zero" }
            return "\(s.text) makes \(v.n)" + (s.mixes ? " (× and ÷ go first)" : "")
        }
        if l.nums.count == 1 { return "\(makes(r, rv)), not \(l.text)" }
        if r.nums.count == 1 { return "\(makes(l, lv)), not \(r.text)" }
        return "\(makes(l, lv)), but \(makes(r, rv))"
    }
}
