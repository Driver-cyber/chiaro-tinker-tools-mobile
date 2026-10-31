//  DotToDot.swift — pin points on a grid; the lines between them become a picture.
//
//  Pairs mode asks "Pin (3, 5)": set across and up with the − / + buttons and
//  a ghost dot shows where the pin will go. Steps mode, for younger kids, asks
//  "Go 3 right and 2 up" from the last pin, with arrow buttons and no numbers
//  on the axes. Pin places the dot and draws the line; Undo picks up the last
//  pin; Clear starts the picture over. A wrong pin is shown in orange with what
//  it is versus what was asked, and Undo fixes it. The last pin goes back to
//  the start, the shape closes and fills, and it says how many corners it has.
//  Explore is the same plane with no picture: close a shape on its first pin
//  and it fills in and gets named.

import SwiftUI

struct GridPoint: Equatable, Hashable {
    var x: Int
    var y: Int
}

enum DotGeometry {
    static let size = 10           // the plane runs 0…10 both ways

    static func point(_ p: CGPoint, side: CGFloat) -> CGPoint {
        let pad = side * 0.06, u = (side - 2 * pad) / CGFloat(size)
        return CGPoint(x: pad + p.x * u, y: pad + (CGFloat(size) - p.y) * u)
    }

    static func path(_ pts: [CGPoint], side: CGFloat, closed: Bool) -> Path {
        var path = Path()
        guard let first = pts.first else { return path }
        path.move(to: point(first, side: side))
        for p in pts.dropFirst() { path.addLine(to: point(p, side: side)) }
        if closed { path.closeSubpath() }
        return path
    }

    /// The nearest grid point to a tap, for Explore.
    static func nearest(_ p: CGPoint, side: CGFloat) -> GridPoint {
        let pad = side * 0.06, u = (side - 2 * pad) / CGFloat(size)
        let x = Int(((p.x - pad) / u).rounded()), y = size - Int(((p.y - pad) / u).rounded())
        return GridPoint(x: min(max(x, 0), size), y: min(max(y, 0), size))
    }

    /// "a triangle", "a square", "a rectangle", or "a shape with 6 corners".
    static func name(_ pts: [GridPoint]) -> String {
        switch pts.count {
        case 3: return "a triangle"
        case 4:
            let xs = Set(pts.map(\.x)), ys = Set(pts.map(\.y))
            if xs.count == 2 && ys.count == 2 {
                let w = xs.max()! - xs.min()!, h = ys.max()! - ys.min()!
                return w == h ? "a square" : "a rectangle"
            }
            return "a shape with 4 corners"
        case 5: return "a pentagon, with 5 corners"
        case 6: return "a hexagon, with 6 corners"
        default: return "a shape with \(pts.count) corners"
        }
    }
}

enum DotToDot {
    /// The pins to place, in order: every point, then back to the start.
    static func targets(_ p: DotPicture) -> [GridPoint] {
        let pts = p.points.map { GridPoint(x: $0.x, y: $0.y) }
        return pts + [pts[0]]
    }

    /// "Go 3 right and 2 up" from one pin to the next.
    static func stepText(from a: GridPoint, to b: GridPoint) -> String {
        let dx = b.x - a.x, dy = b.y - a.y
        var parts: [String] = []
        if dx != 0 { parts.append("\(abs(dx)) \(dx > 0 ? "right" : "left")") }
        if dy != 0 { parts.append("\(abs(dy)) \(dy > 0 ? "up" : "down")") }
        return "Go " + parts.joined(separator: " and ")
    }

    static func pairText(_ p: GridPoint) -> String { "Pin (\(p.x), \(p.y))" }
}

struct DotToDotView: View {
    let picture: DotPicture
    let steps: Bool
    let done: () -> Void
    let next: () -> Void
    let close: () -> Void

    @State private var pins: [GridPoint] = []
    @State private var cursor = GridPoint(x: 0, y: 0)
    @State private var finished = false
    @State private var bursts = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var targets: [GridPoint] { DotToDot.targets(picture) }
    /// How many pins are right so far (a wrong pin is always the last one).
    private var good: Int { pins.enumerated().prefix { $0.element == targets[$0.offset] }.count }
    private var wrongPin: GridPoint? { pins.count > good ? pins.last : nil }
    private var target: GridPoint? { good < targets.count ? targets[good] : nil }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                CircleButton(symbol: "xmark", label: "Back to pictures", action: close)
                Text(finished ? "A \(picture.name)!" : (steps ? "Dot to Dot: Steps" : "Dot to Dot: Pairs"))
                    .font(Theme.round(24)).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.6)
                Spacer()
                PlayerBadge()
            }
            .padding(.top, 8)
            instruction
            Plane(pins: pins, wrong: wrongPin, cursor: finished ? nil : cursor, numbers: !steps,
                  closedFill: finished ? picture.paint.color : nil, shapes: [], tap: nil)
                .aspectRatio(1, contentMode: .fit)
            if finished { finishedPanel } else { controls }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .overlay { if !reduceMotion { Burst(trigger: bursts).allowsHitTesting(false) } }
        .onAppear(perform: start)
    }

    private func start() {
        if steps {                      // the first dot is given; everything after is steps
            pins = [targets[0]]
            cursor = targets[0]
        } else {
            pins = []
            cursor = GridPoint(x: 0, y: 0)
        }
    }

    private var instructionText: String {
        if let w = wrongPin, let t = target {
            return steps ? "That pin went off the path. Tap Undo and try again."
                         : "That's (\(w.x), \(w.y)). We wanted (\(t.x), \(t.y)). Tap Undo and try again."
        }
        guard let t = target else { return "" }
        let closing = good == targets.count - 1
        if steps, let last = pins.last {
            return (closing ? "Back to the start! " : "") + DotToDot.stepText(from: last, to: t)
        }
        return (closing ? "Back to the start: " : "") + DotToDot.pairText(t)
    }

    private var instruction: some View {
        Text(finished ? "It has \(picture.points.count) corners and \(picture.points.count) sides." : instructionText)
            .font(Theme.round(24))
            .foregroundStyle(wrongPin != nil ? Theme.odd : Theme.text)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, minHeight: 60)
            .padding(.horizontal, 12)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
            .onTapGesture { Speech.say(finished ? "A \(picture.name)!" : instructionText) }
            .accessibilityAddTraits(.isHeader)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            if steps {
                StepPad(cursor: $cursor, from: pins.last ?? cursor)
            } else {
                HStack(spacing: 10) {
                    Stepper2(label: "Across", value: $cursor.x)
                    Stepper2(label: "Up", value: $cursor.y)
                }
            }
            HStack(spacing: 10) {
                Button { pin() } label: { Label("Pin", systemImage: "mappin") }
                    .buttonStyle(BigButtonStyle())
                    .disabled(wrongPin != nil)
                    .opacity(wrongPin != nil ? 0.4 : 1)
                Button { undo() } label: { Label("Undo", systemImage: "arrow.uturn.backward") }
                    .buttonStyle(SoftButtonStyle())
                Button { start(); Haptics.tick() } label: { Label("Clear", systemImage: "trash") }
                    .buttonStyle(SoftButtonStyle())
            }
            .labelStyle(.titleAndIcon)
        }
    }

    private func pin() {
        guard wrongPin == nil else { return }
        pins.append(cursor)
        if pins.last == targets[pins.count - 1] {
            Haptics.tick()
            if pins.count == targets.count { complete() }
        } else {
            Haptics.miss()
            Speech.say(instructionText)
        }
    }

    private func undo() {
        guard pins.count > (steps ? 1 : 0) else { return }
        pins.removeLast()
        if let last = pins.last { cursor = last }
        Haptics.tick()
    }

    private func complete() {
        withAnimation(.easeOut(duration: 0.5)) { finished = true }
        bursts += 1
        Haptics.right()
        done()
        Speech.say("A \(picture.name)! It has \(picture.points.count) corners.")
    }

    private var finishedPanel: some View {
        VStack(spacing: 10) {
            Button(action: next) { Label("Next picture", systemImage: "arrow.right") }.buttonStyle(BigButtonStyle())
            Button("Done", action: close).buttonStyle(SoftButtonStyle())
        }
    }
}

/// The coordinate plane: grid, optional numbers, pins and lines, a ghost cursor.
struct Plane: View {
    let pins: [GridPoint]
    let wrong: GridPoint?
    let cursor: GridPoint?
    let numbers: Bool
    let closedFill: Color?
    let shapes: [(points: [GridPoint], color: Color)]
    let tap: ((GridPoint) -> Void)?
    @State private var pulse = false

    var body: some View {
        GeometryReader { g in
            let side = min(g.size.width, g.size.height)
            let n = DotGeometry.size
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 22).fill(Theme.card)
                Path { p in
                    for i in 0...n {
                        p.move(to: DotGeometry.point(CGPoint(x: i, y: 0), side: side))
                        p.addLine(to: DotGeometry.point(CGPoint(x: i, y: n), side: side))
                        p.move(to: DotGeometry.point(CGPoint(x: 0, y: i), side: side))
                        p.addLine(to: DotGeometry.point(CGPoint(x: n, y: i), side: side))
                    }
                }
                .stroke(Theme.border, lineWidth: 1)
                Path { p in
                    p.move(to: DotGeometry.point(CGPoint(x: 0, y: 0), side: side))
                    p.addLine(to: DotGeometry.point(CGPoint(x: n, y: 0), side: side))
                    p.move(to: DotGeometry.point(CGPoint(x: 0, y: 0), side: side))
                    p.addLine(to: DotGeometry.point(CGPoint(x: 0, y: n), side: side))
                }
                .stroke(Theme.muted, lineWidth: 2)
                if numbers {
                    ForEach(0...n, id: \.self) { i in
                        Text("\(i)").font(Theme.round(10, .bold)).foregroundStyle(Theme.muted)
                            .position(DotGeometry.point(CGPoint(x: CGFloat(i), y: -0.45), side: side))
                        if i > 0 {
                            Text("\(i)").font(Theme.round(10, .bold)).foregroundStyle(Theme.muted)
                                .position(DotGeometry.point(CGPoint(x: -0.45, y: CGFloat(i)), side: side))
                        }
                    }
                }
                ForEach(Array(shapes.enumerated()), id: \.offset) { _, s in
                    let path = DotGeometry.path(s.points.map { CGPoint(x: $0.x, y: $0.y) }, side: side, closed: true)
                    path.fill(s.color.opacity(0.75))
                    path.stroke(Theme.text, lineWidth: 3)
                }
                let good = wrong == nil ? pins : Array(pins.dropLast())
                if let fill = closedFill {
                    DotGeometry.path(good.map { CGPoint(x: $0.x, y: $0.y) }, side: side, closed: true)
                        .fill(fill.opacity(0.85))
                        .transition(.opacity)
                }
                DotGeometry.path(good.map { CGPoint(x: $0.x, y: $0.y) }, side: side, closed: false)
                    .stroke(Theme.text, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                if let w = wrong, let last = good.last {
                    DotGeometry.path([CGPoint(x: last.x, y: last.y), CGPoint(x: w.x, y: w.y)], side: side, closed: false)
                        .stroke(Theme.odd, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 6]))
                }
                ForEach(Array(good.enumerated()), id: \.offset) { _, p in
                    Circle().fill(Theme.sprout).frame(width: 14, height: 14)
                        .position(DotGeometry.point(CGPoint(x: p.x, y: p.y), side: side))
                }
                if let w = wrong {
                    Circle().fill(Theme.odd).frame(width: 16, height: 16)
                        .position(DotGeometry.point(CGPoint(x: w.x, y: w.y), side: side))
                }
                if let c = cursor {
                    Circle().stroke(Theme.even, lineWidth: 3).frame(width: 26, height: 26)
                        .scaleEffect(pulse ? 1.15 : 0.9)
                        .overlay(Circle().fill(Theme.even.opacity(0.35)).frame(width: 12, height: 12))
                        .position(DotGeometry.point(CGPoint(x: c.x, y: c.y), side: side))
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: c)
                }
            }
            .frame(width: side, height: side)
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .local) { p in tap?(DotGeometry.nearest(p, side: side)) }
            .frame(maxWidth: .infinity)
        }
        .onAppear { withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { pulse = true } }
        .accessibilityElement()
        .accessibilityLabel(cursor.map { "Grid. The ghost dot is at \($0.x) across, \($0.y) up. \(pins.count) pins placed." } ?? "Grid")
    }
}

/// − value + with a label, for Pairs and Explore. Stays within 0…10.
struct Stepper2: View {
    let label: String
    @Binding var value: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(label).font(Theme.round(14, .bold)).foregroundStyle(Theme.muted)
            HStack(spacing: 6) {
                step("minus", -1)
                Text("\(value)")
                    .font(Theme.round(30))
                    .foregroundStyle(Theme.text)
                    .frame(minWidth: 44)
                    .monospacedDigit()
                step("plus", +1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(label) \(value)")
    }

    private func step(_ symbol: String, _ d: Int) -> some View {
        Button { value = min(max(value + d, 0), DotGeometry.size); Haptics.tick() } label: {
            Image(systemName: symbol).font(.system(size: 20, weight: .bold))
                .frame(width: 52, height: 52)
                .background(Theme.bg, in: Circle())
        }
        .foregroundStyle(Theme.text)
        .accessibilityLabel("\(label) \(d > 0 ? "plus" : "minus") one")
    }
}

/// Arrow buttons for Steps mode, with the count so far from the last pin.
struct StepPad: View {
    @Binding var cursor: GridPoint
    let from: GridPoint

    var body: some View {
        let dx = cursor.x - from.x, dy = cursor.y - from.y
        HStack(spacing: 10) {
            arrow("arrow.left", -1, 0)
            VStack(spacing: 10) {
                arrow("arrow.up", 0, 1)
                arrow("arrow.down", 0, -1)
            }
            arrow("arrow.right", 1, 0)
            VStack(alignment: .leading, spacing: 4) {
                Text(dx == 0 ? "–" : "\(abs(dx)) \(dx > 0 ? "right" : "left")")
                Text(dy == 0 ? "–" : "\(abs(dy)) \(dy > 0 ? "up" : "down")")
            }
            .font(Theme.round(18, .bold))
            .foregroundStyle(Theme.muted)
            .frame(minWidth: 90, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    private func arrow(_ symbol: String, _ dx: Int, _ dy: Int) -> some View {
        Button {
            cursor = GridPoint(x: min(max(cursor.x + dx, 0), DotGeometry.size), y: min(max(cursor.y + dy, 0), DotGeometry.size))
            Haptics.tick()
        } label: {
            Image(systemName: symbol).font(.system(size: 22, weight: .heavy))
                .frame(width: 64, height: 52)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 2))
        }
        .foregroundStyle(Theme.text)
        .accessibilityLabel(symbol.replacingOccurrences(of: "arrow.", with: ""))
    }
}

/// A blank plane. Pin anywhere (numbers or a tap); pin back on a shape's first
/// point to close it, and it fills in and gets named.
struct ExploreView: View {
    let close: () -> Void
    @State private var pins: [GridPoint] = []
    @State private var shapes: [(points: [GridPoint], color: Color)] = []
    @State private var cursor = GridPoint(x: 5, y: 5)
    @State private var message = "Pin dots anywhere. Pin your first dot again to close a shape!"
    private let colors: [Color] = [Paint.orange.color, Paint.blue.color, Paint.green.color, Paint.red.color, Paint.yellow.color]

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                CircleButton(symbol: "xmark", label: "Back", action: close)
                Text("Explore").font(Theme.round(24)).foregroundStyle(Theme.text)
                Spacer()
                PlayerBadge()
            }
            .padding(.top, 8)
            Text(message)
                .font(Theme.round(18, .bold)).foregroundStyle(Theme.text)
                .multilineTextAlignment(.center).minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 60)
                .padding(.horizontal, 12)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
            Plane(pins: pins, wrong: nil, cursor: cursor, numbers: true, closedFill: nil, shapes: shapes) { p in cursor = p; Haptics.tick() }
                .aspectRatio(1, contentMode: .fit)
            HStack(spacing: 10) {
                Stepper2(label: "Across", value: $cursor.x)
                Stepper2(label: "Up", value: $cursor.y)
            }
            HStack(spacing: 10) {
                Button { pin() } label: { Label("Pin", systemImage: "mappin") }.buttonStyle(BigButtonStyle())
                Button { undo() } label: { Label("Undo", systemImage: "arrow.uturn.backward") }.buttonStyle(SoftButtonStyle())
                Button { pins = []; shapes = []; message = "A blank page. Pin anywhere!"; Haptics.tick() } label: {
                    Label("Clear", systemImage: "trash")
                }.buttonStyle(SoftButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private func pin() {
        if pins.count >= 3, cursor == pins[0] {
            let name = DotGeometry.name(pins)
            shapes.append((pins, colors[shapes.count % colors.count]))
            pins = []
            message = "You made \(name)!"
            Haptics.right()
            Speech.say(message)
            return
        }
        if pins.last == cursor { return }
        pins.append(cursor)
        message = "Pinned (\(cursor.x), \(cursor.y))."
        Haptics.tick()
    }

    private func undo() {
        if !pins.isEmpty {
            pins.removeLast()
        } else if let last = shapes.popLast() {         // reopen the last closed shape
            pins = last.points
        }
        message = pins.last.map { "Back to (\($0.x), \($0.y))." } ?? "Pin dots anywhere."
        Haptics.tick()
    }
}
