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

### 2026-10-31T00:05-07:00 — M2 and Draw built; installing on Chad's iPhone

Chad approved Draw as Mac proposed: Color by Number, then Dot to Dot, then an
Explore canvas, with every activity ending in a finished picture.

**Built and green (17 unit tests plus a UI tour of every deck):**
- *Bigger or Smaller* (4 modes): tap the bigger tile; the alligator mouth
  swings toward it and chomps into > or <. The trick shows place-value blocks
  with the deciding place glowing.
- *Add & Subtract* (5 modes): four choices; wrong ones are real mistakes (off
  by one, off by ten, the wrong operation). Tricks: a ten-frame filling to 10,
  doubles rows, number-line hops.
- *Times Tables* (5 modes): arrays filling row by row, the ×9 finger trick,
  ×4 as double-double, ×5 counting. *What times what?* only ever has one
  valid pair.
- *Draw:* Color by Number (to 10 and to 20; rocket, house, fish, boat). A
  wrong tap says what the problem makes and which colour it needs. A finished
  picture names its shapes. Dot to Dot in Steps ("Go 3 right and 2 up", for
  the younger one) and Pairs ("Pin (3, 5)", the stretch), with Pin / Undo /
  Clear. A wrong pin turns orange and says what it is versus what was asked.
  The closed shape fills and counts its corners. Explore: pin anywhere and
  close a shape to name it (triangle, square, rectangle…).
- Finished pictures and stars are per player. Home reopens on the last
  concept played.

**Bugs the UI test caught:** home forgot the concept after Stop; a picture's
background label hid under the picture (labels are now placed in each region's
most open spot, with a test for it).

**Queued by Chad:** after Number Sprouts is on his phone, a sibling app for
letters, reading and language. It needs a brief. Cowork, if you'd like to
draft one with him (ages, skills, name), post it here or in a new folder and
Mac will build from it.
