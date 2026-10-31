//  TrickCard.swift — after a miss, the trick that cracks it; after a round, the stars.
//
//  The Trick card says one short sentence and shows it: the dots slide from a
//  loose grid into pairs, and if one is left over it glows orange. Past 20 it
//  points at the last digit instead, then pairs that digit's dots.

import SwiftUI

struct TrickOverlay: View {
    let card: EvenOddCard
    let gotIt: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35).ignoresSafeArea().accessibilityHidden(true)
            VStack(spacing: 18) {
                (Text("\(card.n) is ") + Text(EvenOdd.word(card.isEven)).foregroundColor(card.isEven ? Theme.even : Theme.odd))
                    .font(Theme.round(36))
                    .foregroundStyle(Theme.text)
                Group {
                    if EvenOdd.usesLastDigit(card) { LastDigitVisual(n: card.n) } else { PairsVisual(n: card.n) }
                }
                .frame(minHeight: 120)
                Text(EvenOdd.trick(card))
                    .font(Theme.round(20, .semibold))
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Got it", action: gotIt).buttonStyle(BigButtonStyle())
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 34))
            .padding(12)
            .transition(.move(edge: .bottom))
        }
        .onAppear { Speech.say(EvenOdd.trick(card)) }
    }
}

/// n dots slide from rows of five into pairs; a leftover glows orange.
struct PairsVisual: View {
    let n: Int
    var dot: CGFloat = 22
    @State private var paired = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var gap: CGFloat { dot * 0.45 }
    private var pairColumns: Int { (n + 1) / 2 }
    private var width: CGFloat { max(CGFloat(pairColumns), 5) * (dot + gap * 1.6) }
    private var height: CGFloat { max(CGFloat((n + 4) / 5), 2) * (dot + gap) + 8 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<pairColumns, id: \.self) { c in
                if c * 2 + 1 < n {                                  // a whole pair gets a soft capsule
                    Capsule()
                        .stroke(Theme.even.opacity(0.6), lineWidth: 2)
                        .frame(width: dot + 8, height: dot * 2 + gap + 8)
                        .offset(x: pairX(c) - 4, y: -4)
                        .opacity(paired ? 1 : 0)
                }
            }
            ForEach(0..<n, id: \.self) { i in
                let leftover = n % 2 == 1 && i == n - 1
                Circle()
                    .fill(paired ? (leftover ? Theme.odd : Theme.even) : Theme.muted)
                    .frame(width: dot, height: dot)
                    .scaleEffect(paired && leftover ? 1.25 : 1)
                    .offset(paired ? pairPos(i) : gridPos(i))
            }
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .accessibilityElement()
        .accessibilityLabel(n % 2 == 0 ? "\(n) dots in \(n / 2) pairs, none left over" : "\(n) dots in \(n / 2) pairs and one left over")
        .onAppear {
            if reduceMotion { paired = true; return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) { paired = true }
        }
    }

    private func gridPos(_ i: Int) -> CGSize {
        CGSize(width: CGFloat(i % 5) * (dot + gap), height: CGFloat(i / 5) * (dot + gap))
    }
    private func pairX(_ c: Int) -> CGFloat { CGFloat(c) * (dot + gap * 1.6) }
    private func pairPos(_ i: Int) -> CGSize {
        CGSize(width: pairX(i / 2), height: CGFloat(i % 2) * (dot + gap))
    }
}

/// Big numbers: light up the last digit, then pair that digit's dots.
struct LastDigitVisual: View {
    let n: Int
    @State private var lit = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let digits = Array(String(n))
        let last = n % 10
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                ForEach(Array(digits.enumerated()), id: \.offset) { k, d in
                    let isLast = k == digits.count - 1
                    Text(String(d))
                        .font(Theme.round(56))
                        .foregroundStyle(isLast && lit ? Theme.onColor : (isLast ? Theme.text : Theme.muted.opacity(lit ? 0.5 : 1)))
                        .frame(width: 52, height: 72)
                        .background(isLast && lit ? (last % 2 == 0 ? Theme.even : Theme.odd) : Color.clear, in: RoundedRectangle(cornerRadius: 16))
                        .scaleEffect(isLast && lit ? 1.12 : 1)
                }
            }
            if last == 0 {
                Text("0 dots: nothing left over")
                    .font(Theme.round(18, .bold))
                    .foregroundStyle(Theme.muted)
                    .opacity(lit ? 1 : 0)
            } else if lit {
                PairsVisual(n: last, dot: 18)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("The last digit of \(n) is \(last)")
        .onAppear {
            if reduceMotion { lit = true; return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.4)) { lit = true }
        }
    }
}

// MARK: - End of round

struct SummaryView: View {
    let stars: Int
    let firstTry: Int
    let count: Int
    let again: () -> Void
    let done: () -> Void
    @State private var shown = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 26) {
                Text("Round done!")
                    .font(Theme.round(40))
                    .foregroundStyle(Theme.text)
                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < shown ? "star.fill" : "star")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundStyle(i < shown ? Theme.star : Theme.border)
                            .scaleEffect(i < shown ? 1 : 0.8)
                            .rotationEffect(.degrees(i < shown ? 0 : -20))
                    }
                }
                .accessibilityElement()
                .accessibilityLabel("\(stars) of 3 stars")
                Text("\(firstTry) of \(count) on the first try")
                    .font(Theme.round(22, .bold))
                    .foregroundStyle(Theme.muted)
                VStack(spacing: 12) {
                    Button(action: again) { Label("Play again", systemImage: "arrow.clockwise") }
                        .buttonStyle(BigButtonStyle())
                    Button("Done", action: done).buttonStyle(SoftButtonStyle())
                }
                .padding(.top, 10)
            }
            .padding(24)
        }
        .task {
            if reduceMotion { shown = stars; return }
            for i in 1...stars {
                try? await Task.sleep(for: .milliseconds(i == 1 ? 350 : 380))
                withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) { shown = i }
                Haptics.tick()
            }
        }
    }
}
