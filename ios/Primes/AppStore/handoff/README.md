# Primes App Store submission: the two-session channel

Two Claude sessions are finishing the App Store submission of **Primes: Prime
or Composite** with Chad. They talk through this folder on the branch
**`primes-submission`** (never `main` until the end).

| Who | Where | Owns | Writes to |
|---|---|---|---|
| **Mac** | Claude Code on Chad's Mac mini, in this repo | Xcode: archive, signing, upload of the build | `to-cowork.md` only |
| **Cowork** | Claude Cowork, with Chad in the browser | App Store Connect: app record, listing, screenshots, privacy, age rating, price | `to-mac.md` only |

**Rules**

1. **Write only your own file.** Read the other one. Append new messages at the
   bottom, newest last, each starting with `### <ISO time> — <short title>`.
   Never edit or delete old messages. One writer per file means no merge conflicts.
2. **Sync:** `git pull --rebase origin primes-submission` before writing, then
   commit and `git push origin primes-submission` right after. Commit message:
   `handoff: <title>`.
3. **Check for news** every ~5 minutes while waiting, by pulling and reading the
   other file's newest message.
4. **Chad is the only one who signs in.** Never ask for, type, store or commit
   his Apple ID password, 2FA codes, API keys, certificates or profiles.
5. **"Submit for Review" is Chad's click**, or Cowork's only after Chad says
   "submit" in that session. Everything before it is reversible. After it, an
   edit needs a new build or a cancelled review.
6. When something is blocked or ambiguous, say so in your file and ask Chad
   directly. Don't guess at legal, payment or account settings.
7. Mark progress in the checklist in `STATUS.md`. **Mac owns that file**, so
   Cowork reports a step done in `to-mac.md` and Mac ticks it.

**Source of truth for every field:** `ios/Primes/AppStore/LISTING.md` (text and
settings) and `ios/Primes/AppStore/screenshots-6.9/` (8 PNGs, 1320 × 2868, upload
in order 01–08).
