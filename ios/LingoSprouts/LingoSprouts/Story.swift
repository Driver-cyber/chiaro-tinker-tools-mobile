//  Story.swift — build a silly sentence, hear it, keep it.
//
//  Four rows of tiles: Who? Did what? To what? Where? Pick one from each and
//  the scene appears in pictures with the sentence under it. "Read it" says
//  the sentence with each word lighting up as it's spoken; tap any single word
//  to hear just that word. Every story read is kept in the player's story book.

import SwiftUI

enum StoryParts {
    static let rows: [(title: String, tiles: [Word])] = [
        ("Who?", Words.storyWho), ("Did what?", Words.storyDid), ("To what?", Words.storyWhat), ("Where?", Words.storyWhere),
    ]

    /// "The dog ate a pizza in the park."
    static func sentence(_ parts: [Word]) -> String {
        let s = parts.map(\.text).joined(separator: " ") + "."
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    /// A saved story: its pictures, a tab, its sentence.
    static func saved(_ parts: [Word]) -> String { parts.map(\.pic).joined() + "\t" + sentence(parts) }
    static func split(_ saved: String) -> (pics: String, sentence: String) {
        let p = saved.components(separatedBy: "\t")
        return (p.first ?? "", p.count > 1 ? p[1] : saved)
    }
}

struct StoryBuilder: View {
    @EnvironmentObject private var model: AppModel
    @State private var offered: [[Word]] = []
    @State private var chosen: [Int: Word] = [:]
    @State private var bursts = 0

    private var parts: [Word]? {
        let p = (0..<StoryParts.rows.count).compactMap { chosen[$0] }
        return p.count == StoryParts.rows.count ? p : nil
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                CircleButton(symbol: "xmark", label: "Back") { Reader.shared.stop(); model.screen = .home }
                Text("Build a story").font(Theme.round(26)).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.6)
                Spacer()
                CircleButton(symbol: "dice.fill", label: "New tiles") { deal() }
                PlayerBadge()
            }
            .padding(.top, 8)
            scene
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(StoryParts.rows.enumerated()), id: \.offset) { r, row in
                        Text(row.title).font(Theme.round(17, .bold)).foregroundStyle(Theme.muted)
                        HStack(spacing: 8) {
                            ForEach(r < offered.count ? offered[r] : [], id: \.self) { w in tile(w, row: r) }
                        }
                    }
                }
            }
            HStack(spacing: 10) {
                Button { read() } label: { Label("Read it", systemImage: "speaker.wave.2.fill") }
                    .buttonStyle(BigButtonStyle())
                    .disabled(parts == nil)
                    .opacity(parts == nil ? 0.45 : 1)
                Button { chosen = [:]; deal() } label: { Label("New story", systemImage: "arrow.clockwise") }
                    .buttonStyle(SoftButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .overlay { Burst(trigger: bursts).allowsHitTesting(false) }
        .onAppear { if offered.isEmpty { deal() } }
    }

    private func deal() {
        offered = StoryParts.rows.enumerated().map { r, row in
            var four = Array(row.tiles.shuffled().prefix(4))
            if let keep = chosen[r], !four.contains(keep) { four[0] = keep }     // keep what's already picked
            return four
        }
        Haptics.tick()
    }

    private func tile(_ w: Word, row: Int) -> some View {
        let on = chosen[row] == w
        return Button { chosen[row] = w; Haptics.tick() } label: {
            VStack(spacing: 2) {
                Text(w.pic).font(.system(size: 30))
                Text(w.text).font(Theme.round(13, .bold)).foregroundStyle(on ? Theme.onColor : Theme.text)
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .padding(.horizontal, 2)
            .background(on ? Theme.sprout : Theme.card, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(on ? Theme.sprout : Theme.border, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(w.text)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private var scene: some View {
        VStack(spacing: 10) {
            Text((0..<StoryParts.rows.count).map { chosen[$0]?.pic ?? "❔" }.joined(separator: " "))
                .font(.system(size: 44))
                .accessibilityHidden(true)
            if let p = parts {
                SpokenSentence(sentence: StoryParts.sentence(p))
            } else {
                Text("Pick a tile in each row.").font(Theme.round(18, .bold)).foregroundStyle(Theme.muted)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 150)
        .modifier(CardChrome(glowing: false))
    }

    private func read() {
        guard let p = parts else { return }
        Reader.shared.say(StoryParts.sentence(p))
        model.saveStory(StoryParts.saved(p))
        bursts += 1
        Haptics.right()
    }
}

/// A sentence whose words light up as they're spoken; tap a word to hear it alone.
struct SpokenSentence: View {
    let sentence: String
    @ObservedObject private var reader = Reader.shared

    private var words: [(text: String, range: NSRange)] {
        var out: [(String, NSRange)] = []
        let ns = sentence as NSString
        var loc = 0
        for w in sentence.components(separatedBy: " ") {
            let r = ns.range(of: w, range: NSRange(location: loc, length: ns.length - loc))
            out.append((w, r))
            loc = r.location + r.length
        }
        return out
    }

    var body: some View {
        let speakingThis = reader.text == sentence
        FlowRow(spacing: 6) {
            ForEach(Array(words.enumerated()), id: \.offset) { _, w in
                let lit = speakingThis && reader.speaking.map { NSIntersectionRange($0, w.range).length > 0 } == true
                Button { reader.say(w.text.trimmingCharacters(in: .punctuationCharacters)) } label: {
                    Text(w.text)
                        .font(Theme.round(28))
                        .foregroundStyle(lit ? Theme.onColor : Theme.text)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(lit ? Theme.even : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                        .scaleEffect(lit ? 1.08 : 1)
                        .animation(.easeOut(duration: 0.12), value: lit)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(w.text)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(sentence)
    }
}

/// Lays children out left to right, wrapping onto new lines.
struct FlowRow: Layout {
    var spacing: CGFloat = 6
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var x: CGFloat = 0, y: CGFloat = 0, line: CGFloat = 0, widest: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 { y += line + spacing; x = 0; line = 0 }
            x += size.width + spacing
            line = max(line, size.height)
            widest = max(widest, x)
        }
        return CGSize(width: min(widest, width), height: y + line)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, line: CGFloat = 0
        // centre each line: measure lines first
        var lines: [[(Subviews.Element, CGSize)]] = [[]]
        var lineWidth: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if lineWidth + size.width > bounds.width, !lines[lines.count - 1].isEmpty { lines.append([]); lineWidth = 0 }
            lines[lines.count - 1].append((s, size))
            lineWidth += size.width + spacing
        }
        for l in lines {
            let w = l.map(\.1.width).reduce(0, +) + spacing * CGFloat(max(l.count - 1, 0))
            x = bounds.minX + (bounds.width - w) / 2
            line = l.map(\.1.height).max() ?? 0
            for (s, size) in l {
                s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += line + spacing
        }
    }
}

struct StoryBook: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        let stories = Array((model.current?.stories ?? []).reversed())
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                CircleButton(symbol: "xmark", label: "Back") { Reader.shared.stop(); model.screen = .home }
                Text("My story book").font(Theme.round(26)).foregroundStyle(Theme.text)
                Spacer()
                PlayerBadge()
            }
            .padding(.top, 8)
            if stories.isEmpty {
                VStack(spacing: 10) {
                    Text("📖").font(.system(size: 60))
                    Text("No stories yet.").font(Theme.round(22)).foregroundStyle(Theme.text)
                    Text("Build one, tap Read it, and it lands here.").font(Theme.round(16, .semibold)).foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(stories.enumerated()), id: \.offset) { _, saved in
                            let s = StoryParts.split(saved)
                            Button { Reader.shared.say(s.sentence) } label: {
                                VStack(spacing: 6) {
                                    Text(s.pics).font(.system(size: 36))
                                    Text(s.sentence).font(Theme.round(20)).foregroundStyle(Theme.text).multilineTextAlignment(.center)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity)
                                .background(Theme.card, in: RoundedRectangle(cornerRadius: 22))
                                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.border, lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(s.sentence)
                            .accessibilityHint("Reads the story")
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
