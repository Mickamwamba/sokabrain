# AFCON scorers from Wikipedia: 1980, 1994, 1996, 1998

RSSSF gives these four tournaments' results but not all of their scorers — none
at all for 1996 and 1998, and a handful of gaps in 1980 and 1994. Wikipedia
names them, and this pipeline moves them across.

Across all 35 AFCON tournaments, goals with a named scorer went from **91% to
99.90%** — 2,005 of 2,007. **Two** goals are still unnamed, both in matches whose
source is missing the goal *event* itself, which no amount of naming fixes:
Tunisia 1-1 Angola (2019) and Zambia 1-1 Tanzania (2023).

Five players on the published all-time scoring list were short only because of
this gap, and four now match it exactly: **Hossam Hassan 11**, **Kalusha Bwalya
10**, **Joel Tiéhi 10**, **Benni McCarthy 7**. Abedi Pele reached 6 of 7; his
last goal is in a tournament this did not touch.

Run in two passes, because the years differ in what they needed:

| | Matches | Goals staged | Events written |
|---|---|---|---|
| 1996 + 1998 | 61 | 171 | 167 in 59 matches |
| 1980 + 1994 | 36 | 77 | 5 in 1 match |

The second pass wrote little because those two years were nearly complete
already: every match that **already had goal events was skipped, not added to**,
so only the one match with none (Algeria 3-2 Guinea, 1980) loaded. The last
straggler, Ghana's goal in the 1994 quarter-final, was a single existing event
with no scorer, so it was named by hand in
`docs/reconciliation/fixes/2026-09-16_akonnor_1994_quarter_final.sql` rather than
loaded — adding an event there would have given the match four goals for a 1-2.

```
fetch_wikipedia_afcon.py       article wikitext -> raw/afcon_wikipedia/YYYY.wikitext
normalize_wikipedia_afcon.py   wikitext -> canonical matches + goals (canon.json)
validate_wikipedia_afcon.py    canon.json vs the vault: no writes, reports everything
playermatch.py                 is this full name a player we already hold? (doctested)
load_wikipedia_afcon_scorers.py  canon.json -> match_events, with provenance
```

Re-run it end to end with:

```
python3 fetch_wikipedia_afcon.py 1996 1998
python3 normalize_wikipedia_afcon.py 1996 1998 > raw/afcon_wikipedia/canon.json
python3 validate_wikipedia_afcon.py raw/afcon_wikipedia/canon.json
python3 load_wikipedia_afcon_scorers.py raw/afcon_wikipedia/canon.json --commit
```

and for the second pass, identically with `1980 1994` and
`canon_1980_1994.json`. The loader is safe to re-run: a match that already has
goal events is never added to.

## Why wikitext and not the rendered page

The match data lives in `{{football box}}` templates whose arguments are exactly
the fields wanted — date, teams, score, and a goal list with minutes. Rendering
throws that structure away. `?action=raw` returns the source, and the raw
articles are kept so a parser change never needs a refetch.

## The goal grammar

Every form observed in the two articles, all handled:

| Written | Means |
|---|---|
| `{{goal\|15}}` | one goal, 15' |
| `{{goal\|30\|\|33}}` | the same player twice; the empty argument is a separator |
| `{{goal\|36\|pen.}}` | a penalty |
| `{{goal\|90\|o.g.}}` | an own goal |
| `{{goal\|57\|pen.\|73\|pen.}}` | two penalties |
| `{{goal\|16\|\|85\|pen.}}` | one ordinary goal, one penalty |
| `{{golden goal\|105}}` | the 1996 quarter-final winner |
| `{{goal\|90+3}}` | stoppage time, kept in `added_time`, not flattened to 90' |

A numeric argument opens a goal; a following non-numeric argument qualifies the
goal just opened. Anything unrecognised is **reported, never dropped** — the
lesson of the first RSSSF load, which silently recorded five penalties as
ordinary goals because it did not understand `55pen`.

Two subtleties that each cost a goal if missed:

* **A scorer can be inherited.** `[[Benni McCarthy|McCarthy]] {{goal|60}},
  {{golden goal|112}}` is one man scoring twice. A goal template preceded by
  nothing but punctuation belongs to the previous scorer; treating it as
  anonymous left that match a goal short of its own score, which is how the
  problem was noticed.
* **Names come from the link target, not the display text.** `[[Phil
  Masinga|Masinga]]` gives "Phil Masinga". That is the whole value of this
  source: the vault holds these players as surnames, and a full name is what
  lets the loader recognise one. Wikipedia's disambiguators are stripped —
  "Mark Williams (South African footballer)" is an article title, not a name.

## What the validator checks before anything loads

* **Every staged match finds exactly one vault match**, on the unordered pair of
  teams plus a date within a day. All 61 and all 36 did.
* **Sides are reversed in 18 of the 61, and 2 of the 36.** The two sources disagree about who was
  at home; RSSSF has "Guinea 2-2 Madagascar" where Wikipedia has Madagascar
  first. In every case the score agrees once flipped, so the disagreement is
  presentational and the goals are mapped onto the vault's orientation. **The
  vault's fixture is never rewritten.** A score that did *not* agree once
  flipped would be a reconciliation question, not an overwrite (principle 2).
* **Every match's goal list adds up to its own score** — all 61, before loading.
* **Which vault players these names resolve to**, which is the part that matters
  most after merging 45 duplicate records in September 2026.

## Player identity, and the two traps in it

`playermatch.py` decides whether an incoming full name IS a player the vault
already holds. It is deliberately reluctant, because the two outcomes are not
symmetrical: refusing a true match costs a duplicate record that the audit's
Identity checks raise for a human, while accepting a false one silently moves
goals onto the wrong man.

Of 107 names, **24 attached to existing players and 82 were created**, with no
two incoming players ever landing on one record. The rules, in order: an exact
name; a forename that agrees (`Tchiressoua Guel` → `Tchiresso Guel`); an initial
that agrees (`Kenneth Malitoli` → `K.Malitoli`); or a bare surname, but only
when the vault holds exactly one such record **and** only one incoming player
carries that surname.

That last condition is not fussiness. The first draft matched on surname alone
and produced two wrong answers immediately:

* **Johnson Bwalya → Kalusha Bwalya.** Zambia fielded both. Kalusha is on the
  all-time list, and would have finished on 12 against a real 10.
* **Kenneth Malitoli and Mordon Malitoli → the same record.** Zambia fielded
  both of them too.

Both are now separate records, and the audit reports the Malitoli pair — and a
bare "Y. Traoré" that sits beside three named Burkinabè Traorés — as candidates
for someone to judge.

## What was deliberately not touched

**Both finals already had their scorers from RSSSF, and were left alone.** They
are the only two of the 61 matches that did, and they are a free cross-source
check: Wikipedia names the same men. South Africa 2-0 Tunisia is Mark Williams
twice (Wikipedia 73' and 75', the vault 72' and 74' — a minute apart, and the
minutes were not changed); Egypt 2-0 South Africa is Ahmed Hassan 5' and Tarek
Mostafa 13', which is exactly what the vault holds.

Own goals are stored under the **scorer's own team** (principle 5). Wikipedia,
like RSSSF and ligikuu before it, lists them under the side they count for.
There is one in these two tournaments.

## What the second pass added to the pipeline

Two things, both of which the normalizer **reported rather than swallowed** —
which is the only reason they were noticed:

* **Five more team codes.** 1980 and 1994 bring Nigeria (as both `NGA` and
  `NGR`), Mali, Senegal and Tanzania. An unmapped code aborts that match instead
  of guessing at it.
* **Stoppage time.** `{{goal|90+3}}` is a 90th-minute-plus-three goal, and the
  vault has an `added_time` column for exactly that, so it is stored apart
  rather than flattened into the minute. Two goals in 1980 use it. Checked
  afterwards: 1996 and 1998 contain no such notation, so the earlier pass lost
  nothing.

## A thing this made possible, not yet done

The skipped matches print what Wikipedia says about them, and for these years
that is a full name where the vault holds a surname — "Muda Lawal 11'" against
the vault's bare "Lawal". Nigeria has four Lawal records and the audit flags
them; Wikipedia's 1980 match reports could settle which goals belong to Muda
Lawal and which to another. That is an identity question for a human, on the
evidence this harvest now provides, and nothing here presumes it.
