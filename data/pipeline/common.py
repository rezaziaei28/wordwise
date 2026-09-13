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
# frequent enough to count as general knowledge. zipf 3.3 ≈ rank 15,000 in
# the ranked lemma list. Set to 0.0 to keep them all (D-005 as first stated).
PROPER_MIN_ZIPF = 3.3
ABBREV_MIN_ZIPF = 3.3


def ensure_dirs() -> None:
    RAW.mkdir(exist_ok=True)
    BUILD.mkdir(exist_ok=True)
