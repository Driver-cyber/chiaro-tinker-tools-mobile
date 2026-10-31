# Mac → Cowork

### 2026-10-30T23:30-07:00 — M1 done: Number Sprouts, Even or Odd

Thanks for the brief. M1 is built on `kids-math-v1` at `ios/NumberSprouts/`.

**Decided by Chad** (now in `STATUS.md`):
- Name: **Number Sprouts**, bundle `com.chiarotinkertools.numbersprouts`.
- Haptics only by default.
- **Structure change:** the home screen is a concept bar at the top (Even or
  Odd · Bigger or Smaller · Add & Subtract · Times Tables), then **modes named
  by skill**, each with its own stars, instead of a Sprout/Grow/Stretch
  picker. His reason: a kid who has mastered one thing shouldn't get bored by
  random easy cards. Levels still exist under the hood. Even or Odd's modes are
  *Pair the dots* (1–10 with dots), *Numbers to 20*, and *Last digit*
  (10–999).

**What works (simulator, verified by a UI test from a fresh install):**
- First launch goes straight to "Add a player": name, colour, one of 30 emoji
  or 6 SF Symbols. "Who's playing?" has big tiles, a pencil to edit, and an
  Add tile. The player badge in the corner switches players.
- The card flies in and the number pops. Drag it into the Even or Odd basket
  (or tap the basket). Right answers get a green glow, a star burst, the card
  dropping in and a success haptic. A miss gets a shake, a soft haptic, the
  Trick card (dots slide into pairs, a leftover glows orange; past 20 the last
  digit lights up and its dots pair), then one retry.
- Read-aloud button reads the question; the Trick card reads its sentence too.
- Summary: 1–3 stars from first-try answers (9+ → 3, 6+ → 2, else 1;
  finishing always earns one), Play again / Done. Stars are kept per player,
  per mode.
- Reduce Motion swaps the animations for fades.

**For M2, a proposal for Chad (not decided):** modes by skill for the other
decks, e.g.
- *Bigger or Smaller:* Within 20 · Tens first (to 100) · Look-alikes (68 vs 86)
  · To 1,000.
- *Add & Subtract:* Make 10 · Doubles · Within 20 · Missing number · Two-digit.
- *Times Tables:* ×2 ×5 ×10 · ×3 ×4 · ×9 tricks · Mixed · What times what?

Each round in a mode stays in that skill, so no random easy run.

**Open for Chad:** whether M2 should add an "auto" option that suggests the
next mode after two 3-star rounds (the brief's "auto" idea, as a suggestion
rather than a forced level-up).

### 2026-10-30T23:45-07:00 — M2 modes approved; no auto nudge; an art idea

Chad approved the M2 modes as proposed (Bigger or Smaller: Within 20 · Tens
first · Look-alikes · To 1,000; Add & Subtract: Make 10 · Doubles · Within 20
· Missing number · Two-digit; Times Tables: ×2 ×5 ×10 · ×3 ×4 · ×9 tricks ·
Mixed · What times what?). **No auto nudge:** kids pick their own mode.

New idea from Chad, still open: a concept where math and art meet (paint by
numbers, simple geometry, or a coordinate plane with Pin / Undo / Clear). Mac's
recommendation is in Chad's chat. If you discuss it with him, please post the
decision here before Mac builds it.
