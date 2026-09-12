# Ingestion: the Tanzania Premier League, 2008/09 to 2026/27

> For the Africa Cup of Nations (13 tournaments, 2002-2025) see
> [AFCON.md](AFCON.md). It uses the same WhoScored browser harvest but a
> separate pipeline, because the source changes page format halfway
> through and files own goals under opposite teams either side of that
> split.

How the vault went from three seasons of the TPL to nineteen, and what each
source is actually good for. The scripts here re-run the whole thing.

```
fetch_ligikuu.py            official site  -> raw SportsPress JSON
(browser harvest, below)    whoscored.com  -> fixtures.txt + teams.json
normalize_ligikuu.py    \
normalize_whoscored.py   >  raw -> canonical match records (one shape)
teamnames.py            /   one canonical name per club, so sources join
load.py                     canonical -> vault, with provenance
```

## The two sources

### `ligikuu.co.tz` — the official league site

Runs WordPress with **SportsPress**, whose REST API is open at
`/wp-json/sportspress/v2/`. No scraping of rendered HTML is needed, and no key.
`events` carries the fixture, the result, and a per-player performance block
with **goalscorers and their minutes**, cards and assists.

It covers **2020/21 onward** — one season earlier than expected — but only
2022/23 to 2025/26 are complete. Two traps:

* **The `seasons` taxonomy lies.** Several leagues are tagged with the wrong
  season: every event in "NBC PREMIER LEAGUE 2022/23" is tagged 2023/24. The
  season is taken from the **league**, which is right.
* **SportsPress demo content is still in the database** — "Kangaroos vs
  Bluebirds" and friends sit inside the 2020/21 league. They are excluded by name.

Twenty-two teams and forty-seven players are referenced by events but return
404: deleted from the site while their appearances survived. Club names are
recovered from the event title ("Home vs Away"); the players stay unnamed,
because an unattributed goal is better than a wrong one.

### `whoscored.com` — regions/217/tournaments/382

Cloudflare returns 403 to plain HTTP, so this one needs a real browser. Once a
page is open, the fixture feed is same-origin JSON:

```
/tournaments/{stageId}/data/?d=YYYYMM&isAggregate=false
```

`d` takes a month, so a season is ~14 requests rather than one per match. Each
season's `stageId` comes from its own page; the ids are listed in
`whoscored_stages.json`.

It covers **2008/09 to 2026/27 but skips 2017/2018 entirely**, and carries
fixtures, scores and card totals — **no goalscorers**. That is why the early
seasons have no event log: nothing was dropped, the source has none.

## What the cross-check found

Both sources were checked against the vault's own reconciled seasons before
anything was written.

| | matches compared | scores disagreeing |
|---|---|---|
| whoscored vs vault, 2018/19 | 376 | **0** |
| whoscored vs vault, 2019/20 | 380 | **0** |
| ligikuu vs whoscored, 2020/21–2026/27 | 986 | **0** |

Not one score conflict in 1,742 comparisons. That is what made the seasons
where no independent check is possible — 2008/09 to 2016/17, on WhoScored alone
— safe to accept.

Two things the check found that the vault had wrong are documented in
`../reconciliation/README.md`: 86 kickoff dates, and the four open date flags.

### Where WhoScored is not to be trusted

**Home and away.** Two 2018/19 fixtures are the wrong way round on WhoScored
where RSSSF and the vault agree with each other. Orientation is taken from the
majority, never from WhoScored alone.

## Judgement calls made while loading

**The official site's performance rows are not lineups.** It records a row only
for players who did something — about four a match, never a full eleven. Writing
them as `match_lineups` would invent appearances and corrupt every
per-appearance statistic (principle 6). They are written as
`player_team_stints` instead, which is what they actually establish: this player
turned out for this club, between these dates. A stint here is a floor on the
real spell, not a transfer record.

**Nothing already reconciled is touched.** 2017/18, 2018/19 and 2019/20 are
skipped by the loader, and a season whose edition already holds matches is
skipped too, so a re-run cannot duplicate anything.

**Disagreements are recorded, not resolved** (principle 2). The 34 between the
two sources — all kickoff dates, no scores — are in `reconciliation_diffs`
under the ligikuu-vs-whoscored run.

## Running it

`load.py` needs `psycopg2`, which macOS system Python will not install into;
use a virtualenv. It runs inside a transaction and **rolls back unless given
`--commit`**, so a dry run costs nothing:

```sh
python3 -m venv .venv && .venv/bin/pip install psycopg2-binary
python3 docs/ingestion/fetch_ligikuu.py raw/ligikuu
python3 docs/ingestion/normalize_ligikuu.py  raw/ligikuu   canon_ligikuu.json
python3 docs/ingestion/normalize_whoscored.py raw/whoscored canon_whoscored.json
.venv/bin/python docs/ingestion/load.py canon_ligikuu.json canon_whoscored.json          # dry run
.venv/bin/python docs/ingestion/load.py canon_ligikuu.json canon_whoscored.json --commit
```

The WhoScored harvest is a browser snippet rather than a script, because it has
to run inside a page that has already passed Cloudflare. It is kept in
`harvest_whoscored.js`.

## Assists, added afterwards

`load.py` skips an edition that already holds matches, which is what makes it
safe to re-run — but it also means it cannot pick up a field that was missed the
first time. `load_assists.py` does that one job: it finds each match through its
`entity_source_map` provenance (the ligikuu event id recorded at load, so the
join is exact rather than a re-match on names and dates) and adds ASSIST rows.
A match that already has them is skipped, so re-running cannot double a tally.

1,078 assists, all attributed, 2023/24 onward — the source records none before
that. They are standalone rows rather than `related_player_id` on a goal,
because the source gives a bare count with no indication of which goal each one
created; the schema doc explains the choice.

## What landed

19 editions of the competition, 4,380 matches, 4,169 with a score. 20 clubs and
502 players new to the vault, 742 player-club stints, 1,684 goal and card events.

Every ingested season is a complete double round robin except two, both flagged
in the dashboard: **2016/17** is missing 1 fixture and **2020/21** is missing 43,
in both sources rather than in one.

**Every new edition is unpublished.** They are in the vault and visible in the
admin dashboard; none of them reaches the public site until someone publishes it.
