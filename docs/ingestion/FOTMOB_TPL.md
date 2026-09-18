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
