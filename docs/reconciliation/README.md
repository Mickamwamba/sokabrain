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
