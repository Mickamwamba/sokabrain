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
