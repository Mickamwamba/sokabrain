"""Download RSSSF's African Nations Cup pages for 1957-2000.

    python3 fetch_rsssf_afcon.py raw/afcon_pre2002

One file per tournament, saved as fetched. The pages are small, hand-written
plain text inside minimal HTML, and they change rarely -- re-running skips
whatever is already on disk, so a re-parse never depends on the network.

RSSSF is a volunteer archive; the crawl is one request per second with a
contactable user agent, and 22 files is the whole job.
"""
import sys
import time
import urllib.request
from pathlib import Path

YEARS = "57 59 62 63 65 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 98 00".split()
UA = "sokabrain-ingest/1.0 (personal football vault; contact kimollomick17@gmail.com)"


def main(out_dir: str):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    for year in YEARS:
        target = out / f"{year}.html"
        if target.exists() and target.stat().st_size > 0:
            print(f"{year}: already have it")
            continue
        url = f"https://www.rsssf.org/tables/{year}a.html"
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        body = urllib.request.urlopen(req, timeout=30).read()
        target.write_bytes(body)
        print(f"{year}: {len(body):,} bytes")
        time.sleep(1)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "raw/afcon_pre2002")
