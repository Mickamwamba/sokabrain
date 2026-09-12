# Ingestion: the Africa Cup of Nations, 2002 to 2025

Thirteen tournaments, 496 matches, from whoscored.com. This is the first
national-team competition in the vault, and the first ingestion where the
source changes format halfway through.

```
(browser harvest, below)   whoscored.com  -> raw/afcon/fixtures.tsv + events.json
nationnames.py             one canonical name per national team
afcon_rounds.py            stage -> round, and the bracket check that verifies it
normalize_afcon.py         raw -> canonical match records
load_afcon.py              canonical -> vault, with provenance
```

## What was loaded

| | |
|---|---|
| tournaments | 13 (2002, 2004, 2006, 2008, 2010, 2012, 2013, 2015, 2017, 2019, 2021, 2023, 2025) |
| matches | 496 — 444 written, 52 already held as edition 14 |
| goals | 1,121, of which **1,101 (98.2%) name a scorer** |
| editions created | 12, all `is_published = FALSE` |
| players created | 1,020 |

Everything arrives unpublished. Nothing reaches the public site until someone
publishes it in the dashboard, the same gate the 16 new TPL editions went
through.

## The source

`whoscored.com/regions/247/tournaments/104`. Cloudflare 403s plain HTTP, so
this needs a real browser, exactly as the TPL harvest did. Two feeds matter:

* **Fixtures** — `/tournaments/{stageId}/data/?d=YYYYMM`. `d` is mandatory;
  omitting it returns nothing. AFCON drifts across the calendar (2019 in June,
  2021 played in **January 2022**, 2023 in **January 2024**, 2025 into January
  2026), so the harvest probes months rather than assuming any window.
* **Match pages** — `/matches/{id}/live/`, for scorers and cards.

Stage ids per season come from each season page's `#stages` dropdown.

### The stage layout is not uniform

| tournaments | stages | round |
|---|---|---|
| 2002–2017 | 4 groups + quarter finals + semi finals + **bronze match** + final | stated |
| 2019 | 6 groups + `1/8 Finals` + the same four | stated |
| 2021, 2023, 2025 | 6 groups + a single **`Final Stage`** of 16 matches | **not stated** |

2025 also carries an extra `AFCON Grp. Stages` stage, which returns no matches
and is ignored.

### The match page has two entirely different formats

The split is at 2013, and it is not clean — **2015 has the modern format while
2017 does not**.

* `initialMatchDataForScrappers` (2002–2012, 2017; 252 matches) — a terse JS
  array literal with elisions, so it is evaluated rather than JSON-parsed.
  Scorers are a **name only**: no player id, and often just a surname.
* `matchCentreData` (2015, 2019–2025; 240 matches) — the full Opta blob, with
  real player ids, venue, referee, and separate half-time / full-time /
  extra-time / shootout scores.

Four matches have neither: the 2013 semi-finals, third-place match and final
all carry `matchCentreData: null`. Their events were recovered from the stage
fixture feed's `incidents` array, which does carry player names and ids for
them, and are marked `fmt: "feed"`.

## What had to be got right

### Own goals are filed under opposite teams by the two formats

This is the same trap that bit the original migration, and it is live here:

* `matchCentreData` files an own goal under **the scoring player's own team** —
  the vault's convention (principle 5).
* the legacy block files it under **the team it counts for**.

Verified on every own goal in the data. In match 130757 (Egypt 4-1) the four
Egyptian goals sit under home while Egypt defender Abdel el Sakka's own goal
sits under away. Carrying the legacy side across unchanged would have credited
every 2002-2012 own goal to the wrong team. `normalize_afcon.py` flips them so
everything downstream sees one convention.

### `homeScore` already includes extra time, and `etScore` is not what it looks like

The fixture feed's `homeScore` is the **result** score, extra time included, so
it is not the 90-minute score. Worse, the Opta blob's `etScore` is not the
after-extra-time score either: it reports the winner's score against a zero, so
the 2015 quarter-final **Tunisia 1-2 Equatorial Guinea comes back as `0 : 2`**.

What is trustworthy: `ftScore` (genuinely 90 minutes) and the fixture feed's
result. So `home_score` is the 90-minute score, `home_score_et` the result where
extra time was played, and for the legacy format — which states no 90-minute
score — it is reconstructed by dropping goals after minute 90 and then
**checked**, because a match that went to extra time must have been level at 90.

### Shootout kicks are not goals

82 of the 102 penalty-qualified "goals" in the modern format are shootout kicks,
and the legacy format has its own `penaltyshootout-scored` / `-missed`. All are
dropped; the shootout lives in `home_score_pens` / `away_score_pens`. Recording
them would have double-counted every shootout.

### `elapsed` is unreliable

Matches are labelled `PEN` that never went to a shootout — the 2002 semi-final
Nigeria 1-2 Senegal was the golden-goal game. Nothing is derived from `elapsed`;
the score fields decide.

### Rescinded cards

`VoidYellowCard` marks a booking later withdrawn. Those are dropped rather than
written as yellows.

### Togo's three 2010 matches were never played

The three status-7 rows in 2010 Group B are Togo's, abandoned after the attack
on the team bus in Cabinda. They load as `CANCELLED` with no score, not as
scoreless full-time games.

## Deriving the knockout round, and proving it

For 2021, 2023 and 2025 the round is not in the data. `afcon_rounds.py` orders
the 16 `Final Stage` matches by kickoff and takes 8 / 4 / 2, then identifies the
last two by **who is playing in them**: the final is contested by the two
semi-final winners, the third-place match by the two losers. Penalty shootouts
decide who advanced, never the goal total.

It then verifies the whole ladder — every quarter-finalist must have won a
round-of-16 tie, every semi-finalist a quarter-final — and **raises rather than
guessing** if any of it fails. The same check was run against the nine
tournaments where WhoScored states the round, and all nine pass.

## Players

Identity comes from the WhoScored player id where the source gives one. The
2002-2012 and 2017 pages name a scorer but carry no id, so those are keyed by
**(name, national team)**, which is safe because a player turns out for one
country. Checked before relying on it: across all 13 tournaments only one
(name, team) pair spans more than eight years — Asamoah Gyan for Ghana, who is
genuinely one player. No single-token name spans more than six.

15 name-keyed scorers resolved onto players already in the vault from the legacy
2019 edition (Mohamed Salah, Riyad Mahrez, John Obi Mikel and others) rather
than being duplicated.

## What was deliberately left out

* **Substitutions.** 2,666 are in the harvest and none were loaded: the vault
  has never stored one, nothing reads them, and the modern format pairs them
  across two rows. They stay in `raw/afcon/events.json`.
* **Referees.** `matches.referee_id` points at `coaches`, and filing match
  officials as coaches is a modelling decision, not an ingest one.
* **Lineups.** Available for the modern half only. Writing them would create
  exactly the coverage asymmetry the public site already has to suppress.

Venue is loaded where present (240 of 496), attendance where non-zero (154).
Both stay NULL otherwise, per principle 6.

## The 2019 reconciliation

AFCON 2019 was already in the vault as **edition 14**, from the legacy SokaFC
migration. The load itself did not touch it: WhoScored's copy was compared
against it and the disagreements recorded as **reconciliation run 38**, 24
diffs. They were then reviewed and applied as a separate, deliberate step --
`../reconciliation/fixes/2026-09-12_afcon_2019_corrections.sql`.

All 52 matches matched. 19 disagreed, and they were three separate defects:

| defect | matches | example |
|---|---|---|
| group matches with an inflated away score | 10 | Ghana v Benin stored **2-6**, actually 2-2 |
| knockout ties where the shootout winner was credited an extra goal | 4 | Morocco v Benin stored 1-2, actually 1-1 (Benin won 4-1 on pens) |
| matches left NULL that were 0-0 | 5 | Mauritania v Angola |

The decisive evidence was internal, not WhoScored's word: **for 16 of these the
vault's stored score disagreed with the vault's own `match_events`, and the
event log was what agreed with WhoScored.** So the stored score was the thing
in doubt. The third defect is the same lost-goalless-draw bug found in TPL
2017/18 (run 8).

The four shootout ties each carried a phantom `PENALTY_GOAL` in minute 120 with
no player -- the legacy migration had modelled the shootout as a goal. Those
four events were deleted and the shootout moved to `*_score_pens`.

The same change brought edition 14 into line with the twelve new editions: it
now has its six groups, its 24 participants, `ROUND OF 16` and `THIRD PLACE`
separated out of the old catch-all `KNOCKOUT` label, and the 90-minute /
extra-time / shootout score split. All 24 diffs are resolved `ACCEPT_B`.

## Running it

The harvest is a browser session, not a script, because it has to run inside a
page that has already passed Cloudflare. Its two outputs are committed under
`raw/afcon/` precisely so it does not have to be repeated.

```sh
python3 -m venv .venv && .venv/bin/pip install psycopg2-binary
python3 docs/ingestion/normalize_afcon.py \
        docs/ingestion/raw/afcon/fixtures.tsv \
        docs/ingestion/raw/afcon/events.json  canon_afcon.json
.venv/bin/python docs/ingestion/load_afcon.py canon_afcon.json            # dry run
.venv/bin/python docs/ingestion/load_afcon.py canon_afcon.json --commit
```

`load_afcon.py` rolls back unless given `--commit`, and skips any edition that
already holds matches, so a re-run cannot duplicate anything.

`normalize_afcon.py` prints a per-season summary and rebuilds every score from
its own events as a check.

Across all 13 tournaments as loaded, **491 of 493 played matches have a score
reproduced exactly by their own event log**, 58 are goalless with no events,
and none scored a goal without recording it. The two exceptions are both a
*missing event*, not a wrong score: Zambia 1-1 Tanzania (2023), where WhoScored
has no event for Zambia's goal, and Tunisia 1-1 Angola (2019), where the legacy
event log is a goal short. Re-running the loader now reports every one of the
13 editions as agreeing with the source.
