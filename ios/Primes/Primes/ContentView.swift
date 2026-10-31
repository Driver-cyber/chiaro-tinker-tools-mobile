//  ContentView.swift — the three screens: welcome, question, answer.

import SwiftUI

struct ContentView: View {
    @StateObject private var game = Game()
    @State private var sheet: SheetRoute?

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 6) {
                TierBar(tier: $game.tier)
                Text("Streak \(game.streak)")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(Theme.muted)
                    .opacity(game.screen == .welcome ? 0 : 1)   // keeps its line, so Play doesn't shift the layout
                Group {
                    switch game.screen {
                    case .welcome:  WelcomeView(game: game, sheet: $sheet)
                    case .question: QuestionView(game: game, sheet: $sheet)
                    case .answer:   AnswerView(game: game, sheet: $sheet)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .frame(maxWidth: 520)
        }
        .tint(Theme.accent)
        .sheet(item: $sheet) { route in
            RefSheet(route: route, game: game, sheet: $sheet)
                .presentationDetents([.medium])          // the bottom half: the number stays in view
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.bg)
        }
    }
}

struct TierBar: View {
    @Binding var tier: Tier
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tier.allCases) { t in
                Button { tier = t; Haptics.tick() } label: {
                    Text(t.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(t == tier ? Theme.accent : Theme.muted)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(t == tier ? Theme.accent.opacity(0.14) : Color.clear)
                }
                .accessibilityAddTraits(t == tier ? .isSelected : [])
                if t != Tier.allCases.last { Theme.border.frame(width: 1) }
            }
        }
        .frame(maxWidth: 340)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct WelcomeView: View {
    @ObservedObject var game: Game
    @Binding var sheet: SheetRoute?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("Prime or Composite")
                .font(Theme.serif(34))
                .foregroundStyle(Theme.accent)
                .multilineTextAlignment(.center)
            Text("A number from 2 to 999. Work it out by hand, then call it. Every answer shows the method.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 300)
                .padding(.top, 12)
            Button { sheet = .found } label: {
                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        Text("\(game.foundCount) of \(PrimeEngine.all.count) primes found").foregroundStyle(Theme.muted)
                        Spacer()
                        Text("See them ›").foregroundStyle(Theme.accent)
                    }
                    .font(.system(size: 13.5))
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.muted.opacity(0.18))
                            Capsule().fill(Theme.accent)
                                .frame(width: g.size.width * CGFloat(game.foundCount) / CGFloat(PrimeEngine.all.count))
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
            }
            .frame(maxWidth: 320)
            .padding(.top, 28)
            Spacer()
            Button("Play") { game.deal() }.buttonStyle(FilledButtonStyle())
        }
    }
}

struct QuestionView: View {
    @ObservedObject var game: Game
    @Binding var sheet: SheetRoute?

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)
            Text(String(game.n))
                .font(Theme.mono(112, .bold))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(Theme.text)
                .accessibilityLabel("Number \(game.n)")
            Text("Is it prime?")
                .font(.system(size: 16))
                .foregroundStyle(Theme.muted)
                .padding(.top, 6)
                .padding(.bottom, 22)
            HStack(spacing: 12) {
                answerButton("Prime", true)
                answerButton("Composite", false)
            }
            Spacer(minLength: 8)
            Spacer(minLength: 0).frame(maxHeight: 72)   // a little extra room below lifts the number above a half sheet
            HStack(spacing: 8) {
                Button("Roots") { sheet = .roots }.swipeUpOpens { sheet = .roots }
                Button("Prime tricks") { sheet = .tricks }.swipeUpOpens { sheet = .tricks }
                Button("Checklist") { sheet = .checklist }.swipeUpOpens { sheet = .checklist }
            }
            .buttonStyle(OutlineButtonStyle())
        }
    }

    private func answerButton(_ title: String, _ prime: Bool) -> some View {
        Button { game.answer(saidPrime: prime) } label: {
            Text(title)
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity, minHeight: 92)
                .background(Theme.panel, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.accent, lineWidth: 1.5))
        }
    }
}

struct AnswerView: View {
    @ObservedObject var game: Game
    @Binding var sheet: SheetRoute?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(PrimeEngine.verdictLine(saidPrime: game.saidPrime, prime: game.isPrime))
                        .font(Theme.serif(25))
                        .foregroundStyle(game.wasRight ? Theme.success : Theme.danger.opacity(0.8))
                        .padding(.top, 14)
                    (Text(String(game.n)).font(Theme.mono(15, .bold)).foregroundColor(Theme.text) +
                     Text(" is \(game.isPrime ? "prime" : "composite").").foregroundColor(Theme.muted))
                        .font(.system(size: 15))
                    if game.freshFind {
                        Text("New prime found · \(game.foundCount) of \(PrimeEngine.all.count)")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.accent)
                    }
                    if game.isPrime { primeExplanation } else { compositeExplanation }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button("Next") { game.deal() }
                .buttonStyle(FilledButtonStyle())
                .padding(.top, 12)
        }
    }

    private var compositeExplanation: some View {
        let p = PrimeEngine.spf(game.n)
        let worked = PrimeEngine.apply(p, game.n)
        return VStack(alignment: .leading, spacing: 8) {
            Text(PrimeEngine.equation(game.n)).font(Theme.mono(30, .bold)).foregroundStyle(Theme.text)
            MathBox(header: "\(p) trick", subheader: PrimeEngine.tricks[p]!.trick, lines: worked.steps)
        }
    }

    private var primeExplanation: some View {
        let e = PrimeEngine.primeExplanation(game.n)
        return VStack(alignment: .leading, spacing: 10) {
            if let list = e.listNote { Text(list).foregroundStyle(Theme.text) }
            if let root = e.rootLine { MathBox(lines: [root]) }
            if let verdict = e.verdict { Text(verdict).foregroundStyle(Theme.text) }
            if !e.checked.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(e.checked, id: \.self) { p in
                        Button { sheet = .trick(p) } label: {
                            Text(String(p)).font(Theme.mono(16)).foregroundStyle(Theme.text)
                                .frame(minWidth: 48, minHeight: 48)
                                .frame(maxWidth: .infinity)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
                        }
                    }
                }
                Text("Tap a prime to watch its trick fail on \(game.n).")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.muted)
            }
        }
        .font(.system(size: 15))
    }
}

/// The monospaced worked-math panel.
struct MathBox: View {
    var header: String? = nil
    var subheader: String? = nil
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let header {
                (Text(header).foregroundColor(Theme.accent).bold() +
                 Text(subheader.map { " · \($0)" } ?? "").foregroundColor(Theme.text))
            }
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line).foregroundStyle(Theme.text)
            }
        }
        .font(Theme.mono(14.5))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
    }
}

extension View {
    /// Swipe up on a reference button to pull its sheet up; a tap still works.
    func swipeUpOpens(_ open: @escaping () -> Void) -> some View {
        simultaneousGesture(DragGesture(minimumDistance: 16).onEnded { v in
            guard v.translation.height < -30, abs(v.translation.height) > abs(v.translation.width) else { return }
            Haptics.tick()
            open()
        })
    }
}
