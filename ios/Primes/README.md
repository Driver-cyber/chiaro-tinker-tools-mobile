# Primes — native iPhone app

Prime or Composite, the CTT pocket tool, as a native SwiftUI app. Same game as
the ÷ pocket on chiaromobile: numbers 2–999 in Easy / Medium / Hard, every
answer shows the method, Roots / Prime tricks / Checklist as half-height
sheets, and a 168-of-168 found-primes meter.

* **Bundle id:** `com.chiarotinkertools.primes` · iPhone, portrait · iOS 17+
* **Progress:** the found primes live on the phone (UserDefaults), riding the
  phone's own iCloud backup. Nothing is sent anywhere; no sync secret in the app.
* **Not deployed by Cloudflare:** Pages publishes `src/` only, so this folder
  never touches chiaromobile.

## Run it on your iPhone (no Terminal needed)

1. **Open** `ios/Primes/Primes.xcodeproj` in Xcode 16 or newer.
2. **Signing:** click the blue *Primes* project icon → target **Primes** →
   *Signing & Capabilities* → **Team:** pick your Apple Developer team.
   (Do the same for the **PrimesTests** target.)
3. **Plug in your iPhone**, pick it in the device menu at the top of the
   window, and press **▶ Run**. The first time, the phone may ask you to trust
   the developer: *Settings → General → VPN & Device Management*. It may also
   ask you to turn on *Developer Mode* (*Settings → Privacy & Security*).
4. **Run the tests:** **⌘U**. They check the handoff's acceptance list and
   compare every output of the Swift engine with the web game's.

If Xcode reports a build error, copy the message (file + line) back to Claude.
This project was written in a Linux sandbox with no Swift compiler, so the
first build is its first real compile.

## Layout

| Path | What |
|---|---|
| `Primes/Engine.swift` | the game logic: buckets, weighted draw, the 11 tricks, explanations |
| `Primes/Game.swift` | one sitting's state + the found-primes store + haptics |
| `Primes/ContentView.swift` | welcome / question / answer screens |
| `Primes/Sheets.swift` | Roots, Prime tricks, Checklist (+ trick detail), Primes found |
| `Primes/Theme.swift` | chiaroscuro colours (Cream in light mode), button styles |
| `PrimesTests/` | acceptance, web-parity and game tests + `web-fixture.json` |
| `tools/make-fixture.js` | regenerates the fixture from `src/index.html` |
| `icon-source.html` | the app icon's SVG source (amber ÷, lamp glow) |

The Xcode project uses **folder-synchronized groups**: any file you add inside
`Primes/` or `PrimesTests/` is picked up automatically. No project edits needed.

## Keeping it in step with the web game

The web game is the source of truth. If its engine changes, run
`node ios/Primes/tools/make-fixture.js` from the repo root and press ⌘U. Any
number where the Swift port now differs fails by name.
