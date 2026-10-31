//  TrickCard.swift — after a miss, the trick that cracks it; after a round, the stars.
//
//  The Trick card says one short sentence and shows it with a small animation:
//  dots pairing up, the last digit lighting, place-value blocks, a ten-frame
//  filling, two matching rows, hops along a number line, an array filling row
//  by row, or the ×9 finger trick.

import SwiftUI

struct TrickOverlay: View {
    let trick: Trick
    let gotIt: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35).ignoresSafeArea().accessibilityHidden(true)
            VStack(spacing: 18) {
                Text(trick.headline)
                    .font(Theme.round(36))
                    .foregroundStyle(Theme.text)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                TrickVisualView(visual: trick.visual)
                    .frame(maxWidth: .infinity, minHeight: 120)
                Text(trick.sentence)
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
    }
}

struct TrickVisualView: View {
    let visual: TrickVisual
    var body: some View {
        switch visual {
        case .pairs(let n): PairsVisual(n: n)
        case .lastDigit(let n): LastDigitVisual(n: n)
        case .placeValue(let a, let b): PlaceValueVisual(a: a, b: b)
        case .tenFrame(let a, let b): TenFrameVisual(big: a, small: b)
        case .doubles(let a, let b): DoublesVisual(a: a, b: b)
        case .hops(let from, let to): HopsVisual(from: from, to: to)
        case .array(let r, let c): ArrayVisual(rows: r, cols: c)
        case .nines(let n): NinesVisual(n: n)
        }
    }
}

/// Starts false; flips true shortly after appearing (at once with Reduce Motion).
private struct Reveal: ViewModifier {
    @Binding var on: Bool
    var delay: Double = 0.4
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func body(content: Content) -> some View {
        content.onAppear {
            if reduceMotion { on = true; return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(delay)) { on = true }
        }
    }
}

/// Two numbers as hundreds flats, tens rods and ones cubes; the deciding place glows.
struct PlaceValueVisual: View {
    let a: Int
    let b: Int
    @State private var lit = false

    private var deciding: Int {          // 100, 10 or 1: the biggest place where they differ
        for u in [100, 10, 1] where a / u % 10 != b / u % 10 && (max(a, b) >= u || u == 1) { return u }
        return 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            row(a)
            row(b)
        }
        .modifier(Reveal(on: $lit))
        .accessibilityElement()
        .accessibilityLabel("\(a) and \(b) in hundreds, tens and ones")
    }

    private func row(_ n: Int) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            Text(String(n)).font(Theme.round(22)).foregroundStyle(Theme.text).frame(width: 52, alignment: .leading)
            blocks(n / 100, unit: 100) { RoundedRectangle(cornerRadius: 3).frame(width: 20, height: 20) }
            blocks(n / 10 % 10, unit: 10) { RoundedRectangle(cornerRadius: 2).frame(width: 7, height: 30) }
            blocks(n % 10, unit: 1) { RoundedRectangle(cornerRadius: 2).frame(width: 7, height: 7) }
            Spacer(minLength: 0)
        }
    }

    private func blocks<S: View>(_ count: Int, unit: Int, @ViewBuilder _ shape: () -> S) -> some View {
        let glow = lit && unit == deciding
        let s = shape()
        return HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<count, id: \.self) { _ in s }
        }
        .foregroundStyle(glow ? Theme.odd : Theme.even.opacity(0.75))
        .scaleEffect(glow ? 1.08 : 1, anchor: .bottom)
    }
}

/// Fill a ten-frame with the big number, top it up to 10 from the small one, the rest spill over.
struct TenFrameVisual: View {
    let big: Int
    let small: Int
    @State private var moved = false

    var body: some View {
        let need = 10 - big
        VStack(spacing: 10) {
            frame(filled: big, extra: moved ? need : 0)
            HStack(spacing: 6) {
                ForEach(0..<small, id: \.self) { i in
                    Circle().fill(Theme.odd).frame(width: 22, height: 22)
                        .opacity(moved && i < need ? 0 : 1)
                }
            }
            .frame(minHeight: 22)
        }
        .modifier(Reveal(on: $moved, delay: 0.6))
        .accessibilityElement()
        .accessibilityLabel("\(big) fills most of a ten frame; \(need) more from \(small) make 10, and \(small - need) are left")
    }

    private func frame(filled: Int, extra: Int) -> some View {
        VStack(spacing: 4) {
            ForEach(0..<2, id: \.self) { r in
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { c in
                        let i = r * 5 + c
                        RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 2)
                            .frame(width: 34, height: 34)
                            .overlay {
                                if i < filled { Circle().fill(Theme.even).padding(6) }
                                else if i < filled + extra { Circle().fill(Theme.odd).padding(6).transition(.scale) }
                            }
                    }
                }
            }
        }
    }
}

/// Two rows that match; a near-double has one extra, which glows.
struct DoublesVisual: View {
    let a: Int
    let b: Int
    @State private var lit = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            dots(a, extra: false)
            dots(b, extra: b > a)
        }
        .modifier(Reveal(on: $lit))
        .accessibilityElement()
        .accessibilityLabel(a == b ? "Two rows of \(a)" : "A row of \(a) and a row of \(a) plus one")
    }

    private func dots(_ n: Int, extra: Bool) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<n, id: \.self) { i in
                let isExtra = extra && i == n - 1
                Circle().fill(isExtra ? Theme.odd : Theme.even).frame(width: 22, height: 22)
                    .scaleEffect(isExtra && lit ? 1.3 : (lit ? 1 : 0.6))
            }
        }
    }
}

/// A number line from `from` to `to`, hopping one at a time.
struct HopsVisual: View {
    let from: Int
    let to: Int
    @State private var hopped = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let n = max(to - from, 1)
        GeometryReader { g in
            let w = g.size.width - 24
            let step = w / CGFloat(n)
            ZStack(alignment: .topLeading) {
                Path { p in p.move(to: CGPoint(x: 12, y: 70)); p.addLine(to: CGPoint(x: 12 + w, y: 70)) }
                    .stroke(Theme.border, lineWidth: 3)
                ForEach(0...n, id: \.self) { k in
                    let x = 12 + CGFloat(k) * step
                    Path { p in p.move(to: CGPoint(x: x, y: 62)); p.addLine(to: CGPoint(x: x, y: 78)) }
                        .stroke(Theme.muted, lineWidth: 2)
                    if k == 0 || k == n || n <= 10 {
                        Text(String(from + k)).font(Theme.round(n <= 10 ? 15 : 13, .bold))
                            .foregroundStyle(k == 0 || k == n ? Theme.text : Theme.muted)
                            .position(x: x, y: 94)
                    }
                }
                ForEach(0..<hopped, id: \.self) { k in
                    let x0 = 12 + CGFloat(k) * step
                    Path { p in
                        p.move(to: CGPoint(x: x0, y: 62))
                        p.addQuadCurve(to: CGPoint(x: x0 + step, y: 62), control: CGPoint(x: x0 + step / 2, y: 62 - min(46, step * 0.9)))
                    }
                    .stroke(Theme.odd, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }
                Text("\(hopped)").font(Theme.round(22)).foregroundStyle(Theme.odd)
                    .position(x: 12 + CGFloat(hopped) * step, y: 18)
                    .opacity(hopped > 0 ? 1 : 0)
            }
        }
        .frame(height: 110)
        .accessibilityElement()
        .accessibilityLabel("Count up from \(from) to \(to): \(to - from) hops")
        .task {
            if reduceMotion { hopped = n; return }
            for k in 1...n {
                try? await Task.sleep(for: .milliseconds(k == 1 ? 500 : max(120, 420 - n * 15)))
                withAnimation(.easeOut(duration: 0.2)) { hopped = k }
            }
        }
    }
}

/// rows × cols dots, filling in row by row.
struct ArrayVisual: View {
    let rows: Int
    let cols: Int
    @State private var shown = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let d: CGFloat = cols > 7 || rows > 7 ? 13 : 18
        VStack(spacing: d * 0.35) {
            ForEach(0..<rows, id: \.self) { r in
                HStack(spacing: d * 0.35) {
                    ForEach(0..<cols, id: \.self) { _ in
                        Circle().fill(r < shown ? Theme.even : Theme.border).frame(width: d, height: d)
                    }
                    Text(r < shown ? "\((r + 1) * cols)" : "")
                        .font(Theme.round(13, .bold)).foregroundStyle(Theme.muted).frame(width: 30, alignment: .leading)
                }
            }
        }
        .accessibilityElement()
        .frame(minWidth: rows == 0 ? 240 : nil, minHeight: rows == 0 ? 60 : nil)
        .overlay {
            if rows == 0 {
                Text("0 groups of \(cols) is 0").font(Theme.round(24)).foregroundStyle(Theme.muted)
            }
        }
        .accessibilityLabel(rows == 0 ? "No groups, so nothing" : "\(rows) rows of \(cols)")
        .task {
            guard rows > 0 else { return }
            if reduceMotion { shown = rows; return }
            for r in 1...rows {
                try? await Task.sleep(for: .milliseconds(r == 1 ? 450 : 260))
                withAnimation(.easeOut(duration: 0.2)) { shown = r }
            }
        }
    }
}

/// The ×9 finger trick: fold down finger n; fingers to the left are tens, to the right are ones.
struct NinesVisual: View {
    let n: Int
    @State private var folded = false

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(1...10, id: \.self) { k in
                    let down = folded && k == n
                    Capsule()
                        .fill(down ? Theme.odd : (folded && k < n ? Theme.even : (folded ? Theme.right : Theme.muted.opacity(0.5))))
                        .frame(width: 18, height: down ? 22 : 64)
                        .padding(.leading, k == 6 ? 10 : 0)
                }
            }
            .frame(height: 64, alignment: .bottom)
            if folded {
                HStack(spacing: 18) {
                    Label("\(n - 1) tens", systemImage: "hand.raised.fill").foregroundStyle(Theme.even)
                    Label("\(10 - n) ones", systemImage: "hand.raised.fill").foregroundStyle(Theme.right)
                }
                .font(Theme.round(16, .bold))
            }
        }
        .modifier(Reveal(on: $folded, delay: 0.5))
        .accessibilityElement()
        .accessibilityLabel("Fold down finger \(n): \(n - 1) fingers before it, \(10 - n) after, so \(9 * n)")
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
