//  Engine.swift — Prime or Composite, by hand.
//
//  A line-for-line port of the web game's engine (src/index.html, "Primes —
//  prime or composite, by hand"). Pure logic, no UI: number buckets per tier,
//  the weighted draw, the eleven divisibility tricks worked on a number, and
//  the explanation text. PrimesTests/PrimesTests.swift (WebParityTests) checks every
//  output here against fixtures generated from the web engine, so the two
//  can't drift silently.

import Foundation

enum Tier: String, CaseIterable, Identifiable {
    case easy, medium, hard
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum Bucket: String, CaseIterable {
    case obvious, threes, hard, primes
}

struct TierConfig {
    let min: Int
    let weights: [Bucket: Int]   // percent — tune here
}

struct Trick {
    let trick: String
    let example: String
    let k: Int      // chop multiplier (0 for the non-chop tricks)
    let op: Int     // +1 add, -1 subtract (0 for the non-chop tricks)
}

struct Worked {
    let ok: Bool          // always equals n % p == 0 (asserted in tests)
    let lines: [String]
    /// One step per line — phones wrap long sums mid-expression otherwise.
    var steps: [String] { lines.flatMap { $0.components(separatedBy: ", ") } }
}

struct PrimeExplanation {
    let listNote: String?     // "29 is on the prime list."
    let rootLine: String?     // "523: 22² = 484 and 23² = 529, so check primes up to 22."
    let verdict: String?      // "None of 2, 3, … divide it, so it’s prime."
    let checked: [Int]        // the primes cleared, tappable in the UI
}

enum PrimeEngine {
    static let config: [Tier: TierConfig] = [
        .easy:   TierConfig(min: 2,   weights: [.obvious: 20, .threes: 20, .hard: 20, .primes: 40]),
        .medium: TierConfig(min: 2,   weights: [.obvious: 0,  .threes: 25, .hard: 35, .primes: 40]),
        .hard:   TierConfig(min: 100, weights: [.obvious: 0,  .threes: 0,  .hard: 50, .primes: 50]),
    ]

    /// √999 ≈ 31.6, so these test every number in range.
    static let small = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31]

    static let tricks: [Int: Trick] = [
        2:  Trick(trick: "Last digit is even", example: "538 ✓", k: 0, op: 0),
        3:  Trick(trick: "Digit sum divisible by 3", example: "471 → 12 ✓", k: 0, op: 0),
        5:  Trick(trick: "Last digit is 0 or 5", example: "935 ✓", k: 0, op: 0),
        7:  Trick(trick: "Chop last digit, ×2, subtract", example: "161 → 16 − 2 = 14 ✓", k: 2, op: -1),
        11: Trick(trick: "Alternating sum (+ − + …)", example: "506 → 5 − 0 + 6 = 11 ✓", k: 0, op: 0),
        13: Trick(trick: "Chop, ×4, add", example: "182 → 18 + 8 = 26 ✓", k: 4, op: 1),
        17: Trick(trick: "Chop, ×5, subtract", example: "221 → 22 − 5 = 17 ✓", k: 5, op: -1),
        19: Trick(trick: "Chop, ×2, add", example: "247 → 24 + 14 = 38 ✓", k: 2, op: 1),
        23: Trick(trick: "Chop, ×7, add", example: "299 → 29 + 63 = 92 = 4 × 23 ✓", k: 7, op: 1),
        29: Trick(trick: "Chop, ×3, add", example: "377 → 37 + 21 = 58 = 2 × 29 ✓", k: 3, op: 1),
        31: Trick(trick: "Chop, ×3, subtract", example: "403 → 40 − 9 = 31 ✓", k: 3, op: -1),
    ]

    static let chopNote = "\u{201C}Chop\u{201D} means split off the last digit. Multiply that digit as shown, then add it to or subtract it from what\u{2019}s left. If the result is a multiple of the prime (including 0), so is the original number."

    /// Smallest prime factor; n itself when n is prime.
    static func spf(_ n: Int) -> Int {
        for p in small {
            if p * p > n { break }
            if n % p == 0 { return p }
        }
        return n
    }

    static func isPrime(_ n: Int) -> Bool { n >= 2 && spf(n) == n }

    /// All 168 primes under 1,000.
    static let all: [Int] = (2...999).filter { isPrime($0) }

    static let buckets: [Tier: [Bucket: [Int]]] = {
        var out: [Tier: [Bucket: [Int]]] = [:]
        for tier in Tier.allCases {
            var b: [Bucket: [Int]] = [.obvious: [], .threes: [], .hard: [], .primes: []]
            for n in config[tier]!.min...999 {
                if isPrime(n) {
                    if tier != .easy && n <= 5 { continue }   // Medium/Hard drop 2, 3, 5
                    b[.primes]!.append(n)
                } else if n % 2 == 0 || n % 5 == 0 {
                    b[.obvious]!.append(n)
                } else if n % 3 == 0 {
                    b[.threes]!.append(n)
                } else {
                    b[.hard]!.append(n)
                }
            }
            out[tier] = b
        }
        return out
    }()

    /// Pick a bucket by weight, then a number from it; never the previous number.
    static func draw(_ tier: Tier, prev: Int?) -> (n: Int, bucket: Bucket) {
        let w = config[tier]!.weights, b = buckets[tier]!
        let keys = Bucket.allCases.filter { (w[$0] ?? 0) > 0 && !(b[$0] ?? []).isEmpty }
        let total = keys.reduce(0) { $0 + w[$1]! }
        while true {
            var r = Double.random(in: 0..<Double(total))
            var key = keys[keys.count - 1]
            for k in keys {
                if r < Double(w[k]!) { key = k; break }
                r -= Double(w[k]!)
            }
            let arr = b[key]!
            let n = arr[Int.random(in: 0..<arr.count)]
            if n != prev { return (n, key) }
        }
    }

    // MARK: - Worked tricks

    static func neg(_ x: Int) -> String { x < 0 ? "−\(-x)" : "\(x)" }

    /// "26 = 2 × 13 ✓" — 0 and negative multiples count.
    static func mult(_ r: Int, _ p: Int) -> String {
        if r % p != 0 { return "\(neg(r)) — not a multiple of \(p) ✗" }
        if r == 0 || abs(r) == p { return "\(neg(r)) ✓" }
        return "\(neg(r)) = \(neg(r / p)) × \(p) ✓"
    }

    /// Work p's trick on n.
    static func apply(_ p: Int, _ n: Int) -> Worked {
        let t = tricks[p]!
        let ds = String(n).compactMap { $0.wholeNumberValue }
        let last = n % 10
        switch p {
        case 2:
            return Worked(ok: last % 2 == 0, lines: ["Last digit \(last)" + (last % 2 == 0 ? " is even ✓" : " is odd ✗")])
        case 5:
            let ok = last == 0 || last == 5
            return Worked(ok: ok, lines: ["Last digit \(last)" + (ok ? " ✓" : " — not 0 or 5 ✗")])
        case 3:
            let s = ds.reduce(0, +)
            let head = ds.count > 1 ? ds.map { String($0) }.joined(separator: " + ") + " = " : ""
            return Worked(ok: s % 3 == 0, lines: [head + mult(s, 3)])
        case 11:
            var r = 0
            var parts: [String] = []
            for (i, d) in ds.enumerated() {
                r += i % 2 == 1 ? -d : d
                parts.append(i == 0 ? "\(d)" : (i % 2 == 1 ? "− \(d)" : "+ \(d)"))
            }
            let head = ds.count > 1 ? parts.joined(separator: " ") + " = " : ""
            return Worked(ok: r % 11 == 0, lines: [head + mult(r, 11)])
        default:
            var lines: [String] = []
            var x = n
            var step = 0
            while true {
                let a = x / 10, d = x % 10, m = d * t.k, r = a + t.op * m
                let again = r >= 100 && step < 4
                lines.append((step > 0 ? "again: \(x) → " : "") +
                             "chop → \(a) and \(d), \(d) × \(t.k) = \(m), \(a)" + (t.op > 0 ? " + " : " − ") + "\(m) = " +
                             (again ? "\(neg(r)) (still 100+)" : mult(r, p)))
                if again { x = r; step += 1; continue }
                return Worked(ok: r % p == 0, lines: lines)
            }
        }
    }

    // MARK: - Explanations

    /// "221 = 13 × 17"
    static func equation(_ n: Int) -> String {
        let p = spf(n)
        return "\(n) = \(p) × \(n / p)"
    }

    static func primeExplanation(_ n: Int) -> PrimeExplanation {
        let k = Int(Double(n).squareRoot())
        let chk = small.filter { $0 <= k }
        let list: String? = n <= 31 ? "\(n) is on the prime list." + (n <= 3 ? " Nothing to check." : "") : nil
        guard !chk.isEmpty else { return PrimeExplanation(listNote: list, rootLine: nil, verdict: nil, checked: []) }
        let root = "\(n): \(k)² = \(k * k) and \(k + 1)² = \((k + 1) * (k + 1)), so check primes up to \(k)."
        let verdict = (chk.count > 1
            ? "None of " + chk.map { String($0) }.joined(separator: ", ") + " divide it"
            : "\(chk[0]) doesn\u{2019}t divide it") + ", so it\u{2019}s prime."
        return PrimeExplanation(listNote: list, rootLine: root, verdict: verdict, checked: chk)
    }

    static func verdictLine(saidPrime: Bool, prime: Bool) -> String {
        if saidPrime { return prime ? "Yes! Prime." : "Not quite — it\u{2019}s composite." }
        return prime ? "Not quite — it\u{2019}s prime." : "Correct — composite."
    }
}
