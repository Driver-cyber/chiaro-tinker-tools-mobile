# 🗺 CTT Mobile — Evolution & Decision Log

> **Note to Claude:** Read this to understand the current vibe before
> suggesting changes. Settled decisions shouldn't be relitigated without a
> real reason — but "we found a real reason" is always valid. Rules are
> defaults; judgment is primary.
>
> **Pre-fork history lives in the desktop repo** —
> `chiaro-tinker-tools/DECISIONS.md` covers everything from the PJT fork
> through CTT v0.5.0 (Opening → Journal/Time Card/Blueprint → Closing, cloud
> sync, chiaroscuro brand). This log starts at the split.

## 🎯 The North Star (Current Goal)
* **Goal:** the mobile surface of Chad's personal tool belt — CTT in the
  pocket, quick to open, honest to close.
* **Deeper mission:** trustworthy closure, same as the sibling. On a phone the
  anti-engagement ethos sharpens: the one tile that wants to be closed.
* **Current phase:** M0 shipped (founding PWA) → M1 (mobile ergonomics via
  dogfooding).

## 📝 Change Log (Decisions)

* **[2026-07-24] Repo founded — the surface split.**
    * *Decision — two repos, one soul:* `chiaro-tinker-tools` stays the
      desktop surface (desktop browser + Tauri macOS); this repo is the mobile
      surface (mobile-browser PWA now, iOS native someday). Chad's call, made
      so each surface can stay focused instead of one repo carrying both sets
      of compromises. Founding docs inherited whole, with the split caveat.
    * *Decision — fork point:* copied `src/index.html` from the desktop repo
      at **CTT v0.5.0** verbatim, then layered PWA-only changes. Mobile starts
      its own version line: **CTT Mobile v0.1.0**.
    * *Decision — schema lockstep (load-bearing):* both repos share one synced
      `db` (`SCHEMA='ctt-1'`). Schema/`normalize()` changes must land on both
      sides (or be verified tolerated) before merging. Divergence of surface:
      yes. Divergence of data model: never.
    * *Decision — sync is the bridge, and the phone's safety net:* same
      Worker+KV sync, configured at runtime by sync code. localStorage is
      per-origin, so the mobile deploy starts empty until Chad pastes his
      sync code — that's the designed onboarding, not a bug. iOS PWA storage
      eviction is survivable because the KV copy is the durable one.
    * *Decision — PWA shape:* the single-file ethos holds; the app gains
      exactly three companions in `src/`: `manifest.webmanifest`, `sw.js`,
      `icons/` (rendered from the plague-mask glyph — amber line on walnut,
      faint lamp glow; regular + maskable + apple-touch sizes). Service worker
      caches the **shell only** (never data, never the sync origin),
      navigations are network-first so deploys arrive silently — no update
      banners, per the ethos. `CACHE` name version-bumps with the subtitle.
    * *Decision — iOS chrome:* standalone display, `black-translucent` status
      bar, `viewport-fit=cover` + safe-area insets absorbed by the sticky
      appbar (top) and body (sides/bottom). No-op outside a notched install.
    * *Decision — M0 ships the desktop layout untouched:* no mobile redesign
      speculation. Dogfood on the actual iPhone first; let real friction write
      the M1 backlog.

* **[2026-07-25] Custom domain — the canonical door.**
    * *Decision (Chad):* **https://chiaromobile.chadstewartcpa.com** now fronts
      the Pages project (the desktop sibling got `chiaro.chadstewartcpa.com`
      the same morning). No code changes needed — every path in the app, SW,
      and manifest is relative, so the PWA works identically on any origin.
    * *Rule of thumb recorded:* PWA install, localStorage, and the sync-code
      config are all **per-origin**. The custom domain is the canonical door —
      install and onboard there, not on the `pages.dev` alias, so the
      home-screen app and its local data live on the address meant to last.
      (Anything set up on the alias earlier just re-onboards with the sync
      code — the KV copy is the durable one; nothing is lost.)

* **[2026-07-25] v0.2.0 — the bell crosses the bridge (first sibling backport).**
    * *Decision (Chad):* backport the desktop v0.6.x arc — the **tinker's
      bell** and the derived **code hints** in the log dropdown — and give the
      bell a mobile-native third form: **full-screen mode**. ⛶ on the bell
      head grows the face to fill the phone (controls in the bottom third,
      ✕ top-right, safe-area aware); ✕ shrinks it back **without stopping
      anything**. Chad's instinct, confirmed against platform convention —
      full-screen takeover is what Clock-style timers do; Document PiP
      doesn't exist on iOS Safari, so this is the honest translation of the
      desktop ⧉ pop-out.
    * *Implementation choice:* full-screen is a **pure CSS state** on the same
      nodes (`.bell-panel.full` + fixed inset overlay) — no second document,
      no moved DOM, so the v0.6.2 cross-document scar can't reopen here. The
      controls are addEventListener-wired anyway (house pattern).
    * *Screen Wake Lock:* while full-screen AND running, the phone stays
      awake (`navigator.wakeLock`, feature-detected, re-armed on
      visibilitychange since the OS drops locks on backgrounding). Ethos
      check: a kitchen timer that lets the screen sleep is a kitchen timer
      you never see ring — this is a tool Chad invoked minutes ago, not a
      leash. Released the instant either condition ends.
    * *Backgrounding, honestly:* the countdown is wall-clock (`endAt`), so
      leaving the PWA never drifts it — on return it catches up instantly and
      rings if its time passed. What it cannot do is pulse or chime while iOS
      has the tab frozen; the only workaround is push notifications, which
      CTT will never use. Full-screen + wake lock is the whole answer.
    * *Lockstep note:* zero schema impact — the bell is ephemeral (never
      touches db/save/sync) and hints are derived at render time. No
      coordination needed; siblings stay in lockstep by not touching the db.
    * *Verified* headless at 390×844 with real element clicks: overlay
      measured exactly 390×844, ✕ at the top-right inset, rung pulse in
      full-screen, ✕-collapse with the timer still running, round-trip
      expand/collapse mid-run. Wake lock acquired in-harness.

* **[2026-07-26] v0.3.0 — the timer visual system (lockstep backport of
  desktop v0.7.0).**
    * *Decision (Chad, planned in a claude.ai session):* the bell's pixel
      grid becomes a **swappable renderer registry** — six visuals (Ember
      grid, Balance, Moon, The Thinker, Lantern, Sundial), **random per
      timer start/reset**, Visual dropdown **hot-swaps preserving timer
      state**; a manual pick holds for the current timer only. Renderers are
      pure functions of elapsed fraction — `render(p) → {vb, body, post?}` —
      the `bell` object stays the only brain. Full details and guardrails in
      the desktop repo's DECISIONS entry (same date); this repo carries the
      identical engine.
    * *Mobile specifics:* the visuals render inside the existing full-screen
      mode untouched — the `.bell-vis` square grows to `min(84vw,50vh)` when
      full. Wake lock, ✕-collapse, and the rung pulse compose with any
      renderer. Zero schema impact (ephemeral, derived) — no lockstep
      coordination needed beyond shipping both sides the same day, which
      this did.
    * *Verified* headless at 390×844 with real clicks: all six render clean
      at five p-values; no horizontal overflow; mid-run hot-swap preserved
      state exactly; full-screen overlay 390×844 with the visual at 328px;
      wake lock held in full+running and released on ✕; reset returned the
      dropdown to Random; Thinker length-cache built.

* **[2026-07-26] v0.4.0 — the scratch sheet (lockstep with desktop v0.8.0:
  the FIRST real schema addition since the split).**
    * *Decision (Chad):* the 8×25 formula grid ("un-squint the numbers")
      lands on mobile the same day as desktop — see the desktop repo's
      DECISIONS entry for the full design (pocket-tool pattern, napkin
      rules, two-tap clear, frozen scope).
    * *SCHEMA LOCKSTEP, honored for real this time:* `db.scratch.cells`
      (raw strings, "A1".."H25") + the `mergeDefaults()` default now exist
      in BOTH repos. Verified here with legacy-shaped data: a pre-scratch
      db staged in localStorage boots clean and gains the default. Both
      normalizers also preserve unknown keys, so a skewed deploy window
      can't drop a sibling's sheet — but same-day is the rule, and it held.
    * *Mobile specifics:* the ▦ pocket button sits in the appbar next to
      the save pill; the overlay is safe-area padded; the grid scrolls
      horizontally INSIDE `.scratch-wrap` (the page itself never
      side-scrolls — standing rule), row numbers sticky, 14px inputs with
      fat tap targets. Backdrop tap closes; the room underneath never moves.
    * *Verified* headless at 390×844 with focus-emulated real events:
      `=B1*B2` → 276.04, `=SUM(B1:B3)` → 688.71, cold-reload persistence,
      page scrollWidth exactly 390 with the wrap scrolling internally,
      backdrop-tap close. *Harness scar (from the desktop round, bit again
      here):* `Emulation.setFocusEmulationEnabled` must be re-issued after
      every navigation — it doesn't survive one, and without it headless
      documents swallow focus/blur events while still moving activeElement.

* **[2026-07-26] v0.4.1 — scratch-sheet ergonomics (lockstep with desktop
  v0.8.1).** Arrow-key cell navigation (Left/Right from text edges only) and
  Excel-style point-to-refer: mid-formula, tapping a cell inserts its ref;
  consecutive taps replace the last pointed ref; a complete formula commits
  and moves on tap. Includes the input-event fix for the point-span flag
  (keydown alone misses IME/autocomplete — matters extra on iOS keyboards).
  Verified at 390×844 with real key + mouse events: 6⏎5⏎ list entry,
  =tap+tap → 11, ArrowDown navigation. Zero schema impact; full details in
  the desktop repo's v0.8.1 entry.

* **[2026-07-26] v0.4.2 — accounting number format (lockstep with desktop
  v0.8.2).** Commas + fixed two decimals on every displayed number; display
  only, raw text untouched. No schema impact.

* **[2026-07-26] v0.4.3 — composition bar + source-cell highlighting
  (lockstep with desktop v0.8.3).** A wide formula bar above the grid mirrors
  the cell being edited (ref label at left) — on a phone this matters double,
  since a cell is 84px wide. Tapping cells while composing inserts refs into
  the bar; every referenced cell (ranges expanded) is outlined amber while
  the formula is open. Escape follows Excel's rule: abandon an in-progress
  edit, keep the sheet; nothing to abandon → close. Verified at 390×844 with
  real key + tap events. Zero schema impact; full details in the desktop
  repo's v0.8.3 entry.

* **[2026-07-26] v0.4.4 — the involuntary-zoom fix (Chad, pre-install).**
    * *Symptom:* on the phone "the screen zooms in so the windows aren't
      always fitting." *Cause:* mobile Safari auto-zooms the page whenever
      focus lands on a control whose text is under 16px — and it does **not**
      zoom back out on blur. Every input in the app was 14px (the global
      `select,input,textarea` rule), so any tap anywhere left the viewport
      stuck wide.
    * *Fix:* a `@media (pointer: coarse)` block forcing all form controls to
      16px. Deliberately **not** `maximum-scale=1` / `user-scalable=no` —
      deliberate pinch-zoom stays available (accessibility); only the
      *involuntary* zoom is removed. Scoped to coarse pointers, so the
      desktop sibling's density is untouched.
    * *Follow-on:* 16px digits need more room, so mobile scratch cells widen
      to 112px (measured: `24,798,329.10` wants ~90px of text box). Chasing
      width forever is a losing game, so truncation became **honest**
      instead — `text-overflow:ellipsis` on cells in BOTH repos (mobile
      v0.4.4 / desktop v0.8.4). A silently clipped `4,959,665.82` reading as
      a complete `4,959,665.8` is a wrong number an accountant could act on;
      `49,568,236…` can't be misread. The composition bar shows the whole
      value on focus.
    * *Verified* at 390×844 with touch emulation (so `pointer: coarse`
      actually matches): zero visible controls under 16px anywhere in the
      app, all five rooms plus the open sheet at `scrollWidth` exactly 390,
      the panel fitting the viewport, and eight-figure sums rendering whole.

* **[2026-07-26] v0.5.0 — M1 opens: the desktop-shaped tables fold away
  (Chad, from the phone).**
    * *Chad's read:* the Time Log and Daily Codes tables are seven-column
      desktop surfaces — "not really designed for mobile and I probably
      won't use those on mobile except maybe rarely." Correct: time entry
      is a sit-down act, and the desktop is right there.
    * *Decision:* both panels become collapsible and **start collapsed** on
      the mobile surface. Each header carries a live count (`· 5 blocks`,
      `· 2 codes`) so a shut drawer still says what's in it — closed, not
      hidden. Tapping the header opens it; the header's own controls
      (Day start, **+ Add …**) never toggle the drawer, and they're hidden
      while it's shut, since adding a block you can't see is a trap.
    * *State is session-only, deliberately:* an expanded drawer stays open
      across re-renders and room switches while Chad is working, and a
      fresh open starts calm again. That's the Open lens answered — the
      phone's Time Card opens to the day's total, the bell, and the plan,
      not a squint. No db field, so no schema change and no lockstep.
    * **First deliberate layout divergence from the desktop sibling** — the
      point of the split, finally exercised. Desktop keeps both tables open;
      it has the room. Divergence of surface: yes. Of data model: never.
    * *Bug caught in-harness:* an inline `style="display:flex"` on the Time
      Log's action group outranked the collapsed rule, stranding the
      controls on a shut drawer. Styling moved into the class. Standing
      lesson: inline styles beat stylesheet state rules — keep state-driven
      properties out of `style=` attributes.
    * *Verified* at 390×844 with touch emulation and real taps: both panels
      collapsed on load with correct counts, tables not rendered, actions
      hidden; header tap expands and shows all rows; **+ Add time block**
      adds without collapsing and updates the count; expansion survives
      `renderTimecard()` and room switches; a reload starts calm again;
      `scrollWidth` still exactly 390.

* **[2026-07-26] v0.6.0 — the time log and codes become CARDS (Chad, after
  actually using them on the phone).**
    * *Correction to v0.5.0's premise:* Chad predicted he'd rarely use time
      blocks on mobile; he then used them and reported "really hard to use."
      Collapsing the tables treated the symptom (clutter); the disease was
      the shape — a seven-column table on a 390px canvas forces a sideways
      hunt for the field you want.
    * *Decision:* each row becomes a **vertical card**. Time block: ▲▼ +
      code select / start → stop + duration / note + 🔔 ✕ — three lines,
      nothing off-screen. Code: letter + client + hours + ✕ / bill +
      category / the sync pair stacked with its status pill.
    * *Decision — ▲▼ replaces the drag handle.* Not a downgrade: HTML5
      drag-and-drop **never fires on touch**, so reordering was silently
      impossible on this surface the whole time — and reordering matters
      because start times chain from the previous block. Same
      `moveLogEntry()` underneath; edge buttons disable at the ends.
    * *Decision — one renderer, not two.* The table path is **gone** from
      this repo rather than branched on width. Maintaining two layouts in
      one file is the real long-term cost, and this repo IS the phone.
      Consequence accepted: chiaromobile on a laptop shows cards too; the
      desktop app is the right tool there.
    * *Layout note:* at 390px the times row cannot also carry 🔔 ✕ without
      wrapping them onto an orphan line — the actions ride the note row
      instead. Measured, not guessed: cards land at 147px, three rows.
    * *Verified* at 390×844 with touch emulation and real taps: 3 blocks +
      2 codes render as cards with zero tables left; no card overflows its
      column and the page stays exactly 390 wide; every field present per
      card; ▲ reorders and start times recompute (8:00 → 9:30 → 12:15);
      first ▲ and last ▼ disabled; 🔔 still pre-fills the bell; ✕ deletes;
      code cards keep letter/client/bill/hours/sync select/status pill.
    * *Follow-on parked:* the Month Report table has the same shape problem
      and would want the same treatment. Not built — Chad's call.

* **[2026-07-26] v0.7.0 — the Project Journal follows the Time Card into
  cards (Chad).**
    * *Decision:* the sections table (section · status · budget · actual ·
      variance · scratchpad — six columns) becomes one **card per section**:
      happy checkbox + name on top, `Updated:` and ✎/✕ on a meta line, then
      Budget/Actual with the variance trailing right, then the scratchpad
      full width with Expand/Copy beneath. Same reframe as v0.6.0, same
      reasoning: wide lines work on a desktop, cards work in a hand.
    * *Both project shapes preserved:* flat (ORDO/Simple) keeps the happy
      checkbox with its ember burst; the audit binder keeps its full
      STATUSES select — moved to its own line, since a status dropdown and
      a section name can't share 390px — and its group headers become
      tappable `.groupcard` rows with counts and the same chevron.
    * *`noteCell()` → `noteBlock()`:* the scratchpad's debounced auto-save,
      expand, and copy behaviour is unchanged; only its container stopped
      being a `<td>`.
    * **No tables remain anywhere on the mobile surface** — the last one
      (Month Report) aside, which is parked. Dead CSS retired with the
      markup (`.section-col`, `.col-num`, `.group-row*`).
    * *Verified* at 390×844 with touch emulation and real taps: 7 section
      cards, zero tables in the journal pane, nothing overflows, page stays
      exactly 390 wide; a card carries checkbox/name/budget/variance/
      scratchpad/rename; a budget edit persists and the variance recomputes
      live; the checkbox still flips status; the scratchpad still saves;
      search still filters (with an honest empty state); and forcing the
      audit template renders 2 group cards + 7 status selects.

* **[2026-07-26] v0.8.0 — the Month Report becomes cards; the last table on
  the mobile surface is gone (Chad).**
    * *Decision:* the report's four-column table (client · type · hours ·
      share bar) becomes one **card per client/project**: name + hours + ▸
      on top, category dot + share percent beneath, the bar across the
      bottom. The whole card is the tap target for the note trail.
    * *Sorting survives the table's death:* the sortable `<th>`s become a
      **sort bar** of three chips (Client · Type · Hours) carrying the same
      `.sortcaret` spans, so `sortReport()`/`updateSortCarets()` work
      unchanged.
    * *`copyReport()` now reads DATA, not markup.* It used to scrape
      `#reportBody tr` cells — which the card reframe would have silently
      broken. It reads the last rendered rows (`_reportRows`) instead. A
      DOM-scraping export is a latent trap in any renderer change; worth
      remembering the next time one shows up.
    * *Copy reworded for touch* ("Tap any card…"), and the dead
      `#reportBody tr.clickrow` CSS retired with the markup.
    * **`grep -c "<table"` on this repo now returns 0.** Every working
      surface on the phone is cards.
    * *Verified* at 390×844 with touch emulation: 2 report cards, zero
      tables anywhere in the document, nothing overflows, page exactly 390
      wide; card carries label/hours/category/percent/bar; sort chips
      re-order and the caret moves; `copyReport()` produces
      "Longview — 4.50 / Vetters C3 — 2.00" from data; tapping a card opens
      the note-trail modal.

* **[2026-07-26] v0.9.0 — project workshop links (lockstep with desktop
  v0.9.1).** A project can carry an optional `appUrl` pointing at its own
  companion web app; a **⧉ Workshop** button appears in the project header
  when set, and a **⧉** mark beside it in Recent. Rationale, decision, and
  the "tabs are rooms, this is a door" reasoning live in the desktop repo's
  entry for the same date. **Schema-lockstep:** new project field, landed
  both sides the same hour; no `normalize()` change needed since the field
  is read with `||''` — a db predating it simply has no door, verified
  against that legacy shape. Zero mobile-specific divergence.

* **[2026-08-12] Workshop links stop mangling same-origin paths, and import
  grows an undo.** Two fixes, both landed the same hour as the desktop
  sibling; details and reasoning live in the desktop repo's entry for this
  date. The mobile-specific halves:
    * *`updateAppUrl` no longer prepends `https://` to a path beginning `/`.*
      The standing rule that fell out of it matters most on this surface:
      `appUrl` rides the **synced** db, but the two surfaces are on
      **different origins** (`chiaromobile` vs `chiaro`), so a relative path
      entered on the desktop resolves against *this* origin on the phone and
      404s. **Synced fields take absolute URLs.** Visible in the test run —
      the `/gertie/` case resolved its href against the mobile origin.
    * *Import takes an undo snapshot before overwriting* (v0.9.2). This is
      the surface that made it urgent: no file backup (`backupNow()` is
      `FS_ENABLED`/Tauri only) **and it syncs**, so a wrong file imported on
      the phone reaches the desktop on the next push. Both modes snapshot —
      merge included, since days are combined with `Object.assign` and any
      date in both files is silently overwritten by the incoming one. Sync
      credentials stripped going in, live ones re-attached coming out. A
      refused snapshot blocks the import and offers an explicit override.
    * **Schema-lockstep: unaffected.** The undo buffer lives under its own
      key (`ctt_import_undo_v1`), outside `db`, so it never enters sync or
      export.
    * *Still outstanding for this repo:* **rich notes** (desktop v0.9.0) are
      not ported — `projectNotes` and the section scratchpads are still plain
      textareas here. Markdown is the stored format on both sides, so the
      data is compatible today; this is a rendering gap, not a schema one.

* **[2026-10-30] v0.10.0 — Primes, plus the day-map schema default
  (lockstep with desktop v0.11.0 / v0.10.0).** Chad's handoff: a
  prime-or-composite mental-math drill, landing first here at
  chiaromobile. Also pays desktop v0.10.0's lockstep debt: `db.blocks`
  (the Blueprint day map's per-date blocks) now defaults here too, verified
  against a legacy-shaped db with a canary key. This surface doesn't render
  the day map yet; it just carries the field safely.
    * *Placement (Chad, asked and answered):* a **sixth tab**, after Closing,
      not a pocket tool, even though "tabs are rooms, pockets are tools" was
      the pattern. A drill you sit down to is a room. `#primes` deep-links
      straight to it (a home-screen bookmark lands on the game).
    * *The streak, and why it doesn't break the ethos (Chad ratified):* the
      constitution says "no streaks… ever." The handoff asked for one. We
      kept it, **in memory only**: it resets on a wrong answer and dies on
      refresh or tab close. The ethos forbids *re-engagement* mechanics,
      chains that pull you back tomorrow. A counter that can't outlive the
      sitting is practice feedback, not a leash. The line, recorded so it
      holds: **nothing about the game persists, so nothing about it can
      summon.** Playing writes zero bytes to storage (verified).
    * *Open/Close lens:* on open, one number and two buttons, first function
      fast. On close, nothing to tidy and nothing held. Walk away mid-run and
      the bench is exactly as you left it.
    * *Engine:* identical in both sibling repos (byte-for-byte, asserted).
      Weighted buckets (obvious / threes / hard composites / primes) per tier
      in one `PC_CONFIG` object; never repeats the previous number. Every
      answer shows the method: `n = p × q` plus p's trick worked on n (chops
      re-applied while ≥100, one step per line so phones don't wrap
      mid-sum), or the root bound plus tappable primes that open their trick
      failing on n. Sheets: one at a time; ✕, backdrop, Escape; ← Back from a
      Checklist trick, never a stacked sheet.
    * *Deviations from the handoff, deliberate:* theme follows CTT's own
      tokens and Cream toggle rather than `prefers-color-scheme` (the
      handoff also says to match the site); muted red is `--danger` mixed
      toward `--muted`; reference "tables" render as grid rows, because the
      mobile surface keeps no `<table>`.
    * *Verified:* 168 primes; all 11 tricks agree with real divisibility on
      every n in 2–999 (10,978 cases) and every composite gets a ✓ worked
      example; spot checks 221/377/403/961/997; 1,000 draws per tier within
      ±2.4 pts of the weights, Hard never below 100 or a multiple of 2/3/5.
      UI suites with real taps: mobile 37/37 at 390×844 (answer buttons
      mid-screen, reference row in the bottom third, every button ≥48px, no
      sideways scroll, refresh → welcome), desktop 35/35. A screenshot caught
      the sheets falling back from monospace (the font variable was scoped
      inside the column the sheets render outside of), fixed and asserted.

* **[2026-10-30] Primes: try it first, then check (Chad's dogfood note).**
  A trick opened from the Checklist mid-question now shows only the trick
  and its generic example, plus **Check my work on n** (toggles to "Hide the
  work"; starts hidden on every open). From the answer screen the work stays
  visible, because the answer is already out. Also: the ✕ takes focus only
  when a sheet was opened from the keyboard (iOS painted the touch-focused ✕
  as a filled orange square), and game buttons get their own hover tint
  instead of the global accent fill that iOS leaves stuck on the last tap.

* **[2026-10-30] Primes becomes a pocket tool, and learns which primes you've
  found (Chad; desktop v0.12.0 / mobile v0.11.0).** *Revises two lines of the
  entry above:* it is no longer a sixth tab, and the game no longer writes
  nothing.
    * *Pocket, not room (Chad changed his mind, and the house pattern
      agrees):* **÷** in the appbar beside ▦ summons it **full screen** over
      any room, with a 48px ✕ in the top-right. Escape closes an open sheet
      first, then the pocket (and yields to app modals). Layer 80: above the
      scratch sheet (70), below modals (99); its own sheets sit at 90. The
      question survives closing; a refresh still starts at the welcome
      screen. `#primes` now opens the pocket over the Opening, and closing it
      clears the hash so the link works again. Five tabs again.
    * *The meter, and the one thing it remembers:* `db.primes.solved =
      {n: 'YYYY-MM-DD'}`, the first day each prime was **called Prime
      correctly**, on any tier. Composites, misses and repeats write nothing;
      a later miss never un-finds a prime. It lives in the synced db (not
      device storage) so iOS eviction can't erase it and it follows Chad to
      desktop. **SCHEMA LOCKSTEP:** the default landed in both repos the same
      hour, verified against a legacy-shaped db with a canary key.
    * *Why a 168-of-168 meter is inside the ethos:* it's **finite and
      completable**, a mirror of mastery like Gertie's car painting itself in,
      not a scoreboard of diligence. No reminders, no "come back," no
      decay. The found sheet keeps unfound primes **dark** (a tile, not the
      number), so it can never spoil a question. You light them by calling
      them.
    * *Verified:* mobile 59/59 and desktop 57/57 with real taps; acceptance
      20/20; engine still byte-identical across repos.

* **[2026-10-30] Checklist tricks close back to the Checklist (Chad's dogfood
  note; desktop v0.12.1 / mobile v0.11.1).** ✕ on a trick opened from the
  Checklist used to close everything, back to the question. Now ✕, the
  backdrop and Escape all close **just the trick** and land on the Checklist,
  ticks intact, and **← Back to checklist** moved from the header to a
  full-width button pinned at the bottom of the sheet (thumb zone). From the
  Checklist itself, ✕ closes all the way. Answer-screen tricks have no
  checklist behind them, so their ✕ still closes completely.

* **[2026-10-30] Primes sheets take the bottom half (Chad; desktop v0.12.2 /
  mobile v0.11.2).** Roots, Prime tricks, Checklist and every trick sheet
  are capped at 50dvh and scroll inside, so the number being worked on
  stays visible while you use them. The backdrop dim dropped from .55 to .3,
  so that number reads clearly instead of fading. Short, sideways screens
  (≤500px tall) get a 60px number so it still clears a half-height sheet.
  Measured: number fully above the sheet at 360×740, 375×667, 390×844,
  430×932, 844×390, 1280×720 and 1440×900.

* **[2026-10-30] v0.12.0 — the pocket FAB: tools in the thumb zone (Chad).**
  *Mobile-only divergence; desktop keeps ▦/÷ in the appbar.* The pocket
  tools left the crowded appbar for one round **✦** button pinned
  bottom-right (above the home-bar safe area). Tap it and Scratch and Primes
  fan out in an arc (100°→170°, up and to the left of the thumb) with labels;
  the button turns to ✕. Tapping a tool, ✕, the scrim, or Escape folds it.
    * *Extensible by construction:* a new pocket tool is one more `.fab-item`
      plus a case in `fabPick`; the arc spaces itself for any count.
    * *Never in the way:* layer 60 (under the pockets at 70/80 and modals at
      99), so an open tool always covers it; pages get bottom padding so the
      button never sits on the last item; it **tucks away while a text field
      is focused**, so it can't float over an input above the iOS keyboard.
    * *Why it suits the PWA:* in standalone mode this is the iPhone-native
      shape, a primary action under the thumb, not a toolbar glyph at the top
      of a tall screen.
    * *Verified* at 390×844 with real touch events: 16/16 FAB checks
      (position, arc geometry, 48px+ targets, labels on screen, both tools
      open, all three ways to fold, the pocket covering it, hide-while-typing),
      plus the Primes suite 63/63 through the FAB.

* **[2026-10-30] Primes: room to breathe (Chad).** The number sat right on the
  top edge of a half-height sheet (11–20px). The question block now has extra
  space below it (`clamp(24px, 11vh, 96px)`), which lifts the number about
  30–40px. Measured: ~50px of air between number and sheet on every portrait
  phone and desktop, answer buttons still mid-screen, sideways phones keep
  their compact layout. *Test scar:* a CDP navigation that only changes the
  `#hash` can reuse the in-memory document, so a "fresh" measurement ran on
  the pre-edit page. Navigate via about:blank (or drop the hash) before
  measuring.

* **[2026-10-30] The pocket FAB goes everywhere and gains the Bell (Chad;
  desktop v0.13.0 / mobile v0.13.0).** *Revises "mobile-only divergence"
  above:* desktop adopts the same bottom-right ✦ button, and ▦/÷ leave its
  appbar too. A third tool joins the arc, **🔔 Bell**, which opens the
  tinker's bell from any room:
    * *Desktop:* calls the existing ⧉ pop-out (Document PiP, always-on-top
      window) directly from the click, so the user gesture holds. If it's
      already floating it says so rather than opening a second window.
      Browsers without Document PiP (Safari, Firefox) jump to the Time Card
      with the bell open.
    * *Mobile:* iOS has no floating windows, so the equivalent is the bell's
      **full-screen mode**. The FAB remembers the room it was opened from,
      shows the Time Card (the full-screen layer lives inside it), grows the
      bell, and ✕ or Escape returns to that room with the timer still
      running.
    * *Labels placed radially:* with three tools, left-hand labels collided
      with neighbours. Each label now sits just outside its own button along
      the arc direction, offset by the label box's reach along that
      direction (|ux|·w/2 + |uy|·h/2), so even the diagonal one clears its
      button. Asserted: zero overlaps at 360, 390, 430 and 1440 widths.
    * *Desktop skips hide-while-typing:* there's no on-screen keyboard to
      dodge, and the Time Card's many inputs would make the button flicker.
    * *Verified:* FAB suites mobile 19/19, desktop 16/16 (PiP path stubbed
      and the no-PiP fallback both exercised); Primes 63/61; acceptance 20/20;
      half-sheet geometry at every size; day map 30/30.

* **[2026-10-31] Primes goes native — `ios/Primes/`, a SwiftUI iPhone app
  (Chad).** The first native code in this repo, and deliberately small: the
  Primes pocket tool as its own app, not a wrap of CTT.
    * *Where (Chad):* a folder in this repo, not a new repo — this
      constitution already homes iOS native here (M2), and Pages publishes
      only `src/`, so the folder can't touch chiaromobile. Moving it to its
      own repo later is a `git mv`.
    * *Progress (Chad):* its own 168-of-168 on the phone (UserDefaults,
      riding the device's iCloud backup). No sync secret in a native binary,
      fully offline, no merge logic. The web game keeps its own count.
    * *Bundle id:* `com.chiarotinkertools.primes` — chosen deliberately on
      day one per the inherited scar. iPhone, portrait, iOS 17+.
    * *Native touches, not a redesign:* the same three screens, sheets as
      true iOS half-height sheets (`.presentationDetents([.medium])`, so the
      number stays in view as Chad asked on the web), success/error haptics,
      light/dark following the phone (Cream in daylight).
    * *Written without a compiler:* download.swift.org is outside this
      sandbox's network policy and SwiftUI is Apple-only anyway, so the first
      real compile happens in Chad's Xcode. Mitigations: the project file
      uses Xcode 16 folder-synchronized groups (tiny, hand-checkable) and was
      parsed and cross-referenced (26 objects, no dangling refs); the engine
      type is `PrimeEngine` (not `Primes`, the module name); and the test
      target carries **web parity** — `web-fixture.json`, generated from the
      live web engine, compares every number 2–999 and all 10,978
      trick-on-number pairs, so any drift in the Swift port fails by name on
      the first ⌘U. `tools/make-fixture.js` regenerates it if the web game
      changes.
    * *Open offer:* if Chad turns on Remote Control for this folder on his
      Mac, Claude can run `xcodebuild` there and fix compile errors directly.
    * *First real compile (Mac mini, Xcode 26.5, iOS 26 simulator): nothing
      broke.* The project opened, built and passed all 10 tests on the
      first `xcodebuild test`, with zero Swift warnings. None of the
      ranked trouble spots fired: no type-checker timeouts, no `Text`
      concatenation or availability errors, and `web-fixture.json` landed
      in the test bundle via the synchronized folder. Checked that the
      green wasn't vacuous: parity asserts all 998 numbers and 10,978
      pairs, and a fixture regenerated from today's `src/index.html`
      (in a scratch copy) is byte-identical to the committed one.
      Screenshots driven by a throwaway XCUITest in a scratch copy of
      the project (simctl can't tap, and AppleScript UI scripting hangs
      behind a macOS Accessibility prompt). Welcome, question,
      answer and all three half-height sheets render as designed, in
      Cream and in dark.
    * *Signing:* `DEVELOPMENT_TEAM = Y3D7LWWL56` (Chad's team, the same
      one kasette-native uses) is now committed, so ⌘R works without the
      Signing step. The team's wildcard profile covers the bundle id. First
      install went to Chad's iPhone 16e over Wi-Fi with a Release build:
      `xcodebuild … -destination 'id=<hardware UDID>' -allowProvisioningUpdates`,
      then `xcrun devicectl device install app`. The scar for next time:
      a `-destination id=` needs the hardware UDID (`xcrun xctrace list
      devices`), not the CoreDevice identifier.
    * *Swipe up to open (Chad):* a swipe up on Roots, Prime tricks or
      Checklist pulls that sheet up, as a second way in beside the tap
      (`swipeUpOpens`, a simultaneous drag, so taps still land). Swipe
      down to close needed no code: it's the native sheet's own drag from
      the grabber. UI-tested on the simulator in a scratch copy: all three
      open by swipe and close by drag, and taps still open them.
    * *Three looks, all kept (Chad):* after a mock-up of three directions,
      Chad kept them all as a picker on the welcome screen, remembered on
      the phone (`primes.theme` in UserDefaults; not progress, so not
      synced). **Lamp** is the original. **Marginalia** is a library at
      night: gilt on green-black, Hoefler Text with old-style figures,
      ivory paper by day, right answers gilt so it keeps one accent.
      **Phosphor** is an 80s terminal: green phosphor, SF Mono, uppercase
      labels, inverse-video selection, faint scanlines, a glow on the
      number. Each look also follows the phone's light/dark setting.
      Built-in iOS fonts only, so nothing third-party is bundled (the
      mock-ups' Garamond and VT323 pixel face stayed on the canvas).
      Mechanism: `Theme` reads a static `style`, and ContentView rebuilds
      its tree with `.id(style)` on a change, so views keep their plain
      `Theme.x` reads. The look is chosen only on the welcome screen, with
      no sheet open.
    * *Back to welcome, more room below (Chad):* a ‹ beside the tier bar on
      the question and answer screens (`Game.home()`: sets the number
      down unanswered, clears the checklist, keeps the streak), and 28 pt
      of bottom padding instead of 12 on every screen, so Play and Next sit
      in the same place.
    * *Scar:* `.accessibilityLabel` on a container of buttons relabels
      every button in it. The UI test caught it: all three look buttons
      read "Look".
    * *The ✦ tool fan (Chad; revises "swipe up to open" above):* the
      bottom row of Roots / Prime tricks / Checklist became a ✦ in the
      bottom-right corner that fans out three round buttons (Roots up,
      Prime tricks on the diagonal, Checklist left), labels placed
      radially as on the web pocket FAB. Swipe-up is gone. The question
      screen re-laid for the thumb: tier bar a little lower (every screen),
      the number higher with a capped gap under it, Prime / Composite lower
      in the room the row used to take. An open fan may cover them, by
      design. *Scar:* the first fan placed its buttons with `.offset`, and
      a UI tap on "Prime tricks" didn't open its sheet; placing everything
      with `.position` in one fixed frame fixed it.
      *Tuned the same day:* the answers sat too low, so they're back up
      under the question (the gap is capped), with the free room below.
    * *How to play, and why primes (Chad):* "New here? How to play ›" on
      the welcome screen opens a full-height sheet (swipe down closes).
      The top is enough to play: the square-root rule, 91 tested live (it
      looks prime; it's 7 × 13), why the square root suffices, what the
      buttons do. Below it, Chad's why, then five beats that pin to the
      screen while the scroll drives the math: 360 splitting into primes;
      Euclid (2·3·5·7 + 1 = 211, prime; and the twist 30031 = 59 × 509,
      both prime; plain "prime" chips, since "new" / "not on the list"
      only made sense to someone who knew the game's tracker); the Ulam
      spiral drawing out to 2,601; 12- vs 17-year cicadas against a
      6-year predator (met 8× vs once in 102 years); RSA (61 × 53 = 3233
      forward, trial division back, then a labelled 617-digit stand-in).
      Ends on 168 and Play. Every figure is checked arithmetic; the
      claims that are theory say so ("one theory", "nobody has proved all
      of it"). Scroll-driven, so the reader sets the pace; the one timed
      animation (91's checks) respects Reduce Motion. *Scar:* a
      GeometryReader can report a zero height on its first pass, and
      `Int(0 / 0)` traps; guard every division by a measured size.
    * *To the App Store (Chad):* listed as **Primes: Prime or Composite**,
      free, Education, 4+, Data Not Collected. Paste-ready listing and the
      6.9" screenshots live in `ios/Primes/AppStore/`. Privacy and support
      page: `src/primes.html` on chiaromobile (a standalone page that
      doesn't touch the app shell; support goes to GitHub issues, so no
      email is published). The build declares
      `ITSAppUsesNonExemptEncryption = NO`. *Blocker hit:* the first App
      Store export failed with `PLA Update available`. Apple issues no
      distribution profile until the account holder accepts the updated
      Program License Agreement, so that step is Chad's.
    * *Submitted (2026-10-31, 00:45 CT):* 1.0 (1) is **Waiting for Review**,
      App Store Connect Apple ID 6829131144. Two Claude sessions finished
      it: Claude Code on the Mac (export, upload) and Cowork with Chad in
      App Store Connect (app record, listing, privacy, rating, price,
      attaching the build). They talked through
      `ios/Primes/AppStore/handoff/` on a side branch, with one writer per
      file and STATUS.md owned by Mac. Cowork couldn't push from its
      environment, so Chad relayed its messages by hand, which worked fine.
      What App Store Connect taught us:
      **"✦" is rejected in text fields** (the listing says "star-shaped");
      the **iPad screenshot slot shows as required until an iPhone-only
      build is attached**, then drops off; a free app needs no Paid Apps
      agreement; `ITSAppUsesNonExemptEncryption = NO` skips the export
      question. The App Review contact lives only in App Store Connect,
      never in this public repo.

* **[2026-10-30] Number Sprouts M1 — math flash cards for Chad's kids
  (Chad; brief from Cowork, `ios/NumberSprouts/BRIEF.md`).** A second native
  app in this repo, on branch `kids-math-v1`: ages 6–8, offline, ad-free,
  family install only (no App Store yet). Bundle
  `com.chiarotinkertools.numbersprouts`.
    * *Name and sound (Chad):* Number Sprouts; haptics only by default.
    * *Structure (Chad, revising the brief):* the home screen picks a concept
      at the top, then a mode named by its skill (Even or Odd: Pair the dots,
      Numbers to 20, Last digit), each with its own stars, instead of a
      Sprout/Grow/Stretch picker, so a kid who has a skill down isn't bored by
      random easy cards. The levels stay under the hood.
    * *M1:* profiles (Who's playing?, add and edit), Even or Odd end to end
      (drag or tap a basket, glow and star burst, shake, Trick card with dots
      pairing or the last digit lit, one retry, 1–3 stars), read-aloud,
      Reduce Motion. Primes' bones, copied then simplified; Primes untouched.
    * *Verified:* 9 unit tests (engine ranges and fairness across 900 seeded
      rounds, every number's parity and trick wording, round rules, per-kid
      progress) and a UI test that plays the whole flow from a fresh install,
      recorded for Chad. The first compile was green.
    * *Icon:* drawn in code (`tools/make-icon.swift`), a blue "2" with a green
      sprout floating just above it (Chad preferred it floating).

## 💡 The Parking Lot (Future Ideas — deliberately open)
* **M1 candidates (waiting on dogfood evidence):** thumb-reach for the main
  tabs · tap-target sizing on the day grid · Blueprint board on a narrow
  canvas · scratchpad keyboard/viewport behavior · pull-to-refresh accidental
  triggers.
* **iOS native wrap (M2)** — bundle id chosen deliberately on day one
  (e.g. `com.chiarotinkertools.mobile`); signing unlocked by Chad's Apple
  Developer account. Gate: PWA supremacy running out of road, not capability.
* **Home-screen widget?** — only if it can be a *lamp* (glanceable, silent),
  never a leash. Not designed; ethos check first.
* **Shared-glyph icon pipeline** — the icon set is rendered from the mask
  glyph via headless Chromium; if the glyph evolves in the desktop repo, re-run
  the render rather than hand-editing PNGs.
* **PJT ↔ CTT ↔ CTT Mobile backport notes** — the sibling-flow log lives in
  the desktop repo's parking lot.
