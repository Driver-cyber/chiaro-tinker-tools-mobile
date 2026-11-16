//  MakeTrueView.swift — the Make It True screen: pick a level and a way to see
//  it (Tiles, Scale or Machine), then solve today's numbers as many ways as you
//  can. Switching views keeps the puzzle and the ways found. Numbers drag into
//  place or tap into the next open space; a placed piece taps back off.
//  Tiles lives here; Scale and Machine are in MakeTrueBoards.swift.

import SwiftUI

enum MTView: String, CaseIterable, Identifiable {
    case tiles, scale, machine
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .tiles: return "rectangle.split.3x1.fill"
        case .scale: return "scalemass.fill"
        case .machine: return "gearshape.2.fill"
        }
    }
}

struct MakeTrueView: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage("ns.mt.level") private var levelRaw = MTLevel.easy.rawValue
    @AppStorage("ns.mt.view") private var viewRaw = MTView.tiles.rawValue
    @StateObject private var game = MakeTrueGame(level: MTLevel(rawValue: UserDefaults.standard.string(forKey: "ns.mt.level") ?? "") ?? .easy)
    @State private var targets: [String: CGRect] = [:]
    @State private var hover: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var view: MTView { MTView(rawValue: viewRaw) ?? .tiles }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                CircleButton(symbol: "chevron.left", label: "Home") { model.screen = .home }
                Text("Make It True").font(Theme.round(28)).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.6)
                Spacer()
                PlayerBadge()
            }
            ViewSwitch(selection: Binding(get: { view }, set: { viewRaw = $0.rawValue }))
            HStack(spacing: 10) {
                LevelPicker(selection: Binding(get: { game.level }, set: { l in
                    levelRaw = l.rawValue
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { game.newPuzzle(l) }
                }))
                Spacer(minLength: 0)
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { game.newPuzzle() }
                    Haptics.tick()
                } label: {
                    Label("New", systemImage: "arrow.clockwise").font(Theme.round(16, .bold))
                        .foregroundStyle(game.allFound ? Theme.onColor : Theme.text)
                        .padding(.horizontal, 14).frame(minHeight: 44)
                        .background(game.allFound ? Theme.sprout : Theme.card, in: Capsule())
                        .overlay(Capsule().stroke(game.allFound ? Theme.sprout : Theme.border, lineWidth: 2))
                }
                .accessibilityLabel("New puzzle")
            }
            WaysBar(game: game)
            Group {
                switch view {
                case .tiles: TilesBoard(game: game, targets: targets, hover: $hover)
                case .scale: ScaleBoard(game: game, targets: targets, hover: $hover)
                case .machine: MachineBoard(game: game)
                }
            }
            .id("\(game.puzzleID)-\(viewRaw)")
            .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .coordinateSpace(name: "mt")
        .onPreferenceChange(MTTargets.self) { targets = $0 }
        .overlay { if !reduceMotion { Burst(trigger: game.wins).allowsHitTesting(false) } }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewRaw)
        .onChange(of: game.wins) { _ in model.addStars(mode: game.level.starKey, 1) }
    }
}

// MARK: - Shared pieces

/// Tiles, Scale, Machine: three ways to see the same puzzle.
private struct ViewSwitch: View {
    @Binding var selection: MTView
    var body: some View {
        HStack(spacing: 8) {
            ForEach(MTView.allCases) { v in
                let on = v == selection
                Button { selection = v; Haptics.tick() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: v.symbol).font(.system(size: 17, weight: .bold))
                        Text(v.title).font(Theme.round(16, .bold)).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(on ? Theme.onColor : Theme.text)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(on ? Theme.sprout : Theme.card, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(on ? Theme.sprout : Theme.border, lineWidth: 2))
                }
                .accessibilityLabel(v.title)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}

private struct LevelPicker: View {
    @Binding var selection: MTLevel
    var body: some View {
        HStack(spacing: 2) {
            ForEach(MTLevel.allCases) { l in
                let on = l == selection
                Button { if !on { selection = l; Haptics.tick() } } label: {
                    Text(l.title).font(Theme.round(15, .bold))
                        .foregroundStyle(on ? Theme.onColor : Theme.text)
                        .padding(.horizontal, 11).frame(minHeight: 40)
                        .background(on ? Theme.sprout : .clear, in: Capsule())
                }
                .accessibilityLabel("\(l.title): \(l.count) numbers")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Theme.card, in: Capsule())
        .overlay(Capsule().stroke(Theme.border, lineWidth: 2))
    }
}

/// How many ways are found, and the ways themselves.
private struct WaysBar: View {
    @ObservedObject var game: MakeTrueGame
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill").foregroundStyle(game.found.isEmpty ? Theme.muted.opacity(0.5) : Theme.star)
                Text("\(game.found.count) of \(game.total) \(game.total == 1 ? "way" : "ways")")
                    .font(Theme.round(17, .bold)).foregroundStyle(Theme.text)
                Spacer(minLength: 0)
                if game.total <= 12 {
                    HStack(spacing: 4) {
                        ForEach(0..<game.total, id: \.self) { i in
                            Circle().fill(i < game.found.count ? Theme.star : Theme.border).frame(width: 10, height: 10)
                        }
                    }
                    .accessibilityHidden(true)
                }
            }
            Text(game.message)
                .font(Theme.round(17, .bold))
                .foregroundStyle(game.tone == .right ? Theme.right : game.tone == .miss ? Theme.odd : Theme.muted)
                .lineLimit(2).minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
                .animation(nil, value: game.message)
            if !game.found.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(game.found.reversed(), id: \.self) { w in
                            Text(w).font(Theme.round(14, .bold)).foregroundStyle(Theme.right)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Theme.right.opacity(0.12), in: Capsule())
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Where a dragged piece can land, by id, in the screen's coordinate space.
struct MTTargets: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) { value.merge(nextValue()) { $1 } }
}

extension View {
    func mtTarget(_ id: String) -> some View {
        background(GeometryReader { g in Color.clear.preference(key: MTTargets.self, value: [id: g.frame(in: .named("mt"))]) })
    }
}

func mtHit(_ p: CGPoint, _ targets: [String: CGRect], accept: (String) -> Bool) -> String? {
    targets.filter { accept($0.key) && $0.value.insetBy(dx: -10, dy: -14).contains(p) }
        .min { hypot($0.value.midX - p.x, $0.value.midY - p.y) < hypot($1.value.midX - p.x, $1.value.midY - p.y) }?.key
}

/// A piece that taps into the next space or drags onto one.
struct DragPiece<Label: View>: View {
    let targets: [String: CGRect]
    @Binding var hover: String?
    let accept: (String) -> Bool
    let drop: (String) -> Void
    let tap: () -> Void
    @ViewBuilder let label: () -> Label
    @State private var off: CGSize = .zero
    @State private var dragging = false

    var body: some View {
        label()
            .scaleEffect(dragging ? 1.12 : 1)
            .shadow(color: .black.opacity(dragging ? 0.2 : 0), radius: 10, y: 6)
            .offset(off)
            .zIndex(dragging ? 1 : 0)
            .onTapGesture(perform: tap)
            .gesture(
                DragGesture(minimumDistance: 6, coordinateSpace: .named("mt"))
                    .onChanged { v in
                        dragging = true
                        off = v.translation
                        let t = mtHit(v.location, targets, accept: accept)
                        if t != hover { hover = t; if t != nil { Haptics.tick() } }
                    }
                    .onEnded { v in
                        let t = mtHit(v.location, targets, accept: accept)
                        hover = nil
                        dragging = false
                        if let t { off = .zero; drop(t) } else { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { off = .zero } }
                    }
            )
    }
}

/// A number or sign as a chunky tile.
struct MTChip: View {
    let text: String
    var sign = false
    var size: CGFloat = 64
    var glow = false

    var body: some View {
        Text(text)
            .font(Theme.round(size * (sign ? 0.55 : (text.count > 1 ? 0.46 : 0.56))))
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .foregroundStyle(glow || sign ? Theme.onColor : Theme.text)
            .frame(width: size, height: size * (sign ? 1 : 1.1))
            .background(glow ? Theme.right : (sign ? Theme.sprout : Theme.card), in: RoundedRectangle(cornerRadius: size * 0.26))
            .overlay(RoundedRectangle(cornerRadius: size * 0.26).stroke(glow ? Theme.right : (sign ? .clear : Theme.border), lineWidth: 2))
            .contentShape(Rectangle())
    }
}

/// An empty space that a piece can land in.
struct MTSlot: View {
    var size: CGFloat
    var sign = false
    var hot = false
    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.26)
            .strokeBorder(hot ? Theme.sprout : Theme.border, style: StrokeStyle(lineWidth: hot ? 3 : 2, dash: [6, 5]))
            .background(RoundedRectangle(cornerRadius: size * 0.26).fill(hot ? Theme.sprout.opacity(0.12) : .clear))
            .frame(width: size, height: size * (sign ? 1 : 1.1))
    }
}

/// The puzzle's numbers; a used one leaves its outline behind.
struct NumberBank: View {
    let numbers: [Int]
    let used: Set<Int>
    let targets: [String: CGRect]
    @Binding var hover: String?
    var size: CGFloat = 64
    let accept: (String) -> Bool
    let drop: (Int, String) -> Void
    let tap: (Int) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(numbers.indices, id: \.self) { i in
                if used.contains(i) {
                    MTSlot(size: size).opacity(0.5).accessibilityHidden(true)
                } else {
                    DragPiece(targets: targets, hover: $hover, accept: accept, drop: { drop(i, $0) }, tap: { tap(i) }) {
                        MTChip(text: "\(numbers[i])", size: size)
                    }
                    .accessibilityLabel("Number \(numbers[i])")
                    .accessibilityAddTraits(.isButton)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// Tap to change the sign: + − (× ÷).
struct OpDial: View {
    let op: Op
    let ops: [Op]
    var size: CGFloat = 40
    let change: (Op) -> Void
    var body: some View {
        Button {
            let i = ops.firstIndex(of: op) ?? 0
            change(ops[(i + 1) % ops.count]); Haptics.tick()
        } label: {
            Text(op.rawValue).font(Theme.round(size * 0.6)).foregroundStyle(Theme.onColor)
                .frame(width: size, height: size)
                .background(Theme.sprout, in: Circle())
                .overlay(Circle().stroke(Theme.sprout.opacity(0.35), lineWidth: 4).padding(-4))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sign: \(op.word). Tap to change")
    }
}

// MARK: - Tiles: [ ] ○ [ ] ○ [ ], with = as one of the signs

enum Sign: Equatable {
    case op(Op), equals
    var text: String { if case .op(let o) = self { return o.rawValue } else { return "=" } }
}

struct TilesBoard: View {
    @ObservedObject var game: MakeTrueGame
    let targets: [String: CGRect]
    @Binding var hover: String?
    @State private var nums: [Int?]
    @State private var signs: [Sign?]
    @State private var shakes: CGFloat = 0
    @State private var glow = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(game: MakeTrueGame, targets: [String: CGRect], hover: Binding<String?>) {
        self.game = game; self.targets = targets; _hover = hover
        _nums = State(initialValue: Array(repeating: nil, count: game.numbers.count))
        _signs = State(initialValue: Array(repeating: nil, count: game.numbers.count - 1))
    }

    private var bankSigns: [Sign] { game.level.ops.map { .op($0) } + [.equals] }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)
            GeometryReader { g in
                let n = CGFloat(nums.count)
                let sp: CGFloat = 6
                let opW = min(56, (g.size.width - 20 - sp * (2 * n - 2)) / (n * 1.35 + n - 1))
                let numW = min(76, opW * 1.35)
                HStack(spacing: sp) {
                    ForEach(0..<nums.count, id: \.self) { i in
                        numberSpace(i, numW)
                        if i < signs.count { signSpace(i, opW) }
                    }
                }
                .padding(10)
                .background(glow ? Theme.right.opacity(0.14) : Theme.card.opacity(0.6), in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(glow ? Theme.right : Theme.border, lineWidth: glow ? 3 : 2))
                .modifier(Shake(amount: reduceMotion ? 0 : 10, animatableData: shakes))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 110)
            Text("Put one = sign in, and a sign in every gap").font(Theme.round(15, .semibold)).foregroundStyle(Theme.muted)
                .padding(.top, 6)
            Spacer(minLength: 12)
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    ForEach(bankSigns, id: \.text) { s in
                        DragPiece(targets: targets, hover: $hover, accept: { $0.hasPrefix("o") }, drop: { place(s, $0) }, tap: { tapSign(s) }) {
                            MTChip(text: s.text, sign: true, size: 54)
                        }
                        .accessibilityLabel(s == .equals ? "Equals sign" : "Sign \(s.text)")
                        .accessibilityAddTraits(.isButton)
                    }
                }
                NumberBank(numbers: game.numbers, used: Set(nums.compactMap { $0 }), targets: targets, hover: $hover,
                           size: game.numbers.count > 3 ? 62 : 70,
                           accept: { $0.hasPrefix("n") }, drop: { place($0, $1) }, tap: tapNumber)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: nums)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: signs)
    }

    private func numberSpace(_ i: Int, _ w: CGFloat) -> some View {
        Group {
            if let k = nums[i] {
                MTChip(text: "\(game.numbers[k])", size: w, glow: glow)
                    .onTapGesture { nums[i] = nil; Haptics.tick() }
                    .accessibilityLabel("\(game.numbers[k]). Tap to take it off")
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            } else {
                MTSlot(size: w, hot: hover == "n\(i)").accessibilityLabel("Empty number space")
            }
        }
        .mtTarget("n\(i)")
    }

    private func signSpace(_ i: Int, _ w: CGFloat) -> some View {
        Group {
            if let s = signs[i] {
                MTChip(text: s.text, sign: true, size: w, glow: glow)
                    .onTapGesture { signs[i] = nil; Haptics.tick() }
                    .accessibilityLabel("\(s == .equals ? "Equals" : s.text). Tap to take it off")
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            } else {
                MTSlot(size: w, sign: true, hot: hover == "o\(i)").accessibilityLabel("Empty sign space")
            }
        }
        .mtTarget("o\(i)")
    }

    private func tapNumber(_ k: Int) {
        guard !glow, let i = nums.firstIndex(where: { $0 == nil }) else { return }
        nums[i] = k; Haptics.tick(); check()
    }

    private func tapSign(_ s: Sign) {
        guard !glow else { return }
        guard let i = signs.firstIndex(where: { $0 == nil }) else { return }
        signs[i] = s; Haptics.tick(); check()
    }

    private func place(_ k: Int, _ target: String) {
        guard !glow, let i = Int(target.dropFirst()) else { return }
        nums[i] = k; check()
    }

    private func place(_ s: Sign, _ target: String) {
        guard !glow, let i = Int(target.dropFirst()) else { return }
        signs[i] = s; check()
    }

    private func check() {
        guard nums.allSatisfy({ $0 != nil }), signs.allSatisfy({ $0 != nil }) else { return }
        let values = nums.map { game.numbers[$0!] }
        let eq = signs.indices.filter { signs[$0] == .equals }
        guard eq.count == 1, let at = eq.first else {
            game.say(eq.isEmpty ? "It needs an = sign somewhere" : "Use just one = sign", .miss)
            miss(); return
        }
        func ops(_ r: Range<Int>) -> [Op] { r.map { if case .op(let o) = signs[$0]! { return o } else { return .plus } } }
        let l = Side(nums: Array(values[...at]), ops: ops(0..<at))
        let r = Side(nums: Array(values[(at + 1)...]), ops: ops((at + 1)..<signs.count))
        switch game.submit(l, r) {
        case .miss: miss()
        case .newWay, .again:
            Haptics.right()
            withAnimation(.easeOut(duration: 0.2)) { glow = true }
            Task {
                try? await Task.sleep(for: .milliseconds(1300))
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    glow = false
                    nums = nums.map { _ in nil }; signs = signs.map { _ in nil }
                }
            }
        }
    }

    private func miss() {
        Haptics.miss()
        withAnimation(.linear(duration: 0.45)) { shakes += 1 }
    }
}
