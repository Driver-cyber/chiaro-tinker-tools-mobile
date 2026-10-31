# Number Sprouts — math flash cards for Chad's kids

A small, offline, ad-free iPhone game for ages 6–8. One card at a time; answer
it; every miss shows the trick that cracks it. Built from `BRIEF.md` (Cowork's
brief, approved by Chad), with Primes as its bones.

* **Bundle ID:** `com.chiarotinkertools.numbersprouts` · iPhone, portrait · iOS 17+
* **Family install only for now** (Xcode or TestFlight internal). No App Store.
* **Nothing leaves the phone:** profiles and stars live in UserDefaults. No
  network, no ads, no analytics, no links out. Haptics only by default (no sound).

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

## Layout

| Path | What |
|---|---|
| `NumberSprouts/Modes.swift` | every concept and its modes, in one list |
| `NumberSprouts/Round.swift` | the shared Card, one round of ten, choices, haptics |
| `NumberSprouts/EvenOdd.swift`, `Compare.swift`, `AddSub.swift`, `Times.swift` | the card engines (seedable) |
| `NumberSprouts/Pictures.swift`, `Draw.swift`, `DotToDot.swift` | Draw: the pictures, Color by Number, Dot to Dot and Explore |
| `NumberSprouts/Profiles.swift` | kid profiles and per-profile progress (`AppModel`) |
| `NumberSprouts/WhoView.swift` | "Who's playing?", add and edit a player |
| `NumberSprouts/HomeView.swift` | concept bar, mode tiles, the player badge |
| `NumberSprouts/PlayView.swift` | the card loop: drag into a basket, glow, star burst, shake |
| `NumberSprouts/TrickCard.swift` | the Trick card and its visuals, and the round summary |
| `NumberSprouts/Theme.swift` | bright palette (Even blue, Odd orange), rounded type, big buttons |
| `NumberSprouts/Speech.swift` | read-aloud (AVSpeechSynthesizer, offline) |
| `NumberSproutsTests/` | engine, round and profile tests |
| `tools/make-icon.swift` | draws the app icon (`swift tools/make-icon.swift <out.png>`) |
| `handoff/` | the Mac ↔ Cowork channel for this build |

Run the tests with ⌘U, or:

```
xcodebuild test -project NumberSprouts.xcodeproj -scheme NumberSprouts \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```
