# Lingo Sprouts — letters, sounds and words for Chad's kids

Number Sprouts' sibling for reading and language, for the same kids (ages
6–8). One card at a time, every miss shows the trick, and a story builder for
making something. Built on Number Sprouts' bones (profiles, card loop, trick
card, theme).

* **Bundle ID:** `com.chiarotinkertools.lingosprouts` · iPhone, portrait · iOS 17+
* **Family install only for now.** Nothing leaves the phone: profiles, stars
  and stories live in UserDefaults. No network, ads, analytics or links out.
* **Read aloud, politely:** the 🔊 button reads any card. A grown-up can turn
  on "Read aloud" (the speaker on the home screen) so cards read themselves.
  It's off by default. Speech *ducks* other audio instead of pausing it, and
  gives the volume back when done (Number Sprouts' speech paused Chad's music).
* **Letter sounds are taught through words** ("d, d, dog"): the built-in voice
  says letter *names*, not isolated sounds. Recorded phonics audio would be a
  later step.

## Concepts and modes

| Concept | Modes |
|---|---|
| Sounds | First sound (🐶 ?og) · Last sound · Blend it (c · a · t → 🐱) · sh ch th wh |
| Rhymes | Does it rhyme? · Find the rhyme · Word families (?at) |
| Words | Hear and find (sight words) · Missing letter (c?t) · Spell it (letter tiles) |
| Word tricks | Clap it (syllables) · Put it together (compounds) · Magic e · Sound-alikes |
| Story | Build a story (Who / Did / What / Where; read aloud word by word) · My story book |

## Layout

| Path | What |
|---|---|
| `LingoSprouts/Words.swift` | the word bank, every word with an emoji picture |
| `LingoSprouts/Decks.swift` | the card engines for Sounds, Rhymes, Words, Word tricks |
| `LingoSprouts/Modes.swift` | every concept and its modes |
| `LingoSprouts/Round.swift` | the Card, one round of ten, choices, haptics |
| `LingoSprouts/PlayView.swift` | the card loop: choices and spelling tiles |
| `LingoSprouts/TrickCard.swift` | the Trick card and its word visuals, and the round summary |
| `LingoSprouts/Story.swift` | the story builder and story book |
| `LingoSprouts/Speech.swift` | read-aloud that ducks music and reports each spoken word |
| `LingoSprouts/Profiles.swift`, `WhoView.swift`, `HomeView.swift`, `Theme.swift` | shared with Number Sprouts |
| `LingoSproutsTests/` | word bank, deck, round, story and profile tests |
| `tools/make-icon.swift` | draws the icon (a purple "a" with the sprout floating above) |
