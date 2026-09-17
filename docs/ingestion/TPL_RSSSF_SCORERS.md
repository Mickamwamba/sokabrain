# Premier League scorers from RSSSF

The league had **no scorer at all for twelve of its nineteen seasons** — 5,081
goals. ligikuu holds none before 2023/24 and WhoScored holds none ever, so this
went looking for a third source. RSSSF has one page per Tanzanian season with
round-by-round results and, for some matches, the scorers with minutes and
**full names**.

Coverage went from **36.6% to 41.5%** (3,644 of 8,778 goals), and six seasons
that were flat zero now have real data:

| Season | Before | After | Matches given a log |
|---|---|---|---|
| 2008/09 | 0% | **22%** | 33 |
| 2009/10 | 0% | **35%** | 48 |
| 2010/11 | 0% | **20%** | 25 |
| 2020/21 | 0% | **24%** | 71 |
| 2021/22 | 0% | **3%** | 10 |
| 2022/23 | 0% | **5%** | 10 |

435 goal events across 198 matches, and **no match's log contradicts its score**
— the nine that already did are the recent ligikuu ones and were untouched.

```
fetch_rsssf_tpl.py / curl      season pages -> raw/rsssf_tpl/tanzNN.html
normalize_rsssf_tpl.py         pages -> canonical matches + goals (doctested)
validate_rsssf_tpl.py          canon vs the vault: no writes, reports everything
load_rsssf_tpl_scorers.py      canon -> match_events, with provenance
```

## Why RSSSF and not Flashscore

Flashscore also has this data, back to 2010/11, and was the first candidate. RSSSF
won on every axis that matters:

| | RSSSF | Flashscore |
|---|---|---|
| Access | plain HTTP | 403s plain HTTP; the fast path meant spoofing an API signature |
| Volume | **19 pages** | ~2,400 match pages |
| Names | **full** ("Vitalis Mayanga") | abbreviated ("Dube P.") |
| Earliest | **2007/08** | 2010/11 |

Flashscore remains the only way to reach the six seasons below, if anyone wants
them badly enough.

## What RSSSF does not have

**2011/12 to 2016/17 carry results but no scorers at all** — 2,496 goals. Their
league sections contain date headers and fixtures and nothing else. This is not a
parser gap; there is nothing in the page to parse. 2025/26 is the same.

So the league cannot reach the Africa Cup of Nations' 100% from this source, and
probably not from any: **2,410 of the remaining 5,134 unnamed goals have no known
source anywhere.**

## The parsing, and the bug worth remembering

The scorer grammar is richer than the AFCON pages'. Every form below was found by
surveying all nineteen pages *before* writing the parser, and each is doctested:

| Written | Means |
|---|---|
| `Hassan Kabunda 39` | one goal, 39' |
| `Vitalis Mayanga 3, 20` | **same** player, two goals — a comma-item starting with a digit is another minute, not a new scorer |
| `Stephanie Aziz Ki (3)` | **three** goals, minutes unknown |
| `Salum Chuku 80pen` | penalty |
| `Ayoub Lyanga 90og` / `(og)` | own goal |
| `Peter Mapunda 90+5` | stoppage time, into `added_time` |
| `Shabani 60'(P)` | penalty again, differently decorated |
| `Yona Ndabila 0-2` | the `0-2` is the running score, **not** a minute |
| `?` | a goal whose scorer nobody recorded |

**The bug worth remembering**: the first version read `[Sep 6]` date headers as
scorer lines, inventing a player called "Oct" and over-counting 434 matches. It
also assigned every semicolon-less bracket to the home team, when
`Toto African 0-1 Mtibwa Sugar [Mecky Mexime 2]` is the *away* goal. Together
those two inflated the apparent haul from 503 real goals to 1,944 — which is why
the estimate quoted before the parser was written was more than twice the truth.
Date headers and scorer brackets **cannot be told apart by indentation**: most
pages put both flush left. They are told apart by content — a date header is
exactly `[Mon D]`.

## What is loaded, and what is refused

Only a match whose scorers account for the **whole** score:

- **198 loaded.**
- **8 refused** because RSSSF named only some of the goals. Loading those would
  leave the log disagreeing with the score, the one invariant this league's data
  still holds everywhere. They are counted, not written, and not padded with
  invented events.
- **22 refused** because the vault already had a goal log — this only fills holes.
- **63 refused** on a score that disagrees with the vault. Two sources
  contradicting each other is a reconciliation question, not an overwrite
  (principle 2).
- **432** found no single vault match, 173 of them from 2007/08, a season the
  vault does not hold.

## Player identity

`playermatch.py` resolved the names: 27 matched an existing player exactly, 16 on
a forename, and 235 were created. Only **two** pairs of the 235 turned out to be
duplicates, both because RSSSF itself spells a name two ways across seasons —
"Kisinda" beside "Tuisila Kisinda", "Sabato" beside "Kelvin Sabato". The audit's
Identity checks raised both; neither is merged, because a surname is not evidence.
