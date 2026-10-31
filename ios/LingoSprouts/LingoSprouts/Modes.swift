//  Modes.swift — every concept and its modes, in one list.
//
//  A concept sits in the bar at the top of the home screen; its modes are
//  named by the skill they practise, each with its own stars. Card modes deal
//  a round of ten; Story opens the sentence builder or the story book.

import Foundation

enum Concept: String, CaseIterable, Identifiable {
    case sounds, rhymes, words, tricks, story
    var id: String { rawValue }
    var title: String {
        switch self {
        case .sounds: return "Sounds"
        case .rhymes: return "Rhymes"
        case .words: return "Words"
        case .tricks: return "Word tricks"
        case .story: return "Story"
        }
    }
    var symbol: String {
        switch self {
        case .sounds: return "waveform"
        case .rhymes: return "music.note"
        case .words: return "textformat.abc"
        case .tricks: return "wand.and.stars"
        case .story: return "book.fill"
        }
    }
}

struct Mode: Identifiable {
    enum Play {
        case cards(() -> [Card])
        case storyBuild
        case storyBook
    }
    let id: String
    let concept: Concept
    let title: String
    let detail: String
    let art: String            // the little picture on the tile
    let play: Play
}

enum Modes {
    private static func cards(_ deal: @escaping (inout SystemRandomNumberGenerator) -> [Card]) -> Mode.Play {
        .cards { var g = SystemRandomNumberGenerator(); return deal(&g) }
    }

    static let all: [Mode] = [
        Mode(id: "so.first", concept: .sounds, title: "First sound", detail: "🐶 ?og: what does it start with?", art: "d",
             play: cards { Sounds.round(.first, using: &$0) }),
        Mode(id: "so.last", concept: .sounds, title: "Last sound", detail: "🐶 do?: what does it end with?", art: "g",
             play: cards { Sounds.round(.last, using: &$0) }),
        Mode(id: "so.blend", concept: .sounds, title: "Blend it", detail: "c · a · t: push the sounds together", art: "c·a·t",
             play: cards { Sounds.round(.blend, using: &$0) }),
        Mode(id: "so.digraph", concept: .sounds, title: "sh ch th wh", detail: "Two letters, one sound", art: "sh",
             play: cards { Sounds.round(.digraph, using: &$0) }),

        Mode(id: "rh.yes", concept: .rhymes, title: "Does it rhyme?", detail: "cat · hat? cat · dog?", art: "👂",
             play: cards { Rhymes.round(.yesNo, using: &$0) }),
        Mode(id: "rh.find", concept: .rhymes, title: "Find the rhyme", detail: "Which one rhymes with 🐱 cat?", art: "🎩",
             play: cards { Rhymes.round(.find, using: &$0) }),
        Mode(id: "rh.family", concept: .rhymes, title: "Word families", detail: "?at: change the start, keep the end", art: "-at",
             play: cards { Rhymes.round(.family, using: &$0) }),

        Mode(id: "wo.sight", concept: .words, title: "Hear and find", detail: "Tap 🔊 and find the word: the, said, was…", art: "the",
             play: cards { Reading.round(.sight, using: &$0) }),
        Mode(id: "wo.missing", concept: .words, title: "Missing letter", detail: "c?t: which letter goes in the middle?", art: "c?t",
             play: cards { Reading.round(.missing, using: &$0) }),
        Mode(id: "wo.spell", concept: .words, title: "Spell it", detail: "Tap the letter tiles in order", art: "🔤",
             play: cards { Reading.round(.spell, using: &$0) }),

        Mode(id: "tr.clap", concept: .tricks, title: "Clap it", detail: "but · ter · fly: count the claps", art: "👏",
             play: cards { WordTricks.round(.clap, using: &$0) }),
        Mode(id: "tr.compound", concept: .tricks, title: "Put it together", detail: "sun + flower = sunflower", art: "🌻",
             play: cards { WordTricks.round(.compound, using: &$0) }),
        Mode(id: "tr.magic", concept: .tricks, title: "Magic e", detail: "kit + e = kite", art: "✨e",
             play: cards { WordTricks.round(.magicE, using: &$0) }),
        Mode(id: "tr.alike", concept: .tricks, title: "Sound-alikes", detail: "two, too or to?", art: "2?",
             play: cards { WordTricks.round(.soundAlike, using: &$0) }),

        Mode(id: "st.build", concept: .story, title: "Build a story", detail: "Who? Did what? To what? Where?", art: "🐶🍕", play: .storyBuild),
        Mode(id: "st.book", concept: .story, title: "My story book", detail: "Every story you've made", art: "📖", play: .storyBook),
    ]

    static func modes(_ c: Concept) -> [Mode] { all.filter { $0.concept == c } }
    static func mode(_ id: String) -> Mode? { all.first { $0.id == id } }
}
