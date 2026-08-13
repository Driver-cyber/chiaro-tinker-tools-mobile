# CLAUDE.md — Chiaro Tinker Tools Mobile (CTT Mobile)

*Project constitution. Read this first, every session. Then read `DECISIONS.md`
and `chiaro-tinker-tools-mobile-tracker.html` for current state and priorities.*

---

## 🪞 The Repo Split (what this repo is)

CTT lives on two surfaces, in two sibling repos that share one soul:

| Repo | Surface | Owns |
|---|---|---|
| `Driver-cyber/chiaro-tinker-tools` | **Desktop** | Desktop browser experience, Tauri macOS wrap, the original lineage |
| `Driver-cyber/chiaro-tinker-tools-mobile` (this repo) | **Mobile** | Mobile-browser PWA (live), eventually the iOS native surface |

This repo forked from the desktop repo at **CTT v0.5.0 (2026-07-24)** and
restarts its own version line as **CTT Mobile v0.1.x**. The split exists so
each surface can stay *focused* — desktop doesn't carry mobile compromises,
mobile doesn't carry desktop assumptions.

**The bridge between the surfaces is cloud sync** (Worker + KV), not shared
code. Which makes one rule load-bearing:

> **Schema lockstep.** Both repos read and write the same synced `db`
> (`SCHEMA='ctt-1'`, `normalize()` forward-compat). Any schema change or
> `normalize()` migration must be coordinated across both repos — land it on
> both sides (or confirm the other side's `normalize()` tolerates it) before
> merging. A schema that drifts between siblings corrupts the one thing they
> share. Verify with legacy-shaped data, always.

Improvements general enough to flow between siblings go in the backport notes
(see parking lot in the desktop repo's DECISIONS.md). Divergence is allowed —
that's the point of the split — but divergence of the *data model* is not.

Everything below is the shared constitution, inherited whole. Where the
desktop doc says "desktop later," this repo reads "iOS native later."

---

## 🌟 North Star

**Chiaro's real output isn't in Chiaro. It's in the room Chad walks into after
he closes it.**

CTT is a personal digital tool belt and studio — today a timecard + project
journal re-pointed at Chad's ORDO consulting work, eventually a task surface, a
focus timer (the "tinker's bell"), and whatever the belt grows. But the deeper
mission is not productivity. It is **trustworthy closure**: a safe place to set
down everything unresolved — finished or not — so Chad can leave the mind-space
completely and be present with his family and the people in front of him.

Every other tool measures itself by engagement. This one measures itself by how
completely it can be *left*. Success looks like Chad half-forgetting CTT exists
for a few hours because he trusts it to hold what he left there.

The mobile surface sharpens this: a phone is the engagement machine in Chad's
pocket. CTT Mobile must be the one tile on that screen that *wants to be
closed* — quick capture, quick consult, exhale, pocket. Never a feed, never a
pull.

**Two honest ways to be done for today — CTT must make both feel good:**
- **Completed** — wrapped, finished, the quiet pride of mastery as its own reward.
- **Entrusted** — open and unfinishable right now, but set down with just enough
  of a path that it is *bounded* instead of infinite. A lump of clay on a shelf,
  with a note about what it wants to become.

The dread CTT exists to dissolve is not "unfinished" — it is "undefined, and
therefore endless." Convert infinite into bounded, and the peace follows.

## 🔦 The Open/Close Lens (design test for every feature)

For every screen, tool, and feature, answer two questions:

1. **On open:** What is Chad looking for? Orientation, the one next thing, a
   lamp on the chaos. First function, fast.
2. **On close:** How should it feel to put down? Held, content, free to go.

**If a feature can't answer the second question, it probably doesn't earn its
place.** When proposing new features, state both answers explicitly.

## 🚫 Anti-Engagement Ethos (non-negotiable)

- No streaks, badges, gamification, or re-engagement mechanics. Ever.
- **No push notifications.** On mobile this becomes explicit: the platform will
  offer them; CTT never uses them to summon. (A future tinker's bell ringing a
  timer *Chad set minutes ago* is a tool; "come back to your journal" is a leash.)
- No guilt: no "you haven't logged today," no red dots, no nagging.
- Closing is a success state, not a churn event. It should feel like an exhale.
- Update plumbing follows the same ethos: new deploys arrive silently on the
  next online open — no "update available" banners.

## 🎨 Aesthetic & Voice

- **Chiaroscuro, taken literally:** dark is the *material*, not a mode. Near-black
  field, honored and present. **One warm accent** — a lamp in real dark.
- **Clutter has a home — the edges.** Trinkets, motifs, personality live in
  empty states and naming choices; the *working surfaces* stay crisp. On a
  phone's small canvas this line matters double.
- **Voice:** earnest, literate, a little myth-soaked, unpretentious.
  Ordo ab chao. Light and dark in concert, not several.
- The focus timer, when it arrives, is a **tinker's bell** — never "pomodoro."
- Internal shorthand: **CTT Mobile**. The app may wink at itself as CTT.

## 🛠 Tech Stack (with rationale)

| Layer | Choice | Why |
|---|---|---|
| App | **Single-file HTML** (`src/index.html`) — all markup, CSS, JS inline | Inherited from PJT→CTT and proven: portable, rollback-safe, debuggable in a plain browser, no build loop |
| Framework | **None.** Vanilla JS, one in-memory `db` object | Small surface, no bundler, matches house default |
| State | Single JSON `db` with schema version + `normalize()` | Shared with the desktop sibling — see Schema lockstep above |
| Persistence | `localStorage` (`ctt_v1`) + one-tap JSON export/import + cloud sync (Worker+KV, runtime-config, no secrets) | Same seam as desktop; sync is the sibling bridge |
| PWA | `manifest.webmanifest` + `sw.js` + `icons/` — the only companion files; the app itself stays one file | The iPhone on-ramp. SW caches the shell only, network-first navigations, never touches data or the sync origin |
| Web deploy | **Cloudflare Pages**, auto-deploy from GitHub `main` (build output dir: `src`) | House default; zero secrets in this path |
| Native (later) | iOS wrap when PWA supremacy runs out of road (bundle id chosen deliberately on day one, e.g. `com.chiarotinkertools.mobile`) | Apple Developer account exists; the gate-opener is real need, not capability |
| Repo | `Driver-cyber/chiaro-tinker-tools-mobile` | Public repo; no secrets in source, ever |

## ⚖️ Non-Negotiables

1. **One-tap export from day one.** Never regresses.
2. **Keep the storage seam clean.** All persistence flows through the one
   write/read boundary (`save()`/boot). Do not scatter direct `localStorage`
   calls. The service worker stays out of the data path entirely.
3. **Schema version + `normalize()`**, verified with legacy-shaped data on any
   migration — and coordinated with the desktop sibling (Schema lockstep).
4. **No secrets in the repo or any distributable.** Runtime injection only;
   credentials stripped from every backup and export. Chad's `SYNC_SECRET`
   lives only in Cloudflare + his devices — never ask for it.
5. **Off-device durability is a standing gate for phone-as-primary.** iOS can
   evict PWA storage. Cloud sync cleared this gate (2026-07-21) — keep it
   cleared: any change that could silently break sync on iOS is a blocker.
6. **Anti-engagement ethos** (above) is architecture, not polish.
7. **Original assets only.** No third-party IP.

## 🗺 Phases (mobile line)

- **M0 — Founding PWA (v0.1.0).** The desktop app at v0.5.0, made a true
  installable PWA: manifest, service worker (offline shell, silent updates),
  mask-glyph icon set, iOS standalone chrome + safe-area handling. Deployed on
  Cloudflare Pages. Ships before any mobile-specific redesign — dogfood first.
- **M1 — Mobile ergonomics.** Discovered through dogfooding, not speculated:
  thumb-reach, tap targets, the day-grid and Blueprint on a narrow canvas,
  keyboard behavior in scratchpads. Let real friction write the backlog.
- **M2 — iOS native (parked).** Only when PWA supremacy runs out of road.
  New bundle identifier chosen deliberately; signing/notarization unlocked by
  Chad's Apple Developer account.

## 🧗 Inherited Scars (from PJT/CTT — the ones that apply here)

- **Green build ≠ working app.** A deployed page proves nothing about the SW,
  install, or offline behavior. Real test: install to home screen → airplane
  mode → open → the room is still there.
- `window.prompt()` is unreliable in WebViews — use in-app modals (already the
  house pattern).
- Rolling daily backups beat a single overwriting file.
- Service worker versioning is part of the release: bump the `CACHE` name in
  `sw.js` with the subtitle + JS header on release-worthy builds.
- When iOS native arrives, re-read the desktop repo's Tauri scars
  (`withGlobalTauri`, bundle-identifier data nesting, CSP allowlists) — same
  genus of trap.

## 🧠 Memory & Strategy

- **Read first:** `DECISIONS.md` here; the desktop repo's `DECISIONS.md` for
  pre-fork history and shared-parking-lot items.
- **Measure twice:** propose a plan before any multi-file or structural change
  and wait for explicit approval ('y' / 'go'). Rules are defaults, judgment is
  primary.
- **Pivots:** if a request contradicts prior decisions, ask "are we pivoting?"
- **Token thrift:** targeted reads over recursive scans; the app is one big
  file — use anchors/greps.
- **"idk" is a valid stance.** Name assumptions; prefer reversible moves.
- **Push back.** Chad drives product decisions and wants honest technical
  pushback.


## ⚙️ Session-End Protocol

**Canonical body lives in chad-wiki:**
[`session-end-protocol.md`](https://chadwiki.chadstewartcpa.com/?doc=session-end-protocol.md).
That page is the full *why*; the hooks and the checklist below are the
executable minimum.

> **Scar (2026-08-13):** the user-level `/session-end-protocol` skill does not
> travel to remote/cloud sessions, and `chadwiki.chadstewartcpa.com` is blocked
> by the sandbox egress policy (proxy returns 403). Five sessions running, both
> the skill and the fetch have failed. **Single-sourcing to a place the session
> cannot reach is absence, not single-sourcing** — hence the duplicated
> checklist below. Duplicate the minimum, never the whole document.

**Trigger phrases:** *"shipped X, next Y"*, *"session-end"*, *"wrap up"*,
*"close out"*, *"add to backlog: Z"*.

If the skill IS available, invoke it — it reads the hooks below. If it is not,
run the checklist by hand. Both paths land in the same place.

### Per-project hooks

| Hook | Value |
|---|---|
| Tracker filename | `chiaro-tinker-tools-mobile-tracker.html` |
| Learned-log path | **`project-dashboard/learned-log.json`** — central, not in this repo |
| Commit-message tag | `[<area>]` — recent use: `[schema]`, `[sync]`, `[docs]`. Match `git log --oneline -5` |
| Deploy target | Cloudflare Pages, auto-deploys from `main` → `chiaromobile.chadstewartcpa.com` (build output dir: `src`) |
| Test suite | Lives in the **desktop** repo (`chiaro-tinker-tools/test/`) and runs against this build. One copy on purpose — a drift-guard that can itself drift is not a guard |
| Sibling | `chiaro-tinker-tools` — **schema lockstep**: land db-shape changes on both the same day |
| Release extras | Bump `src/sw.js` `CACHE` in step with the version |
| Inbox source | N/A here — capture lives in the dashboard |

### The checklist (run this when the wiki is unreachable)

1. **Tracker** — update the `#tracker-data` JSON block, and bump `updated` in
   **both** the visual header and the JSON. The page hydrates from JSON on
   load; do not hand-edit the static `<ol>`/`<ul>` fallback lists.
2. **DECISIONS.md** — only if a decision was actually made. Write it as a
   standing rule for future sessions, not as history.
3. **Learned-log** — append one entry to the **central** log (see hooks). This
   repo has none of its own, deliberately: the dashboard's Galaxy tab fetches
   only `./learned-log.json` from `project-dashboard`, so a per-repo log would
   be write-only.
4. **Version bump** if the build is release-worthy — app subtitle + JS comment
   header + `sw.js` `CACHE` name, together.
5. **Verify** — run `npm test` from the CTT repo root, and leave the branch
   clean and pushed.
6. **Inbox sweep** — currently impossible from remote sessions (same 403 as
   the wiki). Note it as skipped rather than silently dropping it.

## 📝 Maintenance Protocol

- After a major pivot or completed phase, ask: "Should I update DECISIONS.md?"
- **Tracker:** update `chiaro-tinker-tools-mobile-tracker.html` at the end of
  any session that completes or changes priorities. Bump the `updated` date in
  both the visual header and the JSON data block.
- **Version-bump on release-worthy builds:** app subtitle + JS comment header
  + `sw.js` `CACHE` name, together.
- **Schema changes:** see Schema lockstep — never in one repo alone.
- **Red team at phase gates and after time gaps**, per house convention:
  argue against recent decisions; land each in Confirmed / Revised / Scheduled.
