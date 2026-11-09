//  QuestMath.swift — the Math Quest's story, creatures and problems.
//
//  An original quest, "The Wishing Star": a sleepy dragon flew off with Sprout
//  Hollow's star, and the kid and a buddy creature travel six stops to bring
//  it home. Each stop is a battle. Regular battles keep to sums and
//  differences up to 100 with one small or round number (40 + 7, 56 + 3);
//  the two boss battles save the two-digit work (23 + 14, 4 × 20, 38 + 45)
//  for the boss's own attacks.

import Foundation

struct QuestProblem: Equatable {
    let text: String           // "47 + 5"
    let answer: Int
    let options: [Int]         // four, one of them the answer
    let trick: String          // shown after a miss
}

enum QuestTier: CaseIterable {
    case within10, within20, to100, bossA, bossB
}

enum QuestMath {
    static func make<G: RandomNumberGenerator>(_ tier: QuestTier, using rng: inout G) -> QuestProblem {
        func r(_ range: ClosedRange<Int>) -> Int { Int.random(in: range, using: &rng) }
        let flip = Bool.random(using: &rng)
        switch tier {
        case .within10:
            if flip {
                let a = r(1...9), b = r(1...(10 - a))
                return add(a, b, using: &rng)
            }
            let a = r(3...10), b = r(1...(a - 1))
            return sub(a, b, using: &rng)
        case .within20:
            if flip {
                let a = r(4...12), b = r(max(2, 11 - a)...min(9, 20 - a))
                return add(a, b, using: &rng)
            }
            let a = r(11...20), b = r(2...9)
            return sub(a, b, using: &rng)
        case .to100:
            switch r(0...3) {
            case 0: return add(r(1...9) * 10, r(1...9), using: &rng)                 // 40 + 7
            case 1: let a = r(12...89); return add(a, r(2...min(9, 99 - a)), using: &rng)   // 56 + 3, 47 + 5
            case 2: let a = r(1...8); return add(a * 10, r(1...(9 - a)) * 10, using: &rng)  // 30 + 50
            default: let a = r(2...9) * 10 + r(3...9); return sub(a, r(1...(a % 10)), using: &rng)  // 48 − 3
            }
        case .bossA:
            switch r(0...2) {
            case 0:                                                                   // 23 + 14, no carrying
                let t1 = r(1...6), t2 = r(1...(8 - t1)), o1 = r(1...8), o2 = r(0...(9 - o1))
                return add(t1 * 10 + o1, t2 * 10 + o2, using: &rng)
            case 1: let n = r(2...3); return times(n, r(1...(9 / n)) * 10, using: &rng)     // 3 × 20
            default: let a = r(4...9); return sub(a * 10, r(1...(a - 1)) * 10, using: &rng)  // 70 − 30
            }
        case .bossB:
            switch r(0...2) {
            case 0:                                                                   // 38 + 45, with carrying
                let o1 = r(2...9), o2 = r((11 - o1)...9), t1 = r(1...5), t2 = r(1...(8 - t1))
                return add(t1 * 10 + o1, t2 * 10 + o2, using: &rng)
            case 1: let n = r(2...5); return times(n, r(1...(9 / n)) * 10, using: &rng)     // 4 × 20
            default:                                                                  // 68 − 25, no borrowing
                let t1 = r(3...9), o1 = r(2...9), t2 = r(1...(t1 - 1)), o2 = r(1...o1)
                return sub(t1 * 10 + o1, t2 * 10 + o2, using: &rng)
            }
        }
    }

    private static func add<G: RandomNumberGenerator>(_ a: Int, _ b: Int, using rng: inout G) -> QuestProblem {
        let s = a + b
        let trick: String
        if a >= 10 && b >= 10 {
            let tens = a / 10 * 10 + b / 10 * 10, ones = a % 10 + b % 10
            trick = ones == 0 ? "Tens: \(a / 10 * 10) + \(b / 10 * 10) = \(tens)."
                : "Tens: \(a / 10 * 10) + \(b / 10 * 10) = \(tens). Ones: \(a % 10) + \(b % 10) = \(ones). \(tens) + \(ones) = \(s)."
        } else if a % 10 == 0 && a >= 10 {
            trick = "\(a / 10) tens and \(b) ones make \(s)."
        } else if b <= 4 {
            trick = "Start at \(a) and count on \(b): " + (1...b).map { String(a + $0) }.joined(separator: ", ") + "."
        } else if a % 10 + b > 10 && a % 10 != 0 {
            let up = 10 - a % 10
            trick = "\(a) + \(up) = \(a + up), then \(b - up) more is \(s)."
        } else {
            trick = "\(a) + \(b) = \(s)."
        }
        return QuestProblem(text: "\(a) + \(b)", answer: s, options: options(s, using: &rng), trick: trick)
    }

    private static func sub<G: RandomNumberGenerator>(_ a: Int, _ b: Int, using rng: inout G) -> QuestProblem {
        let d = a - b
        let trick: String
        if b >= 10 {
            let tens = a / 10 * 10 - b / 10 * 10, ones = a % 10 - b % 10
            trick = ones == 0 ? "Tens: \(a / 10 * 10) − \(b / 10 * 10) = \(tens)."
                : "Tens: \(a / 10 * 10) − \(b / 10 * 10) = \(tens). Ones: \(a % 10) − \(b % 10) = \(ones). \(tens) + \(ones) = \(d)."
        } else if b <= 4 {
            trick = "Start at \(a) and count back \(b): " + (1...b).map { String(a - $0) }.joined(separator: ", ") + "."
        } else {
            trick = "\(b) + \(d) = \(a), so \(a) − \(b) = \(d)."
        }
        return QuestProblem(text: "\(a) − \(b)", answer: d, options: options(d, using: &rng), trick: trick)
    }

    private static func times<G: RandomNumberGenerator>(_ n: Int, _ tens: Int, using rng: inout G) -> QuestProblem {
        let p = n * tens
        return QuestProblem(text: "\(n) × \(tens)", answer: p, options: options(p, near: [10, 20], using: &rng),
                            trick: "\(n) × \(tens / 10) = \(n * tens / 10), so \(n) × \(tens) = \(p).")
    }

    /// The answer and three near misses: one off, two off, ten off.
    static func options<G: RandomNumberGenerator>(_ answer: Int, near: [Int] = [1, 2, 10], using rng: inout G) -> [Int] {
        var pool = near.flatMap { [answer + $0, answer - $0] }.filter { $0 >= 0 && $0 != answer }
        pool.shuffle(using: &rng)
        var out = [answer]
        for v in pool where out.count < 4 && !out.contains(v) { out.append(v) }
        var extra = answer + 3
        while out.count < 4 { if !out.contains(extra) { out.append(extra) }; extra += 1 }
        return out.shuffled(using: &rng)
    }
}

// MARK: - the quest

struct Buddy: Identifiable, Equatable {
    let id: String
    let name: String
    let emoji: String
    let kind: String           // "fire fox"
    let moves: [String]
    let blast: String          // what flies across when it attacks
}

struct Foe: Equatable {
    let name: String
    let emoji: String
    let moves: [String]
    let blast: String
    let hp: Int
    let boss: Bool
}

struct QuestStop: Identifiable, Equatable {
    let id: Int
    let place: String
    let scenery: String
    let story: [String]        // "{buddy}" becomes the buddy's name
    let foe: Foe
    let tier: QuestTier        // the buddy's attacks, and a regular foe's
    let bossTier: QuestTier?   // a boss's own attacks
    let win: String
}

enum Quest {
    static let buddies: [Buddy] = [
        Buddy(id: "cinder", name: "Cinder", emoji: "🦊", kind: "fire fox", moves: ["Spark Pounce", "Flame Twirl"], blast: "🔥"),
        Buddy(id: "puddles", name: "Puddles", emoji: "🐢", kind: "water turtle", moves: ["Bubble Pop", "Wave Roll"], blast: "💧"),
        Buddy(id: "sprig", name: "Sprig", emoji: "🦎", kind: "leaf lizard", moves: ["Leaf Swirl", "Thorn Dash"], blast: "🍃"),
    ]
    static func buddy(_ id: String?) -> Buddy? { buddies.first { $0.id == id } }

    static let stops: [QuestStop] = [
        QuestStop(id: 0, place: "Sunny Meadow", scenery: "🌼 ☀️ 🌿",
                  story: ["Oh no! The Wishing Star of Sprout Hollow is gone. A sleepy dragon flew off with it!",
                          "You and {buddy} set off to bring it home. The path starts in Sunny Meadow."],
                  foe: Foe(name: "Bog Hopper", emoji: "🐸", moves: ["Mud Splash", "Big Hop"], blast: "💦", hp: 3, boss: false),
                  tier: .within10, bossTier: nil, win: "Bog Hopper hops away, giggling. Onward!"),
        QuestStop(id: 1, place: "Whisper Woods", scenery: "🌲 🍄 🌲",
                  story: ["The trees whisper as you walk. Something is watching from a branch…"],
                  foe: Foe(name: "Hootle", emoji: "🦉", moves: ["Wing Flap", "Twig Toss"], blast: "🍂", hp: 3, boss: false),
                  tier: .within20, bossTier: nil, win: "Hootle hoots and points a wing toward the bridge."),
        QuestStop(id: 2, place: "Rumble Bridge", scenery: "🪨 🌉 🪨",
                  story: ["A big bear blocks the bridge.",
                          "\"Nobody crosses Rumble Bridge without a BOSS BATTLE!\" says Grumble."],
                  foe: Foe(name: "Grumble", emoji: "🐻", moves: ["Bear Hug", "Big Stomp"], blast: "💥", hp: 4, boss: true),
                  tier: .to100, bossTier: .bossA, win: "Grumble steps aside and shares a honey snack. Yum!"),
        QuestStop(id: 3, place: "Crystal Cave", scenery: "💎 🕯️ 💎",
                  story: ["The cave sparkles in the dark. {buddy} hears a squeak above you…"],
                  foe: Foe(name: "Echo Bat", emoji: "🦇", moves: ["Squeak Wave", "Swoop"], blast: "🌀", hp: 3, boss: false),
                  tier: .to100, bossTier: nil, win: "Echo Bat flutters off for a nap. The way out glows ahead."),
        QuestStop(id: 4, place: "Windy Peak", scenery: "🏔️ 💨 🏔️",
                  story: ["The wind blows hard on the mountain. A goat jumps onto the path!"],
                  foe: Foe(name: "Rocky", emoji: "🐐", moves: ["Head Bonk", "Rock Roll"], blast: "🪨", hp: 3, boss: false),
                  tier: .to100, bossTier: nil, win: "From the top you can see smoke. The dragon's den is close!"),
        QuestStop(id: 5, place: "Dragon's Den", scenery: "🌋 ⭐ 🌋",
                  story: ["Smokewing the dragon is curled around the Wishing Star.",
                          "\"It's so SHINY,\" says Smokewing. \"Beat me in a BOSS BATTLE and it's yours!\""],
                  foe: Foe(name: "Smokewing", emoji: "🐉", moves: ["Fire Puff", "Tail Swish", "Smoke Ring"], blast: "🔥", hp: 5, boss: true),
                  tier: .to100, bossTier: .bossB, win: "Smokewing gives back the Wishing Star and says sorry. Sprout Hollow cheers!"),
    ]
}

/// What a kid has done in the quest, kept on their profile.
struct QuestSave: Codable, Equatable {
    var buddy: String?
    var cleared = 0            // stops won, in order
}

// MARK: - one battle

/// Turns go foe, buddy, foe, buddy. On the foe's turn a right answer dodges and
/// a miss costs a heart; on the buddy's turn a right answer lands the move.
/// Out of hearts is never game over: the buddy rests and the battle starts again.
final class Battle: ObservableObject {
    enum Turn { case dodge, attack }
    enum Phase: Equatable { case intro, asking, result(right: Bool), won, lost }

    static let hearts = 4

    let stop: QuestStop
    let buddy: Buddy
    @Published private(set) var phase: Phase = .intro
    @Published private(set) var turn: Turn = .dodge
    @Published private(set) var foeHP: Int
    @Published private(set) var buddyHP = Battle.hearts
    @Published private(set) var problem: QuestProblem
    @Published private(set) var move = ""
    private var turns = 0
    private let deal: (QuestTier) -> QuestProblem

    init(stop: QuestStop, buddy: Buddy, deal: @escaping (QuestTier) -> QuestProblem = { t in
        var g = SystemRandomNumberGenerator(); return QuestMath.make(t, using: &g) }) {
        self.stop = stop; self.buddy = buddy; self.deal = deal
        foeHP = stop.foe.hp
        problem = deal(stop.tier)
    }

    var message: String {
        let foe = stop.foe.name
        switch phase {
        case .intro: return stop.foe.boss ? "BOSS BATTLE! \(foe) wants to fight!" : "A wild \(foe) appears!"
        case .asking: return turn == .dodge ? "\(foe) used \(move)! Solve it to dodge!" : "Your turn! Solve it and \(buddy.name) uses \(move)!"
        case .result(let right):
            switch (turn, right) {
            case (.dodge, true): return "Dodged! \(buddy.name) jumped out of the way!"
            case (.dodge, false): return "Oof! \(move) hit \(buddy.name). It was \(problem.answer)."
            case (.attack, true): return foeHP == 0 ? "\(move) hits! \(foe) is all tuckered out!" : "\(move) hits \(foe)!"
            case (.attack, false): return "\(move) missed! It was \(problem.answer)."
            }
        case .won: return "You beat \(foe)! " + stop.win
        case .lost: return "\(buddy.name) is worn out. Have a rest, then try again!"
        }
    }

    func begin() { guard phase == .intro else { return }; ask() }

    private func ask() {
        let bossTurn = turn == .dodge && stop.foe.boss
        problem = deal(bossTurn ? (stop.bossTier ?? stop.tier) : stop.tier)
        let moves = turn == .dodge ? stop.foe.moves : buddy.moves
        move = moves[turns / 2 % moves.count]
        phase = .asking
    }

    @discardableResult
    func answer(_ value: Int) -> Bool {
        guard phase == .asking else { return false }
        let right = value == problem.answer
        if turn == .dodge && !right { buddyHP -= 1 }
        if turn == .attack && right { foeHP -= 1 }
        phase = .result(right: right)
        return right
    }

    func next() {
        guard case .result = phase else { return }
        if foeHP <= 0 { phase = .won; return }
        if buddyHP <= 0 { phase = .lost; return }
        turns += 1
        turn = turn == .dodge ? .attack : .dodge
        ask()
    }

    func restart() {
        foeHP = stop.foe.hp; buddyHP = Battle.hearts; turns = 0; turn = .dodge
        phase = .intro
    }
}
