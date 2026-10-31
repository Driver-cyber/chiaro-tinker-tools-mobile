//  Words.swift — the word bank: every word paired with a built-in emoji picture.
//
//  Short-vowel words (consonant-vowel-consonant) for sounds, blending and
//  spelling; rhyme families; digraphs; sight words; syllable splits; compound
//  words; magic-e pairs; sound-alike sentences; and the story tiles. All plain
//  data, checked by the tests.

import Foundation

struct Word: Equatable, Hashable {
    let text: String
    let pic: String
}

enum Words {
    /// Three-letter short-vowel words with a picture.
    static let cvc: [Word] = [
        Word(text: "cat", pic: "🐱"), Word(text: "dog", pic: "🐶"), Word(text: "pig", pic: "🐷"), Word(text: "hen", pic: "🐔"),
        Word(text: "bug", pic: "🐛"), Word(text: "sun", pic: "☀️"), Word(text: "bus", pic: "🚌"), Word(text: "bed", pic: "🛏️"),
        Word(text: "box", pic: "📦"), Word(text: "fox", pic: "🦊"), Word(text: "hat", pic: "🎩"), Word(text: "bat", pic: "🦇"),
        Word(text: "map", pic: "🗺️"), Word(text: "van", pic: "🚐"), Word(text: "rat", pic: "🐀"), Word(text: "net", pic: "🥅"),
        Word(text: "web", pic: "🕸️"), Word(text: "fan", pic: "🪭"), Word(text: "can", pic: "🥫"), Word(text: "pen", pic: "🖊️"),
        Word(text: "ten", pic: "🔟"), Word(text: "mug", pic: "☕"), Word(text: "log", pic: "🪵"), Word(text: "cap", pic: "🧢"),
        Word(text: "jet", pic: "✈️"), Word(text: "leg", pic: "🦵"), Word(text: "six", pic: "6️⃣"), Word(text: "hug", pic: "🤗"),
        Word(text: "tub", pic: "🛁"), Word(text: "pin", pic: "📌"), Word(text: "nut", pic: "🥜"), Word(text: "ram", pic: "🐏"),
    ]

    static let digraphs = ["sh", "ch", "th", "wh"]
    static let digraphWords: [Word] = [
        Word(text: "ship", pic: "🚢"), Word(text: "shell", pic: "🐚"), Word(text: "sheep", pic: "🐑"), Word(text: "shoe", pic: "👟"),
        Word(text: "shark", pic: "🦈"), Word(text: "shirt", pic: "👕"),
        Word(text: "chick", pic: "🐤"), Word(text: "cheese", pic: "🧀"), Word(text: "chair", pic: "🪑"), Word(text: "cherry", pic: "🍒"),
        Word(text: "chain", pic: "⛓️"),
        Word(text: "thumb", pic: "👍"), Word(text: "three", pic: "3️⃣"), Word(text: "thread", pic: "🧵"),
        Word(text: "whale", pic: "🐳"), Word(text: "wheel", pic: "🛞"),
    ]

    /// Rhyme families: words that share an ending.
    static let families: [(ending: String, words: [Word])] = [
        ("at", [Word(text: "cat", pic: "🐱"), Word(text: "hat", pic: "🎩"), Word(text: "bat", pic: "🦇"), Word(text: "rat", pic: "🐀")]),
        ("og", [Word(text: "dog", pic: "🐶"), Word(text: "log", pic: "🪵"), Word(text: "frog", pic: "🐸")]),
        ("ug", [Word(text: "bug", pic: "🐛"), Word(text: "mug", pic: "☕"), Word(text: "hug", pic: "🤗")]),
        ("an", [Word(text: "van", pic: "🚐"), Word(text: "fan", pic: "🪭"), Word(text: "can", pic: "🥫"), Word(text: "pan", pic: "🍳")]),
        ("en", [Word(text: "hen", pic: "🐔"), Word(text: "pen", pic: "🖊️"), Word(text: "ten", pic: "🔟")]),
        ("ox", [Word(text: "box", pic: "📦"), Word(text: "fox", pic: "🦊")]),
        ("ake", [Word(text: "cake", pic: "🎂"), Word(text: "snake", pic: "🐍")]),
        ("ing", [Word(text: "king", pic: "🤴"), Word(text: "ring", pic: "💍")]),
        ("ee", [Word(text: "bee", pic: "🐝"), Word(text: "tree", pic: "🌳"), Word(text: "three", pic: "3️⃣")]),
        ("ar", [Word(text: "car", pic: "🚗"), Word(text: "star", pic: "⭐"), Word(text: "jar", pic: "🫙")]),
        ("oat", [Word(text: "boat", pic: "⛵"), Word(text: "goat", pic: "🐐"), Word(text: "coat", pic: "🧥")]),
        ("ell", [Word(text: "shell", pic: "🐚"), Word(text: "bell", pic: "🔔")]),
        ("ock", [Word(text: "clock", pic: "🕐"), Word(text: "sock", pic: "🧦"), Word(text: "rock", pic: "🪨")]),
        ("ain", [Word(text: "train", pic: "🚆"), Word(text: "rain", pic: "🌧️"), Word(text: "chain", pic: "⛓️")]),
        ("ish", [Word(text: "fish", pic: "🐟"), Word(text: "dish", pic: "🍽️")]),
        ("ed", [Word(text: "bed", pic: "🛏️"), Word(text: "sled", pic: "🛷")]),
        ("ap", [Word(text: "cap", pic: "🧢"), Word(text: "map", pic: "🗺️")]),
    ]

    /// Words read at a glance (Dolch-style), the earliest ones first.
    static let sight = ["the", "a", "and", "to", "said", "you", "he", "she", "it", "in", "is", "was", "of", "my",
                        "are", "they", "have", "what", "there", "where", "come", "look", "see", "here", "one", "two",
                        "want", "like", "we", "me", "go", "no", "so", "do", "for", "from", "this", "that", "with", "then"]

    /// Words that sound the same; never offered side by side when the kid is listening.
    static let homophones: [Set<String>] = [["to", "two", "too"], ["there", "their", "they're"], ["one", "won"],
                                            ["no", "know"], ["see", "sea"], ["for", "four"], ["here", "hear"]]

    static func soundsSame(_ a: String, _ b: String) -> Bool {
        a == b || homophones.contains { $0.contains(a) && $0.contains(b) }
    }

    /// Syllables, split for clapping.
    static let syllables: [(Word, [String])] = [
        (Word(text: "cat", pic: "🐱"), ["cat"]), (Word(text: "dog", pic: "🐶"), ["dog"]), (Word(text: "frog", pic: "🐸"), ["frog"]),
        (Word(text: "sun", pic: "☀️"), ["sun"]),
        (Word(text: "apple", pic: "🍎"), ["ap", "ple"]), (Word(text: "pizza", pic: "🍕"), ["piz", "za"]),
        (Word(text: "rabbit", pic: "🐰"), ["rab", "bit"]), (Word(text: "tiger", pic: "🐯"), ["ti", "ger"]),
        (Word(text: "monkey", pic: "🐒"), ["mon", "key"]), (Word(text: "robot", pic: "🤖"), ["ro", "bot"]),
        (Word(text: "rocket", pic: "🚀"), ["rock", "et"]), (Word(text: "pencil", pic: "✏️"), ["pen", "cil"]),
        (Word(text: "banana", pic: "🍌"), ["ba", "na", "na"]), (Word(text: "butterfly", pic: "🦋"), ["but", "ter", "fly"]),
        (Word(text: "dinosaur", pic: "🦕"), ["di", "no", "saur"]), (Word(text: "elephant", pic: "🐘"), ["el", "e", "phant"]),
        (Word(text: "octopus", pic: "🐙"), ["oc", "to", "pus"]), (Word(text: "kangaroo", pic: "🦘"), ["kan", "ga", "roo"]),
        (Word(text: "broccoli", pic: "🥦"), ["broc", "co", "li"]),
        (Word(text: "avocado", pic: "🥑"), ["av", "o", "ca", "do"]), (Word(text: "watermelon", pic: "🍉"), ["wa", "ter", "mel", "on"]),
        (Word(text: "helicopter", pic: "🚁"), ["hel", "i", "cop", "ter"]), (Word(text: "alligator", pic: "🐊"), ["al", "li", "ga", "tor"]),
        (Word(text: "caterpillar", pic: "🐛"), ["cat", "er", "pil", "lar"]),
    ]

    /// Two small words that make a bigger one.
    static let compounds: [(String, String, Word)] = [
        ("sun", "flower", Word(text: "sunflower", pic: "🌻")), ("rain", "bow", Word(text: "rainbow", pic: "🌈")),
        ("snow", "man", Word(text: "snowman", pic: "⛄")), ("cup", "cake", Word(text: "cupcake", pic: "🧁")),
        ("foot", "ball", Word(text: "football", pic: "🏈")), ("pop", "corn", Word(text: "popcorn", pic: "🍿")),
        ("butter", "fly", Word(text: "butterfly", pic: "🦋")), ("lady", "bug", Word(text: "ladybug", pic: "🐞")),
        ("tooth", "brush", Word(text: "toothbrush", pic: "🪥")), ("pan", "cake", Word(text: "pancake", pic: "🥞")),
        ("sail", "boat", Word(text: "sailboat", pic: "⛵")), ("mail", "box", Word(text: "mailbox", pic: "📫")),
        ("jelly", "fish", Word(text: "jellyfish", pic: "🪼")), ("sea", "shell", Word(text: "seashell", pic: "🐚")),
        ("cow", "boy", Word(text: "cowboy", pic: "🤠")), ("rain", "coat", Word(text: "raincoat", pic: "🧥")),
        ("snow", "flake", Word(text: "snowflake", pic: "❄️")), ("star", "fish", Word(text: "starfish", pic: "⭐")),
    ]

    /// Magic e: add an e and the vowel says its name.
    static let magicE: [(String, String)] = [
        ("kit", "kite"), ("cap", "cape"), ("tap", "tape"), ("cub", "cube"), ("pin", "pine"), ("hop", "hope"),
        ("can", "cane"), ("not", "note"), ("tub", "tube"), ("rid", "ride"), ("bit", "bite"), ("mad", "made"),
        ("cut", "cute"), ("rob", "robe"), ("plan", "plane"), ("slid", "slide"), ("glob", "globe"), ("hug", "huge"),
    ]

    /// Sound-alikes: a sentence with a blank, the words that sound alike, the right one, and why.
    static let soundAlikes: [(sentence: String, options: [String], answer: String, why: String, pic: String)] = [
        ("I have ___ dogs.", ["two", "too", "to"], "two", "Two is the number 2.", "🐶🐶"),
        ("Can I come ___?", ["two", "too", "to"], "too", "Too means also.", "🙋"),
        ("We walked ___ the park.", ["two", "too", "to"], "to", "To points where you're going.", "🌳"),
        ("Fish swim in the ___.", ["see", "sea"], "sea", "The sea is the ocean.", "🌊"),
        ("I can ___ the moon.", ["see", "sea"], "see", "See is what your eyes do.", "🌙"),
        ("Look over ___!", ["there", "their"], "there", "There is a place: here and there.", "👉"),
        ("The kids lost ___ ball.", ["there", "their"], "their", "Their means it belongs to them.", "⚽"),
        ("I ___ a cake.", ["ate", "eight"], "ate", "Ate means you had food.", "🎂"),
        ("A spider has ___ legs.", ["ate", "eight"], "eight", "Eight is the number 8.", "🕷️"),
        ("I ___ the race!", ["won", "one"], "won", "Won means you came first.", "🏆"),
        ("I have ___ nose.", ["won", "one"], "one", "One is the number 1.", "👃"),
        ("I can ___ the bell.", ["hear", "here"], "hear", "Hear is what ears do, and it has an ear in it!", "🔔"),
        ("Come over ___.", ["hear", "here"], "here", "Here is this place.", "📍"),
        ("The ___ is hot.", ["sun", "son"], "sun", "The sun is in the sky.", "☀️"),
    ]

    /// Story tiles: who, did, what, where.
    static let storyWho: [Word] = [Word(text: "the dog", pic: "🐶"), Word(text: "a cat", pic: "🐱"), Word(text: "the robot", pic: "🤖"),
                                   Word(text: "a dinosaur", pic: "🦖"), Word(text: "the king", pic: "🤴"), Word(text: "a monster", pic: "👾"),
                                   Word(text: "my friend", pic: "🧒"), Word(text: "the frog", pic: "🐸")]
    static let storyDid: [Word] = [Word(text: "ate", pic: "😋"), Word(text: "saw", pic: "👀"), Word(text: "hugged", pic: "🤗"),
                                   Word(text: "chased", pic: "🏃"), Word(text: "painted", pic: "🎨"), Word(text: "found", pic: "🔍"),
                                   Word(text: "kicked", pic: "🦵"), Word(text: "sat on", pic: "🪑")]
    static let storyWhat: [Word] = [Word(text: "a pizza", pic: "🍕"), Word(text: "the moon", pic: "🌙"), Word(text: "a cake", pic: "🎂"),
                                    Word(text: "a balloon", pic: "🎈"), Word(text: "a book", pic: "📚"), Word(text: "a banana", pic: "🍌"),
                                    Word(text: "the bus", pic: "🚌"), Word(text: "a sock", pic: "🧦")]
    static let storyWhere: [Word] = [Word(text: "in the park", pic: "🌳"), Word(text: "at school", pic: "🏫"), Word(text: "under the bed", pic: "🛏️"),
                                     Word(text: "in space", pic: "🚀"), Word(text: "at the beach", pic: "🏖️"), Word(text: "in the bath", pic: "🛁"),
                                     Word(text: "on a boat", pic: "⛵"), Word(text: "in the snow", pic: "❄️")]
}
