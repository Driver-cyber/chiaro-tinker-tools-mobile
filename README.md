# Chiaro Tinker Tools — Mobile (CTT Mobile)

The **mobile surface** of [Chiaro Tinker Tools](https://github.com/Driver-cyber/chiaro-tinker-tools) —
a personal tool belt & studio: timecard, project journal, and trustworthy
closure. This repo is the mobile-browser PWA (and, someday, the iOS native
surface); the sibling repo stays focused on the desktop browser and desktop
native builds.

Forked from the desktop repo at CTT v0.5.0 (2026-07-24). The two surfaces
share one soul — same constitution, same data schema — and meet through cloud
sync (Cloudflare Worker + KV, configured at runtime by a one-paste sync code).

> **No secrets live in this repo.** Sync credentials are entered at runtime
> and stored per-device only; they are stripped from every export and backup.

## Repo layout

```
src/index.html                   the app (the whole thing, single file)
src/manifest.webmanifest         PWA manifest
src/sw.js                        service worker — offline shell, silent updates
src/icons/                       mask-glyph icon set (regular, maskable, apple-touch)
CLAUDE.md                        project constitution (read first)
DECISIONS.md                     decision log (post-fork; pre-fork history in the sibling repo)
chiaro-tinker-tools-mobile-tracker.html   build tracker
```

## Deploy

Cloudflare Pages auto-deploys `main`; the build output directory is `src`
(no build step — the directory is served as-is).

**Canonical door: https://chiaromobile.chadstewartcpa.com** (custom domain,
added 2026-07-25). The `chiaro-tinker-tools-mobile.pages.dev` alias serves the
same build, but PWA installs, localStorage, and the sync-code config are all
**per-origin** — install from the custom domain and stay there, so the data
and the home-screen app live on the address that's meant to last.

## PWA notes

- The service worker caches the **app shell only** — never user data, never
  the sync origin. All state lives in `localStorage` behind the app's single
  storage seam, with the KV cloud copy as the durable one.
- Navigations are network-first: new deploys arrive silently on the next
  online open. No update banners — the anti-engagement ethos applies to
  plumbing too.
- On release-worthy builds, bump the version in three places together: the
  app subtitle, the JS header comment, and the `CACHE` name in `sw.js`.
