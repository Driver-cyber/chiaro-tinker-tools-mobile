//  WhoView.swift — "Who's playing?", and adding or editing a player.
//
//  Big tiles, one tap to start. A first launch with nobody saved goes straight
//  to "Add a player". (Reorder and delete arrive with the parent area in M3;
//  for now the pencil edits name, picture and colour.)

import SwiftUI

struct WhoView: View {
    @EnvironmentObject private var model: AppModel
    @State private var editing: Profile?
    @State private var editMode = false

    var body: some View {
        if model.profiles.isEmpty {
            ProfileEditor(profile: Profile(name: "", icon: "🦊"), firstRun: true) { p in
                model.save(p)
                if let saved = model.profiles.first(where: { $0.id == p.id }) { model.choose(saved) }
            } cancel: {}
        } else {
            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Text("Who's playing?")
                            .font(Theme.round(34))
                            .foregroundStyle(Theme.text)
                        Spacer()
                        Button { withAnimation { editMode.toggle() } } label: {
                            Image(systemName: editMode ? "checkmark" : "pencil")
                                .font(.system(size: 20, weight: .bold))
                                .frame(width: 52, height: 52)
                                .background(Theme.card, in: Circle())
                                .overlay(Circle().stroke(Theme.border, lineWidth: 2))
                        }
                        .foregroundStyle(Theme.text)
                        .accessibilityLabel(editMode ? "Done editing" : "Edit players")
                    }
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                        ForEach(model.profiles) { p in
                            Button {
                                if editMode { editing = p } else { model.choose(p) }
                            } label: { PlayerTile(profile: p, editing: editMode) }
                            .accessibilityLabel(editMode ? "Edit \(p.name)" : p.name)
                        }
                        Button { editing = Profile(name: "", icon: "🐢", color: model.profiles.count) } label: { AddTile() }
                            .accessibilityLabel("Add a player")
                    }
                }
                .padding(20)
            }
            .sheet(item: $editing) { p in
                ProfileEditor(profile: p, firstRun: false) { model.save($0); editing = nil } cancel: { editing = nil }
            }
        }
    }
}

private struct PlayerTile: View {
    let profile: Profile
    let editing: Bool

    var body: some View {
        VStack(spacing: 12) {
            Avatar(profile: profile, size: 96)
            Text(profile.name)
                .font(Theme.round(24))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, minHeight: 176)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(editing ? Theme.sprout : Theme.border, lineWidth: editing ? 3 : 2))
        .overlay(alignment: .topTrailing) {
            if editing {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Theme.sprout)
                    .padding(10)
            }
        }
    }
}

private struct AddTile: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(Theme.sprout)
                .frame(width: 96, height: 96)
                .background(Theme.sprout.opacity(0.14), in: RoundedRectangle(cornerRadius: 27))
            Text("Add a player")
                .font(Theme.round(20, .bold))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, minHeight: 176)
        .background(Theme.card.opacity(0.5), in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Theme.border, style: StrokeStyle(lineWidth: 2, dash: [8, 6])))
    }
}

/// Name, picture and colour. Used for a first player, a new one, or an edit.
struct ProfileEditor: View {
    @State var profile: Profile
    let firstRun: Bool
    let save: (Profile) -> Void
    let cancel: () -> Void
    @FocusState private var nameFocused: Bool

    static let emoji = ["🦊", "🐢", "🦖", "🚀", "⚽", "🦄", "🐙", "🌟", "🐼", "🐯", "🦁", "🐸", "🐵", "🐧", "🦋",
                        "🐝", "🐞", "🐬", "🐳", "🦕", "🌈", "🍕", "🍩", "🎨", "🎸", "🏀", "🚗", "✈️", "🌻", "🍉"]
    static let symbols = ["star.fill", "bolt.fill", "leaf.fill", "moon.stars.fill", "pawprint.fill", "heart.fill"]

    private var canSave: Bool { !profile.name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(firstRun ? "Add a player" : (profile.name.isEmpty ? "New player" : "Edit player"))
                    .font(Theme.round(34))
                    .foregroundStyle(Theme.text)
                HStack(spacing: 16) {
                    Avatar(profile: profile, size: 88)
                    TextField("Name", text: $profile.name)
                        .font(Theme.round(28, .bold))
                        .foregroundStyle(Theme.text)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .focused($nameFocused)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 64)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border, lineWidth: 2))
                        .accessibilityLabel("Player name")
                }
                section("Colour") {
                    HStack(spacing: 10) {
                        ForEach(0..<Theme.tileColors.count, id: \.self) { i in
                            Button { profile.color = i; Haptics.tick() } label: {
                                Circle().fill(Theme.tile(i))
                                    .frame(width: 36, height: 36)
                                    .overlay(Circle().stroke(Theme.text, lineWidth: profile.color == i ? 3 : 0).padding(-4))
                                    .frame(width: 40, height: 44)
                            }
                            .accessibilityLabel("Colour \(i + 1)")
                            .accessibilityAddTraits(profile.color == i ? .isSelected : [])
                        }
                    }
                }
                section("Picture") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                        ForEach(Self.emoji, id: \.self) { e in
                            pick(selected: !profile.isSymbol && profile.icon == e) { Text(e).font(.system(size: 30)) } action: {
                                profile.icon = e; profile.isSymbol = false
                            }
                            .accessibilityLabel(e)
                        }
                        ForEach(Self.symbols, id: \.self) { s in
                            pick(selected: profile.isSymbol && profile.icon == s) {
                                Image(systemName: s).font(.system(size: 24, weight: .bold)).foregroundStyle(Theme.tile(profile.color))
                            } action: { profile.icon = s; profile.isSymbol = true }
                            .accessibilityLabel(s)
                        }
                    }
                }
                HStack(spacing: 12) {
                    if !firstRun { Button("Cancel", action: cancel).buttonStyle(SoftButtonStyle()) }
                    Button(firstRun ? "Let's play" : "Save") { save(profile) }
                        .buttonStyle(BigButtonStyle())
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.45)
                }
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.bg.ignoresSafeArea())
        .onAppear { if profile.name.isEmpty { nameFocused = true } }
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(Theme.round(18, .bold)).foregroundStyle(Theme.muted)
            content()
        }
    }

    private func pick<L: View>(selected: Bool, @ViewBuilder _ label: () -> L, action: @escaping () -> Void) -> some View {
        Button { action(); Haptics.tick() } label: {
            label()
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(selected ? Theme.tile(profile.color).opacity(0.22) : Theme.card, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? Theme.tile(profile.color) : Theme.border, lineWidth: selected ? 3 : 1.5))
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
