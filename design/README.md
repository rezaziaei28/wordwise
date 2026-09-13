# Design documents

This project is developed **design-first, in phases**. Every phase produces a
document here; code is only written against an accepted document. When reality
disagrees with a document, the document is updated first.

| # | Phase | Document | Status |
|---|-------|----------|--------|
| 0 | Decision log | [00-decisions.md](00-decisions.md) | living |
| 1 | Baseline understanding | [01-baseline.md](01-baseline.md) | accepted |
| 2 | Wordlist | [02-wordlist.md](02-wordlist.md) | accepted |
| 3 | Tech stack & architecture | [03-tech-stack.md](03-tech-stack.md) | accepted |
| 4 | MVP specification | [04-mvp.md](04-mvp.md) | M1–M4 built, M5 pending |
| 5+ | Statistics, sharing, sync | later | not started |

## Conventions

- One document per phase, numbered. A document is *accepted* when the owner says
  so; after that, changes go through the decision log.
- Decisions with lasting consequences get an entry in `00-decisions.md`
  (short ADR format: context, decision, consequences).
- Open questions are collected at the end of each document under
  **Open questions** and moved to the decision log once answered.
