"""Step 5: measurements for design/02-wordlist.md → build/05_report.md"""
import random
import sqlite3

from common import BUILD, REPORT_MD, WORDS_SQLITE

random.seed(42)


def main() -> None:
    db = sqlite3.connect(WORDS_SQLITE)
    out = []
    n, size = db.execute("select count(*) from word").fetchone()[0], WORDS_SQLITE.stat().st_size / 1e6
    out.append(f"# Wordlist build report\n\nwords: {n:,} · words.sqlite: {size:.1f} MB\n")
    out.append("## Per band (1,000 words each)\n")
    out.append("| band | ranks | zipf range | proper % | abbrev % | IPA % | example % | avg senses | sample |")
    out.append("|---|---|---|---|---|---|---|---|---|")
    for band in range(1, 41):
        r = db.execute("""select min(rank), max(rank), min(zipf), max(zipf),
                                 avg(is_proper)*100, avg(ipa is not null)*100, avg(is_abbrev)*100
                          from word where band=?""", (band,)).fetchone()
        ex = db.execute("""select avg(example is not null)*100, count(*)*1.0/(select count(*) from word where band=?)
                           from sense s join word w on w.id=s.word_id where w.band=?""", (band, band)).fetchone()
        sample = [row[0] for row in db.execute("select lemma from word where band=? order by random() limit 12", (band,))]
        out.append(f"| {band} | {r[0]}–{r[1]} | {r[3]:.2f}–{r[2]:.2f} | {r[4]:.0f} | {r[6]:.0f} | {r[5]:.0f} | {ex[0]:.0f} | {ex[1]:.1f} | {', '.join(sample)} |")
    out.append("\n## Totals\n")
    for k, v in db.execute("select ipa_source, count(*) from word group by 1"):
        out.append(f"- IPA source `{k}`: {v:,}")
    out.append(f"- proper nouns: {db.execute('select sum(is_proper) from word').fetchone()[0]:,}")
    out.append(f"- abbreviations: {db.execute('select sum(is_abbrev) from word').fetchone()[0]:,}")
    out.append("\n## Cumulative share of running text covered (wordfreq mass of the list's tokens)\n")
    total = db.execute("select sum(power(10, zipf)) from word").fetchone()[0]
    for cut in (1000, 2000, 5000, 10000, 20000, 30000, 40000):
        m = db.execute("select sum(power(10, zipf)) from word where rank<=?", (cut,)).fetchone()[0]
        out.append(f"- top {cut:,}: {m/total*100:.1f} % of the 40K list's mass, band-{cut//1000} zipf ≥ {db.execute('select min(zipf) from word where rank<=?', (cut,)).fetchone()[0]:.2f}")
    out.append(f"- senses: {db.execute('select count(*) from sense').fetchone()[0]:,}, with example: {db.execute('select count(*) from sense where example is not null').fetchone()[0]:,}")
    out.append(f"- forms: {db.execute('select count(*) from form').fetchone()[0]:,}")
    out.append("\n## Missing IPA, by band\n")
    rows = db.execute("select band, count(*) from word where ipa is null group by 1").fetchall()
    out.append(", ".join(f"b{b}:{c}" for b, c in rows))
    out.append("\n## Most frequent dropped tokens (not in Wiktionary)\n")
    with (BUILD / "03_dropped.tsv").open() as fh:
        next(fh)
        toks = [line.split("\t")[0] for _, line in zip(range(80), fh)]
    out.append(", ".join(toks))
    REPORT_MD.write_text("\n".join(out) + "\n")
    print(REPORT_MD)


if __name__ == "__main__":
    main()
