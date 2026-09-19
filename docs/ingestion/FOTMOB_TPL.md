# FotMob, for Premier League scorers

FotMob is the best of the three sources for the seasons it covers, and it
supplies things Flashscore does not. It settled Namungo 3-2 TRA United
(28 May 2024), where Flashscore's own log reads 2-2 and so had no name to give.

| | FotMob | Flashscore | ligikuu |
|---|---|---|---|
| Scorer names | **full** ("Pius Buswita") | abbreviated ("Dube P.") | full |
| Reach a season | **one URL** with `?season=2022-2023` | "Show more" clicks that stop paging | API by league id |
| Whole fixture list | **one call**, embedded in the page | scrape the results DOM | one call |
| Penalties / stoppage | yes | yes | minutes only |
| Earliest match detail | ~2018/19 | ~2019/20 | 2023/24 |

Its league id for the Tanzanian Premier League is **9066**:

    https://www.fotmob.com/en-GB/leagues/9066/fixtures/premier-league?group=by-date&season=2022-2023

## Three traps, all of which cost a wrong answer first

**1. The fixture list is in the page, the match events are not.**
A league page embeds `__NEXT_DATA__` whose `props.pageProps.fixtures.allMatches`
is the complete season — 240 entries with match id, `pageUrl`, both clubs,
`status.scoreStr`, kickoff and round, plus a `status.awarded` flag worth reading.
One call per season replaces an entire scraping loop.

**2. On a MATCH page, `__NEXT_DATA__` is the wrong match.** The URL is
`/matches/{slug}/{code}#{matchId}` and the fragment is what selects the game.
The server renders the *most recent* meeting of those two clubs and the client
then swaps in the right one, so the embedded JSON and the rendered DOM disagree:
on Azam v Polisi `#3999832` the DOM showed the 8-0 while `__NEXT_DATA__` held a
different match entirely, `matchId: 5998275`. **Read the DOM, never the embedded
JSON, on a match page.** Navigating to a bare slug without the fragment 404s or
serves the wrong game.

**3. Away events are mirrored.** Each `[class*="MatchEventItemWrapper"]` holds
an event and a time, and for away goals the time comes *first*. Checking only
the first `.sr-only` label therefore reads "Minute 84" instead of "Goal." and
drops every away goal — two of five on the first match tried. Search all the
`.sr-only` labels in the item instead.

## Reading an event

The accessible labels are the reliable part; the visible text is not, because
collapsing whitespace runs "Minute 15" into the clock "15’" and yields 1515.

| What | Where |
|---|---|
| kind | a `.sr-only` matching /goal/i — "Goal." or "Own goal." |
| minute | the `.sr-only` starting "Minute", as "Minute 90 plus 14" |
| scorer | `[class*="PlayerLinkWrapper"]` |
| running score | `[class*="GoalStringCSS"]`, e.g. "(2 - 0)" |
| penalty | "Penalty" in the item's text |

**Side comes from the running score, not the layout**: compare each goal's
score with the previous one and see which number moved. That is robust against
the mirroring, and it is how an own goal lands on the side it counts for.

```js
const out = []; let ph = 0, pa = 0;
for (const el of document.querySelectorAll('[class*="MatchEventItemWrapper"]')) {
  const labels = [...el.querySelectorAll('.sr-only')].map(s => (s.textContent || '').trim());
  const lb = labels.find(x => /goal/i.test(x));
  if (!lb) continue;
  const sc = (el.querySelector('[class*="GoalStringCSS"]')?.textContent || '')
    .replace(/[‎‏‪-‮]/g, '').match(/\((\d+)\s*-\s*(\d+)\)/);
  if (!sc) continue;
  const h = +sc[1], a = +sc[2];
  const mm = (labels.find(x => /^Minute/i.test(x)) || '').match(/Minute\s+(\d+)(?:\s*plus\s*(\d+))?/i);
  out.push({
    side: h > ph ? 'home' : a > pa ? 'away' : null,
    minute: mm ? +mm[1] : null, added: mm && mm[2] ? +mm[2] : null,
    type: /own goal/i.test(lb) ? 'OWN_GOAL'
        : /penalty/i.test((el.textContent || '').replace(/\s+/g, ' ')) ? 'PENALTY_GOAL' : 'GOAL',
    name: (el.querySelector('[class*="PlayerLinkWrapper"]')?.textContent || '').trim() || null,
  });
  ph = h; pa = a;
}
out
```

## What it does not reach

2017/18 is **absent from FotMob's season list entirely** — the same season
WhoScored skips. And for 2016/17 and earlier the fixture lists exist but every
match page 404s, so the six seasons with no scorers anywhere (2011/12 to
2016/17) stay that way. Three independent sources now agree they cannot be
filled.

## Loading a harvested season

    python3 normalize_fotmob_tpl.py raw/fotmob_tpl/2022-2023.tsv > staged.json
    python3 load_fotmob_tpl.py staged.json 2022/2023            # dry run
    python3 load_fotmob_tpl.py staged.json 2022/2023 --commit

The harvest is one line per match, `<fotmob id>^^<date>|<home>|<away>|<score>^^
<minute>~<side>~<type>~<scorer>;...`, with stoppage time in a companion
`added.txt`. `load_fotmob_tpl.py` is `load_flashscore_tpl.py` with a different
source and a different way of recognising a player, and it keeps that loader's
rule: **it does not replace the vault's goal log, it completes it**, and it
touches a match only when the source's goals add up to the score the vault
already holds.

**A fixture is identified by its two clubs, not its date.** An ordered pair meets
once in a double round-robin, which is a stronger key than a kickoff date two
sources can legitimately disagree about — and one did, by four days, in 2022/23.
The score still has to agree exactly; that is what stops a wrong pairing.

### `<TBD>` is a real goal with an unknown scorer

FotMob renders `<TBD>` in the scorer slot, with no player link, where it has the
goal but not the man. 18 of 2022/23's 561 goals read that way. They load as
events with a NULL `player_id`, which is the truth — not as a player called TBD.

### The club pool is not enough on its own, because players transfer

Narrowing candidate players to the club is what makes name matching safe, but
the vault learns a player's club from the events and squads it holds, so for a
season it has no event log for it knows nothing. A man who scored for Geita Gold
in 2022/23 and Simba in 2023/24 is absent from Geita Gold's pool entirely. A
first pass over the season therefore proposed **68 new records for players the
vault already had**.

`match_fotmob_players.py` answers this with a second pass over the whole vault
that is deliberately stricter than the first: only an **exact set of name
tokens**, matching exactly one player, counts. Order does not matter ("Amza
Moubarack" is "Moubarack Amza"), but containment does not carry across clubs —
"Hassan Maulid" sits inside "Hassan Nassor Maulid" while the vault separately
holds a "Hassan Nassor", and no rule can separate those three. That pass matched
48 of the 68 and cut the creations from 143 to 95.

Where neither pass decides, a player is created. That is the cheaper error on
purpose, and it is the same trade `playermatch.py` documents: a duplicate record
is raised by the audit's Identity checks for a human to merge, whereas a wrong
match silently moves goals onto another man. The exception is two players **at
the same club** whose names both contain the scorer's — there a wrong pick is
both likely and damaging, so the goal keeps its minute and side and loses only
its scorer.

Seven scorers in 2022/23 were created despite already being in the vault,
because the vault holds each of their names **twice** (Saidi Ntibazonkiza,
Vitalis Mayanga, Kelvin Sabato, Japhary Kibaya, Tariq Seif, Haruna Shamte, Salum
Abubakar). Those are pre-existing duplicates, not new ones; merging them is a
separate identity job.

## When the source is patchy: 2020/21

2022/23 and 2021/22 matched the vault goal-for-goal before a page was opened.
2020/21 did not, and the differences are worth knowing before trusting a season.

**FotMob's 2020/21 is a clean 18-team league — 306 fixtures, 18 clubs, 34 games
each. The vault's edition has 20 clubs and 337 fixtures.** The extra 31 belong to
Ihefu FC and BIGMAN FC, who appear only from February 2021, play 16 each, and
have 6 unscored each (those are the 12 fixtures long listed as still SCHEDULED).
Every one of FotMob's 306 matched a vault fixture and **every one of the 306
scores agreed exactly**, so the overlap is solid and the surplus is a separate
question about what those 31 fixtures are — not something this load touches.

**FotMob has the result but no timeline for some matches.** Five of 2020/21's
had no event items at all on a fully-rendered page. The harvest retries once and
then records the match as having nothing at the source, rather than blocking.
That never happened in 2022/23 or 2021/22.

**A club's name on a match page can differ from its name in the fixture list.**
FotMob renders team 1171766 as "Ihefu FC" on match pages while the 2020/21
fixture list calls it "Singida Black Stars". The page identity guard was
rejecting every one of those 34 matches until it was relaxed to require only
**one** of the two clubs to appear in the title. The pairing is not in doubt: the
vault's Singida Black Stars played 34 matches over the same span and all 34
scores agree, while its Ihefu FC has 16 from February.

## Two ways a scorer name can be wrong

**An own goal must not be attributed to a player of the side it counts for.**
FotMob credits Azam's third against Dodoma Jiji (5 Nov 2020) as an own goal by
Prince Dube — Azam's own striker. Loading it would have moved a forward's goal
to the opposing club and registered him there. `load_fotmob_tpl.py` refuses a
name in that position and loads the event unattributed.

**Some player names in the vault were parser output, not names.** Chasing the
2020/21 ambiguities turned up four, fixed in
`docs/reconciliation/fixes/2026-09-18_parser_artifacts_and_2020_21_duplicates.sql`:
two RSSSF minute markers kept as part of a name ("Michael Sarpong (pen)",
"Themi Felix (pen)" — the same defect fixed for AFCON and missed for the league,
and each goal really was a penalty), and two undecoded ligikuu HTML entities
("Ally Ng&#8217;anzi"). Worth a periodic sweep:

    SELECT id, full_name FROM players WHERE full_name ~ '\(|&#|[0-9]';

## How far back FotMob actually reaches: 2020/21, not 2018/19

The table at the top of this file said "earliest match detail ~2018/19". That
was wrong, and it was tested properly on 2026-09-18 by probing match pages
across two seasons:

| Season | Fixture list | Scores | Goal timeline |
|---|---|---|---|
| 2020/21 | yes | yes | mostly (5 of 203 matches had none) |
| **2019/20** | yes, all 380 | **all 767 goals agree with the vault** | **none, in six probes across the season** |
| **2018/19** | yes, 384 | **all 746 goals agree** | **none; every probe 404s** |

Four of the six 2019/20 probes render a normal match page with an empty
timeline; the other two, and all three 2018/19 probes, return FotMob's "We could
not find what you were looking for". **So FotMob cannot name a single goal in
either season**, and the 346 unattributed goals in 2019/20 and 63 in 2018/19 are
out of its reach. Their scores are still worth having as a cross-check: both
seasons agree with the vault exactly, 767 and 746.

Flashscore is the remaining candidate — its archive runs 2010/11 to date and it
does carry per-match scorers — but reaching an old season there needs the
head-to-head route, because its results page stops paging back.

## Naming a side whose goals are all unattributed

2019/20 and 2018/19 need something the other seasons did not: their event logs
are already complete and it is the *scorers* that are missing, and **275 of
2019/20's 346 unnamed events carry no minute**, so the minute rule can never
reach them.

`load_fotmob_tpl.py` therefore has a step for it. When **every** goal event on
one side of a match is unnamed, those events carry nothing that tells them
apart, so if the source lists exactly that many goals for that side, pairing
them is a bijection between interchangeable slots and named goals — and every
bijection gives the same set of facts. That is why this is safe where positional
pairing generally is not (see 17991, where it would have scrambled the scorers).

Two conditions keep it honest: the goal **types** must match as a multiset and
pairing happens within a type (a vault GOAL against a source OWN_GOAL is a
different fact, since the own goal is stored under the other team), and a minute
is only filled where the vault has none.

**It has no season to run against yet**, so `test_name_whole_side.py` exercises
it instead: it strips the scorers from twelve 2022/23 match-sides, runs the
loader over the harvest that named them, checks the same scorers come back, and
rolls the whole thing back. It restricts itself to events FotMob itself named —
mixing sources would measure their disagreement over spelling rather than this
step, which is exactly what the first version of the test did.

## Flashscore reaches 2019/20 where FotMob does not — for part of it

FotMob has no goal timeline before 2020/21, but **Flashscore does**, with the
minute, the side, the running score, the type, and a player link carrying the
whole name. `normalize_flashscore_names.py` turns a harvest into the same shape
the loader already takes, and the loader is told which source it is:

    python3 normalize_flashscore_names.py raw/flashscore_tpl/2019-2020.tsv 2019/2020 > staged.json
    python3 load_fotmob_tpl.py staged.json 2019/2020 --source=flashscore --commit

`--source` exists because provenance has to name the source the rows actually
came from (principle 1); it was hardcoded to `fotmob` before.

**Its season results page only reaches back so far.** For 2019/20 it lists 106
of 380 matches — 14 March to 1 August 2020, the COVID restart and the play-offs
— with no "show more" button at all. That still covered 206 of the season's 346
unattributed goals, which is why it was worth doing before finding a route to
the rest.

Of the 106: **102 matched a vault fixture with the score agreeing exactly.** The
4 refusals are play-off ties whose two clubs also met in the league, so the pair
is no longer unique in the season — the score check caught every one.

### What the harvest is worth

| | |
|---|---|
| matches visited | 86 (those with an unattributed goal) |
| stored | 75 |
| skipped | 11, where Flashscore's own timeline is short of the score |
| goals | 169, of which **160 name a scorer** |
| goals actually named in the vault | **136** |

The gap between 160 and 136 is the type guard doing its job: **7 sides hold a
plain GOAL in the vault where Flashscore says OWN_GOAL.** That is the pattern
this project has hit before — an own goal is the one kind a scorer list has no
natural place to record, so the legacy data filed it as an ordinary goal for the
side it counted for. Correcting those means changing a type AND moving the event
to the scorer's own team, which is a fix file's job, not a loader's.

## Round numbers: seventeen seasons, from one field in the fixture list

Every entry in a league page's `fixtures.allMatches` carries a `round`, and the
official site's SportsPress export does not. `load_rounds_fotmob.py` loads them.
After this pass **4,035 of the league's 4,380 fixtures have a round**, up from
3,437, and thirteen seasons that had gaps have none.

### Getting a season out of the browser in two calls, not eight

Data leaves the browser as plain text in ~950-character chunks (the CSP blocks a
local sink, the clipboard needs focus the tab lacks, and base64 is blocked at the
tool layer). Naming both clubs on every line spends most of those characters
repeating sixteen club names. Indexing the clubs once turns a season from eight
chunks into two, and `read()` takes either form:

    SEASON|2020/2021
    CLUBS|Namungo FC|Coastal Union|...
    1|0>1,2>3,4>5,...

Every transfer was verified by SHA-1 against the browser before loading — a
chunk boundary silently dropped two lines once, in an earlier season.

### Three checks, and each one caught something

`check_source` refuses a whole season rather than writing part of one:

* **no fixture listed twice** — this refused **2016/17**, where FotMob lists
  Kagera Sugar v Stand United in round 2 *and* round 17. The reverse fixture
  exists in neither source, which is why the vault holds 239 fixtures for that
  season and why its round 17 holds seven.
* **every round the same size, and `len(rows) == clubs*(clubs-1)`**.
* **no club in two fixtures in one round** — added during this pass, and it
  refused **2011/12**. Its rounds 19-22 hold 28 fixtures that scramble across
  each other: round 20 has Dodoma Mji twice, round 21 has three clubs twice.

**2011/12's rounds are not recoverable by reasoning.** The 28 fixtures must
decompose into four perfect matchings of the fourteen clubs, and that
decomposition is **not unique** — a search finds more than one, and even a
unique one would not say which block is round 19 and which round 20. RSSSF's
page for that season carries only the final table, no round-by-round results,
and WhoScored has no rounds at all. It is left with none.

### What corroborates FotMob's rounds

Where the vault already had RSSSF's rounds, the two agree essentially perfectly,
which is what justifies trusting FotMob for the fixtures RSSSF left blank:

| Season | agreed | disagreed |
|---|---|---|
| 2014/15 | 156 | 0 |
| 2013/14 | 176 | 0 |
| 2012/13 | 154 | 0 |
| 2015/16 | 238 | 0 |
| 2010/11 | 94 | 0 |
| 2021/22 | 191 | 0 |
| 2020/21 | 88 | 0 |

That is also why 2011/12's clashes read as a defect in that one season rather
than as FotMob deriving round numbers for old seasons generally.

### A round the vault already has is never overwritten

It is kept and the disagreement is written as a **PENDING** `reconciliation_diffs`
row (principle 2), so it survives the terminal. Three came out of this pass:

* **2023/24, four fixtures; 2022/23, five** — every one a Singida Black Stars
  match, and every one settled against the vault by its own kickoff date. The
  round sizes prove it arithmetically: before the fix 2023/24's rounds 1, 17 and
  27 held nine fixtures and 5, 11 and 12 held seven; afterwards all thirty hold
  eight. Same shape in 2022/23. Applied as
  `2026-09-19_tpl_2023_24_singida_rounds.sql` and
  `2026-09-19_tpl_2022_23_singida_rounds.sql`.
* **2025/26, sixteen fixtures — rounds 18 and 19 swapped, and left alone.**
  Chronology cannot adjudicate this one: both sources number out of playing
  order elsewhere in the season (both call the 30 April set round 22, ahead of
  rounds 20 and 21), so neither is simply "the order they were played". The
  sixteen diffs stay PENDING for a human.

**Do not read a disagreement as a defect without checking the round sizes.** In
2023/24 and 2022/23 one round gained an intruder and another lost a fixture, and
in each season one round held eight all along because its intruder and its
absentee cancelled out.

### What still has no round

| Season | fixtures | why |
|---|---|---|
| 2008/09 | 132 | before FotMob's season list, which starts at 2010/11 |
| 2011/12 | 182 | FotMob's rounds contradict themselves; no other source has any |
| 2020/21 | 31 | the Ihefu FC and BIGMAN FC surplus, which FotMob's 306 do not include |
