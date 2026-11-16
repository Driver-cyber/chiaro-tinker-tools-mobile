# Number Sprouts — math flash cards for Chad's kids

A small, offline, ad-free iPhone game for ages 6–8. One card at a time; answer
it; every miss shows the trick that cracks it. Built from `BRIEF.md` (Cowork's
brief, approved by Chad), with Primes as its bones.

* **Bundle ID:** `com.chiarotinkertools.numbersprouts` · iPhone, portrait · iOS 17+
* **Family install only for now** (Xcode or TestFlight internal). No App Store.
* **Nothing leaves the phone:** profiles and stars live in UserDefaults. No
  network, no ads, no analytics, no links out. **Silent:** haptics only, with no
  read-aloud and no sounds (Chad, after playing: speech paused his music).

## Structure (changed from the brief, by Chad)

The home screen picks a **concept** at the top (Even or Odd, Bigger or Smaller,
Add & Subtract, Times Tables), then a **mode named by its skill**, each with its
own stars, instead of one Easy-to-Hard slider. A kid who has a skill down goes
straight to the next one rather than wading through random easy cards. Under
the hood the modes still map to the brief's Sprout → Grow → Stretch.

| Even or Odd mode | Level | Cards |
|---|---|---|
| Pair the dots | Sprout | 1–10, dots on the card |
| Numbers to 20 | Grow | 1–20, the numeral only |
| Last digit | Stretch | 10–999; past 20 the trick is "look at the last digit" |

## Make It True

A few numbers; put them in order with signs between until the math is true
(1, 1, 2 → 1 + 1 = 2, or 2 − 1 = 1). Every true order counts as a way, so
3 × 5 = 15 and 15 ÷ 3 = 5 are both found; the same way with its sides swapped
is not a new one. A star for each new way.

| Level | Numbers | Signs |
|---|---|---|
| Easy | three single digits | + − |
| Medium | adds one double digit | + − × ÷ |
| Hard | four numbers: 2 × 4 + 3 = 11, or 2 + 6 = 5 + 3 | + − × ÷, × and ÷ first |

Three ways to see the same puzzle, switchable at any time: **Tiles** (drag
numbers and signs, = included, into a strip), **Scale** (= means both pans weigh
the same; the beam tips as you go) and **Machine** (pick what should come out,
turn the dials, pull the lever). Every Hard puzzle has a three-and-one way, so
the Machine can always solve it.

## Layout

| Path | What |
|---|---|
| `NumberSprouts/Modes.swift` | every concept and its modes, in one list |
| `NumberSprouts/Round.swift` | the shared Card, one round of ten, choices, haptics |
| `NumberSprouts/EvenOdd.swift`, `Compare.swift`, `AddSub.swift`, `Times.swift` | the card engines (seedable) |
| `NumberSprouts/Pictures.swift`, `Draw.swift`, `DotToDot.swift` | Draw: the pictures, Color by Number, Dot to Dot and Explore |
| `NumberSprouts/MakeTrue.swift` | Make It True: puzzles, every true way, why a try isn't true |
| `NumberSprouts/MakeTrueView.swift`, `MakeTrueBoards.swift` | its screen, and the Tiles, Scale and Machine boards |
| `NumberSprouts/Profiles.swift` | kid profiles and per-profile progress (`AppModel`) |
| `NumberSprouts/WhoView.swift` | "Who's playing?", add and edit a player |
| `NumberSprouts/HomeView.swift` | concept bar, mode tiles, the player badge |
| `NumberSprouts/PlayView.swift` | the card loop: drag into a basket, glow, star burst, shake |
| `NumberSprouts/TrickCard.swift` | the Trick card and its visuals, and the round summary |
| `NumberSprouts/Theme.swift` | bright palette (Even blue, Odd orange), rounded type, big buttons |
| `NumberSproutsTests/` | engine, round and profile tests |
| `tools/make-icon.swift` | draws the app icon (`swift tools/make-icon.swift <out.png>`) |
| `handoff/` | the Mac ↔ Cowork channel for this build |

Run the tests with ⌘U, or:

```
xcodebuild test -project NumberSprouts.xcodeproj -scheme NumberSprouts \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```
