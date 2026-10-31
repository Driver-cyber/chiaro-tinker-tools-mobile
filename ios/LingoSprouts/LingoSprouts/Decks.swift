//  Decks.swift — the card engines for Sounds, Rhymes, Words and Word tricks.
//
//  Pictures can be named more than one way (☕ mug or cup?), so sound cards
//  show the rest of the word, "?og" under 🪵, and the kid finds the missing
//  sound. Wrong choices are close on purpose: other first letters, other rhyme
//  families, sight words that look alike (but never one that sounds the same).

import Foundation

enum Sounds {
    enum Kind { case first, last, blend, digraph }

    static func card<G: RandomNumberGenerator>(_ k: Kind, using rng: inout G) -> Card {
        switch k {
        case .first:
            let w = Words.cvc.randomElement(using: &rng)!
            let letter = String(w.text.prefix(1))
            let others = Set(Words.cvc.map { String($0.text.prefix(1)) }).subtracting([letter]).shuffled(using: &rng)
            let (opts, at) = Dealer.choices(answer: letter, near: others, using: &rng)
            return Card(face: .choice(picture: w.pic, prompt: "?" + w.text.dropFirst(), options: opts, listen: false), answer: at,
                        speech: "\(w.text). What sound does \(w.text) start with?",
                        trick: Trick(headline: "\(w.text) starts with \(letter)",
                                     sentence: "Say it slowly: \(letter), \(letter), \(w.text). The first sound is \(letter).",
                                     visual: .letters(word: w.text, picture: w.pic, lit: [0])))
        case .last:
            let w = Words.cvc.randomElement(using: &rng)!
            let letter = String(w.text.suffix(1))
            let others = Set(Words.cvc.map { String($0.text.suffix(1)) }).subtracting([letter]).shuffled(using: &rng)
            let (opts, at) = Dealer.choices(answer: letter, near: others, using: &rng)
            return Card(face: .choice(picture: w.pic, prompt: w.text.dropLast() + "?", options: opts, listen: false), answer: at,
                        speech: "\(w.text). What sound does \(w.text) end with?",
                        trick: Trick(headline: "\(w.text) ends with \(letter)",
                                     sentence: "Stretch it out: \(w.text.map(String.init).joined(separator: "-")). The last sound is \(letter).",
                                     visual: .letters(word: w.text, picture: w.pic, lit: [w.text.count - 1])))
        case .blend:
            let w = Words.cvc.randomElement(using: &rng)!
            let ending = String(w.text.suffix(2)), start = String(w.text.prefix(2))
            let near = Words.cvc.filter { $0 != w && ($0.text.hasSuffix(ending) || $0.text.hasPrefix(start)) }.shuffled(using: &rng)
                     + Words.cvc.filter { $0 != w }.shuffled(using: &rng)
            let (opts, at) = Dealer.choices(answer: w.pic, near: near.map(\.pic).filter { $0 != w.pic }, using: &rng)
            let letters = w.text.map(String.init)
            return Card(face: .choice(picture: "", prompt: letters.joined(separator: " · "), options: opts, listen: false), answer: at,
                        speech: letters.joined(separator: ", "),
                        trick: Trick(headline: letters.joined(separator: " + ") + " = \(w.text)",
                                     sentence: "Say each sound, then push them together faster and faster: \(w.text)!",
                                     visual: .blend(letters: letters, word: w.text, picture: w.pic)))
        case .digraph:
            let w = Words.digraphWords.randomElement(using: &rng)!
            let d = String(w.text.prefix(2))
            let at = Words.digraphs.firstIndex(of: d)!
            return Card(face: .choice(picture: w.pic, prompt: "??" + w.text.dropFirst(2), options: Words.digraphs, listen: false), answer: at,
                        speech: "\(w.text). Which two letters start \(w.text)?",
                        trick: Trick(headline: "\(w.text) starts with \(d)",
                                     sentence: "Two letters, one sound: \(d) in \(w.text).",
                                     visual: .letters(word: w.text, picture: w.pic, lit: [0, 1])))
        }
    }

    static func round<G: RandomNumberGenerator>(_ k: Kind, using rng: inout G) -> [Card] {
        Dealer.round(using: &rng) { g in card(k, using: &g) }
    }
}

enum Rhymes {
    enum Kind { case yesNo, find, family }

    /// The family a word belongs to, if any.
    static func ending(of w: Word) -> String? { Words.families.first { $0.words.contains(w) }?.ending }

    static func card<G: RandomNumberGenerator>(_ k: Kind, using rng: inout G) -> Card {
        let fam = Words.families.filter { $0.words.count >= 2 }.randomElement(using: &rng)!
        let pair = fam.words.shuffled(using: &rng)
        let a = pair[0]
        switch k {
        case .yesNo:
            let rhymes = Bool.random(using: &rng)
            let other = Words.families.filter { $0.ending != fam.ending }.randomElement(using: &rng)!
            let b = rhymes ? pair[1] : other.words.randomElement(using: &rng)!
            let s = rhymes ? "\(a.text) and \(b.text) both end in -\(fam.ending). Same ending, so they rhyme!"
                           : "\(a.text) ends in -\(fam.ending), but \(b.text) ends in -\(other.ending). No rhyme."
            return Card(face: .choice(picture: a.pic + "  " + b.pic, prompt: "\(a.text) · \(b.text)", options: ["Rhyme 👍", "No rhyme 👎"], listen: false),
                        answer: rhymes ? 0 : 1, speech: "\(a.text), \(b.text). Do they rhyme?",
                        trick: Trick(headline: rhymes ? "\(a.text) and \(b.text) rhyme" : "\(a.text) and \(b.text) don't rhyme",
                                     sentence: s, visual: .rhyme(words: [a, b], ending: rhymes ? fam.ending : "")))
        case .find:
            let right = pair[1]
            let others = Words.families.filter { $0.ending != fam.ending }.flatMap(\.words)
                .filter { ending(of: $0) != fam.ending }.shuffled(using: &rng)
            let (opts, at) = Dealer.choices(answer: "\(right.pic) \(right.text)", near: others.map { "\($0.pic) \($0.text)" }, using: &rng)
            return Card(face: .choice(picture: a.pic, prompt: "rhymes with \(a.text)?", options: opts, listen: false), answer: at,
                        speech: "Which one rhymes with \(a.text)?",
                        trick: Trick(headline: "\(a.text) rhymes with \(right.text)",
                                     sentence: "They share an ending: -\(fam.ending).", visual: .rhyme(words: fam.words, ending: fam.ending)))
        case .family:
            let start = String(a.text.dropLast(fam.ending.count))
            let starts = Words.families.flatMap(\.words).map { String($0.text.dropLast((ending(of: $0) ?? "").count)) }
            let near = fam.words.map { String($0.text.dropLast(fam.ending.count)) } + starts.shuffled(using: &rng) + ["b", "m", "s", "t", "p"]
            let (opts, at) = Dealer.choices(answer: start, near: near.filter { !$0.isEmpty }, using: &rng)
            return Card(face: .choice(picture: a.pic, prompt: "?" + fam.ending, options: opts, listen: false), answer: at,
                        speech: "\(a.text). Which letters make \(a.text)?",
                        trick: Trick(headline: "\(start) + \(fam.ending) = \(a.text)",
                                     sentence: "The -\(fam.ending) family: change the start, keep the ending. " +
                                               fam.words.map(\.text).joined(separator: ", ") + ".",
                                     visual: .rhyme(words: fam.words, ending: fam.ending)))
        }
    }

    static func round<G: RandomNumberGenerator>(_ k: Kind, using rng: inout G) -> [Card] {
        Dealer.round(using: &rng) { g in card(k, using: &g) }
    }
}

enum Reading {
    enum Kind { case sight, missing, spell }

    /// How alike two words look: shared letters in place, shared letters anywhere, similar length.
    static func likeness(_ a: String, _ b: String) -> Int {
        let inPlace = zip(a, b).filter { $0 == $1 }.count
        let shared = Set(a).intersection(Set(b)).count
        return inPlace * 3 + shared * 2 - abs(a.count - b.count)
    }

    static func card<G: RandomNumberGenerator>(_ k: Kind, using rng: inout G) -> Card {
        switch k {
        case .sight:
            let t = Words.sight.randomElement(using: &rng)!
            let near = Words.sight.filter { !Words.soundsSame($0, t) }.shuffled(using: &rng)
                .sorted { likeness($0, t) > likeness($1, t) }
            let (opts, at) = Dealer.choices(answer: t, near: Array(near.prefix(5)).shuffled(using: &rng), using: &rng)
            return Card(face: .choice(picture: "👂", prompt: "Tap 🔊, then find the word", options: opts, listen: true), answer: at,
                        speech: t,
                        trick: Trick(headline: "This is \"\(t)\"",
                                     sentence: "Look at its letters, \(t.map(String.init).joined(separator: "-")), and say it: \(t).",
                                     visual: .letters(word: t, picture: "", lit: Array(0..<t.count))))
        case .missing:
            let w = Words.cvc.randomElement(using: &rng)!
            let vowel = String(w.text[w.text.index(after: w.text.startIndex)])
            let (opts, at) = Dealer.choices(answer: vowel, near: ["a", "e", "i", "o", "u"].shuffled(using: &rng), using: &rng)
            let shown = w.text.prefix(1) + "?" + w.text.suffix(1)
            return Card(face: .choice(picture: w.pic, prompt: String(shown), options: opts, listen: false), answer: at,
                        speech: "\(w.text). Which letter is missing?",
                        trick: Trick(headline: "\(w.text) has \(vowel) in the middle",
                                     sentence: "Stretch it out, \(w.text.map(String.init).joined(separator: "-")), and listen for the middle sound: \(vowel).",
                                     visual: .letters(word: w.text, picture: w.pic, lit: [1])))
        case .spell:
            let w = Words.cvc.randomElement(using: &rng)!
            let letters = w.text.map(String.init)
            let extras = "bcdfghlmnprstuaeio".map(String.init).filter { !letters.contains($0) }.shuffled(using: &rng).prefix(2)
            return Card(face: .spell(picture: w.pic, word: w.text, tiles: (letters + extras).shuffled(using: &rng)), answer: 0,
                        speech: "Spell \(w.text).",
                        trick: Trick(headline: "\(w.text) is spelled \(letters.joined(separator: "-"))",
                                     sentence: "Say it slowly. Each sound gets a letter: \(letters.joined(separator: ", ")).",
                                     visual: .letters(word: w.text, picture: w.pic, lit: Array(0..<letters.count))))
        }
    }

    static func round<G: RandomNumberGenerator>(_ k: Kind, using rng: inout G) -> [Card] {
        Dealer.round(using: &rng) { g in card(k, using: &g) }
    }
}

enum WordTricks {
    enum Kind { case clap, compound, magicE, soundAlike }

    static func card<G: RandomNumberGenerator>(_ k: Kind, using rng: inout G) -> Card {
        switch k {
        case .clap:
            let (w, parts) = Words.syllables.randomElement(using: &rng)!
            let n = parts.count
            return Card(face: .choice(picture: w.pic, prompt: "How many claps in \(w.text)?", options: ["1", "2", "3", "4"], listen: false),
                        answer: n - 1, speech: "\(w.text). How many claps?",
                        trick: Trick(headline: "\(w.text): \(n) \(n == 1 ? "clap" : "claps")",
                                     sentence: "Clap each part: " + parts.joined(separator: " · ") + ".",
                                     visual: .syllables(parts, picture: w.pic)))
        case .compound:
            let (a, b, w) = Words.compounds.randomElement(using: &rng)!
            let sharing = Words.compounds.filter { $0.2 != w && ($0.0 == a || $0.1 == b || $0.0 == b || $0.1 == a) }.map(\.2.text)
            let rest = Words.compounds.map(\.2.text).filter { $0 != w.text }.shuffled(using: &rng)
            let (opts, at) = Dealer.choices(answer: w.text, near: sharing.shuffled(using: &rng) + rest, using: &rng)
            return Card(face: .choice(picture: "", prompt: "\(a) + \(b)", options: opts, listen: false), answer: at,
                        speech: "\(a) plus \(b) makes?",
                        trick: Trick(headline: "\(a) + \(b) = \(w.text)",
                                     sentence: "Two small words make one big word: \(a) and \(b) make \(w.text).",
                                     visual: .compound(a, b, w)))
        case .magicE:
            let (base, word) = Words.magicE.randomElement(using: &rng)!
            let vowel = base.first { "aeiou".contains($0) }.map(String.init) ?? "a"
            let others = Words.magicE.filter { $0.1 != word }.shuffled(using: &rng)
            let near = [base] + others.filter { $0.1.first == word.first }.map(\.1) + others.map(\.1)
            let (opts, at) = Dealer.choices(answer: word, near: near, using: &rng)
            return Card(face: .choice(picture: "", prompt: "\(base) + e", options: opts, listen: false), answer: at,
                        speech: "\(base) plus e makes?",
                        trick: Trick(headline: "\(base) + e = \(word)",
                                     sentence: "The e is magic. It doesn't make a sound, but it makes the \(vowel) say its name: \(base) becomes \(word).",
                                     visual: .magicE(base: base, word: word)))
        case .soundAlike:
            let s = Words.soundAlikes.randomElement(using: &rng)!
            let opts = s.options.shuffled(using: &rng)
            return Card(face: .choice(picture: s.pic, prompt: s.sentence, options: opts, listen: false), answer: opts.firstIndex(of: s.answer)!,
                        speech: s.sentence.replacingOccurrences(of: "___", with: "blank"),
                        trick: Trick(headline: s.sentence.replacingOccurrences(of: "___", with: s.answer), sentence: s.why,
                                     visual: .sentence(s.sentence, word: s.answer, picture: s.pic)))
        }
    }

    static func round<G: RandomNumberGenerator>(_ k: Kind, using rng: inout G) -> [Card] {
        Dealer.round(using: &rng) { g in card(k, using: &g) }
    }
}
