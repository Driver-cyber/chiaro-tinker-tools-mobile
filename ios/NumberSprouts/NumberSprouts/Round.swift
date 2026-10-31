//  Round.swift — one round of ten cards.
//
//  A right answer celebrates and moves on. A miss always opens the Trick card,
//  then the same card comes back for one retry; a second miss shows the trick
//  again and moves on. Stars count first-try answers only, and nothing is ever
//  taken away: no lives, no timer.

import Foundation
import UIKit

final class Round: ObservableObject {
    enum Phase: Equatable {
        case asking      // waiting for an answer
        case right       // celebrating; the view advances after a beat
        case missed      // the Trick card is open
        case retrying    // the same card, once more
        case done        // the round summary
    }

    let level: Level
    @Published private(set) var cards: [EvenOddCard]
    @Published private(set) var index = 0
    @Published private(set) var phase: Phase = .asking
    @Published private(set) var firstTry = 0
    private var retryUsed = false
    private var missedThis = false

    init(level: Level, cards: [EvenOddCard]? = nil) {
        self.level = level
        self.cards = cards ?? EvenOdd.round(level)
    }

    var card: EvenOddCard { cards[index] }
    var count: Int { cards.count }

    /// 1–3 stars from first-try answers: 9–10 → 3, 6–8 → 2, else 1. Finishing always earns one.
    var stars: Int { Round.stars(firstTry: firstTry, of: count) }
    static func stars(firstTry: Int, of count: Int) -> Int {
        let share = Double(firstTry) / Double(max(count, 1))
        return share >= 0.9 ? 3 : share >= 0.6 ? 2 : 1
    }

    /// Returns whether the answer was right; ignored unless a card is waiting.
    @discardableResult
    func answer(even: Bool) -> Bool {
        guard phase == .asking || phase == .retrying else { return false }
        let right = even == card.isEven
        if right {
            if !missedThis { firstTry += 1 }
            phase = .right
            Haptics.right()
        } else {
            missedThis = true
            phase = .missed
            Haptics.miss()
        }
        return right
    }

    /// "Got it" on the Trick card: one retry of the same card, then onward.
    func gotIt() {
        guard phase == .missed else { return }
        if retryUsed { advance() } else { retryUsed = true; phase = .retrying }
    }

    /// After the celebration, or after a second miss.
    func advance() {
        guard phase == .right || phase == .missed else { return }
        retryUsed = false
        missedThis = false
        if index + 1 < count { index += 1; phase = .asking } else { phase = .done }
    }
}

enum Haptics {
    static func right() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func miss() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func tick() { UISelectionFeedbackGenerator().selectionChanged() }
}
