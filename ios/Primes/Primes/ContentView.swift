//  ContentView.swift — the three screens: welcome, question, answer.

import SwiftUI

struct ContentView: View {
    @StateObject private var game = Game()
    @State private var sheet: SheetRoute?
    @AppStorage(Theme.storeKey) private var style = Theme.style.rawValue

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if Theme.style == .phosphor { Scanlines().ignoresSafeArea() }
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Button { sheet = nil; game.home() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 18, weight: .semibold)).frame(width: 44, height: 48)
                    }
                    .foregroundStyle(Theme.muted)
                    .accessibilityLabel("Back to welcome")
                    .opacity(game.screen == .welcome ? 0 : 1)
                    .disabled(game.screen == .welcome)
                    SegmentBar(options: Tier.allCases, selection: $game.tier) { $0.title }
                    Color.clear.frame(width: 44, height: 48)          // balances the back button, so the bar stays centred
                }
                Text("Streak \(game.streak)")
                    .font(Theme.body(13).monospacedDigit())
                    .textCase(Theme.labelCase)
                    .foregroundStyle(Theme.muted)
                    .opacity(game.screen == .welcome ? 0 : 1)   // keeps its line, so Play doesn't shift the layout
                Group {
                    switch game.screen {
                    case .welcome:  WelcomeView(game: game, sheet: $sheet, style: $style)
                    case .question: QuestionView(game: game, sheet: $sheet)
                    case .answer:   AnswerView(game: game, sheet: $sheet)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.top, 22)
            .padding(.bottom, 28)
            .frame(maxWidth: 520)
        }
        .id(style)                                    // a new look rebuilds the tree, so every Theme value is re-read
        .tint(Theme.accent)
        .sheet(item: $sheet) { route in
            RefSheet(route: route, game: game, sheet: $sheet)
                .presentationDetents([.medium])          // the bottom half: the number stays in view
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.bg)
        }
    }
}

/// A row of equal segments: the tier picker, and the look picker on the welcome screen.
struct SegmentBar<T: Hashable>: View {
    let options: [T]
    @Binding var selection: T
    let title: (T) -> String

    var body: some View {
        let inverse = Theme.style == .phosphor        // a terminal shows the selection in inverse video
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { t in
                let on = t == selection
                Button { selection = t; Haptics.tick() } label: {
                    Text(title(t))
                        .font(Theme.body(15, .semibold))
                        .textCase(Theme.labelCase)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(on ? (inverse ? Theme.ink : Theme.accent) : Theme.muted)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(on ? (inverse ? Theme.accent : Theme.accent.opacity(0.14)) : Color.clear)
                }
                .accessibilityAddTraits(on ? .isSelected : [])
                if t != options.last { Theme.border.frame(width: 1) }
            }
        }
        .frame(maxWidth: 340)
        .clipShape(RoundedRectangle(cornerRadius: Theme.r(12)))
        .overlay(RoundedRectangle(cornerRadius: Theme.r(12)).stroke(Theme.border, lineWidth: 1))
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct WelcomeView: View {
    @ObservedObject var game: Game
    @Binding var sheet: SheetRoute?
    @Binding var style: String
    @State private var guide = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("Prime or Composite")
                .font(Theme.serif(34))
                .foregroundStyle(Theme.accent)
                .multilineTextAlignment(.center)
            Text("A number from 2 to 999. Work it out by hand, then call it. Every answer shows the method.")
                .font(Theme.body(15))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 300)
                .padding(.top, 12)
            Button("New here? How to play ›") { guide = true }
                .font(Theme.body(15, .semibold))
                .textCase(Theme.labelCase)
                .foregroundStyle(Theme.accent)
                .frame(minHeight: 44)
                .padding(.top, 4)
            Button { sheet = .found } label: {
                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        Text("\(game.foundCount) of \(PrimeEngine.all.count) primes found").foregroundStyle(Theme.muted)
                        Spacer()
                        Text("See them ›").foregroundStyle(Theme.accent)
                    }
                    .font(Theme.body(13.5))
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
                .overlay(RoundedRectangle(cornerRadius: Theme.r(12)).stroke(Theme.border, lineWidth: 1))
            }
            .frame(maxWidth: 320)
            .padding(.top, 28)
            SegmentBar(options: Style.allCases, selection: Binding(
                get: { Theme.style },
                set: { Theme.style = $0; style = $0.rawValue })) { $0.title }
                .padding(.top, 20)
            Spacer()
            Button("Play") { game.deal() }.buttonStyle(FilledButtonStyle())
        }
        .sheet(isPresented: $guide) {
            GuideView(play: { guide = false; game.deal() })
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.bg)
        }
    }
}

struct QuestionView: View {
    @ObservedObject var game: Game
    @Binding var sheet: SheetRoute?

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 16).frame(maxHeight: 84)     // the number rides high, clear of the tier bar
            Text(String(game.n))
                .font(Theme.number(112))
                .monospacedDigit()
                .shadow(color: Theme.glow, radius: 10)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(Theme.text)
                .accessibilityLabel("Number \(game.n)")
            Text(Theme.prompt + "Is it prime?")
                .font(Theme.body(16))
                .textCase(Theme.labelCase)
                .foregroundStyle(Theme.muted)
                .padding(.top, 6)
            Spacer(minLength: 22).frame(maxHeight: 64)     // answers close under the question
            HStack(spacing: 12) {
                answerButton("Prime", true)
                answerButton("Composite", false)
            }
            Spacer(minLength: ToolFan.size + 20)            // the ✦ corner; an open fan may cover the answers
        }
        .overlay(alignment: .bottomTrailing) { ToolFan(sheet: $sheet) }
    }

    private func answerButton(_ title: String, _ prime: Bool) -> some View {
        Button { game.answer(saidPrime: prime) } label: {
            Text(title)
                .font(Theme.body(21, .bold))
                .textCase(Theme.labelCase)
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity, minHeight: 92)
                .background(Theme.panel, in: RoundedRectangle(cornerRadius: Theme.r(16)))
                .overlay(RoundedRectangle(cornerRadius: Theme.r(16)).stroke(Theme.accent, lineWidth: 1.5))
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
                        .font(Theme.body(15))
                    if game.freshFind {
                        Text("New prime found · \(game.foundCount) of \(PrimeEngine.all.count)")
                            .font(Theme.body(14))
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
                                .overlay(RoundedRectangle(cornerRadius: Theme.r(10)).stroke(Theme.border, lineWidth: 1))
                        }
                    }
                }
                Text("Tap a prime to watch its trick fail on \(game.n).")
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.muted)
            }
        }
        .font(Theme.body(15))
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
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: Theme.r(10)))
        .overlay(RoundedRectangle(cornerRadius: Theme.r(10)).stroke(Theme.border, lineWidth: 1))
    }
}
