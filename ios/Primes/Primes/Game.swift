//  Game.swift — the state of one sitting, plus the one thing that lasts.
//
//  Everything here is in memory except `solved`: the primes you've called
//  right, with the first day you did. It lives in UserDefaults on the phone
//  (so it rides the phone's own iCloud backup) and is never sent anywhere.
//  The streak dies with the app — practice feedback, never a come-back hook.

import Foundation
import UIKit

final class Game: ObservableObject {
    enum Screen { case welcome, question, answer }

    @Published var tier: Tier = .easy            // a change applies to the next number
    @Published private(set) var screen: Screen = .welcome
    @Published private(set) var n: Int = 0
    @Published private(set) var streak = 0
    @Published var checked: Set<Int> = []        // the Checklist; resets on Next
    @Published private(set) var saidPrime = false
    @Published private(set) var freshFind = false
    @Published private(set) var solved: [Int: String] = [:]

    static let storeKey = "primes.solved.v1"
    private let store: UserDefaults

    init(store: UserDefaults = .standard) {
        self.store = store
        load()
    }

    var isPrime: Bool { PrimeEngine.isPrime(n) }
    var wasRight: Bool { saidPrime == isPrime }
    var foundCount: Int { PrimeEngine.all.filter { solved[$0] != nil }.count }

    func deal() {
        checked = []
        n = PrimeEngine.draw(tier, prev: n == 0 ? nil : n).n
        screen = .question
    }

    /// Back to the welcome screen. The number on the table is set down, not answered.
    func home() {
        checked = []
        screen = .welcome
    }

    func answer(saidPrime: Bool) {
        guard screen == .question else { return }
        self.saidPrime = saidPrime
        let right = saidPrime == isPrime
        streak = right ? streak + 1 : 0
        freshFind = false
        if isPrime && right && solved[n] == nil {   // the meter's one write
            solved[n] = Game.today()
            save()
            freshFind = true
        }
        Haptics.result(right)
        screen = .answer
    }

    private func load() {
        guard let data = store.data(forKey: Game.storeKey),
              let raw = try? JSONDecoder().decode([String: String].self, from: data) else { return }
        var out: [Int: String] = [:]
        for (k, v) in raw { if let i = Int(k) { out[i] = v } }
        solved = out
    }

    private func save() {
        var raw: [String: String] = [:]
        for (k, v) in solved { raw[String(k)] = v }
        if let data = try? JSONEncoder().encode(raw) { store.set(data, forKey: Game.storeKey) }
    }

    static func today() -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

enum Haptics {
    static func result(_ right: Bool) {
        UINotificationFeedbackGenerator().notificationOccurred(right ? .success : .error)
    }
    static func tick() { UISelectionFeedbackGenerator().selectionChanged() }
}
