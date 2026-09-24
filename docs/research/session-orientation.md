# Session Orientation

> **Historical note (D54, D55):** this whole note is historical. It was TheBrain's orientation page, and TheBrain is no longer used. It is kept word for word as a record. Current sessions start from `HANDOFF.md` and `CLAUDE.md`; research lives in `docs/research/`.

Read this at the start of every Mo session.

## What this brain is
The Mo Research brain in TheBrain is the research space for Mo, an AI-first, verification-focused programming language. Robert designs; agents build. It is a research experiment, not a product.

## Source of truth
TheBrain is the source of truth for all Mo project documents (decided 2026-09-23). The hosted Claude Docs versions are older frozen copies.

## Where things live
* Big Picture: the working picture of Mo (D20). Its seven children are the areas we design, 1 Spec layer to 7 Ecosystem. This is the only copy; it changes only by decision.
* Thoughts of type Earlier research hold research done before the Big Picture. They are proposals, not decisions, and hang under the areas they feed. Their jumps are named "coupled with" (explore together or in close sequence), "depends on" (the source waits on decisions in the destination) or "tests".
* Parking lot: earlier research outside the seven areas.
* Documents > Design Doc and Documents > Glossary. Use the glossary terms exactly.
* Decisions are recorded only in the repo's docs/DECISIONS.md.
* The mo-v2 repo is public at https://github.com/robertguss/mo-v2. Reference repo docs by URL, e.g. https://github.com/robertguss/mo-v2/blob/main/docs/DECISIONS.md

## Working style Robert has asked for
* Stay high level. Map the territory before getting granular; go deep in one area per session.
* One question at a time.
* Direct, honest feedback over validation.
* Concrete examples over abstractions; explain unfamiliar concepts plainly.

## Terminology to watch
* Say waiver, never exception, for a departure from a rule. Mo has no thrown exceptions.
* Failure = the world misbehaved (handled). Defect = the program misbehaved (stops the unit, reported).

## Working through TheBrain's local API
* The API runs at http://localhost:8001/api while the desktop app is open. Docs: http://localhost:8001/api/index.html
* The key is THE_BRAIN_API_KEY in the mo-v2 repo's fnox.toml. Read it with fnox get, run from the repo folder. Never write the key to a file or print it.
* In notes, start plain bullets with an asterisk. A dash makes an unticked checkbox and a plus makes a ticked one.
* A note update replaces the whole note. Read it first and send back the full text.
