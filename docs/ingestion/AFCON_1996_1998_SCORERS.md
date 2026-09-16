# AFCON 1996 and 1998: who scored

The vault held both tournaments as complete results — 61 matches, every score
right — and named a scorer for **4 of their 171 goals**. RSSSF's pages for these
two years print results without scorer lines. Wikipedia prints them, and this
pipeline moves them across.

Coverage across all 35 AFCON tournaments went from **91% to 99.6%**
(1,999 of 2,007 goals). Five players on the published all-time scoring list
were short only because of this gap, and four of them now match it exactly:
**Hossam Hassan 11**, **Kalusha Bwalya 10**, **Joel Tiéhi 10**, **Benni
McCarthy 7**. Abedi Pele reached 6 of 7; his last goal is in a pre-1996
tournament, not here.

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
  teams plus a date within a day. All 61 did.
* **Sides are reversed in 18 of the 61.** The two sources disagree about who was
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
