//  Profiles.swift — who's playing, and what each kid has earned.
//
//  One profile per kid. Each keeps its own stars (per mode) and finished
//  pictures, so the kids' progress never mixes. Everything lives in
//  UserDefaults on this phone as one small JSON blob; nothing is sent anywhere.

import Foundation
import SwiftUI

struct Profile: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var icon: String              // an emoji, or an SF Symbol name when `isSymbol`
    var isSymbol = false
    var color: Int = 0            // index into Theme.tileColors
    var stars: [String: Int] = [:]          // mode id → stars earned, all rounds
    var rounds: [String: Int] = [:]         // mode id → rounds finished
    var pictures: Set<String> = []          // finished Draw pictures, "dr.steps/boat"
    var lastMode: String?

    init(id: UUID = UUID(), name: String, icon: String, isSymbol: Bool = false, color: Int = 0) {
        self.id = id; self.name = name; self.icon = icon; self.isSymbol = isSymbol; self.color = color
    }

    /// Tolerant decoding: a field added later is simply empty in older saves.
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        icon = try c.decode(String.self, forKey: .icon)
        isSymbol = try c.decodeIfPresent(Bool.self, forKey: .isSymbol) ?? false
        color = try c.decodeIfPresent(Int.self, forKey: .color) ?? 0
        stars = try c.decodeIfPresent([String: Int].self, forKey: .stars) ?? [:]
        rounds = try c.decodeIfPresent([String: Int].self, forKey: .rounds) ?? [:]
        pictures = try c.decodeIfPresent(Set<String>.self, forKey: .pictures) ?? []
        lastMode = try c.decodeIfPresent(String.self, forKey: .lastMode)
    }
}

final class AppModel: ObservableObject {
    enum Screen: Equatable { case who, home, play(String) }

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

    func switchPlayer() { screen = .who }

    func play(_ modeID: String) {
        update { $0.lastMode = modeID }
        screen = .play(modeID)
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

    func recordRound(mode: String, stars: Int) {
        update {
            $0.stars[mode, default: 0] += stars
            $0.rounds[mode, default: 0] += 1
        }
    }

    func recordPicture(_ key: String) {
        update { $0.pictures.insert(key) }
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
