"""Fetch the Wikipedia article wikitext for a set of AFCON tournaments.

    python3 fetch_wikipedia_afcon.py 1996 1998
    python3 fetch_wikipedia_afcon.py "2023 Africa Cup of Nations Group F"

Wikitext, not rendered HTML, because the match data lives in `{{football box}}`
templates whose arguments are exactly the fields we want -- date, teams, score
and a goal list with minutes. The rendered page throws the structure away.

Raw pages land in raw/afcon_wikipedia/ and are never parsed here; that is
normalize_wikipedia_afcon.py's job, so a parser change never needs a refetch.
"""
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

OUT = Path(__file__).parent / "raw" / "afcon_wikipedia"
# A real contact, per Wikimedia's User-Agent policy.
UA = "sokabrain-ingest/1.0 (local football archive research; kimollomick17@gmail.com)"

# Both spellings exist across the years, and the wrong one serves a redirect.
TITLES = ["{year}_African_Cup_of_Nations", "{year}_Africa_Cup_of_Nations"]


def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read().decode("utf-8", "replace")


def page(title):
    """Fetch one article by its exact title, for pages that are not a whole
    tournament -- the modern articles keep their match reports on group
    subpages, e.g. "2023 Africa Cup of Nations Group F"."""
    out = OUT / (title.replace("/", "_") + ".wikitext")
    if out.exists() and out.stat().st_size > 2000:
        print(f"  {title}: already have {out.name} ({out.stat().st_size} bytes)")
        return
    url = "https://en.wikipedia.org/w/index.php?" + urllib.parse.urlencode(
        {"title": title.replace(" ", "_"), "action": "raw"})
    text = fetch(url)
    if len(text) < 500 or text.lstrip().upper().startswith("#REDIRECT"):
        raise SystemExit(f"{title}: redirect or stub ({len(text)} bytes)")
    out.write_text(text)
    print(f"  {title}: wrote {out.name} ({len(text)} bytes)")


def tournament(year):
    out = OUT / f"{year}.wikitext"
    if out.exists() and out.stat().st_size > 5000:
        print(f"  {year}: already have {out.name} ({out.stat().st_size} bytes)")
        return
    for pattern in TITLES:
        title = pattern.format(year=year)
        url = "https://en.wikipedia.org/w/index.php?" + urllib.parse.urlencode(
            {"title": title, "action": "raw"})
        try:
            text = fetch(url)
        except Exception as exc:                                  # noqa: BLE001
            print(f"  {year}: {title} failed ({exc})")
            continue
        # A redirect stub is a few dozen bytes and names its target; keep looking.
        if len(text) < 5000 or text.lstrip().upper().startswith("#REDIRECT"):
            print(f"  {year}: {title} is a redirect or stub, trying the next spelling")
            continue
        out.write_text(text)
        print(f"  {year}: wrote {out.name} ({len(text)} bytes) from {title}")
        return
    raise SystemExit(f"Could not fetch a real article for {year}")


def main(years):
    OUT.mkdir(parents=True, exist_ok=True)
    for i, arg in enumerate(years):
        if i:
            time.sleep(1)                     # be a good citizen
        # A bare year means a whole tournament; anything else is an exact title.
        if arg.isdigit():
            tournament(arg)
        else:
            page(arg)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    main(sys.argv[1:])
