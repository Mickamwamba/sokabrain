# AFCON 1957–2000

The vault's Africa Cup of Nations used to start in 2002. This is how the other
22 tournaments — 1957 to 2000, 354 matches — came in from RSSSF, how they were
checked, and what was decided along the way. **Loaded and published
2026-09-15**, so the public site now covers 1957 to 2025.

```
fetch_rsssf_afcon.py      rsssf.org/tables/{57..00}a.html -> raw/afcon_pre2002/*.html
normalize_rsssf_afcon.py  -> raw/afcon_pre2002/canon_afcon_pre2002.json
validate_rsssf_afcon.py   -> checks; prints problems and things worth knowing
load_afcon_pre2002.py     -> the vault (a dry run that rolls back unless --commit)
```

## What went in

22 editions, 354 matches (352 played, 2 never played), 735 goal events, 428 new
players, 22 seasons, 50 groups, 190 participant entries. A first audit over the
competition opened 8 findings on the new editions, none critical: five goals
whose scorer is unknown even to RSSSF, and three seasons with scored matches
that have no event log at all.

## Why RSSSF and not Flashscore

Flashscore does list all 36 editions back to 1957, but its old tournaments are a
JavaScript app to scrape and carry results only. RSSSF carries dates, venues,
scorers with minutes, attendances, extra time, shoot-outs, lineups for the early
finals, and the final group tables — as plain text. It is also already trusted
here: TPL rounds and two seasons of reconciliation came from it.

## What the parser refuses to do

The pages are hand-written and the layout drifts across four decades: the venue
moves from a trailing `[in Cairo]` into a column between the date and the teams,
half-time scores appear in the 1990s, and walkovers, abandonments and shoot-outs
are written in prose. So `normalize_rsssf_afcon.py` never guesses a team name.
It builds each tournament's vocabulary from the printed tables and from the
right-hand side of match lines (which needs no vocabulary), seeded with the
names these countries played under, then reads the left-hand side against it.
**Anything it cannot read is reported, not dropped** — the run reports none.

The same rule governs scorers. The 1992 page uses `;` both between the two sides
and between two scorers on the same side, so the separator alone cannot be
trusted: every split point is tried, and a scorer list is accepted **only if it
adds up to the stored score**. 264 of the 352 played matches do; the other 88
load as results only, and the audit reports them as missing their event log,
which is true.

## How it was checked

* **Nothing dropped.** Every dated line in each final-tournament section became
  a match: 354 lines, 354 matches.
* **The source's own tables.** RSSSF prints final standings beside the fixtures,
  written by a different hand than the match lines. All 16 group and final-round
  tables recompute exactly — played, won, drawn, lost, goals for and against —
  from the parsed matches. This is what catches a misread score or a match
  attributed to the wrong side.
* **Winners.** Every tournament's winner matches RSSSF's own index
  (`tablesa/afrchamp.html`), including the finals decided on penalties and the
  two tournaments decided by a final round-robin.
* **Independently, against Wikipedia.** 1974: 17 matches, final 2-2 then a 2-0
  replay, Egypt 4-0 Congo for third. 1996: Nigeria withdrew, 15 teams, 29
  matches, South Africa 2-0 Tunisia, Zambia 1-0 Ghana. 1988 and 2000 finals too.
* **After loading, inside the transaction:** 264 of 264 event logs reproduce
  their stored score, own goals included; no team plays itself; nothing is
  published.

## The decisions, as settled

1. **Extra time** (28 matches): RSSSF gives only the after-extra-time score, so
   it is written to both the score and the `*_score_et` columns. The 90 minutes
   are unknown, not zero, and a later source can correct it.
2. **Shoot-outs** (16) go to `*_score_pens`, parsed from both written forms:
   `[aet, 3-4 pen]` and `Ghana won 7-6 on penalties`.
3. **The two matches never played** are CANCELLED with no score — 1957, where
   South Africa was disqualified over its government's apartheid policy, and
   1978, where Tunisia walked off at 1-1 and Nigeria was awarded 2-0. The
   fixtures exist; no invented result reaches a table.
4. **1959 and 1976 were decided by a final round-robin**, not a final, so those
   matches load as group matches in a group called "Final" — a table, which is
   what it was, rather than a bracket. `components/group-tables.tsx` titles a
   single-letter group "Group A" and anything else by its own name.
5. **Own goals are flipped on the way in.** RSSSF lists a goal under the side it
   counts FOR; the vault stores an OWN_GOAL under the scorer's own team
   (principle 5). Getting this backwards is exactly the defect the 2026-09-12
   ligikuu correction had to undo.
6. **A surname alone never merges two players.** Three names (Coulibaly, Lawal,
   Touré) matched existing post-2002 players exactly, but one surname is as
   easily two careers as one, so each starts its own record. Six full-name
   matches were reused, among them Samuel Eto'o and Hossam Hassan, whose
   careers genuinely span both eras.
7. **Kickoff times are unknown.** These pages give dates only, so every match is
   stored at 00:00 UTC. Every AFCON match from 2002 on has a real time.

## Left on the table

* **The qualifying tournaments.** Every page carries them, and they belong to a
  different competition — "African Cup of Nations Qualification" already exists
  in the vault. Not touched.
* **Attendances, referees, venues and the early lineups** are parsed and sit in
  each match's `notes` in the staged JSON, but are not loaded.
* **1996 and 1998 have almost no scorers** in the source: 26 of 27 and 27 of 29
  scored matches with no event log have no annotation at all. Another source
  would be needed.
