# HANDOFF — for the next session (written 2026-10-31)

*Read `CLAUDE.md` first (the constitution), then `DECISIONS.md` (newest
entries at the bottom, just above the Parking Lot), then this file. Rewrite
or delete this file freely once it's absorbed.*

**The next session runs in a terminal on Chad's Mac mini.** Its job is the
one thing a cloud session can't do: compile and run the native iPhone app in
`ios/Primes/`, which was written in a Linux sandbox with no Swift compiler
and **has never been built.**

---

## 0. First: sync. The Mac has been off for weeks

The local clones are probably behind, maybe by dozens of merged PRs.

1. Find the clones (likely `~/Documents/GitHub/chiaro-tinker-tools-mobile` and
   `…/chiaro-tinker-tools`; check, don't assume). If the mobile repo isn't
   cloned, clone `https://github.com/Driver-cyber/chiaro-tinker-tools-mobile`.
2. In each repo, **`git status` before anything else.** If there are local
   changes or unpushed commits, **stop and show Chad.** Never stash, reset,
   discard or force anything without his say-so. Old local work may matter.
3. If clean: `git fetch origin && git checkout main && git pull --ff-only`.
   Chad may do this in GitHub Desktop instead (Fetch origin → Pull origin).
   Either is fine.
4. Confirm you're current: `main` should include at least
   - mobile `4907e1b` (Merge PR #28 — *Primes goes native*)
   - desktop `8386eab` (Merge PR #54 — *pocket FAB comes to desktop*)

## 1. Where things stand

| Surface | Version | Live at |
|---|---|---|
| Desktop web | **CTT v0.13.0** | https://chiaro.chadstewartcpa.com |
| Mobile web (PWA) | **CTT Mobile v0.13.0** | https://chiaromobile.chadstewartcpa.com |
| Native iPhone app | **Primes 1.0 (unbuilt)** | `ios/Primes/` in this repo |

Shipped Oct 20–31, both surfaces unless noted:
- **Blueprint Day view** (desktop only): an hour grid for sketching blocks
  (`db.blocks`), with view-only Outlook events from `.ics` or the Worker's
  optional `?feed=outlook`. Mobile carries the `db.blocks` default (lockstep)
  but doesn't render the day map.
- **Primes**: the prime-or-composite mental-math drill. It's a **pocket
  tool**, not a tab, and it has a 168-of-168 found-primes meter
  (`db.primes.solved`, schema lockstep in both repos).
- **Pocket FAB**: a bottom-right ✦ that fans out Scratch, Primes and Bell.
  Bell = Document-PiP pop-out on desktop, full-screen bell on mobile.
- **`ios/Primes/`**: the SwiftUI app (details below).

## 2. The job: build, test and install the native app

Read `ios/Primes/README.md`. Then:

1. **Toolchain:** `xcodebuild -version` must show **Xcode 16 or newer**. The
   project uses `objectVersion = 77` with folder-synchronized groups, which
   older Xcode can't open. `xcrun simctl list devices available` lists the
   simulator names.
2. **Build and test on a simulator first (no signing needed):**
   ```
   cd ios/Primes
   xcodebuild test -project Primes.xcodeproj -scheme Primes \
     -destination 'platform=iOS Simulator,name=<an available iPhone>'
   ```
3. **Fix what breaks.** First compiles of hand-written SwiftUI usually turn up
   a few errors. Rules:
   - **The web game is the source of truth.** If `WebParityTests` fails, fix
     the Swift (`Primes/Engine.swift`). Never edit `web-fixture.json` or
     loosen a test to get green. The fixture is regenerated only from
     `src/index.html` via `node ios/Primes/tools/make-fixture.js`.
   - Keep the design as built: half-height sheets, a trick opened from the
     Checklist closes back to it, work hidden behind "Check my work"
     mid-question, the streak lives in memory only, and found primes are
     local (UserDefaults).
   - Likely trouble spots, ranked: SwiftUI type-checker timeouts in the long
     view bodies (split them into smaller views); `Text` concatenation;
     `presentationBackground` and other availability; whether
     `web-fixture.json` lands in the **test** bundle's resources (if
     `Bundle(for:)` returns nil, check the synchronized folder's membership).
4. **Look at it:** run it on the simulator and grab screenshots
   (`xcrun simctl io booted screenshot ~/Desktop/primes.png`). Show Chad the
   welcome, question, answer, and a sheet open over a question.
5. **On Chad's iPhone:** it needs his Apple Developer team.
   `DEVELOPMENT_TEAM` is empty in the repo; Chad picks the team in Xcode
   (project → each target → *Signing & Capabilities*), or set it once the ID
   is known. A team ID is fine to commit. **Never** commit certificates,
   provisioning profiles, or `xcuserdata/` (there's a `.gitignore`), and never
   ask for his Apple ID password. First install: the phone asks to trust the
   developer and to enable Developer Mode.
6. **Ship the fixes:** commit on a branch → PR → merge. Chad has authorized
   that cadence. Note what broke in `DECISIONS.md` under the 2026-10-31
   native entry, because it's the scar list for the next native work.

## 3. Facts the Mac session needs

- **Bundle id** `com.chiarotinkertools.primes` (tests: `…primesTests`).
  iPhone, portrait, iOS 17+.
- **Engine type is `PrimeEngine`**, deliberately not `Primes` (that's the
  module name; the clash breaks `@testable import`).
- **Tests (⌘U, or `xcodebuild test`):** the handoff's acceptance checklist;
  web parity across all 998 numbers and 10,978 trick-on-number pairs; and the
  found-primes meter (writes only on the first correct prime call, persists).
- **Cloudflare Pages publishes only `src/`.** Nothing in `ios/` can affect
  chiaromobile.
- **Secrets:** never ask for or commit Chad's `SYNC_SECRET`, the Worker's
  `ICS_URL`, or any Apple credential.

## 4. Open items (Chad's call, not urgent)

- **Outlook live feed (desktop):** the Worker code has the `?feed=outlook`
  route, but it's inert until Chad redeploys `sync/chiaro-sync-worker.js`
  (desktop repo) and adds an `ICS_URL` secret. **Check firm policy first.**
  Published work calendars may be off or prohibited. `.ics` import works
  today.
- **Mobile doesn't render the Day map yet.** The data rides along safely.
- **Browser test suites aren't in the repo.** The CDP suites used this month
  lived in a cloud scratchpad, now gone. The jsdom/CDP harness idea from
  2026-08-12 still stands.
- **Desktop installability (PWA):** still Scheduled, not now.

## Voice

Earnest, literate, a little myth-soaked, unpretentious. Chad drives product;
push back honestly. Closing is a success state. Tabs are rooms, pockets are
tools. Ordo ab chao.
