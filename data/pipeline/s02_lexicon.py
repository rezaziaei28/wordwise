"""Step 2: stream the Kaikki English Wiktionary extract and build

  build/02_lexicon.jsonl   one line per lower-cased lemma:
        {"lemma", "entries": [{"word","pos","is_proper","senses":[...],"ipa_us":[...],"ipa_any":[...]}]}
  build/02_forms.tsv       surface_form \t lemma   (both lower-cased)

A *lemma entry* is a Kaikki entry with at least one sense that is not a
form_of/alt_of link. Everything else contributes only to the form map.
"""
import gzip
import json
import re
import sys
from collections import defaultdict

from common import FORMS_TSV, KAIKKI, LEXICON_JSONL, US_SPELLING_TSV, ensure_dirs

# POS values we accept for lemma entries (Kaikki names).
LEMMA_POS = {
    "noun", "verb", "adj", "adv", "name", "prep", "conj", "det", "pron",
    "intj", "num", "particle", "contraction", "abbrev", "postp", "article",
}
SKIP_SENSE_TAGS = {"obsolete", "archaic", "rare", "dated", "vulgar", "offensive",
                   "derogatory", "misspelling", "nonstandard", "eye-dialect"}
# A form_of / alt_of sense carrying any of these is not a clean inflection or
# spelling variant and must not feed the form map.
BAD_LINK_TAGS = (SKIP_SENSE_TAGS - {"nonstandard"}) | {"dialectal", "Internet", "slang", "informal",
                                   "colloquial", "humorous", "deliberate", "abbreviation",
                                   "initialism", "acronym", "pronunciation-spelling",
                                   "Geordie", "Scotland", "Ireland", "AAVE", "Cockney"}
INFLECTION_TAGS = {"plural", "past", "participle", "present", "comparative",
                   "superlative", "third-person"}
INFLECTING_POS = {"noun", "verb", "adj", "adv"}
WORD_RE = re.compile(r"^[A-Za-z][A-Za-z'\-]*\.?$")
# "Commonwealth and Ireland standard spelling of color." — Kaikki does not
# always turn these into alt_of links, so we parse the gloss as a fallback.
SPELLING_RE = re.compile(r"^(?P<prefix>[A-Za-z ,()\-]*?)\s*(?:standard |alternative )?(?:spelling|form) of (?P<target>[A-Za-z'\-]+)\.?$")
US_PREFIX_RE = re.compile(r"\b(US|American|America)\b")


def clean_gloss(g: str) -> str:
    g = re.sub(r"\s+", " ", g).strip()
    return g


def entry_senses(entry):
    """Return (lemma_senses, form_targets, us_spelling_of) for one Kaikki entry."""
    lemma_senses, targets, us_of = [], [], []
    for s in entry.get("senses", []):
        links = s.get("form_of") or s.get("alt_of")
        glosses = s.get("glosses") or s.get("raw_glosses") or []
        gloss = clean_gloss(glosses[-1]) if glosses else ""
        tags = set(s.get("tags", []))
        if not links and gloss:
            m = SPELLING_RE.match(gloss)
            if m and WORD_RE.match(m.group("target")):
                links = [{"word": m.group("target")}]
                if US_PREFIX_RE.search(m.group("prefix")):
                    tags = tags | {"US"}
                tags = tags | {"alt-of"}
        if links:
            single = [l["word"].lower() for l in links if l.get("word") and WORD_RE.match(l["word"])]
            if single:
                if "contraction" in tags and entry.get("pos") == "contraction":
                    targets.append(single[0])          # I'm → I, don't → do
                elif not (tags & BAD_LINK_TAGS):
                    targets.extend(single)
                    if "alt-of" in tags and ("US" in tags or "American" in tags) and "spelling of" in gloss:
                        us_of.extend(single)           # humor is the US spelling of humour
                continue
            # multi-word target ("Initialism of United States of America"):
            # the gloss itself is the useful definition, keep it as a sense.
        if not gloss:
            continue
        ex = None
        for e in s.get("examples", []):
            t = e.get("text")
            if t and 20 <= len(t) <= 160 and "\n" not in t:
                ex = clean_gloss(t)
                break
        lemma_senses.append({
            "gloss": gloss,
            "tags": sorted(tags & SKIP_SENSE_TAGS),
            "example": ex,
        })
    return lemma_senses, targets, us_of


US_TAGS = {"US", "GA", "General-American", "GenAm", "American"}
RP_TAGS = {"UK", "RP", "Received-Pronunciation", "British"}
NEUTRAL_TAGS = US_TAGS | RP_TAGS | {"Standard", "Canada", "cot-caught-merger"}


def entry_ipa(entry):
    """All IPA transcriptions of an entry, best first: General American strong
    form, then untagged, then RP, then regional; weak/unstressed forms
    (`you` /jə/, `in` /ən/) and phonetic-only [..] forms rank last."""
    ranked = []
    for i, snd in enumerate(entry.get("sounds", [])):
        ipa = snd.get("ipa")
        if not ipa:
            continue
        tags = set(snd.get("tags", []))
        note = (snd.get("note") or "").lower()
        weak = bool(tags & {"unstressed", "weak"}) or "weak" in note or "unstressed" in note
        us, rp = bool(tags & US_TAGS), bool(tags & RP_TAGS)
        regional = bool(tags - NEUTRAL_TAGS) or bool(note and "strong" not in note and "stressed" not in note and not weak)
        tier = 0 if us else 1 if not tags and not note else 2 if rp else 3
        # /jə/ vs /ju/ both tagged GA and neither marked weak: prefer the
        # one with a full vowel.
        vowels = set(re.sub(r"[^aeiouyæɑɒɔəɚɘɛɜɝɪʊʌʏøœɐɨʉ]", "", ipa))
        reduced = bool(vowels) and vowels <= {"ə", "ɚ", "ɘ", "ɨ"}
        ranked.append(((weak, regional, tier, reduced, not ipa.startswith("/"), i), ipa))
    ranked.sort()
    best = ranked[0][0] if ranked else None
    # Flags of the best candidate: [weak, regional, not GA-tagged, reduced].
    # The builder trusts Wiktionary only when all are False, else CMUdict.
    return [ipa for _, ipa in ranked], ([best[0], best[1], best[2] != 0, best[3]] if best else None)


def main() -> None:
    ensure_dirs()
    lexicon = defaultdict(list)          # lower lemma -> entries
    forms = defaultdict(set)             # lower surface -> {lower lemma}
    us_spelling = {}                     # british lemma -> american spelling
    n = 0
    with gzip.open(KAIKKI, "rt", encoding="utf-8") as fh:
        for line in fh:
            n += 1
            if n % 200_000 == 0:
                print(f"  {n:,} entries…", file=sys.stderr)
            e = json.loads(line)
            if e.get("lang_code") != "en":
                continue
            word = e.get("word", "")
            if not WORD_RE.match(word):
                continue
            pos = e.get("pos", "")
            senses, targets, us_of = entry_senses(e)
            lw = word.lower()
            for t in us_of:
                us_spelling.setdefault(t, lw)
            for t in targets:
                if t != lw:
                    forms[lw].add(t)
            if not senses or pos not in LEMMA_POS:
                continue
            if pos in INFLECTING_POS and len(lw) > 1:
                for f in e.get("forms", []):
                    fw = f.get("form", "")
                    ftags = set(f.get("tags", []))
                    if not WORD_RE.match(fw) or not (ftags & INFLECTION_TAGS) or (ftags & BAD_LINK_TAGS) or "alternative" in ftags:
                        continue
                    if fw.lower() != lw:
                        forms[fw.lower()].add(lw)
            for f in e.get("forms", []):        # humour lists humor as its US alternative
                ftags = set(f.get("tags", []))
                fw = f.get("form", "").lower()
                if "alternative" in ftags and "US" in ftags and WORD_RE.match(fw) and fw != lw:
                    us_spelling.setdefault(lw, fw)
            if lw.endswith("."):            # etc. → also reachable as "etc"
                forms[lw[:-1]].add(lw)
            ipa, ipa_flags = entry_ipa(e)
            lexicon[lw].append({
                "word": word,
                "pos": pos,
                "is_proper": pos == "name",
                "senses": senses,
                "ipa": ipa,
                "ipa_flags": ipa_flags,
            })
    with LEXICON_JSONL.open("w") as out:
        for lemma, entries in lexicon.items():
            out.write(json.dumps({"lemma": lemma, "entries": entries}, ensure_ascii=False) + "\n")
    with FORMS_TSV.open("w") as out:
        out.write("form\tlemma\n")
        for f, lemmas in forms.items():
            for l in sorted(lemmas):
                out.write(f"{f}\t{l}\n")
    with US_SPELLING_TSV.open("w") as out:
        out.write("lemma\tus_spelling\n")
        for k, v in us_spelling.items():
            out.write(f"{k}\t{v}\n")
    print(f"kaikki entries: {n:,}; lemmas: {len(lexicon):,}; form links: {sum(len(v) for v in forms.values()):,}")


if __name__ == "__main__":
    main()
