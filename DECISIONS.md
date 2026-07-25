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
