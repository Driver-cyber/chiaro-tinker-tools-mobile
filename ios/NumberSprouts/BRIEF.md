# Kids Math app: build brief for the Mac session

*From Cowork, for Claude Code on the Mac. Chad approved the direction. Build it
on a new branch (`kids-math-v1`), never on main, the same way we did Primes.*

## What we're making

A small, offline, ad-free iPhone flash-card game for Chad's kids, ages 6–8
(1st–2nd grade). Same bones as **Primes** (one question at a time, answer it,
see the trick that cracks it) but simpler concepts, bigger and friendlier
visuals, and real animation. One of the kids has a feel for number patterns, so
every deck needs a **Stretch** level that runs ahead of grade level.

**Feel:** playful and calm. It celebrates, but it doesn't nag. No timers by
default, no streak guilt, no lost lives. A wrong answer is a chance to see the
trick. Play a round, get a sticker, put it down.

## Hard constraints

- **Fully offline.** No network calls, no analytics, no accounts, no links out.
- **No ads, no in-app purchases.**
- **Family install only for now.** Run it on the kids' iPhone 12/13 from Xcode or
  TestFlight internal testing. No App Store submission, so no Kids Category work
  yet. Even so, keep it clean enough to ship later: no web views, no external
  links, nothing collected.
- **Target:** iPhone, portrait, iOS 17+ (both phones can run it). SwiftUI only,
  built-in fonts and SF Symbols, nothing to license.
- **New project** in this repo at `ios/<AppName>/` with its own bundle ID
  `com.chiarotinkertools.<appname>`. Don't modify Primes.

## Reuse from Primes (copy, then simplify)

| Primes piece | Becomes |
|---|---|
| `Engine.swift` (pure logic, tiers, tricks, worked explanation) | One engine per deck: makes a question, checks it, explains it |
| `Game.swift` (ObservableObject, round state, `Haptics`) | Same shape: a round of 10 cards, score as stars, haptics on right and wrong |
| `Theme.swift` (palettes, button styles) | One bright, kid-friendly palette with light and dark, rounded heavy type, big buttons |
| `AnswerView` / `MathBox` ("here's how") | The **Trick card** shown after every answer, with a visual instead of a paragraph |
| `FoundView` (primes light up) | A **sticker book**: earn a sticker per finished round, one sticker set per deck |
| `Sheets` / `ToolFan` | Drop for v1. Tricks show up inline instead. |

## v1 decks (four)

Each deck has three levels, **Sprout → Grow → Stretch**. A round is 10 cards.

1. **Even or Odd**: *drag and drop.* A number (or a group of dots) appears, and
   the kid drags it into the **Even** or **Odd** basket.
   Trick visual: the dots pair up, and if one is left over it's odd. Stretch
   adds 2- and 3-digit numbers with "just look at the last digit."
2. **Bigger or Smaller**: *tap the alligator side.* Two numbers. The kid taps the
   bigger one, and the alligator mouth (built from shapes, no mascot artwork)
   chomps toward it and the `>` or `<` sign snaps in.
   Trick visual: compare the tens first, using place-value blocks. Sprout is
   up to 20, Grow up to 100, and Stretch up to 1,000, including look-alikes
   like 68 vs 86.
3. **Add & Subtract**: *4-choice multiple choice.* Sprout is within 10, Grow
   within 20, and Stretch is two-digit numbers without regrouping, plus missing
   numbers (`7 + ? = 12`).
   Tricks: **make 10** (shown in a ten-frame: 8 + 5 → 8 + 2 + 3),
   **doubles and near-doubles** (6 + 7 = 6 + 6 + 1), **count up to subtract**
   (number-line hops).
4. **Times Tables**: *4-choice multiple choice.* Sprout is ×2, ×5 and ×10
   (skip counting), Grow adds ×3, ×4 and ×9, and Stretch covers all 1–10 plus
   "what times what?"
   Tricks: **×10 adds a zero**, **×5 ends in 0 or 5**, **×9 digits add to 9 and
   the finger trick**, **×4 = double, double**. The visual is an array of dots
   that fills in row by row.

**Wrong answers for multiple choice** should be plausible, never random:
off by one, off by ten, the wrong operation (added instead of subtracted), or
the neighboring times-table fact. No duplicates, and never negative.

## The card loop

1. A card flies in (spring animation). The number pops in with a slight bounce.
2. The kid answers by dragging, tapping, or picking one of 4 choices.
3. **Right:** green glow, a happy haptic, a quick confetti or star burst, and a
   counter ticks up.
   **Wrong:** a gentle shake and a soft haptic. The right answer is shown, then
   the Trick card opens (always, for a miss), and the kid gets one retry.
4. **Trick card:** one short sentence and an animated visual (dots pairing,
   ten-frame filling, blocks lining up, number-line hops). Tapping "Got it" goes
   to the next card.
5. End of round: stars (1–3), the new sticker drops into the sticker book, and
   two buttons: Play again or Done.

## Kid-friendliness

- Tap targets at least 64 pt, large rounded type, high contrast.
- **Read aloud:** a speaker button reads the question with
  `AVSpeechSynthesizer`. It works offline and helps the younger or new reader.
- Every deck icon and button pairs a picture with its word.
- Respect Reduce Motion: swap the bigger animations for fades.

## Parent area (curation)

- Hidden behind a **press-and-hold for 3 seconds** on a small gear. Don't use a
  math question as the gate. These kids will solve it.
- Toggles: which decks are on, the level for each deck (or "auto": move up
  after two 3-star rounds), number ranges, read-aloud on or off, sound on or off.
- Store everything in UserDefaults/`@AppStorage` (or a small Codable file).
  Nothing leaves the phone.

## Kid profiles (Chad's requirement)

- **One profile per kid.** The app opens on a "Who's playing?" screen with big
  tiles showing each kid's emoji or icon and name. One tap starts.
- **Each profile keeps its own** deck levels, stars, sticker book and parent
  settings, so the kids' progress never mixes.
- **Editing profiles** is in the parent area: add, edit, reorder, delete (delete
  asks for confirmation). A profile is just:
  - **Name** (text field)
  - **Emoji or icon** (a picker grid of about 30 kid-friendly emoji such as
    🦊🐢🦖🚀⚽🦄🐙🌟, plus a handful of SF Symbols, and a tile color)
- First launch with no profiles goes straight to "Add a player."
- In the game, a small corner badge shows who's playing. Tap it to switch
  players (no gate needed).

## Milestones (report each one to Chad)

1. **M1:** project skeleton, theme, **kid profiles** (Who's playing? screen,
   with add and edit for name and emoji), and the **Even or Odd** deck playable end to
   end on the simulator (drag, feedback, trick card, round summary). Send Chad
   a screen recording.
2. **M2:** Bigger or Smaller, Add & Subtract, and Times Tables decks.
3. **M3:** sticker book, parent area (including profile reorder and delete).
4. **M4:** install on the kids' iPhone (Xcode direct or TestFlight internal).
   Chad watches them play, and we tune from there.

Unit-test every engine: answers are correct, distractors are valid and
unique, levels stay in range.

## Open questions for Chad

- **Name?** Placeholders until he picks: *Number Sprouts*, *Math Pockets*,
  *Tricky Tiles*.
- Sound effects on by default, or haptics only?
