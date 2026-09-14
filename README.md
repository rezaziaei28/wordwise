# Wordwise

A mobile flashcard app for intermediate English learners: the ~40,000 most
frequent English words, meaning and General American pronunciation, one
swipeable card at a time, most common first. Open source (MIT); data from
permissively licensed sources.

## Why

This is, first of all, my own practice tool.

It bothers me to be reading an article, a book or a post on social media and
hit a word I simply do not know. A native speaker reading that same page knows
essentially every word on it — meaning *and* pronunciation — without thinking
about it. That gap is what I want to close.

So the idea is simple: take the words a "normal" native speaker knows, order
them by how common they actually are, and work through them. Whatever I
already know I retire in one swipe; whatever I don't, the app keeps bringing
back until I do.

It is built to solve my problem first, but the same gap is not mine alone —
so I plan to publish it properly for other people to use soon.

## Layout

- [`design/`](design/) — design-driven development: baseline, wordlist,
  tech stack, MVP spec, decision log.
- [`data/`](data/) — reproducible pipeline that builds `words.sqlite`.
- [`app/`](app/) — the Flutter app (iOS + Android).
