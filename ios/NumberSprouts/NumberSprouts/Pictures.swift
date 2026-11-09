//  Pictures.swift — the Draw pictures: shapes on a 10 × 10 grid, y pointing up.
//
//  Color by Number pictures are regions (polygons and circles), each painted
//  one colour from a small key. Dot to Dot pictures are whole-number points,
//  joined in order and closed back to the start. All original, drawn from
//  plain shapes, so each finished picture can also name its shapes.

import SwiftUI

struct Paint: Equatable {
    let name: String
    let color: Color

    static func == (a: Paint, b: Paint) -> Bool { a.name == b.name }

    static let red = Paint(name: "red", color: .dynamic(dark: 0xF0605A, light: 0xE5463F))
    static let blue = Paint(name: "blue", color: .dynamic(dark: 0x4C8DFF, light: 0x2F6FD6))
    static let sky = Paint(name: "sky blue", color: .dynamic(dark: 0x7CC4F5, light: 0x8ED0FA))
    static let navy = Paint(name: "navy", color: .dynamic(dark: 0x23305C, light: 0x26346B))
    static let yellow = Paint(name: "yellow", color: .dynamic(dark: 0xFFD15C, light: 0xF7C531))
    static let orange = Paint(name: "orange", color: .dynamic(dark: 0xFF9A4D, light: 0xF28A2E))
    static let green = Paint(name: "green", color: .dynamic(dark: 0x4CC97F, light: 0x34A853))
    static let brown = Paint(name: "brown", color: .dynamic(dark: 0xA8754A, light: 0x8B5A33))
    static let white = Paint(name: "white", color: .dynamic(dark: 0xEDEDF2, light: 0xFFFFFF))
    static let pink = Paint(name: "pink", color: .dynamic(dark: 0xF7A1C4, light: 0xF48FB8))
}

/// A finishing touch drawn over a picture and never painted: eyes, smiles,
/// rosy cheeks, raindrops, stars. Faces show from the start, so the kids know
/// who they're coloring.
struct Detail {
    enum Kind {
        case dot(CGPoint, CGFloat)
        case smile(CGPoint, CGFloat)        // a little ‿, also used for sleepy eyes
        case line([CGPoint])
    }
    let kind: Kind
    let color: Color

    static let ink = Color(red: 0.16, green: 0.16, blue: 0.22)
    static let blush = Color(red: 1, green: 0.42, blue: 0.55).opacity(0.5)

    static func eye(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat = 0.16) -> Detail { Detail(kind: .dot(CGPoint(x: x, y: y), r), color: ink) }
    static func cheek(_ x: CGFloat, _ y: CGFloat) -> Detail { Detail(kind: .dot(CGPoint(x: x, y: y), 0.22), color: blush) }
    static func dot(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ color: Color) -> Detail { Detail(kind: .dot(CGPoint(x: x, y: y), r), color: color) }
    static func smile(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat = 0.22) -> Detail { Detail(kind: .smile(CGPoint(x: x, y: y), w), color: ink) }
    static func line(_ pts: [(CGFloat, CGFloat)], _ color: Color = ink) -> Detail { Detail(kind: .line(pts.map { CGPoint(x: $0.0, y: $0.1) }), color: color) }

    /// Drawn in a square of side `side`, y flipped like the regions.
    func view(_ side: CGFloat) -> some View {
        let u = side / 10
        func pt(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * u, y: (10 - p.y) * u) }
        var path = Path()
        var filled = false
        switch kind {
        case .dot(let c, let r):
            path = Path(ellipseIn: CGRect(x: (c.x - r) * u, y: (10 - c.y - r) * u, width: 2 * r * u, height: 2 * r * u))
            filled = true
        case .smile(let c, let w):
            path.addArc(center: pt(c), radius: w * u, startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
        case .line(let pts):
            path.addLines(pts.map(pt))
        }
        return Group {
            if filled { path.fill(color) } else { path.stroke(color, style: StrokeStyle(lineWidth: max(1.5, 0.11 * u), lineCap: .round, lineJoin: .round)) }
        }
    }
}

struct Region {
    enum Shape {
        case poly([CGPoint])
        case circle(CGPoint, CGFloat)
    }
    let shape: Shape
    let paint: Paint

    static func rect(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat, _ p: Paint) -> Region {
        Region(shape: .poly([CGPoint(x: x0, y: y0), CGPoint(x: x1, y: y0), CGPoint(x: x1, y: y1), CGPoint(x: x0, y: y1)]), paint: p)
    }
    static func poly(_ pts: [(CGFloat, CGFloat)], _ p: Paint) -> Region {
        Region(shape: .poly(pts.map { CGPoint(x: $0.0, y: $0.1) }), paint: p)
    }
    static func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ p: Paint) -> Region {
        Region(shape: .circle(CGPoint(x: x, y: y), r), paint: p)
    }

    /// The path in a square of side `side`, flipping y so the grid's up is up.
    func path(_ side: CGFloat) -> Path {
        let u = side / 10
        switch shape {
        case .poly(let pts):
            var p = Path()
            p.addLines(pts.map { CGPoint(x: $0.x * u, y: (10 - $0.y) * u) })
            p.closeSubpath()
            return p
        case .circle(let c, let r):
            return Path(ellipseIn: CGRect(x: (c.x - r) * u, y: (10 - c.y - r) * u, width: 2 * r * u, height: 2 * r * u))
        }
    }

    /// Where the region's problem is printed.
    func center(_ side: CGFloat) -> CGPoint {
        let u = side / 10
        switch shape {
        case .poly(let pts):
            let x = pts.map(\.x).reduce(0, +) / CGFloat(pts.count)
            let y = pts.map(\.y).reduce(0, +) / CGFloat(pts.count)
            return CGPoint(x: x * u, y: (10 - y) * u)
        case .circle(let c, _): return CGPoint(x: c.x * u, y: (10 - c.y) * u)
        }
    }

    /// Roughly how much room the label has, in grid units.
    var room: CGFloat {
        switch shape {
        case .circle(_, let r): return 2 * r
        case .poly(let pts):
            let xs = pts.map(\.x), ys = pts.map(\.y)
            return min(xs.max()! - xs.min()!, ys.max()! - ys.min()!)
        }
    }

    /// For the geometry line at the end: "triangle", "rectangle", "circle"…
    var shapeName: String {
        switch shape {
        case .circle: return "circle"
        case .poly(let pts):
            switch pts.count {
            case 3: return "triangle"
            case 4:
                let axisAligned = Set(pts.map(\.x)).count == 2 && Set(pts.map(\.y)).count == 2
                if axisAligned {
                    let w = Set(pts.map(\.x)).sorted(), h = Set(pts.map(\.y)).sorted()
                    return abs((w[1] - w[0]) - (h[1] - h[0])) < 0.01 ? "square" : "rectangle"
                }
                return "four-sided shape"
            case 5: return "pentagon"
            case 6: return "hexagon"
            default: return "\(pts.count)-sided shape"
            }
        }
    }
}

struct ColorPicture: Identifiable {
    let id: String
    let name: String          // "rocket"
    let regions: [Region]     // back to front; the first is the background
    var details: [Detail] = []  // faces and finishing touches, on top, never painted

    var paints: [Paint] {
        var out: [Paint] = []
        for r in regions where !out.contains(r.paint) { out.append(r.paint) }
        return out
    }

    /// Where region i's problem is printed, in a 10-unit square (y down): its
    /// centre when that's clear, otherwise the open spot inside it that's
    /// furthest from anything drawn on top (the sky's label mustn't hide
    /// behind the rocket).
    func labelPoint(_ i: Int) -> CGPoint {
        let mine = regions[i].path(10)
        let above = regions[(i + 1)...].map { $0.path(10) }
        func free(_ p: CGPoint) -> Bool { mine.contains(p) && !above.contains { $0.contains(p) } }
        func clearance(_ p: CGPoint) -> Int {
            var n = 0
            for r in [0.4, 0.8, 1.2] as [CGFloat] {
                for k in 0..<8 {
                    let a = CGFloat(k) * .pi / 4
                    if free(CGPoint(x: p.x + cos(a) * r, y: p.y + sin(a) * r)) { n += 1 }
                }
            }
            return n
        }
        let c = regions[i].center(10)
        if free(c) && clearance(c) >= 20 { return c }
        var best = c, score = -1
        for x in stride(from: 0.5, through: 9.5, by: 0.25) {
            for y in stride(from: 0.5, through: 9.5, by: 0.25) {
                let p = CGPoint(x: x, y: y)
                guard free(p) else { continue }
                let s = clearance(p)
                if s > score { score = s; best = p }
            }
        }
        return best
    }

    /// "1 rectangle, 3 triangles and 3 circles" (the background doesn't count).
    var shapeSummary: String {
        var counts: [(String, Int)] = []
        for r in regions.dropFirst() {
            if let i = counts.firstIndex(where: { $0.0 == r.shapeName }) { counts[i].1 += 1 } else { counts.append((r.shapeName, 1)) }
        }
        let parts = counts.map { "\($0.1) \($0.0)\($0.1 == 1 ? "" : "s")" }
        guard parts.count > 1 else { return parts.first ?? "" }
        return parts.dropLast().joined(separator: ", ") + " and " + parts.last!
    }
}

struct DotPicture: Identifiable {
    let id: String
    let name: String
    let points: [(x: Int, y: Int)]
    let paint: Paint
}

enum Pictures {
    static let color: [ColorPicture] = [
        ColorPicture(id: "rocket", name: "rocket", regions: [
            .rect(0, 0, 10, 10, .navy),
            .poly([(3.5, 2.5), (6.5, 2.5), (6.5, 7), (3.5, 7)], .white),
            .poly([(3.5, 7), (6.5, 7), (5, 9.6)], .red),
            .circle(5, 5.2, 0.95, .sky),
            .poly([(3.5, 2.5), (3.5, 4.6), (1.8, 1.4)], .red),
            .poly([(6.5, 2.5), (8.2, 1.4), (6.5, 4.6)], .red),
            .poly([(4.1, 2.5), (5.9, 2.5), (5, 0.4)], .yellow),
            .circle(8.4, 8.4, 0.55, .yellow),
            .circle(1.6, 7.6, 0.45, .yellow),
        ]),
        ColorPicture(id: "house", name: "house", regions: [
            .rect(0, 0, 10, 10, .sky),
            .rect(0, 0, 10, 1.5, .green),
            .rect(2, 1.5, 8, 6, .orange),
            .poly([(1.2, 6), (8.8, 6), (5, 9.1)], .red),
            .rect(4.2, 1.5, 5.8, 4.4, .brown),
            .rect(6.2, 3.4, 7.6, 4.8, .yellow),
            .circle(8.7, 8.7, 0.9, .yellow),
        ]),
        ColorPicture(id: "fish", name: "fish", regions: [
            .rect(0, 0, 10, 10, .blue),
            .poly([(7, 5), (9.6, 7.4), (9.6, 2.6)], .yellow),
            .poly([(1.4, 5), (3, 6.9), (5.6, 7.3), (7.4, 5), (5.6, 2.7), (3, 3.1)], .orange),
            .poly([(4.2, 6.9), (5.4, 8.6), (6, 7.1)], .yellow),
            .circle(3.1, 5.4, 0.5, .navy),
            .circle(1.9, 8.2, 0.5, .white),
            .circle(2.9, 9.2, 0.35, .white),
            .poly([(7.8, 0), (8.8, 0), (9.4, 2.3), (8.3, 1.4)], .green),
        ]),
        ColorPicture(id: "boat", name: "boat", regions: [
            .rect(0, 0, 10, 10, .sky),
            .circle(2, 8.4, 1, .yellow),
            .rect(0, 0, 10, 3, .blue),
            .poly([(1.4, 3), (8.6, 3), (7.4, 1.3), (2.6, 1.3)], .brown),
            .poly([(5.3, 3.4), (5.3, 8.8), (8.5, 3.4)], .white),
            .poly([(4.9, 3.4), (4.9, 7.6), (2.1, 3.4)], .red),
            .poly([(5.3, 8.8), (5.3, 9.7), (6.4, 9.25)], .red),
        ]),
        ColorPicture(id: "tree", name: "apple tree", regions: [
            .rect(0, 0, 10, 10, .sky),
            .rect(0, 0, 10, 1.6, .green),
            .rect(4.2, 1.6, 5.8, 4.6, .brown),
            .circle(5, 6.6, 2.6, .green),
            .circle(4, 7.4, 0.55, .red),
            .circle(6.1, 5.6, 0.55, .red),
            .circle(5.6, 8.1, 0.55, .red),
            .circle(8.6, 8.7, 0.9, .yellow),
        ]),
        ColorPicture(id: "car", name: "car", regions: [
            .rect(0, 0, 10, 10, .sky),
            .rect(0, 0, 10, 2.2, .green),
            .poly([(2.6, 5), (7.2, 5), (6.2, 7.2), (3.4, 7.2)], .red),
            .rect(1, 3, 9, 5.2, .red),
            .rect(3.8, 5.3, 4.9, 6.7, .white),
            .rect(5.2, 5.3, 6.2, 6.7, .white),
            .circle(3, 3, 1.05, .navy),
            .circle(7, 3, 1.05, .navy),
            .circle(1.7, 8.6, 0.85, .yellow),
        ]),
        ColorPicture(id: "flower", name: "flower", regions: [
            .rect(0, 0, 10, 10, .sky),
            .rect(0, 0, 10, 1.5, .green),
            .rect(4.7, 1.5, 5.3, 5.2, .green),
            .poly([(5.3, 2.6), (7.6, 4.2), (5.3, 3.6)], .green),
            .circle(5, 8.1, 1.25, .orange),
            .circle(6.55, 7, 1.25, .orange),
            .circle(5.95, 5.3, 1.25, .orange),
            .circle(4.05, 5.3, 1.25, .orange),
            .circle(3.45, 7, 1.25, .orange),
            .circle(5, 6.6, 1.1, .yellow),
        ]),
        ColorPicture(id: "snowman", name: "snowman", regions: [
            .rect(0, 0, 10, 10, .navy),
            .rect(0, 0, 10, 2, .white),
            .circle(5, 3.4, 2, .white),
            .circle(5, 6.3, 1.45, .white),
            .rect(4, 7.5, 6, 9.4, .brown),
            .poly([(5, 6.5), (6.8, 6.2), (5, 5.9)], .orange),
            .circle(1.6, 8.4, 0.4, .yellow),
            .circle(8.4, 8.8, 0.4, .yellow),
            .circle(8.2, 5.2, 0.4, .yellow),
        ]),

        // Scenes: little characters with a bit of story. Faces are details.
        ColorPicture(id: "teaparty", name: "tea party", regions: [
            .rect(0, 0, 10, 10, .sky),
            .poly([(0.3, 10), (1.7, 10), (1, 8.7)], .yellow),
            .poly([(4.3, 10), (5.7, 10), (5, 8.7)], .yellow),
            .poly([(8.3, 10), (9.7, 10), (9, 8.7)], .yellow),
            .circle(1.3, 7.5, 0.65, .brown),
            .circle(3.5, 7.5, 0.65, .brown),
            .circle(2.4, 3.9, 1.5, .brown),
            .circle(2.4, 6.2, 1.5, .brown),
            .poly([(6.8, 7.1), (7, 9.7), (7.8, 7.3)], .pink),
            .poly([(8.2, 7.3), (9, 9.7), (9.2, 7.1)], .pink),
            .circle(8, 3.9, 1.5, .white),
            .circle(8, 6.2, 1.5, .white),
            .rect(0.6, 0, 9.4, 3.2, .pink),
            .circle(5, 4.4, 1.15, .orange),
            .poly([(5.9, 4.1), (6.7, 5.1), (6.3, 5.4), (5.8, 4.8)], .orange),
            .poly([(4.3, 5.4), (5.7, 5.4), (5, 6.3)], .orange),
            .rect(3.1, 3.2, 4.2, 4.3, .yellow),
            .rect(5.9, 3.2, 7, 4.3, .yellow),
        ], details: [
            .eye(1.9, 6.45), .eye(2.9, 6.45), .eye(2.4, 5.95, 0.17), .smile(2.4, 5.75, 0.2), .cheek(1.5, 5.95), .cheek(3.3, 5.95),
            .eye(7.5, 6.45), .eye(8.5, 6.45), .smile(8, 5.85, 0.2), .cheek(7.1, 5.95), .cheek(8.9, 5.95),
            .eye(4.6, 4.6, 0.13), .eye(5.4, 4.6, 0.13), .smile(5, 4.3, 0.17),
        ]),
        ColorPicture(id: "rainduck", name: "rainy day duck", regions: [
            .rect(0, 0, 10, 10, .sky),
            .circle(2, 9.2, 1.3, .white),
            .circle(3.7, 9.6, 1.1, .white),
            .circle(7.6, 9.4, 1.3, .white),
            .poly([(0.8, 0.3), (9.2, 0.3), (8.4, 1.5), (1.6, 1.5)], .blue),
            .poly([(2.4, 6.6), (3.5, 7.9), (5.1, 8.5), (6.7, 7.9), (7.8, 6.6)], .red),
            .circle(4.6, 2.9, 1.7, .yellow),
            .circle(5.8, 5.1, 1.15, .yellow),
            .poly([(3.2, 3.3), (5.1, 3.1), (4, 1.9)], .white),
            .poly([(6.7, 5.3), (8.2, 4.9), (6.7, 4.3)], .orange),
        ], details: [
            .line([(4.3, 6.6), (4.3, 4.5), (4, 4.2), (3.7, 4.4)]),
            .eye(6.1, 5.5, 0.17), .cheek(6.35, 4.85),
            .line([(1.3, 7.5), (1.1, 7)], .blue), .line([(8.9, 7.2), (8.7, 6.7)], .blue), .line([(1.6, 5.1), (1.4, 4.6)], .blue),
            .line([(8.7, 3.7), (8.5, 3.2)], .blue), .line([(9.3, 5.7), (9.1, 5.2)], .blue), .line([(0.9, 2.8), (0.7, 2.3)], .blue),
        ]),
        ColorPicture(id: "mushroom", name: "snail's mushroom house", regions: [
            .rect(0, 0, 10, 10, .sky),
            .rect(0, 0, 10, 2.2, .green),
            .rect(2, 2.2, 5.6, 5.6, .white),
            .poly([(0.8, 5.4), (1.6, 7.2), (3.8, 8.6), (6, 7.2), (6.8, 5.4)], .red),
            .rect(3.3, 2.2, 4.6, 4.2, .orange),
            .circle(2.75, 4.5, 0.5, .yellow),
            .circle(2.4, 6.5, 0.55, .white),
            .circle(4.9, 7.2, 0.6, .white),
            .circle(8.6, 8.7, 0.9, .yellow),
            .poly([(6, 2.2), (9.7, 2.2), (9.7, 3.1), (9.1, 3.4), (8.6, 2.9)], .yellow),
            .circle(7.6, 3.3, 1, .orange),
        ], details: [
            .dot(4.35, 3.2, 0.1, Detail.ink),
            .line([(7.6, 3.3), (7.9, 3.3), (7.9, 3.6), (7.4, 3.7), (7.2, 3.2), (7.6, 2.8), (8.2, 3)]),
            .line([(9.2, 3.3), (9.3, 4)]), .eye(9.32, 4.05, 0.13), .smile(9.25, 2.85, 0.15),
            .smile(8.6, 8.75, 0.25), .smile(8.25, 8.95, 0.12), .smile(8.95, 8.95, 0.12),
        ]),
        ColorPicture(id: "campfox", name: "camping fox", regions: [
            .rect(0, 0, 10, 10, .navy),
            .rect(0, 0, 10, 2.4, .green),
            .circle(8.3, 8.4, 1, .yellow),
            .poly([(0.6, 2.4), (5, 2.4), (2.8, 6.4)], .orange),
            .poly([(2.2, 2.4), (3.4, 2.4), (2.8, 4.2)], .brown),
            .rect(5.4, 1, 8, 2, .brown),
            .poly([(5.6, 2), (7.8, 2), (6.7, 4.6)], .red),
            .poly([(6.2, 2), (7.2, 2), (6.7, 3.4)], .yellow),
            .circle(9, 3.1, 0.95, .orange),
            .poly([(8.05, 5), (8.35, 6), (8.8, 5)], .orange),
            .poly([(9.2, 5), (9.65, 6), (9.95, 5)], .orange),
            .poly([(8, 5), (10, 5), (9, 3.6)], .orange),
        ], details: [
            .dot(1.2, 8.8, 0.12, .white), .dot(3, 9.3, 0.12, .white), .dot(5.2, 8.6, 0.12, .white),
            .dot(6.4, 9.5, 0.12, .white), .dot(1.8, 7.4, 0.12, .white), .dot(4.4, 7.6, 0.12, .white),
            .smile(8.6, 4.6, 0.15), .smile(9.4, 4.6, 0.15), .eye(9, 3.8, 0.13),
            .smile(8.0, 8.55, 0.15), .smile(8.6, 8.55, 0.15),
        ]),
    ]

    static let dots: [DotPicture] = [
        DotPicture(id: "house", name: "house", points: [(2, 1), (8, 1), (8, 6), (5, 9), (2, 6)], paint: .orange),
        DotPicture(id: "boat", name: "boat", points: [(1, 3), (5, 3), (5, 9), (8, 3), (9, 3), (7, 1), (3, 1)], paint: .blue),
        DotPicture(id: "fish", name: "fish", points: [(1, 5), (3, 7), (6, 7), (8, 5), (10, 7), (10, 3), (8, 5), (6, 3), (3, 3)], paint: .orange),
        DotPicture(id: "star", name: "star", points: [(5, 10), (6, 7), (9, 7), (7, 5), (8, 2), (5, 4), (2, 2), (3, 5), (1, 7), (4, 7)], paint: .yellow),
        DotPicture(id: "rocket", name: "rocket", points: [(5, 10), (7, 7), (7, 3), (9, 1), (6, 2), (4, 2), (1, 1), (3, 3), (3, 7)], paint: .red),
    ]

    static func count(_ kind: DrawKind) -> Int {
        switch kind {
        case .color: return color.count
        case .dotSteps, .dotPairs: return dots.count
        case .explore: return 0
        }
    }
}
