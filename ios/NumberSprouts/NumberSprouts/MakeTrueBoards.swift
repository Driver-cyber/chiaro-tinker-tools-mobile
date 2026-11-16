//  MakeTrueBoards.swift — the other two ways to see Make It True.
//
//  Scale: numbers go on two pans, a sign dial sits between two on the same pan,
//  and the beam tips toward the heavier side as you go. Level is true: = means
//  both sides weigh the same. Blocks under each pan show how much is there.
//
//  Machine: pick the number that should come out and drop it in the bin; the
//  rest go in the hoppers. Turn the dials to pick the signs, swap the order,
//  pull the lever, and see what pops out. A match grows a sprout.

import SwiftUI

// MARK: - Scale

struct ScaleBoard: View {
    @ObservedObject var game: MakeTrueGame
    let targets: [String: CGRect]
    @Binding var hover: String?
    @State private var left: [Int] = []          // indices into game.numbers
    @State private var right: [Int] = []
    @State private var lops: [Op] = []
    @State private var rops: [Op] = []
    @State private var level = false

    private var cap: Int { game.numbers.count - 1 }
    private func side(_ idx: [Int], _ ops: [Op]) -> Side { Side(nums: idx.map { game.numbers[$0] }, ops: ops) }
    private func weight(_ idx: [Int], _ ops: [Op]) -> Q? { idx.isEmpty ? Q(0) : side(idx, ops).value }

    /// Degrees, positive when the left is heavier. A side that doesn't come
    /// out even (or goes below zero) weighs nothing.
    private var tilt: Double {
        func w(_ q: Q?) -> Double { max(0, q?.double ?? 0) }
        let d = w(weight(left, lops)) - w(weight(right, rops))
        return 16 * tanh(d / 4)
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { g in
                let w = g.size.width
                let panW = min(160, w * 0.42)
                let half = w / 2 - panW / 2 - 4
                let pivot = CGPoint(x: w / 2, y: 26)
                let a = tilt * .pi / 180
                let lEnd = CGPoint(x: pivot.x - half * cos(a), y: pivot.y + half * sin(a))
                let rEnd = CGPoint(x: pivot.x + half * cos(a), y: pivot.y - half * sin(a))
                ZStack {
                    Post(top: pivot, bottom: CGPoint(x: pivot.x, y: pivot.y + 150))
                        .fill(Theme.border)
                    Capsule().fill(level ? Theme.right : Theme.muted)
                        .frame(width: half * 2 + 16, height: 10)
                        .rotationEffect(.radians(-a))
                        .position(pivot)
                    Circle().fill(level ? Theme.right : Theme.text).frame(width: 18, height: 18).position(pivot)
                    pan("L", left, lops, width: panW, hangFrom: lEnd) { lops = $0 }
                    pan("R", right, rops, width: panW, hangFrom: rEnd) { rops = $0 }
                }
            }
            .frame(height: 240)
            Spacer(minLength: 8)
            NumberBank(numbers: game.numbers, used: Set(left + right), targets: targets, hover: $hover,
                       size: game.numbers.count > 3 ? 62 : 70,
                       accept: { $0 == "L" || $0 == "R" }, drop: { put($0, on: $1) },
                       tap: { put($0, on: left.count < cap ? "L" : "R") })
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.6), value: tilt)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: left + right)
    }

    /// A pan on its strings: the numbers sitting on it, then how much it holds.
    private func pan(_ id: String, _ idx: [Int], _ ops: [Op], width: CGFloat, hangFrom end: CGPoint, setOps: @escaping ([Op]) -> Void) -> some View {
        let k = CGFloat(max(cap, 2))
        let chip = min(54, (width - 12) / (k + 0.62 * (k - 1)))
        let dial = chip * 0.62
        let strings: CGFloat = 34
        let hot = hover == id
        return VStack(spacing: 0) {
            Strings().stroke(Theme.muted.opacity(0.7), lineWidth: 1.5).frame(width: width - 12, height: strings)
            HStack(spacing: 2) {
                ForEach(Array(idx.enumerated()), id: \.element) { j, n in
                    if j > 0 {
                        OpDial(op: ops[j - 1], ops: game.level.ops, size: dial) { o in
                            var o2 = ops; o2[j - 1] = o; setOps(o2); check()
                        }
                    }
                    MTChip(text: "\(game.numbers[n])", size: chip, glow: level)
                        .onTapGesture { take(n, from: id) }
                        .accessibilityLabel("\(game.numbers[n]) on the \(id == "L" ? "left" : "right"). Tap to take it off")
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
            }
            .frame(width: width, height: chip * 1.1, alignment: .bottom)
            Capsule().fill(hot ? Theme.sprout : (level ? Theme.right : Theme.text.opacity(0.75)))
                .frame(width: width, height: 9)
            Blocks(value: weight(idx, ops), empty: idx.isEmpty).padding(.top, 6)
        }
        .padding(.bottom, 4)
        .background(RoundedRectangle(cornerRadius: 18).fill(hot ? Theme.sprout.opacity(0.1) : .clear).padding(.top, strings))
        .mtTarget(id)
        .fixedSize()
        .position(x: end.x, y: end.y + (strings + chip * 1.1 + 9 + 6 + 34 + 4) / 2)
        .accessibilityElement(children: .contain)
    }

    private func put(_ n: Int, on id: String) {
        guard !level else { return }
        if id == "L", left.count < cap {
            if !left.isEmpty { lops.append(.plus) }; left.append(n)
        } else if id == "R", right.count < cap {
            if !right.isEmpty { rops.append(.plus) }; right.append(n)
        } else {
            game.say("That side is full. Leave a number for the other side", .miss); Haptics.miss(); return
        }
        Haptics.tick(); check()
    }

    private func take(_ n: Int, from id: String) {
        guard !level else { return }
        func remove(_ idx: inout [Int], _ ops: inout [Op]) {
            guard let j = idx.firstIndex(of: n) else { return }
            idx.remove(at: j)
            if !ops.isEmpty { ops.remove(at: max(j - 1, 0)) }
        }
        if id == "L" { remove(&left, &lops) } else { remove(&right, &rops) }
        Haptics.tick(); check()
    }

    private func check() {
        guard left.count + right.count == game.numbers.count else {
            if !game.found.isEmpty || !(left + right).isEmpty {
                game.say("Put every number on the scale", .hint)
            }
            return
        }
        switch game.submit(side(left, lops), side(right, rops)) {
        case .miss: Haptics.miss()
        case .newWay, .again:
            Haptics.right()
            withAnimation(.easeOut(duration: 0.2)) { level = true }
            Task {
                try? await Task.sleep(for: .milliseconds(1400))
                withAnimation(.easeOut(duration: 0.3)) { level = false }
            }
        }
    }
}

private struct Post: Shape {
    let top: CGPoint, bottom: CGPoint
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: top.x - 5, y: top.y))
        p.addLine(to: CGPoint(x: top.x + 5, y: top.y))
        p.addLine(to: CGPoint(x: bottom.x + 22, y: bottom.y))
        p.addLine(to: CGPoint(x: bottom.x - 22, y: bottom.y))
        p.closeSubpath()
        return p
    }
}

/// The V of strings from the beam's end down to the pan's edges.
private struct Strings: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY)); p.addLine(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        return p
    }
}

/// How much a pan holds: bars of ten and single blocks.
private struct Blocks: View {
    let value: Q?
    let empty: Bool
    var body: some View {
        Group {
            if empty {
                Text(" ").font(Theme.round(14, .bold))
            } else if let v = value?.whole, v >= 0 {
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(0..<min(v / 10, 6), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2).fill(Theme.even).frame(width: 7, height: 34)
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(7), spacing: 2), count: 2), spacing: 2) {
                        ForEach(0..<(v % 10), id: \.self) { _ in RoundedRectangle(cornerRadius: 1.5).fill(Theme.odd).frame(width: 7, height: 7) }
                    }
                    .frame(width: 16, height: 34, alignment: .bottom)
                    Text("\(v)").font(Theme.round(16, .heavy)).foregroundStyle(Theme.text).padding(.leading, 4)
                }
                .accessibilityLabel("This side weighs \(v)")
            } else {
                Text(value.map { $0.n < 0 ? "below 0" : "not even" } ?? "?")
                    .font(Theme.round(14, .bold)).foregroundStyle(Theme.odd).frame(height: 34)
            }
        }
        .frame(height: 34)
    }
}

// MARK: - Machine

struct MachineBoard: View {
    @ObservedObject var game: MakeTrueGame
    @State private var bin: Int?                 // index of the number that should come out
    @State private var order: [Int] = []         // the hoppers, left to right
    @State private var ops: [Op] = []
    @State private var ball: Q?
    @State private var runs: CGFloat = 0
    @State private var running = false
    @State private var sprout = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 14) {
            machine
            HStack(spacing: 14) {
                ballView
                Image(systemName: "arrow.right").font(.system(size: 22, weight: .heavy)).foregroundStyle(Theme.muted)
                binView
            }
            Spacer(minLength: 4)
            if bin == nil {
                Text("Which number should come out? Tap it into the bin").font(Theme.round(16, .bold)).foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                NumberBank(numbers: game.numbers, used: [], targets: [:], hover: .constant(nil), size: game.numbers.count > 3 ? 62 : 70,
                           accept: { _ in false }, drop: { _, _ in }, tap: choose)
            } else {
                Button { pull() } label: {
                    Label("Pull the lever", systemImage: "hand.point.down.fill")
                }
                .buttonStyle(BigButtonStyle())
                .disabled(running)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: bin)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: order)
    }

    private var machine: some View {
        let n = max(order.count, game.numbers.count - 1)
        let chip: CGFloat = n > 2 ? 58 : 68
        return HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    ForEach(0..<n, id: \.self) { i in
                        if i > 0 {
                            VStack(spacing: 6) {
                                if i - 1 < ops.count {
                                    OpDial(op: ops[i - 1], ops: game.level.ops, size: 38) { ops[i - 1] = $0; ball = nil }
                                } else {
                                    Circle().strokeBorder(Theme.border, style: StrokeStyle(lineWidth: 2, dash: [4, 4])).frame(width: 38, height: 38)
                                }
                                Button { swap(i - 1) } label: {
                                    Image(systemName: "arrow.left.arrow.right").font(.system(size: 14, weight: .heavy))
                                        .foregroundStyle(Theme.text).frame(width: 36, height: 30)
                                        .background(Theme.bg, in: Capsule())
                                }
                                .buttonStyle(.plain)
                                .disabled(order.count < 2)
                                .accessibilityLabel("Swap these two")
                            }
                            .padding(.top, 10)
                        }
                        if i < order.count {
                            MTChip(text: "\(game.numbers[order[i]])", size: chip, glow: sprout)
                                .id(order[i])
                                .accessibilityLabel("\(game.numbers[order[i]]) in the machine")
                        } else {
                            MTSlot(size: chip).accessibilityHidden(true)
                        }
                    }
                }
                HStack(spacing: 18) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: "gearshape.fill").font(.system(size: i == 1 ? 34 : 24))
                            .foregroundStyle(Theme.muted.opacity(0.6))
                            .rotationEffect(.degrees(Double(runs) * (i == 1 ? -180 : 240)))
                    }
                }
                .accessibilityHidden(true)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(sprout ? Theme.right : Theme.border, lineWidth: sprout ? 3 : 2))
            .modifier(Shake(amount: reduceMotion || !running ? 0 : 4, animatableData: runs * 3))
            Lever(down: running).frame(width: 30, height: 120).padding(.top, 10).onTapGesture { if bin != nil { pull() } }
                .accessibilityHidden(true)
        }
    }

    private var ballView: some View {
        let whole = ball?.whole
        let hit = ball != nil && bin.map { Q(game.numbers[$0]) == ball } == true
        return ZStack {
            Circle().fill(ball == nil ? Theme.bg : (hit ? Theme.right : Theme.odd)).frame(width: 66, height: 66)
                .overlay(Circle().stroke(Theme.border, lineWidth: ball == nil ? 2 : 0))
            Text(ball == nil ? "?" : (whole.map(String.init) ?? "÷?"))
                .font(Theme.round(whole.map { abs($0) > 99 } == true ? 20 : 28))
                .foregroundStyle(ball == nil ? Theme.muted : Theme.onColor)
                .minimumScaleFactor(0.5)
        }
        .scaleEffect(ball == nil ? 0.9 : 1)
        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: ball)
        .accessibilityLabel(ball == nil ? "Nothing out yet" : "The machine made \(whole.map(String.init) ?? "a number that isn't whole")")
    }

    private var binView: some View {
        Button { clearBin() } label: {
            VStack(spacing: 2) {
                ZStack(alignment: .top) {
                    if let b = bin {
                        MTChip(text: "\(game.numbers[b])", size: 66, glow: sprout)
                    } else {
                        MTSlot(size: 66, hot: true)
                    }
                    Text("🌱").font(.system(size: 40))
                        .scaleEffect(sprout ? 1 : 0.01, anchor: .bottom)
                        .opacity(sprout ? 1 : 0)
                        .offset(y: -42)
                        .animation(.spring(response: 0.5, dampingFraction: 0.55), value: sprout)
                }
                Text("the bin").font(Theme.round(13, .bold)).foregroundStyle(Theme.muted)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(bin.map { "Bin: \(game.numbers[$0]). Tap to pick a different number" } ?? "The bin is empty")
    }

    private func choose(_ i: Int) {
        bin = i
        order = game.numbers.indices.filter { $0 != i }
        ops = Array(repeating: .plus, count: order.count - 1)
        ball = nil
        game.say("Pick the signs, then pull the lever", .hint)
        Haptics.tick()
    }

    private func clearBin() {
        guard bin != nil, !running else { return }
        bin = nil; order = []; ops = []; ball = nil
        Haptics.tick()
    }

    private func swap(_ i: Int) {
        guard i + 1 < order.count, !running else { return }
        order.swapAt(i, i + 1); ball = nil; Haptics.tick()
    }

    private func pull() {
        guard let b = bin, !running else { return }
        running = true; ball = nil
        Haptics.tick()
        withAnimation(.easeInOut(duration: 0.7)) { runs += 1 }
        Task {
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 200 : 750))
            let l = Side(nums: order.map { game.numbers[$0] }, ops: ops)
            ball = l.value
            running = false
            switch game.submit(l, Side(nums: [game.numbers[b]], ops: [])) {
            case .miss: Haptics.miss()
            case .newWay, .again:
                Haptics.right()
                sprout = true
                try? await Task.sleep(for: .milliseconds(1600))
                sprout = false
            }
        }
    }
}

/// The lever on the machine's side: a stick with a knob that drops when pulled.
private struct Lever: View {
    let down: Bool
    var body: some View {
        ZStack(alignment: .top) {
            Capsule().fill(Theme.border).frame(width: 8, height: 110).offset(y: 10)
            Circle().fill(Theme.odd).frame(width: 30, height: 30)
                .offset(y: down ? 84 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.55), value: down)
        }
    }
}
