//  Profiles.swift — who's playing, and what each kid has earned.
//
//  One profile per kid. Each keeps its own levels and stars so the kids'
//  progress never mixes. Everything lives in UserDefaults on this phone as one
//  small JSON blob; nothing is sent anywhere.

import Foundation
import SwiftUI

struct Profile: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var icon: String              // an emoji, or an SF Symbol name when `isSymbol`
    var isSymbol = false
    var color: Int = 0            // index into Theme.tileColors
    var levels: [String: Level] = [:]       // deck id → chosen level
    var stars: [String: Int] = [:]          // deck id → stars earned, all rounds
    var rounds: [String: Int] = [:]         // deck id → rounds finished

    func level(_ deck: String) -> Level { levels[deck] ?? .sprout }
}

final class AppModel: ObservableObject {
    enum Screen: Equatable { case who, home, play }

    @Published private(set) var profiles: [Profile] = []
    @Published var currentID: UUID?
    @Published var screen: Screen = .who

    static let storeKey = "ns.profiles.v1"
    private let store: UserDefaults

    init(store: UserDefaults = .standard) {
        self.store = store
        load()
    }

    var current: Profile? { profiles.first { $0.id == currentID } }

    func choose(_ p: Profile) {
        currentID = p.id
        screen = .home
        Haptics.tick()
    }

    func switchPlayer() {
        screen = .who
    }

    /// Adds or replaces a profile by id.
    func save(_ p: Profile) {
        let name = p.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        var p = p
        p.name = name
        if let i = profiles.firstIndex(where: { $0.id == p.id }) { profiles[i] = p } else { profiles.append(p) }
        persist()
    }

    func setLevel(_ level: Level, deck: String) {
        update { $0.levels[deck] = level }
    }

    func recordRound(deck: String, stars: Int) {
        update {
            $0.stars[deck, default: 0] += stars
            $0.rounds[deck, default: 0] += 1
        }
    }

    private func update(_ change: (inout Profile) -> Void) {
        guard let id = currentID, let i = profiles.firstIndex(where: { $0.id == id }) else { return }
        change(&profiles[i])
        persist()
    }

    private func load() {
        guard let data = store.data(forKey: Self.storeKey),
              let saved = try? JSONDecoder().decode([Profile].self, from: data) else { return }
        profiles = saved
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(profiles) { store.set(data, forKey: Self.storeKey) }
    }
}
