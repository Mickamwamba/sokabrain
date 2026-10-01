# Open decisions

Questions the data cannot answer by itself. Each needs someone with football
knowledge, or a source not yet found, to make a call. **None of these should be
"fixed" by a script guessing.** Counts are as of 2026-10-01; the data audit
(`/admin/audit`) has the live numbers.

When you settle one, write the change as a fix file (see `docs/RUNBOOK.md`,
"Fix a data error"), then remove it from this list.

## Quick wins

- **Data flag 44 is stale.** It says Tanzania Prisons 3-2 JKT Tanzania (match
  17991) holds 6 goal events, but the match was corrected on 2026-09-17 and now
  holds 5 for a 3-2. Resolve the flag in `/admin/flags`.
- **The last audit run was #30, on 2026-09-20.** Run it again before working the
  list below, because some findings will already be resolved.

## Fixtures and seasons

- **Tanzania 2020/21: 31 fixtures involving Ihefu FC and BIGMAN FC.** The
  season's other sources show a clean 18-club league. These two clubs appear
  only from February 2021, with 16 matches each. What those fixtures actually
  were (a play-off, a second stage, or bad source data) is unknown.
- **45 fixtures are still `SCHEDULED` more than a week after kickoff.** These
  include 12 from Tanzania 2020/21, five years old. Each is one of three things:
  played (find the score), postponed or cancelled (set the status), or never
  real (remove it with a fix file). The audit's `STALE_SCHEDULED` check lists
  them.
- **Tanzania 2025/26: rounds 18 and 19 are swapped between FotMob and the
  vault.** There are 16 `PENDING` rows in `reconciliation_diffs`, run 150.
  Chronology doesn't settle it, because both sources number rounds out of
  playing order elsewhere in that season. Leaving them pending is a legitimate
  answer.
- **20 legacy editions have never been reviewed for publication.** They are
  domestic cups, continental club rounds, qualifiers, U17 and First Division
  from the SokaFC dump (2017–2020). Most are thin. Publish them, leave them, or
  decide they don't belong.

## Player identity (one person, one record)

- **6 player records are an initial plus a surname**: B. Sylla (10886),
  M. Sylla (10908), Y. Traoré (11247), M. Mkopi (11757), W Patrick (13047) and
  B Majogoru (13071). Each needs a source that names that specific goal before it
  can be merged into a full-name record or renamed.
- **42 surname-only candidates** are open in the audit
  (`SCORER_NAME_ABBREVIATED`). They are mostly Senegalese and Malian AFCON
  surnames (Gueye, Diallo, Diarra, Camara, Touré), where several real players
  share a name.
- **Likely duplicates the audit cannot raise**, because the two records have
  different names:
  - Bakari Nondo (12531) and Bakari Mwamnyeto (1444), both Yanga SC.
  - Feisal Salum (2069, Azam and Tanzania) and the Yanga Feisal Salum.
- **Names held twice in Tanzania 2022/23** whose newer goals went to new records:
  Saidi Ntibazonkiza, Vitalis Mayanga, Kelvin Sabato (five records, two of them
  legacy junk), Japhary Kibaya, Tariq Seif, Haruna Shamte and Salum Abubakar.
- **Daniel Lyanga and Kelvin Sabato are ambiguous in 2020/21**, so their goals
  that season were left unattributed.

## Goals and events

- **Tanzania 2019/20: 7 sides hold a plain GOAL where Flashscore says OWN_GOAL.**
  Fixing one means changing the type and moving the event to the scorer's own
  team. That needs a fix file, not a loader.
- **626 unnamed-scorer findings.** Most have no source anywhere; `docs/HISTORY.md`
  records which seasons are at their ceiling. Do not invent names to close them.
- **57 matches have no score** (`MISSING_SCORE`). Some are genuine gaps in the
  sources; some may be unplayed matches carrying the wrong status.

## Player careers

- **54 overlapping club spells and 49 spells left open** after the player moved
  on. Each player's console page has a one-click fix, but each one is a call
  about real dates, so none are corrected automatically.

## Provenance

- **5,911 `match_events` rows have no `entity_source_map` row.** They span every
  loader, not just the legacy migration. A blanket backfill would claim a source
  for rows whose source is unknown, so this needs a per-loader investigation, or
  it should be accepted and documented.

## Sources and permissions

- **Rwanda's official league site** (`rwandapremierleague.rw`) has the best
  per-match data for that league: full names, assists and cards. But its
  `robots.txt` disallows the endpoint. **Ask the league for permission** before
  using it. If they say yes, also check two vault scorer totals it could not
  confirm: Taïba Mbonyumwami (14) and Jean Claude Girumugisha (7).
- **Flashscore** is the only remaining source for about 140 unnamed 2019/20
  goals, through its head-to-head pages. It would mean a large browser harvest;
  agree it with their terms first.

## Code gaps (for a developer, not an editor)

- **Kijiweni's per-client rate limits need `TRUST_PROXY` set when the site is
  deployed.** Until then every web fan shares one budget, because the backend
  sees all web posts coming from the web server. See "Kijiweni rate limits" in
  `docs/RUNBOOK.md`.
- **The iOS app allows plain HTTP** (`NSAllowsArbitraryLoads`) for local
  development. Remove it for release.
- **Socket.io push is not built** (priority 6). Clients poll today.
- **The weekly data jobs are not scheduled** (`docs/RUNBOOK.md`).
- **There are no admin roles.** Every admin can manage access and publish.
