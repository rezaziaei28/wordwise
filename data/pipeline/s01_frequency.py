"""Step 1: dump the top-N English tokens from wordfreq with their frequency.

Output: build/01_frequency.tsv  (token, zipf, freq_per_billion)
"""
import re

from wordfreq import top_n_list, word_frequency, zipf_frequency

from common import FREQUENCY_TSV, TOKEN_POOL, ensure_dirs

TOKEN_RE = re.compile(r"^[a-z][a-z'\-]*$")


def keep(token: str) -> bool:
    if not TOKEN_RE.match(token):
        return False
    if len(token) == 1 and token not in ("a", "i"):
        return False
    if token.startswith("-") or token.endswith("-") or token.startswith("'"):
        return False
    return True


def main() -> None:
    ensure_dirs()
    tokens = top_n_list("en", TOKEN_POOL, wordlist="large")
    kept = 0
    with FREQUENCY_TSV.open("w") as out:
        out.write("token\tzipf\tfreq_per_billion\n")
        for t in tokens:
            if not keep(t):
                continue
            z = zipf_frequency(t, "en", wordlist="large")
            f = word_frequency(t, "en", wordlist="large") * 1e9
            out.write(f"{t}\t{z:.2f}\t{f:.3f}\n")
            kept += 1
    print(f"tokens from wordfreq: {len(tokens)}, kept after filter: {kept}")


if __name__ == "__main__":
    main()
