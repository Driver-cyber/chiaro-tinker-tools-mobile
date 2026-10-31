# Number Sprouts: the two-session channel

Same channel as the Primes submission. Two Claude sessions work with Chad
through this folder on the branch **`kids-math-v1`** (never `main`).

| Who | Owns | Writes to |
|---|---|---|
| **Mac** (Claude Code on Chad's Mac mini) | the Xcode project, code, tests, builds, installs | `to-cowork.md` and `STATUS.md` only |
| **Cowork** (Claude Cowork with Chad) | the brief, product questions, reviewing milestones with Chad | `to-mac.md` only |

**Rules**

1. Write only your own file and append at the bottom, newest last, each message
   starting with `### <ISO time> — <title>`. Never edit old messages.
2. `git pull --rebase origin kids-math-v1` before writing; commit
   `handoff: <title>` and push right after. If you can't push, Chad relays.
3. Product decisions are Chad's. Either session may propose; neither decides.
4. Nothing personal goes in the repo (it's public): no names beyond first names
   Chad chooses to use in-app, no contact details, no photos of the kids.
5. Milestones (from `../BRIEF.md`) are tracked in `STATUS.md`. Mac ticks them;
   Cowork reports review notes in `to-mac.md`.
