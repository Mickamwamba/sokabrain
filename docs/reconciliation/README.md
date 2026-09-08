# Source reconciliation

Independently-sourced reference data used to check the migrated vault, kept so a
comparison can be re-run rather than taken on trust.

## `wikipedia_tpl_2017_18.json`

Final table for the 2017–18 Tanzanian Premier League, from
<https://en.wikipedia.org/wiki/2017%E2%80%9318_Tanzanian_Premier_League>
(retrieved 2026-09-07).

The table was checked for internal consistency before being used: 480 team-games
(= 240 matches × 2), goals for equal to goals against (470 each), wins equal to
losses, draws even, and every row's points equal to `3W + D`. It passed all of
them, which is what made it usable as a reference.

Wikipedia carries **no match-by-match results** for this season — only the final
table — so the comparison was made at team-aggregate level.

### What the comparison found

For all 16 clubs, the vault's **wins, losses, goals for and goals against
matched Wikipedia exactly**. Only draws differed, and for every club the
shortfall equalled precisely the number of its matches with a NULL score. All 42
such matches carried zero goal events.

The only explanation consistent with all of that: **the legacy migration lost
0–0 draws**, storing the score as NULL rather than 0. The data was never
missing — it was mis-encoded.

Filling those 42 matches with 0–0 makes the vault's table match Wikipedia
exactly, in every column, with identical final positions. Recorded as
reconciliation run 8 (84 diffs, resolved `ACCEPT_A`).

## `rsssf_tpl_2017_18_matches.json`

All 240 matches of 2017/18 — round, date, teams and score — parsed from
<https://www.rsssf.org/tablest/tanz2018.html> (retrieved 2026-09-07). RSSSF
publishes round-by-round results as plain text, which is why it worked where
the live-score sites did not.

The parse was validated before use: exactly 240 matches over 30 rounds of 8,
16 clubs each appearing 30 times, 470 goals, 42 goalless draws — every figure
agreeing with the independent final table.

Two parsing traps worth knowing if this is ever re-run:

* Team names are padded to a fixed width, so `Tanzania Prisons` (16 characters)
  leaves only **one** space before the score. Anchoring on a two-space gap
  silently drops one match per round.
* An abandoned match appears **twice** — once as the abandonment, once as the
  replayed remainder (round 20, Tanzania Prisons v Mbao). Counting both inflates
  the season to 241.

### Result

**All 240 scores and all 240 kickoff dates are identical to the vault.** Zero
disagreements. This confirms at match level — not merely in aggregate — that
the 42 recovered 0-0 draws were correct. Recorded as reconciliation run 11.

### Goalscorers: still missing

42 goals across 27 matches have an event row but no player named. No accessible
source was found for per-match scorers in this league and season: besoccer is
behind a login, Soccerway / Flashscore / Livesport are JavaScript-rendered,
worldfootball.net returns 403, and neither Wikipedia nor RSSSF carries them.
Wikipedia names only a season top scorer (Emmanuel Okwi, 20), which our event
log does not corroborate.

Filling these will need either a source that renders server-side, a browser
capable of running JavaScript, or contemporary match reports.

### Not yet checked

2018/19 (61 NULL scores) and 2019/20 (29 NULL scores at full time) show the same
signature — every NULL-score match has zero goal events. That is suggestive, not
proof. **Verify each season against its own source before applying the same
fix**; the arithmetic that made 2017/18 conclusive has to be redone per season.


---

## 2018/19 — `wikipedia_tpl_2018_19.json`, `rsssf_tpl_2018_19_matches.json`

Same method as 2017/18, and it found a **different defect**. Blanket-applying the
2017/18 fix here would have been wrong, which is why the arithmetic is redone
per season.

### Why RSSSF could be trusted for this season

Its 380 parsed results reproduce **RSSSF's own published final table** exactly,
and that table is in turn identical to Wikipedia's. Two independent tables and
the match list all agree, so the match list is sound.

### The join key matters

Joining our matches to the reference on `(home, away)` produced four apparent
score conflicts. All four were artefacts: six of our fixtures have **home and
away reversed**, so an orientation-based join silently compared our record
against the *other leg*. Re-joining on `(date, unordered team pair)` — because
orientation was itself in doubt — gave the true picture:

| | Count |
|---|---|
| already correct | 314 |
| missing a score | 61 (60 of them 0-0) |
| home and away reversed | 6 |
| genuine score conflicts | **0** |

### The reversed fixtures

For each, the *result* was right but the venue was wrong — e.g. we held
`Mtibwa Sugar 1-2 Yanga` where the fixture was `Yanga 2-1 Mtibwa Sugar`. Because
per-team wins, draws, goals for and goals against are unchanged by orientation,
**a league table cannot detect this defect** — only a match-level comparison can.
It corrupts home/away records, and it left six fixtures duplicated while their
six reverse fixtures were missing entirely.

### Result

Applying 61 fills and 6 swaps reproduces the Wikipedia table exactly: all 20
clubs, all seven columns, identical final positions. Recorded as reconciliation
run 14.

Goalscorers are again unresolved — 60 goals across this season have no scorer,
and no accessible source publishes them.


---

## 2019/20 — `wikipedia_tpl_2019_20.json`, `rsssf_tpl_2019_20_matches.json`

A third distinct defect: not mis-encoding, but a **truncated dataset**.

**The season was completed**, not curtailed. It paused for COVID, resumed in
June 2020 and finished on 26 July; all 20 clubs played 38. Our legacy data stops
dead at 15 March 2020, so nothing after the restart was ever captured.

RSSSF's 380 results reproduce the Wikipedia final table exactly for all 20
clubs, which is what made it authoritative enough to adjudicate conflicts
against our own values.

### Applied

| Action | Count |
|---|---|
| matches created (absent entirely, mostly rounds 31-38) | 31 |
| scores filled | 93 |
| home/away reversed, then filled | 2 |
| wrong scores corrected | 3 |
| empty phantom SCHEDULED rows deleted | 3 |
| corrupt row voided (not deleted) | 1 |

Result: 380 completed matches, no missing scores, 767 goals, and a table
matching Wikipedia exactly across all 20 clubs with identical positions.
Recorded as reconciliation run 17.

### Match 1252 — voided, needs a decision

A third `Biashara United v Ruvu Shooting` fixture when both legs already exist
(1226 and 1121), scored 2-1 where the real fixtures were 0-0 both times, and
crediting two goals to Tarick Seif for Biashara on 2020-02-01 — a month after he
transferred to Yanga. RSSSF has no such match.

**Deleted** (2026-09-08), along with its three event rows and provenance. The
row is preserved verbatim in `deleted_match_1252.json` should it ever need to be
reconstructed. 2019/20 is now exactly 380 rows, all FULL_TIME.

It was voided to CANCELLED first and flagged BLOCKER rather than deleted
outright, so the decision to destroy it was a person's rather than a script's.

### Parsing note

Round 21 contains a match **decided by award, not played**: `Ruvu Shooting 0-3
Tanzania Prisons`, Ruvu having failed to provide an ambulance. RSSSF writes it as
`awd` with the result inside a bracket that wraps across two lines, gluing
`ambulance]` onto the next fixture's away team. Both had to be handled explicitly.
The vault has no way to record that a result was awarded rather than played; it
now looks like an ordinary 3-0.


---

## The four earlier legacy snapshots — checked, and they hold nothing new

`compare_legacy_snapshots.py`, run against
`~/Documents/Hype/Backups/SokaDatabase` (2026-09-08).

The migration read one dump, `sokafc_02_APRIL_2020.sql`. Four earlier snapshots
of the same production database sit beside it — July, August, November and
December 2018. They were never examined. If production had ever lost a row, an
earlier snapshot would still hold it, and the vault's largest remaining gap —
goals with no scorer — could have been closed from our own history rather than
from an external source.

It cannot. The result is a clean negative, and worth recording so nobody spends
the afternoon again.

| Checked against April 2020 | jul2018 | aug2018 | nov2018 | dec2018 |
|---|---|---|---|---|
| matches absent | 0 | 0 | 0 | 0 |
| lineup rows absent | 0 | 0 | 0 | 0 |
| events absent | 0 | 4 | 3 | 7 |
| **events that lost their scorer** | **0** | **0** | **0** | **0** |
| events whose scorer changed | 0 | 0 | 0 | 0 |

Primary keys are stable across all five snapshots, so the join is exact rather
than heuristic: of jul2018's 544 events, all 544 appear in April 2020 with an
identical `(match, type, minute)` tuple.

### What this settles

**Not one event ever lost its scorer.** The goals with no scorer were entered
without one, on the day, and stayed that way — 823 of April 2020's 3,062 goal
events, and already 76 of 544 in the very first snapshot. This is not migration
damage and not production data loss; it is what the source has always been. The
only way to fill them is a source outside SokaFC, and none has been found (see
"Goalscorers: still missing" above).

Coverage never went backwards either: lineup rows grew 1,502 → 1,553 → 1,589 →
2,024, and no match or lineup row was ever deleted. The vault holds everything
the legacy app ever held.

### The eleven deleted events

Four are cards. **Seven are goals, and every one of them had no scorer** —
someone was tidying up unattributed goals by hand. They belong to matches 351,
372, 387, 442, 456 and 466. All of those matches now carry a score verified
against RSSSF, and their event logs reconcile to it, so the deletions did no
harm and nothing needs restoring.

### A side finding: our disputed dates are entered reschedules

The snapshots also show *how* our kickoff dates came to be. Match 440 (Mtibwa
Sugar v Singida United, flagged as disagreeing with RSSSF by 49 days) sat at
2018-12-01 with status `PP` in December 2018, and was re-entered by hand as
2019-01-22 sometime before April 2020. Its round-mate 439 was rescheduled the
same way, from 2018-12-01 to 2019-04-17 — and RSSSF agrees with that one
exactly.

So our 2019-01-22 is a deliberate entry by someone following the league, not a
migration artefact, which makes it harder to dismiss in favour of RSSSF's
2019-03-12. The flag stays open and still wants a third source.

## Kickoff times were three hours late

Not a source comparison but found in the same pass, and applied as
`fixes/2026-09-08_kickoff_timezone.sql`: legacy MySQL `datetime` values are
Tanzanian local time, and the migration stored them as UTC. All 1,549 matches
with a real time were shifted back three hours; five "time unknown" placeholders
at 00:00–01:00 were left alone. No kickoff date moved, so every reconciliation
recorded above still holds. Full rationale is in the schema doc.


---

## whoscored.com as a third source (2026-09-08)

Added while ingesting the full league history (see `../ingestion/README.md`).
WhoScored covers 2008/09 to 2026/27 but **skips 2017/2018**, so it overlaps two
of the vault's three reconciled seasons.

### It agrees with the vault completely on scores

| | fixtures joined | scores disagreeing |
|---|---|---|
| 2018/19 | 376 | **0** |
| 2019/20 | 380 | **0** |

Zero. That, plus zero conflicts against the official league site over another
986 matches, is what made WhoScored trustworthy enough to accept alone for
2008/09–2016/17, where no second source exists.

### It settled all four open date flags

Flags 24–27 were raised because RSSSF disagreed with the vault about a kickoff
date and there was no third source to break the tie. WhoScored agrees with
RSSSF against us on **all four**, so all four are closed and the dates
corrected:

| match | vault held | RSSSF and WhoScored both say |
|---|---|---|
| 365 Stand United v Tanzania Prisons | 2018-09-28 | 2018-09-27 |
| 442 Lipuli v Biashara United | 2018-12-02 | 2018-12-03 |
| 522 Coastal Union v African Lyon | 2019-01-19 | 2019-01-20 |
| 440 Mtibwa Sugar v Singida United | 2019-01-22 | **2019-03-12** |

Match 440 was the 49-day disagreement. The earlier note that our date looked
like a deliberate reschedule still stands — it was one — but whoever entered it
was wrong, and two independent compilers say so.

### And it exposed 82 wrong dates in 2019/20

A bigger find. RSSSF and WhoScored agree with **each other** on 373 of that
season's 380 kickoff dates, and the vault disagreed with the agreed date on 82
of them.

The season was suspended for COVID in March 2020, resumed in June and finished
on 26 July. Both sources place the resumed fixtures in June and July, and
neither has a single match in April or May. **The vault had 60 matches inside
the suspension**, including one on 2019-05-13, three months before the season
began.

The cause: the 2019/20 pass reconciled *scores* against RSSSF and filled them
correctly, but never corrected the kickoff dates on the rows it filled, so
those matches kept their legacy dates. The season's own write-up recorded the
June restart while the data said May, and nothing checked one against the
other.

86 dates were corrected in total (82 in 2019/20, 4 in 2018/19), applied as
`fixes/2026-09-08_kickoff_dates.sql`. Only the date moved; the time of day was
left alone. Seven dates where the two sources disagree with each other were
left alone too — the vault already sides with one of them in every case.

### Where WhoScored is wrong

Two 2018/19 fixtures are the wrong way round on it — `Kagera Sugar 0-0 Mbao`
and `Ndanda 1-3 Mwadui` — where RSSSF and the vault agree with each other. Its
home/away is not reliable on its own, so orientation is decided by majority.
