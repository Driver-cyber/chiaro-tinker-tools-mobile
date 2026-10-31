//  Modes.swift — every concept and its modes, in one list.
//
//  A concept sits in the bar at the top of the home screen; its modes are
//  named by the skill they practise, each with its own stars. Card modes deal
//  a round of ten; Draw modes open a picture to finish.

import Foundation

enum Concept: String, CaseIterable, Identifiable {
    case evenOdd, biggerSmaller, addSubtract, times, draw
    var id: String { rawValue }
    var title: String {
        switch self {
        case .evenOdd: return "Even or Odd"
        case .biggerSmaller: return "Bigger or Smaller"
        case .addSubtract: return "Add & Subtract"
        case .times: return "Times Tables"
        case .draw: return "Draw"
        }
    }
    var symbol: String {
        switch self {
        case .evenOdd: return "circle.grid.2x2.fill"
        case .biggerSmaller: return "greaterthan"
        case .addSubtract: return "plus.forwardslash.minus"
        case .times: return "multiply"
        case .draw: return "paintbrush.pointed.fill"
        }
    }
}

enum DrawKind: Equatable {
    case color(max: Int)       // color by number, answers up to max
    case dotSteps              // dot to dot: "3 right, 2 up"
    case dotPairs              // dot to dot: "Pin (3, 5)"
    case explore               // a blank plane: pin anywhere
}

struct Mode: Identifiable {
    enum Play {
        case cards(() -> [Card])
        case draw(DrawKind)
    }
    let id: String
    let concept: Concept
    let title: String
    let detail: String
    let art: String            // the little picture on the tile
    let play: Play
}

enum Modes {
    static let all: [Mode] = [
        Mode(id: "eo.dots", concept: .evenOdd, title: "Pair the dots", detail: "1 to 10, with dots to pair up", art: "••",
             play: .cards { var g = SystemRandomNumberGenerator(); return EvenOdd.round(.dots, using: &g) }),
        Mode(id: "eo.twenty", concept: .evenOdd, title: "Numbers to 20", detail: "1 to 20, just the number", art: "17",
             play: .cards { var g = SystemRandomNumberGenerator(); return EvenOdd.round(.toTwenty, using: &g) }),
        Mode(id: "eo.last", concept: .evenOdd, title: "Last digit", detail: "Big numbers: look at the last digit", art: "348",
             play: .cards { var g = SystemRandomNumberGenerator(); return EvenOdd.round(.lastDigit, using: &g) }),

        Mode(id: "bs.twenty", concept: .biggerSmaller, title: "Within 20", detail: "Which is bigger? Numbers to 20", art: "9<14",
             play: .cards { var g = SystemRandomNumberGenerator(); return Compare.round(.within20, using: &g) }),
        Mode(id: "bs.tens", concept: .biggerSmaller, title: "Tens first", detail: "To 100: the tens decide", art: "52>38",
             play: .cards { var g = SystemRandomNumberGenerator(); return Compare.round(.tensFirst, using: &g) }),
        Mode(id: "bs.look", concept: .biggerSmaller, title: "Look-alikes", detail: "68 or 86? Look carefully", art: "68·86",
             play: .cards { var g = SystemRandomNumberGenerator(); return Compare.round(.lookAlikes, using: &g) }),
        Mode(id: "bs.thousand", concept: .biggerSmaller, title: "To 1,000", detail: "The hundreds decide first", art: "406",
             play: .cards { var g = SystemRandomNumberGenerator(); return Compare.round(.toThousand, using: &g) }),

        Mode(id: "as.onetwo", concept: .addSubtract, title: "+1 and +2", detail: "Add or take away 1 or 2", art: "5+1",
             play: .cards { var g = SystemRandomNumberGenerator(); return AddSub.round(.onesTwos, using: &g) }),
        Mode(id: "as.ten", concept: .addSubtract, title: "Make 10", detail: "8 + 5 is 8 + 2 + 3", art: "8+5",
             play: .cards { var g = SystemRandomNumberGenerator(); return AddSub.round(.makeTen, using: &g) }),
        Mode(id: "as.doubles", concept: .addSubtract, title: "Doubles", detail: "6 + 6, and 6 + 7 is one more", art: "6+6",
             play: .cards { var g = SystemRandomNumberGenerator(); return AddSub.round(.doubles, using: &g) }),
        Mode(id: "as.twenty", concept: .addSubtract, title: "Within 20", detail: "Add and take away", art: "13−8",
             play: .cards { var g = SystemRandomNumberGenerator(); return AddSub.round(.within20, using: &g) }),
        Mode(id: "as.missing", concept: .addSubtract, title: "Missing number", detail: "7 + ? = 12", art: "7+?",
             play: .cards { var g = SystemRandomNumberGenerator(); return AddSub.round(.missing, using: &g) }),
        Mode(id: "as.two", concept: .addSubtract, title: "Two-digit", detail: "Tens, then ones", art: "43+25",
             play: .cards { var g = SystemRandomNumberGenerator(); return AddSub.round(.twoDigit, using: &g) }),

        Mode(id: "tt.01", concept: .times, title: "×0 ×1", detail: "Zero makes 0; one keeps it the same", art: "×1",
             play: .cards { var g = SystemRandomNumberGenerator(); return Times.round(.zeroOne, using: &g) }),
        Mode(id: "tt.2", concept: .times, title: "×2 table", detail: "Doubles: 2, 4, 6, 8…", art: "×2",
             play: .cards { var g = SystemRandomNumberGenerator(); return Times.round(.table(2), using: &g) }),
        Mode(id: "tt.3", concept: .times, title: "×3 table", detail: "A double plus one more", art: "×3",
             play: .cards { var g = SystemRandomNumberGenerator(); return Times.round(.table(3), using: &g) }),
        Mode(id: "tt.4", concept: .times, title: "×4 table", detail: "Double, then double again", art: "×4",
             play: .cards { var g = SystemRandomNumberGenerator(); return Times.round(.table(4), using: &g) }),
        Mode(id: "tt.510", concept: .times, title: "×5 ×10", detail: "Fives end in 0 or 5; tens add a zero", art: "×5",
             play: .cards { var g = SystemRandomNumberGenerator(); return Times.round(.fiveTen, using: &g) }),
        Mode(id: "tt.9", concept: .times, title: "×9 tricks", detail: "The digits add to 9", art: "×9",
             play: .cards { var g = SystemRandomNumberGenerator(); return Times.round(.nines, using: &g) }),
        Mode(id: "tt.mixed", concept: .times, title: "Mixed", detail: "All of 1 to 10", art: "7×8",
             play: .cards { var g = SystemRandomNumberGenerator(); return Times.round(.mixed, using: &g) }),
        Mode(id: "tt.what", concept: .times, title: "What times what?", detail: "? × ? = 24", art: "?×?",
             play: .cards { var g = SystemRandomNumberGenerator(); return Times.round(.whatTimesWhat, using: &g) }),

        Mode(id: "dr.color10", concept: .draw, title: "Color by Number", detail: "Answers up to 10 color the picture", art: "🎨",
             play: .draw(.color(max: 10))),
        Mode(id: "dr.color20", concept: .draw, title: "Color to 20", detail: "Color by Number, answers to 20", art: "🖍️",
             play: .draw(.color(max: 20))),
        Mode(id: "dr.steps", concept: .draw, title: "Dot to Dot: Steps", detail: "3 right, 2 up: find the picture", art: "→↑",
             play: .draw(.dotSteps)),
        Mode(id: "dr.pairs", concept: .draw, title: "Dot to Dot: Pairs", detail: "Pin (3, 5): find the picture", art: "(3,5)",
             play: .draw(.dotPairs)),
        Mode(id: "dr.explore", concept: .draw, title: "Explore", detail: "Pin anywhere and draw your own", art: "✏️",
             play: .draw(.explore)),
    ]

    static func modes(_ c: Concept) -> [Mode] { all.filter { $0.concept == c } }
    static func mode(_ id: String) -> Mode? { all.first { $0.id == id } }
}
