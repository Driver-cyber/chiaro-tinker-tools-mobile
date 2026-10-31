//  LingoSproutsTests.swift — the word bank is sound, every deck's answers are
//  right and its choices fair, a round's rules hold, stories read well, and
//  profiles keep their own progress.

import XCTest
@testable import LingoSprouts

final class WordBankTests: XCTestCase {
    func testWordBankIsSound() {
        for w in Words.cvc {
            XCTAssertEqual(w.text.count, 3, w.text)
            XCTAssertTrue("aeiou".contains(w.text[w.text.index(after: w.text.startIndex)]), "\(w.text) has a short vowel in the middle")
        }
        XCTAssertEqual(Set(Words.cvc.map(\.text)).count, Words.cvc.count, "no repeats")
        XCTAssertEqual(Set(Words.cvc.map(\.pic)).count, Words.cvc.count, "every picture is different")
        for w in Words.digraphWords { XCTAssertTrue(Words.digraphs.contains(String(w.text.prefix(2))), w.text) }
        for f in Words.families {
            XCTAssertGreaterThanOrEqual(f.words.count, 2, f.ending)
            for w in f.words { XCTAssertTrue(w.text.hasSuffix(f.ending), "\(w.text) is in -\(f.ending)") }
        }
        for (w, parts) in Words.syllables { XCTAssertEqual(parts.joined(), w.text); XCTAssertTrue((1...4).contains(parts.count)) }
        for (a, b, w) in Words.compounds { XCTAssertEqual(a + b, w.text) }
        for (base, word) in Words.magicE { XCTAssertEqual(base + "e", word) }
        for s in Words.soundAlikes {
            XCTAssertTrue(s.sentence.contains("___")); XCTAssertTrue(s.options.contains(s.answer))
            for o in s.options { XCTAssertTrue(Words.soundsSame(o, s.answer), "\(o) sounds like \(s.answer)") }
        }
        XCTAssertTrue(Words.soundsSame("to", "two")); XCTAssertFalse(Words.soundsSame("the", "they"))
    }
}

final class DeckTests: XCTestCase {
    private func options(_ c: Card) -> [String] {
        if case .choice(_, _, let o, _) = c.face { return o }
        return []
    }

    func testEveryCardModeDealsTenFairCards() {
        for mode in Modes.all {
            guard case .cards(let deal) = mode.play else { continue }
            for _ in 0..<60 {
                let cards = deal()
                XCTAssertEqual(cards.count, 10, mode.id)
                for k in 1..<cards.count { XCTAssertNotEqual(cards[k].trick.headline, cards[k - 1].trick.headline, "\(mode.id): no repeat in a row") }
                for c in cards {
                    XCTAssertFalse(c.trick.sentence.isEmpty)
                    if case .choice(_, _, let o, _) = c.face {
                        XCTAssertGreaterThanOrEqual(o.count, 2, mode.id); XCTAssertEqual(Set(o).count, o.count, "\(mode.id) unique: \(o)")
                        XCTAssertTrue(o.indices.contains(c.answer), mode.id)
                    }
                }
            }
        }
    }

    func testSounds() {
        var g = SeededGenerator(seed: 1)
        for _ in 0..<300 {
            let f = Sounds.card(.first, using: &g)
            if case .letters(let word, _, _) = f.trick.visual { XCTAssertEqual(options(f)[f.answer], String(word.prefix(1))) }
            let l = Sounds.card(.last, using: &g)
            if case .letters(let word, _, _) = l.trick.visual { XCTAssertEqual(options(l)[l.answer], String(word.suffix(1))) }
            let b = Sounds.card(.blend, using: &g)
            if case .blend(_, let word, let pic) = b.trick.visual {
                XCTAssertEqual(options(b)[b.answer], pic)
                XCTAssertEqual(options(b).filter { o in Words.cvc.contains { $0.pic == o && $0.text == word } }.count, 1, "only one picture is the word")
            }
            let d = Sounds.card(.digraph, using: &g)
            if case .letters(let word, _, _) = d.trick.visual { XCTAssertEqual(options(d)[d.answer], String(word.prefix(2))) }
        }
    }

    func testRhymes() {
        var g = SeededGenerator(seed: 2)
        for _ in 0..<300 {
            let y = Rhymes.card(.yesNo, using: &g)
            if case .rhyme(let ws, _) = y.trick.visual {
                let same = Rhymes.ending(of: ws[0]) == Rhymes.ending(of: ws[1])
                XCTAssertEqual(y.answer, same ? 0 : 1, "\(ws.map(\.text))")
            }
            let f = Rhymes.card(.find, using: &g)
            if case .rhyme(_, let ending) = f.trick.visual {
                for (i, o) in options(f).enumerated() {
                    let text = String(o.split(separator: " ").last!)
                    let w = Words.families.flatMap(\.words).first { $0.text == text }!
                    XCTAssertEqual(Rhymes.ending(of: w) == ending, i == f.answer, "\(o) vs -\(ending)")
                }
            }
            let fam = Rhymes.card(.family, using: &g)
            if case .choice(_, let prompt, let o, _) = fam.face {
                XCTAssertTrue(fam.trick.headline.hasSuffix("= " + o[fam.answer] + prompt.dropFirst()), fam.trick.headline)
            }
        }
    }

    func testReading() {
        var g = SeededGenerator(seed: 3)
        for _ in 0..<300 {
            let s = Reading.card(.sight, using: &g)
            XCTAssertEqual(options(s)[s.answer], s.speech)
            for (i, o) in options(s).enumerated() where i != s.answer {
                XCTAssertFalse(Words.soundsSame(o, s.speech), "never a sound-alike when listening: \(o) / \(s.speech)")
            }
            let m = Reading.card(.missing, using: &g)
            if case .letters(let word, _, _) = m.trick.visual {
                XCTAssertEqual(options(m)[m.answer], String(word[word.index(after: word.startIndex)]))
            }
            let sp = Reading.card(.spell, using: &g)
            if case .spell(_, let word, let tiles) = sp.face {
                var pool = tiles
                for ch in word { XCTAssertNotNil(pool.firstIndex(of: String(ch)), "tiles can spell \(word)"); pool.remove(at: pool.firstIndex(of: String(ch))!) }
                XCTAssertEqual(tiles.count, word.count + 2)
            }
        }
    }

    func testWordTricks() {
        var g = SeededGenerator(seed: 4)
        for _ in 0..<300 {
            let c = WordTricks.card(.clap, using: &g)
            if case .syllables(let parts, _) = c.trick.visual { XCTAssertEqual(options(c)[c.answer], String(parts.count)) }
            let k = WordTricks.card(.compound, using: &g)
            if case .compound(_, _, let w) = k.trick.visual { XCTAssertEqual(options(k)[k.answer], w.text) }
            let m = WordTricks.card(.magicE, using: &g)
            if case .magicE(let base, let word) = m.trick.visual { XCTAssertEqual(options(m)[m.answer], word); XCTAssertTrue(options(m).contains(base)) }
            let a = WordTricks.card(.soundAlike, using: &g)
            if case .sentence(_, let word, _) = a.trick.visual { XCTAssertEqual(options(a)[a.answer], word) }
        }
    }
}

final class RoundTests: XCTestCase {
    private func card(_ answer: Int) -> Card {
        Card(face: .choice(picture: "", prompt: "q\(answer)", options: ["a", "b"], listen: false), answer: answer, speech: "",
             trick: Trick(headline: "h\(answer)", sentence: "s", visual: .letters(word: "a", picture: "", lit: [])))
    }

    func testAMissShowsTheTrickThenOneRetry() {
        let r = Round(modeID: "t", cards: [card(0), card(1)])
        XCTAssertFalse(r.answer(1)); XCTAssertEqual(r.phase, .missed)
        r.gotIt(); XCTAssertEqual(r.phase, .retrying)
        XCTAssertTrue(r.answer(0)); XCTAssertEqual(r.firstTry, 0)
        r.advance(); XCTAssertEqual(r.index, 1)
        XCTAssertFalse(r.answer(-1), "a wrong spelling"); XCTAssertTrue(r.wrongPicks.isEmpty)
        r.gotIt(); r.answer(-1); r.gotIt()
        XCTAssertEqual(r.phase, .done)
    }

    func testStars() {
        XCTAssertEqual(Round.stars(firstTry: 9, of: 10), 3)
        XCTAssertEqual(Round.stars(firstTry: 6, of: 10), 2)
        XCTAssertEqual(Round.stars(firstTry: 0, of: 10), 1)
    }
}

final class StoryTests: XCTestCase {
    func testSentencesReadWell() {
        let parts = [Words.storyWho[0], Words.storyDid[0], Words.storyWhat[0], Words.storyWhere[0]]
        XCTAssertEqual(StoryParts.sentence(parts), "The dog ate a pizza in the park.")
        let saved = StoryParts.saved(parts)
        XCTAssertEqual(StoryParts.split(saved).sentence, "The dog ate a pizza in the park.")
        XCTAssertEqual(StoryParts.split(saved).pics, "🐶😋🍕🌳")
        for r in StoryParts.rows { XCTAssertGreaterThanOrEqual(r.tiles.count, 4, r.title) }
    }
}

final class ProfileTests: XCTestCase {
    private func freshStore() -> UserDefaults {
        let name = "LSTests-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    func testStoriesAndSettingsPersistPerPlayer() {
        let store = freshStore()
        let m = AppModel(store: store)
        XCTAssertFalse(m.readAloud, "read aloud starts off")
        m.save(Profile(name: "Ada", icon: "🦊")); m.save(Profile(name: "Ben", icon: "🦖"))
        m.choose(m.profiles[0])
        m.saveStory("🐶\tThe dog ate a cake.")
        m.saveStory("🐱\tA cat saw the moon.")
        m.saveStory("🐶\tThe dog ate a cake.")
        m.recordRound(mode: "so.first", stars: 3)
        m.readAloud = true
        let again = AppModel(store: store)
        XCTAssertEqual(again.profiles[0].stories, ["🐱\tA cat saw the moon.", "🐶\tThe dog ate a cake."], "no duplicates, newest last")
        XCTAssertEqual(again.profiles[0].stars["so.first"], 3)
        XCTAssertTrue(again.profiles[1].stories.isEmpty, "progress never mixes")
        XCTAssertTrue(again.readAloud)
    }
}
