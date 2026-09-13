"""Shared paths and helpers for the wordlist pipeline."""
from pathlib import Path

DATA = Path(__file__).resolve().parent.parent
RAW = DATA / "raw"
BUILD = DATA / "build"

KAIKKI = RAW / "kaikki-en.jsonl.gz"
CMUDICT = RAW / "cmudict.dict"

FREQUENCY_TSV = BUILD / "01_frequency.tsv"
LEXICON_JSONL = BUILD / "02_lexicon.jsonl"
FORMS_TSV = BUILD / "02_forms.tsv"
US_SPELLING_TSV = BUILD / "02_us_spelling.tsv"
LEMMAS_TSV = BUILD / "03_lemmas.tsv"
WORDS_SQLITE = BUILD / "words.sqlite"
REPORT_MD = BUILD / "05_report.md"

TARGET_SIZE = 40_000
TOKEN_POOL = 300_000

# Proper nouns (obama, london) and abbreviations (usa, nba) are kept only when
# frequent enough to count as general knowledge. zipf 4.0 ≈ rank 5,000 in
# the ranked lemma list (D-011; 3.3 ≈ rank 15,000 was too permissive).
# Set to 0.0 to keep them all (D-005 as first stated).
PROPER_MIN_ZIPF = 4.0
ABBREV_MIN_ZIPF = 4.5

# One- and two-letter lemmas are kept only if listed here or if they are
# genuine all-caps abbreviations above ABBREV_MIN_ZIPF (tv, uk). Everything
# else that short (de, la, st, al, ll, ez, …) is tokenizer debris or foreign.
SHORT_WORDS = {
    "a", "i", "am", "an", "as", "at", "be", "by", "do", "go", "he", "hi", "if",
    "in", "is", "it", "me", "my", "no", "of", "oh", "ok", "on", "or", "ox",
    "so", "to", "up", "us", "we", "ah", "aw", "eh", "um", "uh", "yo", "ma",
    "pa", "ad", "ex", "id", "re", "lo", "ta", "pi", "mr", "dr", "ms", "pm",
}

# Never words: protocol/URL debris, Roman numerals, and tokens whose
# frequency comes from something other than their Wiktionary sense
# (ez, ca, et are Spanish/Latin/abbreviation noise in the corpora).
STOP_RE = r"^(https?|www|com|org|net|[ivxlc]{2,}|ez|ca|et)$"


def ensure_dirs() -> None:
    RAW.mkdir(exist_ok=True)
    BUILD.mkdir(exist_ok=True)
