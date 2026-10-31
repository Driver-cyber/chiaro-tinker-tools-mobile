//  HomeView.swift — pick a concept at the top, then a mode, and play.
//
//  Concepts (Sounds, Rhymes, Words, Word tricks, Story) sit in a row at the
//  top. Under the chosen one, its modes are named by the skill they practise
//  ("First sound", "Magic e"), each with its own stars, so a
//  kid who has one skill down goes straight to the next instead of wading
//  through random easy cards. The list itself lives in Modes.swift.

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var picked: Concept?

    /// Reopens on the concept of the last mode played, so Stop or Done comes back to where the kid was.
    private var concept: Concept {
        picked ?? model.current?.lastMode.flatMap { Modes.mode($0)?.concept } ?? .sounds
    }

    /// Stars for card modes; the story count for Story.
    private func progress(_ mode: Mode, _ p: Profile?) -> (symbol: String, text: String, lit: Bool) {
        switch mode.play {
        case .storyBuild: return ("sparkles", "Make one up", false)
        case .storyBook:
            let n = p?.stories.count ?? 0
            return ("book.fill", "\(n) \(n == 1 ? "story" : "stories")", n > 0)
        case .cards: break
        }
        let stars = p?.stars[mode.id] ?? 0
        return ("star.fill", "\(stars)", stars > 0)
    }

    var body: some View {
        let p = model.current
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Hi, \(p?.name ?? "friend")!")
                    .font(Theme.round(34))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer()
                Button { model.readAloud.toggle(); Haptics.tick() } label: {
                    Image(systemName: model.readAloud ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(model.readAloud ? Theme.onColor : Theme.muted)
                        .frame(width: 52, height: 52)
                        .background(model.readAloud ? Theme.even : Theme.card, in: Circle())
                        .overlay(Circle().stroke(Theme.border, lineWidth: 2))
                }
                .accessibilityLabel(model.readAloud ? "Read aloud is on" : "Read aloud is off")
                .accessibilityHint("Reads each card out loud as it appears")
                PlayerBadge()
            }
            ConceptBar(selection: Binding(get: { concept }, set: { picked = $0 }))
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(Modes.modes(concept)) { mode in
                        ModeTile(mode: mode, progress: progress(mode, p), last: p?.lastMode == mode.id) {
                            model.play(mode.id)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

/// The concepts, one picture-and-word button each.
private struct ConceptBar: View {
    @Binding var selection: Concept

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Concept.allCases) { c in
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
