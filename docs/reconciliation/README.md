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

### Not yet checked

2018/19 (61 NULL scores) and 2019/20 (29 NULL scores at full time) show the same
signature — every NULL-score match has zero goal events. That is suggestive, not
proof. **Verify each season against its own source before applying the same
fix**; the arithmetic that made 2017/18 conclusive has to be redone per season.
