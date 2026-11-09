//  Story.swift — Story mode's script. You start as One, a single dot, and grow
//  a dot at a time into the primes and the numbers they build, then hear them
//  in music, then learn they never run out.
//
//  Each chapter is a run of steps read by scrolling; the picture pinned at the
//  top changes as each step passes. Some steps are gates: a prime-or-composite
//  call like the game's, or a choice. The story waits at a gate until it's
//  passed. Every number on these pages is checked in PrimesTests (StoryTests).

import Foundation

enum DotShape: Equatable { case row, ring, grid(Int, Int) }

enum Stage: Equatable {
    case dots(Int, DotShape)
    case sieve(by: [Int], done: Bool = false)     // 1…30, multiples of these crossed out
    case number(Int)
    case atoms([Int])
    case ratio(Int, Int, String)                  // two strings, a : b, and the interval's name
    case rhythm(Int, Int)                         // a beats against b
}

struct Option: Equatable {
    let text: String
    let reply: String
    var right = true
}

enum Gate: Equatable {
    case call(Int)                                // prime or composite, like the game
    case choose(String, [Option])
}

struct Step: Equatable {
    var text: String
    var stage: Stage
    var math: [String]? = nil
    var gate: Gate? = nil
}

struct Chapter: Identifiable {
    let id: Int
    let title: String
    let blurb: String
    let guide: GuideScreen
    let guideTitle: String
    let steps: [Step]
}

enum Story {
    static let doneKey = "primes.story.done"

    static let chapters: [Chapter] = [
        Chapter(id: 1, title: "One", blurb: "A single dot in the dark.",
                guide: .rectangle, guideTitle: "A prime can't make a rectangle", steps: [
            Step(text: "In the beginning there is one dot of light in the dark. That's you. Your name is One.",
                 stage: .dots(1, .row)),
            Step(text: "One is a strange number. Multiply yourself by yourself and nothing changes. Copying won't help you grow.",
                 stage: .dots(1, .row), math: ["1", "×", "1", "=", "1"]),
            Step(text: "Something else is glowing out there. Another one, drifting closer.",
                 stage: .dots(1, .row),
                 gate: .choose("What do you do?", [
                    Option(text: "Reach for it", reply: "You pull it close. One and one make two."),
                    Option(text: "Wait and watch", reply: "It drifts in anyway and settles beside you. One and one make two."),
                 ])),
            Step(text: "You are Two now. Try lining your dots up in equal rows: one row of two is the only way. Only 1 and 2 divide you.",
                 stage: .dots(2, .row), math: ["1", "+", "1", "=", "2"]),
            Step(text: "That makes you the very first prime: a number only 1 and itself divide. Remember the feeling. Every even number from here on carries a piece of you.",
                 stage: .dots(2, .row)),
        ]),

        Chapter(id: 2, title: "Three and Four", blurb: "The first shape, and the first recipe.",
                guide: .elements, guideTitle: "The atoms of math", steps: [
            Step(text: "Another dot drifts in. You are Three.", stage: .dots(3, .row)),
            Step(text: "You try to arrange yourself.",
                 stage: .dots(3, .row),
                 gate: .choose("Can three dots stand in more than one equal row?", [
                    Option(text: "Yes, two rows", reply: "Two rows would need a dot and a half in each. Dots don't split.", right: false),
                    Option(text: "No, just one row", reply: "Right. Three is 1 × 3 and nothing else."),
                 ])),
            Step(text: "A number that can only stand in one row is prime. When rows won't work, you make a ring. Two and Three: the first two elements.",
                 stage: .dots(3, .ring)),
            Step(text: "Then a fourth dot arrives, and something new happens. The dots click into a square, two rows of two.",
                 stage: .dots(4, .grid(2, 2))),
            Step(text: "So what are you now?", stage: .dots(4, .grid(2, 2)), gate: .call(4)),
            Step(text: "Four is composite: built from smaller primes. You aren't a new element anymore. You're a molecule, made of two Twos.",
                 stage: .dots(4, .grid(2, 2)), math: ["4", "=", "2", "×", "2"]),
            Step(text: "Every composite number has a recipe of primes, and only one. That's why primes are called the atoms of math.",
                 stage: .dots(4, .grid(2, 2))),
        ]),

        Chapter(id: 3, title: "Five to Ten", blurb: "New elements, and the first mixtures.",
                guide: .molecules, guideTitle: "Build a number from atoms", steps: [
            Step(text: "You grow to Five. Two rows leave a dot over. Three or four rows are worse. Five won't make a rectangle any way you turn it.",
                 stage: .dots(5, .ring)),
            Step(text: "Five dots, one ring.", stage: .dots(5, .ring), gate: .call(5)),
            Step(text: "One more dot drifts in.",
                 stage: .dots(5, .ring),
                 gate: .choose("How do you build Six?", [
                    Option(text: "2 × 3", reply: "Two rows of three. Your first recipe that mixes two different primes."),
                    Option(text: "2 × 2 × 2", reply: "Count it: 2 × 2 is 4, and × 2 is 8. Too many.", right: false),
                    Option(text: "3 × 3", reply: "That's 9, a bigger square.", right: false),
                 ])),
            Step(text: "Six is where Two and Three meet. Two rows of three, or three rows of two. Same atoms either way.",
                 stage: .dots(6, .grid(2, 3)), math: ["6", "=", "2", "×", "3"]),
            Step(text: "Seven arrives with no rows at all. Primes get rarer the bigger you grow, but they never stop coming.",
                 stage: .dots(7, .ring)),
            Step(text: "Eight is three Twos stacked up.",
                 stage: .dots(8, .grid(2, 4)), math: ["8", "=", "2", "×", "2", "×", "2"]),
            Step(text: "Nine dots settle into a square.", stage: .dots(9, .grid(3, 3)), gate: .call(9)),
            Step(text: "Nine is Three times Three. And Ten is Two and Five. You haven't needed a new atom since Seven. The ones you have are building everything.",
                 stage: .dots(10, .grid(2, 5)), math: ["10", "=", "2", "×", "5"]),
        ]),

        Chapter(id: 4, title: "The Sieve", blurb: "Sorting a crowd of thirty.",
                guide: .sieve, guideTitle: "Sift them out by hand", steps: [
            Step(text: "Now you can see a whole crowd of numbers, 1 to 30. Some are new elements. The rest are made of old ones. Time to sort them.",
                 stage: .sieve(by: [])),
            Step(text: "Two goes first. Every second number after it has a Two inside. Cross them all out.",
                 stage: .sieve(by: [2])),
            Step(text: "The first number still standing after 2 is the next prime.",
                 stage: .sieve(by: [2]),
                 gate: .choose("Who goes next?", [
                    Option(text: "3", reply: "Three. It crosses out every third number."),
                    Option(text: "4", reply: "4 is already crossed out. It's 2 × 2.", right: false),
                    Option(text: "9", reply: "9 comes later, and it isn't prime: 3 × 3.", right: false),
                 ])),
            Step(text: "Three crosses out every third number. Some, like 6 and 12, were already gone.",
                 stage: .sieve(by: [2, 3])),
            Step(text: "Find the next one still standing.",
                 stage: .sieve(by: [2, 3]),
                 gate: .choose("Next prime?", [
                    Option(text: "5", reply: "Five. Of its multiples, only 25 was still standing."),
                    Option(text: "7", reply: "7 is prime, but 5 is still standing and comes first.", right: false),
                    Option(text: "9", reply: "9 is crossed out. Three got it.", right: false),
                 ])),
            Step(text: "And that's it. Seven would cross out 14, 21 and 28, but they're already gone, and 7 × 7 is 49, past the crowd. Everything still standing is prime.",
                 stage: .sieve(by: [2, 3, 5], done: true),
                 math: ["2", "3", "5", "7", "11", "13", "17", "19", "23", "29"]),
        ]),

        Chapter(id: 5, title: "Disguises", blurb: "Bigger numbers hide their recipes.",
                guide: .roots, guideTitle: "Square roots and tricks", steps: [
            Step(text: "At the edge of the crowd stands 91. It's odd, it doesn't end in 5, its digits add to 10. It looks like a new element.",
                 stage: .number(91)),
            Step(text: "You don't have to try every number. Only primes, and only up to the square root. 9 × 9 is 81 and 10 × 10 is 100, so if 91 has a recipe, it uses 2, 3, 5 or 7.",
                 stage: .number(91), math: ["9", "×", "9", "=", "81"]),
            Step(text: "Test Seven with its trick: chop off the last digit, double it, subtract.",
                 stage: .number(91), gate: .call(91)),
            Step(text: "A disguise. 91 is Seven and Thirteen holding hands.",
                 stage: .number(91), math: ["91", "=", "7", "×", "13"]),
            Step(text: "Next in line: 97. Its square root is under 10 too, so the same four primes decide it.",
                 stage: .number(97), gate: .call(97)),
            Step(text: "That's the whole game in your pocket. Every number up to 999 is a new element or a recipe, and you can tell which by hand.",
                 stage: .number(97)),
        ]),

        Chapter(id: 6, title: "The Music", blurb: "Harmony is primes you can hear.",
                guide: .cicadas, guideTitle: "Nature counts in primes", steps: [
            Step(text: "Out past the crowd, you hear something: a string, humming. Pluck a string half as long and it hums twice as fast. Your ear calls them the same note, an octave apart. That's Two, singing.",
                 stage: .ratio(2, 1, "octave")),
            Step(text: "Now a string two thirds as long. It shakes 3 times for every 2 of the first. Tap play and listen.",
                 stage: .ratio(3, 2, "perfect fifth"),
                 gate: .choose("Which primes are in this sound?", [
                    Option(text: "2 and 3", reply: "The fifth, 3 : 2. After the octave it's the steadiest sound there is. Two and Three, in harmony."),
                    Option(text: "5 only", reply: "Count the shakes: 3 against 2. No Five yet.", right: false),
                    Option(text: "2 and 7", reply: "Not this one. Seven's sound is coming.", right: false),
                 ])),
            Step(text: "Bring in Five and you get 5 : 4, the major third. Stack 4 : 5 : 6 and you have a major chord. Nearly all the harmony you've ever heard is made from three atoms: 2, 3 and 5.",
                 stage: .ratio(5, 4, "major third")),
            Step(text: "Seven makes 7 : 4, the harmonic seventh. A little sour, a little bluesy. Barbershop singers lean toward it to make their chords ring.",
                 stage: .ratio(7, 4, "harmonic seventh")),
            Step(text: "Here's a puzzle as old as Pythagoras. Stack twelve fifths and you should land back where you started, seven octaves up. Twelve fifths is 3¹² over 2¹². Seven octaves is 2⁷.",
                 stage: .atoms([2, 3]),
                 gate: .choose("Can a pile of Threes ever exactly equal a pile of Twos?", [
                    Option(text: "No, never", reply: "Never. 3¹² is 531,441 and 2¹⁹ is 524,288: close, but not equal. Every number has one recipe, so Threes can't turn into Twos. Musicians call the gap the Pythagorean comma."),
                    Option(text: "Yes, if you stack enough", reply: "Stack forever and they still won't meet. Any pile of Threes is odd, and any pile of Twos is even.", right: false),
                 ])),
            Step(text: "So a piano cheats a little. It splits the octave into 12 equal steps, and every fifth comes out a hair flat. And 12? Two Twos and a Three.",
                 stage: .ratio(3, 2, "perfect fifth"), math: ["12", "=", "2", "×", "2", "×", "3"]),
            Step(text: "Primes play in rhythm, too. Clap 3 against 2, and the two beats land together once every 6.",
                 stage: .rhythm(3, 2), math: ["3", "×", "2", "=", "6"]),
            Step(text: "Now 5 against 3.",
                 stage: .rhythm(5, 3),
                 gate: .choose("How often do they land together?", [
                    Option(text: "Every 15", reply: "5 × 3 = 15. Two primes share nothing, so they only meet at their product. Just like the cicadas."),
                    Option(text: "Every 8", reply: "That's 5 + 3. Watch the playhead: they meet when both rows hit at once.", right: false),
                    Option(text: "Every 5", reply: "Five is one row's cycle. The other row isn't back yet.", right: false),
                 ])),
            Step(text: "That's why prime polyrhythms sound so restless. They take the longest possible time to come back together.",
                 stage: .rhythm(5, 3)),
        ]),

        Chapter(id: 7, title: "Forever", blurb: "Do the elements ever run out?",
                guide: .euclid, guideTitle: "They never run out", steps: [
            Step(text: "You've met four elements under ten: 2, 3, 5 and 7. Could that be all of them? Here's a way to find out.",
                 stage: .atoms([2, 3, 5, 7])),
            Step(text: "Multiply them all together, then add one.",
                 stage: .atoms([2, 3, 5, 7]), math: ["2", "×", "3", "×", "5", "×", "7", "+", "1"],
                 gate: .choose("What do you get?", [
                    Option(text: "211", reply: "2 × 3 × 5 × 7 is 210. Add 1 and you get 211."),
                    Option(text: "210", reply: "That's the product. Don't forget the + 1.", right: false),
                    Option(text: "18", reply: "That's adding them: 2 + 3 + 5 + 7 + 1. Multiply instead.", right: false),
                 ])),
            Step(text: "Divide 211 by 2, 3, 5 or 7 and every one leaves a remainder of 1. None of your elements are in its recipe.",
                 stage: .number(211)),
            Step(text: "So is 211 a new element, or made of ones you haven't met?",
                 stage: .number(211), gate: .call(211)),
            Step(text: "A new prime, missing from your list. Euclid saw this about 2,300 years ago: take any list of primes, multiply, add one, and something new turns up. The elements never run out.",
                 stage: .number(211)),
            Step(text: "And you? You were One: not prime, not composite, the dot everything grew from. Every number since is a story told in primes. Now you can read them.",
                 stage: .dots(1, .row)),
        ]),
    ]
}

extension GuideScreen: Identifiable {
    var id: Int { rawValue }
}
