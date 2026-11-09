//  HomeView.swift — Paint by Number first, everything else one tap down.
//
//  Home is the pictures to paint, with a To 10 / To 20 switch, then two tiles
//  (Dot to Dot, Draw your own) and one for the card games. Number games keeps
//  the old concept bar and skill tiles; Dot to Dot lists its two ways to play.
//  Back from any game returns to the screen it was started from.

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage("ns.paintTo") private var paintTo = 10

    var body: some View {
        let p = model.current
        let modeID = paintTo == 20 ? "dr.color20" : "dr.color10"
        let done = p?.pictures ?? []
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Hi, \(p?.name ?? "friend")!")
                    .font(Theme.round(34))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer()
                PlayerBadge()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Paint by Number").font(Theme.round(24)).foregroundStyle(Theme.text)
                        Spacer()
                        LevelSwitch(value: $paintTo)
                    }
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                        ForEach(Pictures.color) { pic in
                            PictureCard(kind: .color(max: paintTo), id: pic.id, name: pic.name, finished: done.contains("\(modeID)/\(pic.id)")) {
                                model.play(modeID, picture: pic.id)
                            }
                        }
                    }
                    WideTile(title: "Math Quest", detail: "Battle creatures with math and bring home the Wishing Star", symbol: "shield.lefthalf.filled") {
                        model.screen = .quest; Haptics.tick()
                    }
                    HStack(spacing: 14) {
                        SquareTile(title: "Dot to Dot", art: "→↑") { model.screen = .dots; Haptics.tick() }
                        SquareTile(title: "Draw your own", art: "✏️") { model.play("dr.explore") }
                    }
                    WideTile(title: "Number games", detail: "Even or odd, bigger or smaller, adding, times tables", symbol: "square.grid.2x2.fill") {
                        model.screen = .games; Haptics.tick()
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

/// To 10 or To 20: how big the answers in the pictures get.
private struct LevelSwitch: View {
    @Binding var value: Int
    var body: some View {
        HStack(spacing: 4) {
            ForEach([10, 20], id: \.self) { n in
                let on = value == n
                Button { value = n; Haptics.tick() } label: {
                    Text("To \(n)").font(Theme.round(16, .bold))
                        .foregroundStyle(on ? Theme.onColor : Theme.text)
                        .padding(.horizontal, 14).frame(minHeight: 44)
                        .background(on ? Theme.sprout : .clear, in: Capsule())
                }
                .accessibilityLabel("Answers to \(n)")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Theme.card, in: Capsule())
        .overlay(Capsule().stroke(Theme.border, lineWidth: 2))
    }
}

private struct SquareTile: View {
    let title: String
    let art: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(art).font(Theme.round(34)).foregroundStyle(Theme.text).accessibilityHidden(true)
                Text(title).font(Theme.round(20)).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 130)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(Theme.border, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}

private struct WideTile: View {
    let title: String
    let detail: String
    let symbol: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: symbol).font(.system(size: 28, weight: .bold)).foregroundStyle(Theme.sprout)
                    .frame(width: 60, height: 60).background(Theme.bg, in: RoundedRectangle(cornerRadius: 18))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(Theme.round(22)).foregroundStyle(Theme.text)
                    Text(detail).font(Theme.round(15, .semibold)).foregroundStyle(Theme.muted).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 20, weight: .bold)).foregroundStyle(Theme.muted)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(Theme.border, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}

/// A screen one level down from home: Back, a title, the player, then the list.
private struct SubScreen<Content: View>: View {
    @EnvironmentObject private var model: AppModel
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                CircleButton(symbol: "chevron.left", label: "Home") { model.screen = .home }
                Text(title).font(Theme.round(28)).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.6)
                Spacer()
                PlayerBadge()
            }
            content
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

/// Stars for card modes; finished pictures for Draw.
private func progress(_ mode: Mode, _ p: Profile?) -> (symbol: String, text: String, lit: Bool) {
    if case .draw(let kind) = mode.play {
        guard kind != .explore else { return ("scribble", "Free play", false) }
        let done = p?.pictures.filter { $0.hasPrefix(mode.id + "/") }.count ?? 0
        return ("photo.fill", "\(done) of \(Pictures.count(kind)) pictures", done > 0)
    }
    let stars = p?.stars[mode.id] ?? 0
    return ("star.fill", "\(stars)", stars > 0)
}

/// The card games: a concept at the top, then its skills.
struct GamesView: View {
    @EnvironmentObject private var model: AppModel
    @State private var picked: Concept?

    /// Opens on the concept of the last card game played.
    private var concept: Concept {
        if let c = picked { return c }
        if let c = model.current?.lastMode.flatMap({ Modes.mode($0)?.concept }), Concept.games.contains(c) { return c }
        return .evenOdd
    }

    var body: some View {
        let p = model.current
        SubScreen(title: "Number games") {
            ConceptBar(selection: Binding(get: { concept }, set: { picked = $0 }))
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(Modes.modes(concept)) { mode in
                        ModeTile(mode: mode, progress: progress(mode, p), last: p?.lastMode == mode.id) { model.play(mode.id) }
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
}

/// Dot to Dot's two ways to play.
struct DotsView: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        let p = model.current
        SubScreen(title: "Dot to Dot") {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(["dr.steps", "dr.pairs"].compactMap(Modes.mode)) { mode in
                        ModeTile(mode: mode, progress: progress(mode, p), last: p?.lastMode == mode.id) { model.play(mode.id) }
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
}

/// The concepts, one picture-and-word button each.
private struct ConceptBar: View {
    @Binding var selection: Concept

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Concept.games) { c in
                let on = c == selection
                Button { selection = c; Haptics.tick() } label: {
                    VStack(spacing: 6) {
                        Image(systemName: c.symbol).font(.system(size: 24, weight: .bold))
                        Text(c.title)
                            .font(Theme.round(11.5, .bold))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(on ? Theme.onColor : Theme.text)
                    .frame(maxWidth: .infinity, minHeight: 88)
                    .padding(.horizontal, 2)
                    .background(on ? Theme.sprout : Theme.card, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(on ? Theme.sprout : Theme.border, lineWidth: 2))
                }
                .accessibilityLabel(c.title)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}

/// One skill: its name, what it covers, its progress. One tap plays it.
private struct ModeTile: View {
    let mode: Mode
    let progress: (symbol: String, text: String, lit: Bool)
    let last: Bool
    let play: () -> Void

    var body: some View {
        Button(action: play) {
            HStack(spacing: 16) {
                Text(mode.art)
                    .font(Theme.round(mode.art.count > 3 ? 19 : 28))
                    .foregroundStyle(Theme.text)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(6)
                    .frame(width: 76, height: 76)
                    .background(Theme.bg, in: RoundedRectangle(cornerRadius: 20))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title).font(Theme.round(22)).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.7)
                    Text(mode.detail).font(Theme.round(15, .semibold)).foregroundStyle(Theme.muted).fixedSize(horizontal: false, vertical: true)
                    Label(progress.text, systemImage: progress.symbol)
                        .font(Theme.round(15, .bold))
                        .foregroundStyle(progress.lit ? Theme.star : Theme.muted.opacity(0.6))
                }
                Spacer(minLength: 0)
                Image(systemName: "play.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.onColor)
                    .frame(width: 52, height: 52)
                    .background(Theme.sprout, in: Circle())
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(last ? Theme.sprout : Theme.border, lineWidth: last ? 3 : 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.title). \(mode.detail). \(progress.text)")
    }
}

/// Who's playing, in the corner. Tap to switch players (no gate needed).
struct PlayerBadge: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        if let p = model.current {
            Button { model.switchPlayer() } label: {
                HStack(spacing: 8) {
                    Avatar(profile: p, size: 40)
                    Image(systemName: "arrow.left.arrow.right").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.muted)
                }
                .padding(6)
                .padding(.trailing, 6)
                .frame(minHeight: 52)
                .background(Theme.card, in: Capsule())
                .overlay(Capsule().stroke(Theme.border, lineWidth: 2))
            }
            .accessibilityLabel("Playing as \(p.name). Switch player")
        }
    }
}
