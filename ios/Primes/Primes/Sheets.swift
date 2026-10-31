//  Sheets.swift — the half-height reference sheets.
//
//  One sheet at a time. A trick opened from the Checklist replaces the
//  Checklist inside the same sheet (never a stacked sheet): ✕ returns to the
//  Checklist with its ticks intact, and "← Back to checklist" sits at the
//  bottom. Mid-question the work on this number stays hidden behind
//  "Check my work" — try it by hand first. From the answer screen the work
//  is shown, since the answer is already out.

import SwiftUI

enum SheetRoute: Identifiable, Equatable {
    case roots, tricks, checklist, found
    case trick(Int)          // opened from the answer screen
    var id: String {
        switch self {
        case .roots: return "roots"
        case .tricks: return "tricks"
        case .checklist: return "checklist"
        case .found: return "found"
        case .trick(let p): return "trick\(p)"
        }
    }
}

struct RefSheet: View {
    let route: SheetRoute
    @ObservedObject var game: Game
    @Binding var sheet: SheetRoute?
    @State private var detail: Int? = nil    // a trick opened from the Checklist

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.text)
                Spacer()
                Button { close() } label: {
                    Image(systemName: "xmark").font(.system(size: 17, weight: .semibold)).frame(width: 48, height: 48)
                }
                .foregroundStyle(Theme.text)
                .accessibilityLabel(detail != nil ? "Back to checklist" : "Close")
            }
            .padding(.leading, 16)
            .padding(.trailing, 4)
            .padding(.top, 10)
            Theme.border.frame(height: 1)
            ScrollView {
                content
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if detail != nil {
                Theme.border.frame(height: 1)
                Button("← Back to checklist") { detail = nil }
                    .buttonStyle(OutlineButtonStyle(accent: true))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
        }
    }

    private var title: String {
        if let p = detail { return "\(p) trick" }
        switch route {
        case .roots: return "Square roots"
        case .tricks: return "Prime tricks"
        case .checklist: return "Checklist"
        case .found: return "Primes found · \(game.foundCount) of \(PrimeEngine.all.count)"
        case .trick(let p): return "\(p) trick"
        }
    }

    private func close() {
        if detail != nil { detail = nil } else { sheet = nil }
    }

    @ViewBuilder private var content: some View {
        if let p = detail {
            TrickDetail(p: p, n: game.n, hideWork: true).id(p)
        } else {
            switch route {
            case .roots: RootsView()
            case .tricks: TricksView()
            case .checklist: ChecklistView(game: game, detail: $detail)
            case .found: FoundView(solved: game.solved)
            case .trick(let p): TrickDetail(p: p, n: game.n, hideWork: false).id(p)
            }
        }
    }
}

struct RootsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Row(left: "Square", right: "Value", head: true)
            ForEach([10, 15, 20, 25, 30, 31], id: \.self) { x in
                Row(left: "\(x)²", right: "\(x * x)", head: false)
            }
            Group {
                (Text("Squares of numbers ending in 5: ").bold().foregroundColor(Theme.text) +
                 Text("multiply the first digit by the next number up, then stick 25 on the end. 35² → 3 × 4 = 12 → 1225."))
                    .padding(.top, 14)
                (Text("One off a round number: ").bold().foregroundColor(Theme.text) +
                 Text("square the round number, add or subtract twice it, then add 1. 21² → 400 + 40 + 1 = 441. 19² → 400 − 40 + 1 = 361."))
                    .padding(.top, 10)
            }
            .font(.system(size: 14))
            .foregroundStyle(Theme.muted)
            .lineSpacing(3)
        }
    }

    private struct Row: View {
        let left: String, right: String, head: Bool
        var body: some View {
            HStack {
                Text(left).frame(maxWidth: .infinity, alignment: .leading)
                Text(right).frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(head ? .system(size: 11.5, weight: .semibold) : Theme.mono(16))
            .textCase(head ? .uppercase : nil)
            .foregroundStyle(head ? Theme.muted : Theme.text)
            .padding(.vertical, head ? 6 : 9)
            .padding(.horizontal, 6)
            .overlay(alignment: .bottom) { Theme.border.frame(height: 1) }
        }
    }
}

struct TricksView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("Prime").frame(width: 52, alignment: .leading)
                Text("Trick · example")
            }
            .font(.system(size: 11.5, weight: .semibold))
            .textCase(.uppercase)
            .foregroundStyle(Theme.muted)
            .padding(6)
            .overlay(alignment: .bottom) { Theme.border.frame(height: 1) }
            ForEach(PrimeEngine.small, id: \.self) { p in
                HStack(alignment: .top, spacing: 8) {
                    Text(String(p)).font(Theme.mono(16, .bold)).frame(width: 52, alignment: .leading)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(PrimeEngine.tricks[p]!.trick).font(.system(size: 14.5))
                        Text(PrimeEngine.tricks[p]!.example).font(Theme.mono(13)).foregroundStyle(Theme.muted)
                    }
                }
                .foregroundStyle(Theme.text)
                .padding(.vertical, 9)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .bottom) { Theme.border.frame(height: 1) }
            }
            Text(PrimeEngine.chopNote)
                .font(.system(size: 14))
                .foregroundStyle(Theme.muted)
                .lineSpacing(3)
                .padding(.top, 12)
        }
    }
}

struct ChecklistView: View {
    @ObservedObject var game: Game
    @Binding var detail: Int?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(PrimeEngine.small, id: \.self) { p in
                let on = game.checked.contains(p)
                HStack(spacing: 12) {
                    Button {
                        if on { game.checked.remove(p) } else { game.checked.insert(p) }
                        Haptics.tick()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(on ? Theme.accent : Color.clear)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(on ? Theme.accent : Theme.muted, lineWidth: 1.5))
                                if on {
                                    Image(systemName: "checkmark").font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.ink)
                                }
                            }
                            .frame(width: 30, height: 30)
                            Text(String(p)).font(Theme.mono(21, .bold)).foregroundStyle(Theme.text)
                            Spacer()
                        }
                        .frame(minHeight: 48)
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Cleared \(p)")
                    .accessibilityAddTraits(on ? .isSelected : [])
                    Button { detail = p } label: {
                        Image(systemName: "info.circle").font(.system(size: 19)).foregroundStyle(Theme.accent)
                            .frame(width: 48, height: 48)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                    }
                    .accessibilityLabel("\(p) trick")
                }
                .frame(minHeight: 58)
                .overlay(alignment: .bottom) { Theme.border.frame(height: 1) }
            }
        }
    }
}

struct TrickDetail: View {
    let p: Int
    let n: Int
    let hideWork: Bool
    @State private var revealed = false

    var body: some View {
        let t = PrimeEngine.tricks[p]!
        let worked = PrimeEngine.apply(p, n)
        let showWork = !hideWork || revealed
        VStack(alignment: .leading, spacing: 10) {
            Text(t.trick).font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.text)
            (Text("Example: ") + Text(t.example).font(Theme.mono(14)))
                .font(.system(size: 14))
                .foregroundStyle(Theme.muted)
            if hideWork {
                Text("Try it on \(n) first.").font(.system(size: 14)).foregroundStyle(Theme.muted).padding(.top, 4)
                Button(revealed ? "Hide the work" : "Check my work on \(n)") { revealed.toggle() }
                    .buttonStyle(OutlineButtonStyle(accent: true))
            } else {
                Text("On \(n):").font(.system(size: 14)).foregroundStyle(Theme.muted).padding(.top, 4)
            }
            if showWork {
                MathBox(lines: worked.steps)
                Text(worked.ok ? "\(p) divides \(n)." : "\(p) doesn\u{2019}t divide \(n).")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.text)
            }
        }
    }
}

struct FoundView: View {
    let solved: [Int: String]

    var body: some View {
        let found = PrimeEngine.all.filter { solved[$0] != nil }.count
        let left = PrimeEngine.all.count - found
        VStack(alignment: .leading, spacing: 0) {
            Text("Each one lights the first time you call it prime. " +
                 (left > 0 ? "\(left) still in the dark." : "Every prime under 1,000, identified by hand."))
                .font(.system(size: 14))
                .foregroundStyle(Theme.muted)
                .lineSpacing(3)
            ForEach(0..<10, id: \.self) { c in
                let ps = PrimeEngine.all.filter { $0 / 100 == c }
                HStack {
                    Text("\(c == 0 ? 1 : c * 100)–\(c * 100 + 99)")
                    Spacer()
                    Text("\(ps.filter { solved[$0] != nil }.count) of \(ps.count)")
                }
                .font(.system(size: 11.5))
                .textCase(.uppercase)
                .foregroundStyle(Theme.muted)
                .padding(.top, 14)
                .padding(.bottom, 6)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 38), spacing: 5)], spacing: 5) {
                    ForEach(ps, id: \.self) { n in
                        // Unfound primes stay dark — a tile, not the number — so the grid can't spoil a question.
                        let lit = solved[n] != nil
                        Text(lit ? String(n) : "·")
                            .font(Theme.mono(13.5, lit ? .bold : .regular))
                            .foregroundStyle(lit ? Theme.accent : Theme.muted.opacity(0.4))
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .background(lit ? Theme.accent.opacity(0.10) : Theme.muted.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
                            .overlay(RoundedRectangle(cornerRadius: 7).stroke(lit ? Theme.accent : Color.clear, lineWidth: 1))
                            .accessibilityLabel(lit ? "\(n), found" : "not yet found")
                    }
                }
            }
        }
    }
}
