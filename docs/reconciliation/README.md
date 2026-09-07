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
