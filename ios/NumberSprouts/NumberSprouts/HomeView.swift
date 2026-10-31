//  HomeView.swift — pick a concept at the top, then a mode, and play.
//
//  Concepts (Even or Odd, Bigger or Smaller, Add & Subtract, Times Tables) sit
//  in a row at the top. Under the chosen one, its modes are named by the skill
//  they practise ("Pair the dots", "Last digit"), each with its own stars, so a
//  kid who has one skill down goes straight to the next instead of wading
//  through random easy cards. M1 has Even or Odd; the rest arrive in M2.

import SwiftUI

enum Concept: String, CaseIterable, Identifiable {
    case evenOdd, biggerSmaller, addSubtract, times
    var id: String { rawValue }
    var title: String {
        switch self {
        case .evenOdd: return "Even or Odd"
        case .biggerSmaller: return "Bigger or Smaller"
        case .addSubtract: return "Add & Subtract"
        case .times: return "Times Tables"
        }
    }
    var symbol: String {
        switch self {
        case .evenOdd: return "circle.grid.2x2.fill"
        case .biggerSmaller: return "greaterthan"
        case .addSubtract: return "plus.forwardslash.minus"
        case .times: return "multiply"
        }
    }
    var ready: Bool { self == .evenOdd }
}

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var concept: Concept = .evenOdd

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
                PlayerBadge()
            }
            ConceptBar(selection: $concept)
            ScrollView {
                VStack(spacing: 14) {
                    if concept.ready {
                        ForEach(Level.allCases) { level in
                            ModeTile(level: level,
                                     stars: p?.stars[EvenOdd.key(level)] ?? 0,
                                     last: p?.level(EvenOdd.deckID) == level) {
                                model.setLevel(level, deck: EvenOdd.deckID)
                                model.screen = .play
                            }
                        }
                    } else {
                        ComingSoon(concept: concept)
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
                            .font(Theme.round(12.5, .bold))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(on ? Theme.onColor : (c.ready ? Theme.text : Theme.muted))
                    .frame(maxWidth: .infinity, minHeight: 88)
                    .padding(.horizontal, 2)
                    .background(on ? Theme.sprout : Theme.card, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(on ? Theme.sprout : Theme.border, lineWidth: 2))
                }
                .accessibilityLabel(c.ready ? c.title : "\(c.title), coming soon")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}

/// One skill: its name, what it covers, its stars. One tap plays it.
private struct ModeTile: View {
    let level: Level
    let stars: Int
    let last: Bool
    let play: () -> Void

    var body: some View {
        Button(action: play) {
            HStack(spacing: 16) {
                ModeIcon(level: level)
                VStack(alignment: .leading, spacing: 4) {
                    Text(EvenOdd.modeTitle(level)).font(Theme.round(24)).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.7)
                    Text(EvenOdd.modeDetail(level)).font(Theme.round(15, .semibold)).foregroundStyle(Theme.muted)
                    Label("\(stars)", systemImage: "star.fill")
                        .font(Theme.round(15, .bold))
                        .foregroundStyle(stars > 0 ? Theme.star : Theme.muted.opacity(0.6))
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
        .accessibilityLabel("\(EvenOdd.modeTitle(level)). \(EvenOdd.modeDetail(level)). \(stars) stars")
    }
}

/// A small picture of each mode: dots, a numeral, a big number with its last digit lit.
private struct ModeIcon: View {
    let level: Level
    var body: some View {
        Group {
            switch level {
            case .sprout:
                HStack(spacing: 6) {
                    VStack(spacing: 5) { dot(Theme.even); dot(Theme.even) }
                    VStack(spacing: 5) { dot(Theme.odd); dot(.clear) }
                }
            case .grow:
                Text("17").font(Theme.round(34)).foregroundStyle(Theme.text)
            case .stretch:
                HStack(spacing: 0) {
                    Text("34").font(Theme.round(26)).foregroundStyle(Theme.muted)
                    Text("8").font(Theme.round(26)).foregroundStyle(Theme.onColor)
                        .padding(.horizontal, 4)
                        .background(Theme.even, in: RoundedRectangle(cornerRadius: 7))
                }
            }
        }
        .frame(width: 76, height: 76)
        .background(Theme.bg, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityHidden(true)
    }
    private func dot(_ c: Color) -> some View { Circle().fill(c).frame(width: 15, height: 15) }
}

private struct ComingSoon: View {
    let concept: Concept
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: concept.symbol).font(.system(size: 44, weight: .bold)).foregroundStyle(Theme.muted)
            Text("\(concept.title) is still growing.")
                .font(Theme.round(22))
                .foregroundStyle(Theme.text)
            Text("Coming soon!").font(Theme.round(17, .semibold)).foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .background(Theme.card.opacity(0.6), in: RoundedRectangle(cornerRadius: 26))
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
