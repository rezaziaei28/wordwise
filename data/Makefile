# Wordlist data pipeline. `make all` rebuilds build/words.sqlite from scratch.
PY := .venv/bin/python
KAIKKI_URL := https://kaikki.org/dictionary/English/kaikki.org-dictionary-English.jsonl.gz
CMUDICT_URL := https://raw.githubusercontent.com/cmusphinx/cmudict/master/cmudict.dict

.PHONY: all venv download report clean

all: build/words.sqlite report

venv: .venv/bin/python
.venv/bin/python:
	python3 -m venv .venv && .venv/bin/pip install -q -r requirements.txt

download: raw/kaikki-en.jsonl.gz raw/cmudict.dict
raw/kaikki-en.jsonl.gz:
	mkdir -p raw && curl -L -o $@ $(KAIKKI_URL)
raw/cmudict.dict:
	mkdir -p raw && curl -L -o $@ $(CMUDICT_URL)

build/01_frequency.tsv: .venv/bin/python pipeline/s01_frequency.py pipeline/common.py
	$(PY) pipeline/s01_frequency.py
build/02_lexicon.jsonl: .venv/bin/python raw/kaikki-en.jsonl.gz pipeline/s02_lexicon.py
	$(PY) pipeline/s02_lexicon.py
build/03_lemmas.tsv: build/01_frequency.tsv build/02_lexicon.jsonl pipeline/s03_lemmatize.py pipeline/common.py
	$(PY) pipeline/s03_lemmatize.py
build/words.sqlite: build/03_lemmas.tsv raw/cmudict.dict pipeline/s04_build_sqlite.py
	$(PY) pipeline/s04_build_sqlite.py
report: build/words.sqlite pipeline/s05_report.py
	$(PY) pipeline/s05_report.py

clean:
	rm -rf build

# Copy the built dictionary into the Flutter app's assets.
APP_ASSETS := ../app/assets
install-app: build/words.sqlite
	mkdir -p $(APP_ASSETS)
	cp build/words.sqlite $(APP_ASSETS)/words.sqlite
	sqlite3 build/words.sqlite "select value from meta where key='built'" > $(APP_ASSETS)/words.version
	@echo "installed $$(cat $(APP_ASSETS)/words.version)"
