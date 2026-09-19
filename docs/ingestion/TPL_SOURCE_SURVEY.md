# Which sources actually have Tanzanian Premier League goalscorers

Surveyed 2026-09-18, for the two seasons that still need scorer names: 2019/20
(210 goals unattributed) and 2018/19 (34). **Every claim here was tested by
loading the page and reading its DOM**, not by reading a search result or a page
summary — twice in this survey a summariser reported scorers that the page does
not contain.

| Source | Season coverage | Per-match scorers | Verdict |
|---|---|---|---|
| **Flashscore** | results page reaches back only ~4 months | full names via player links | **used**; the only source that both has names and agrees with the vault |
| Soccerway | identical 106 matches, no pager | — | **the same platform as Flashscore** (redirects to a Flashscore-style URL); not an independent source |
| Livesport | — | — | same group again |
| **footballdatabase.eu** | **all 38 rounds, Aug 2019 onward** | **almost none** | fixtures and scores only |
| **BeSoccer** | full season, all rounds | abbreviated ("P. Liponda") | **rejected on accuracy** — see below |
| FotMob | fixtures and scores | none before 2020/21 | established earlier, `FOTMOB_TPL.md` |
| Transfermarkt | no Tanzanian league | — | no |
| worldfootball.net | no Tanzanian league slug | — | no |

## Flashscore's reach is the season's tail, not the season

Its per-season results page has **no "show more" button at all** and lists only
the last few months:

| Season | matches listed | earliest |
|---|---|---|
| 2019/20 | 106 of 380 | 14 March 2020 |
| 2018/19 | 104 of 380 | 10 March 2019 |

That still covered 206 of 2019/20's 346 unattributed goals and 54 of 2018/19's
63, because the unattributed goals are not spread evenly.

## footballdatabase.eu: the full fixture list, and no scorers

It has a clean per-round URL — `/en/competition/overall/12405-ligi_kuu_tanzania_bara/2019-2020/{193825-N}-journee_{N}`
for rounds 1 to 31 — and the numeric match id alone resolves
(`/en/match/overview/1900787`). 279 non-goalless matches were collected this way.

**But 19 of 20 match pages sampled say "No key stat for this match".** Only one,
JKT Tanzania 1-3 Simba (round 1), carried scorers. Sampling covered August 2019
through July 2020 and included big-club fixtures, in case coverage tracked them;
it does not.

**What it is still worth**: all **279 of its fixtures matched a vault fixture
with the score agreeing exactly, zero conflicts.** That is an independent
confirmation of 2019/20's scores and of the club identifications — including
that its oddly-labelled "DT Bank" (slug `singida_fountain_gate`) is the club the
vault holds as Singida Black Stars, since all 38 of that club's fixtures line up.

## BeSoccer: has the data, disagrees with it

BeSoccer is the only source found with named scorers for the early 2019/20
season, reachable by setting its 38-option round selector. Its August 2019
matches do carry scorers.

**It was rejected because it disagrees with Flashscore too often to load blind.**
Compared on four matches both cover:

| Match | Result |
|---|---|
| Mbao 2-0 Ndanda | both scorers agree |
| KMC 0-3 Mbeya City | 2 of 3 agree; third is Chidiebere (Flashscore) against P. Mapunda (BeSoccer) |
| Mtibwa 2-1 Ruvu Shooting | 2 of 3 agree; the away goal is Sadat Mohamed against S. Nanguo |
| Tanzania Prisons 2-2 Azam | differs on minutes and on which player scored the own goal |

Roughly a third of goals disagree, and **nothing available adjudicates between
them** — there is no third source with names for these matches. Loading BeSoccer
would mean overwriting or contradicting Flashscore-derived names on a coin flip.

It also only gives an initial and a surname ("P. Liponda"), including in its
player-link slugs, so full names would need a second pass over player pages —
and planting abbreviations is the identity defect this project has spent days
undoing.

**If BeSoccer is ever revisited**, the way to use it is as a *third* opinion on
matches where two sources already disagree, not as a primary source.

## What remains unreachable

140 of 2019/20's unattributed goals and 9 of 2018/19's fall outside Flashscore's
window, and no surveyed source has trustworthy names for them.
