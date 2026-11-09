//  HomeView.swift — five topics at home; each topic's games one tap down.
//
//  Home is just the topics (Sounds, Rhymes, Words, Word tricks, Story), one
//  big tile each, plus read aloud and the player. A topic opens its games,
//  named by the skill they practise ("First sound", "Magic e"), each with its
//  own stars. Back from a game returns to its topic. The list itself lives
//  in Modes.swift.

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: AppModel

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
                ReadAloudButton()
                PlayerBadge()
            }
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(Concept.allCases) { c in
                        TopicTile(concept: c, last: p?.lastMode.flatMap { Modes.mode($0)?.concept } == c) {
                            model.screen = .topic(c); Haptics.tick()
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

/// One topic's games, with Back to home.
struct TopicView: View {
    @EnvironmentObject private var model: AppModel
    let concept: Concept

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
            HStack(spacing: 12) {
                CircleButton(symbol: "chevron.left", label: "Home") { model.screen = .home }
                Text(concept.title).font(Theme.round(28)).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.6)
                Spacer()
                ReadAloudButton()
                PlayerBadge()
            }
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

/// Reads each card out loud as it appears, when on.
private struct ReadAloudButton: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
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
    }
}

/// A topic at home: its picture, name and what's inside.
private struct TopicTile: View {
    let concept: Concept
    let last: Bool
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(spacing: 16) {
                Image(systemName: concept.symbol)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Theme.sprout)
                    .frame(width: 76, height: 76)
                    .background(Theme.bg, in: RoundedRectangle(cornerRadius: 20))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(concept.title).font(Theme.round(24)).foregroundStyle(Theme.text)
                    Text(concept.blurb).font(Theme.round(15, .semibold)).foregroundStyle(Theme.muted).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 20, weight: .bold)).foregroundStyle(Theme.muted)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(last ? Theme.sprout : Theme.border, lineWidth: last ? 3 : 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(concept.title). \(concept.blurb)")
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
