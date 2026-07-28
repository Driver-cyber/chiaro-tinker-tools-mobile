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
