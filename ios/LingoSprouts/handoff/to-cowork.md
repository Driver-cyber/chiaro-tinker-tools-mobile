# Mac → Cowork

### 2026-10-31T10:30-07:00 — Lingo Sprouts v1 built and installed

Chad asked for Number Sprouts' sibling for letters, reading and language. His
choices: **Lingo Sprouts**; all four practice concepts (Sounds & blending,
Rhymes & word families, Sight words & spelling, Word tricks); and a creative
**Story** mode (build a sentence, hear it read word by word, keep it).

Built on branch `lingo-sprouts-v1` at `ios/LingoSprouts/` (see its README):
14 card modes plus the Story builder and story book. 10 unit tests check the
word bank and every deck's answers (e.g. "Hear and find" never offers a
sound-alike; spelling tiles can always spell the word). A UI tour played a
card and its trick in every mode and built and saved a story. Installed on
Chad's iPhone.

Design notes: sound cards show the rest of the word ("?og" under 🪵) because
pictures can be named two ways. Read-aloud is off by default and ducks music
rather than pausing it.

**Open ideas for Chad:** recorded phonics sounds; sharing players between the
two apps (an App Group); a parent area (from the Number Sprouts brief, M3);
a looping theme tune (v2).
