"""Step 3: map frequency tokens to lemmas, aggregate, rank, cut at TARGET_SIZE.

Output: build/03_lemmas.tsv  (rank, lemma, zipf, freq_per_billion, forms, top_token)
        build/03_dropped.tsv (token, freq) tokens that matched nothing in Wiktionary
"""
import json
import re

import simplemma
import math
from collections import defaultdict

from common import (ABBREV_MIN_ZIPF, BUILD, FORMS_TSV, FREQUENCY_TSV, LEMMAS_TSV,
                    LEXICON_JSONL, PROPER_MIN_ZIPF, SHORT_WORDS, STOP_RE, TARGET_SIZE,
                    US_SPELLING_TSV)

ABBREV_RE = re.compile(r"^(Abbreviation|Initialism|Acronym|Clipping|Short form|Short for|Ellipsis) of\b", re.I)
# "A male given name from Hebrew", "A surname", "A diminutive of the male
# given names Alan, Albert…", "Nickname for Alexandria"
STOP = re.compile(STOP_RE)


class Flags:
    """Classification of one lemma from its Wiktionary entries (D-011)."""

    def __init__(self, lemma: str, entries: list):
        es = [e for e in entries if e["senses"]]
        senses = [s for e in es for s in e["senses"]]
        untagged = [(e, s) for e in es for s in e["senses"] if not s["tags"]]
        name_senses = [s for e in es if e["pos"] == "name" for s in e["senses"]]
        other_untagged = [s for e, s in untagged if e["pos"] != "name"]
        all_capitalised = bool(es) and all(e["word"][:1].isupper() for e in es)
        all_upper = bool(es) and all(e["word"].isupper() and len(e["word"]) > 1 for e in es)

        # Names: every entry capitalised, a `name` entry, and the name senses
        # outnumber the untagged common ones (david, chicago, russia, jesus).
        self.is_proper = all_capitalised and bool(name_senses) and len(other_untagged) <= len(name_senses)
        # People (D-011): a given-name sense drops the lemma unless a sense
        # is strongly notable (capital, country, US state, month, …); a
        # surname sense drops it unless an entry has a Wikipedia link *and*
        # a sense is at least a place (obama, lincoln, hamilton stay;
        # taylor, wilson, kennedy, derek, amanda go).
        name_senses = [s for e in es if e["pos"] == "name" for s in e["senses"]]
        given = any(s.get("given") for s in name_senses)
        surname = any(s.get("surname") for s in name_senses)
        notable = max((s.get("notable", 0) for s in senses), default=0)
        wikipedia = any(e.get("wikipedia") for e in es)
        self.is_person = all_capitalised and notable < 2 and (
            given or (surname and not (wikipedia and notable >= 1))
        )
        # Abbreviations: every sense an abbreviation gloss, or every entry ALL CAPS.
        self.is_abbrev = lemma not in SHORT_WORDS and (
            (bool(senses) and all(ABBREV_RE.match(s["gloss"]) for s in senses)) or all_upper
        )
        # Short debris: ≤ 2 letters and neither a listed word nor an all-caps abbreviation.
        self.is_debris = bool(STOP.match(lemma)) or (
            len(lemma) <= 2 and lemma not in SHORT_WORDS and not all_upper
        )


def load_lemmas() -> tuple[set, set, dict]:
    """All lemmas; the *strong* ones (at least one non-proper-noun entry with an
    untagged, not rare/archaic/… sense — centre, a French region + "alt of
    center", and theatre, one rare sense, are lemmas but not strong); and
    per-lemma [Flags]."""
    lemmas, strong, flags = set(), set(), {}
    with LEXICON_JSONL.open() as fh:
        for line in fh:
            o = json.loads(line)
            lemmas.add(o["lemma"])
            entries = [e for e in o["entries"] if e["senses"]]
            if any(e["pos"] != "name" and any(not s["tags"] for s in e["senses"]) for e in entries):
                strong.add(o["lemma"])
            flags[o["lemma"]] = Flags(o["lemma"], entries)
    return lemmas, strong, flags


def load_forms() -> dict:
    forms = defaultdict(set)
    with FORMS_TSV.open() as fh:
        next(fh)
        for line in fh:
            f, l = line.rstrip("\n").split("\t")
            forms[f].add(l)
    return forms


def main() -> None:
    lemmas, strong, flags = load_lemmas()
    forms = load_forms()
    freq_of = {}
    with FREQUENCY_TSV.open() as fh:
        next(fh)
        for line in fh:
            t, z, f = line.rstrip("\n").split("\t")
            freq_of[t] = float(f)

    def resolve(token: str) -> str | None:
        """Follow form links until a strong lemma is reached
        (recognised→recognise→recognize, centres→centre→center). Falls back to
        the last weak lemma seen on the chain."""
        seen, cur, weak = set(), token, None
        for _ in range(4):
            if cur != token and cur in strong:
                return cur
            if cur != token and cur in lemmas and weak is None:
                weak = cur
            if cur not in forms or cur in seen:
                return weak
            seen.add(cur)
            cands = forms[cur]
            sl = simplemma.lemmatize(cur, lang="en").lower()
            cur = sl if sl in cands else max(cands, key=lambda c: freq_of.get(c, 0.0))
        return weak

    agg = defaultdict(float)
    members = defaultdict(list)
    dropped = []
    for token, f in freq_of.items():
        target = None
        cand = resolve(token)
        # A token with its own Wiktionary entry (running, used, could, news)
        # folds only if simplemma independently agrees (running→run) — so
        # could/his/news stay lemmas. A token without one follows the link.
        if cand and (token not in strong or simplemma.lemmatize(token, lang="en").lower() == cand):
            target = cand
        if target is None and token not in lemmas:
            # No usable Wiktionary link: try simplemma's lemma, then a stripped
            # possessive; either must land on a strong lemma (via resolve).
            sl = simplemma.lemmatize(token, lang="en").lower()
            base = token[:-2] if token.endswith("'s") else None
            for c in (sl, base):
                if c and c != token:
                    # a possessive may attach to a proper noun (america's)
                    t = c if c in strong or (c is base and c in lemmas) else resolve(c)
                    if t:
                        target = t
                        break
        if target is None and token in lemmas and not token.endswith("'s"):
            target = token
        if target is None:
            dropped.append((token, f))
            continue
        agg[target] += f
        members[target].append(token)

    us_spelling = {}
    with US_SPELLING_TSV.open() as fh:
        next(fh)
        for line in fh:
            k, v = line.rstrip("\n").split("\t")
            us_spelling[k] = v

    # A British lemma whose US spelling is itself a lemma (favourite/favorite,
    # centre/center) merges into the US one; senses come from the US entry.
    for key in list(agg):
        us = us_spelling.get(key)
        if us and us != key and us in agg:
            agg[us] += agg.pop(key)
            members[us].extend(members.pop(key))
            del us_spelling[key]

    ranked = sorted(agg.items(), key=lambda kv: -kv[1])
    excluded = {"proper": 0, "abbrev": 0, "person": 0, "debris": 0}
    with LEMMAS_TSV.open("w") as out:
        out.write("rank\tlemma\tlex_key\tzipf\tfreq_per_billion\tis_proper\tis_abbrev\tforms\ttop_token\n")
        rank = 0
        for key, f in ranked:
            zipf = math.log10(f) if f > 0 else 0.0  # per-billion → zipf
            fl = flags[key]
            lemma = us_spelling.get(key, key)       # headword in American spelling
            if fl.is_person:
                excluded["person"] += 1
                continue
            if fl.is_debris or STOP.match(lemma):
                excluded["debris"] += 1
                continue
            is_proper, is_abbrev = int(fl.is_proper), int(fl.is_abbrev)
            if is_proper and zipf < PROPER_MIN_ZIPF:
                excluded["proper"] += 1
                continue
            if is_abbrev and zipf < ABBREV_MIN_ZIPF:
                excluded["abbrev"] += 1
                continue
            rank += 1
            if rank > TARGET_SIZE:
                break
            toks = sorted(members[key], key=lambda t: -freq_of[t])
            other = [t for t in toks if t != lemma and not t.endswith("'s")]
            out.write(f"{rank}\t{lemma}\t{key}\t{zipf:.2f}\t{f:.3f}\t{is_proper}\t{is_abbrev}\t{','.join(other)}\t{toks[0]}\n")
    with (BUILD / "03_dropped.tsv").open("w") as out:
        out.write("token\tfreq_per_billion\n")
        for t, f in sorted(dropped, key=lambda x: -x[1]):
            out.write(f"{t}\t{f:.3f}\n")
    print(f"tokens: {len(freq_of):,}; lemmas found: {len(agg):,}; dropped tokens: {len(dropped):,}; "
          f"written: {min(TARGET_SIZE, rank):,}; zipf at cut: {zipf:.2f}; excluded below threshold: {excluded}")


if __name__ == "__main__":
    main()
