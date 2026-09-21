#!/usr/bin/env python3
"""Name the goals a provider left as initials, using a league's own player directory.

    python3 topup_scorers_from_directory.py 872 28542            # dry run
    python3 topup_scorers_from_directory.py 872 28542 --commit
    python3 topup_scorers_from_directory.py 1423 28106 \
        --directory raw/upl/players.json --source upl

**Two leagues, two directories, one script.** Rwanda's directory is an index
whose rows abbreviate too, so the real name comes from a second fetch of
`players.php?id=N`. Uganda's runs SportsPress and hands over the full name in
the listing itself, so a row carrying `full_name` is used as it stands and
nothing is fetched. Pass `--source` to name the source the rows came from:
provenance must record the site the name actually came from (principle 1), and
this was hardcoded to Rwanda's until Uganda arrived.

SportMonks publishes this league's scorers as a display string, and for the
Rwandan league that string is usually an abbreviation -- "G. Ndonga Bivula" --
with no player id behind it. `load_fotmob_tpl.py`'s rule applies: an
abbreviation is never written into the player table, because planting one
rebuilds the identity problem this project has spent days undoing. So those
goals were loaded UNATTRIBUTED, which is the truth but not the whole of it.

The league's own site publishes a directory of every registered player. Scoping
a surname to a club usually leaves exactly one candidate, and that player's page
carries the real name. This fills the gap the honest way: the goal was already
in the vault, and only its scorer was unknown.

**It only ever fills a NULL.** An event that already names someone is never
touched, whatever the directory says -- that would be overwriting one source
with another (principle 2), and the existing name usually came from a better
one.

Three refusals, each of which stops a wrong name rather than a missing one:

* **Ambiguity.** Two players sharing a surname at one club resolves to nobody.
* **A name that does not agree.** Gicumbi's directory holds one Tuyisenge, and
  SportMonks shows goals for both "J. Tuyisenge" and "A. Tuyisenge"; matching on
  surname alone credited both to the same man. And Gorilla's "I. Sunday"
  resolved to "Albert Steven Ishimwe", whose I matches Ishimwe though the man is
  Inemesit Sunday Akang. So the resolved name must carry every initial AND every
  written word of the abbreviation.
* **A name that is still an abbreviation** after resolution.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import time
import unicodedata
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fetch_rpl_players import get as rpl_get, title_of  # noqa: E402

import psycopg2  # noqa: E402

DSN = "host=127.0.0.1 port=5432 dbname=sokabrain"
GOAL_TYPES = ("GOAL", "PENALTY_GOAL", "OWN_GOAL")
SM = "https://api.sportmonks.com/v3/football"


def token(name: str) -> list[str]:
    """Lower-case, accent-stripped word tokens.

    >>> token("Gédéon Ndonga Bivula")
    ['gedeon', 'ndonga', 'bivula']
    """
    s = unicodedata.normalize("NFD", name or "")
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return [t for t in re.sub(r"[^a-z0-9 ]", " ", s.lower()).split() if t]


def initials_and_surnames(listed: str) -> tuple[list[str], list[str]]:
    """Split an abbreviated name into its initials and its real words.

    >>> initials_and_surnames("G. Ndonga Bivula")
    (['g'], ['ndonga', 'bivula'])
    >>> initials_and_surnames("Chukwuma O.")
    (['o'], ['chukwuma'])
    """
    ini, sur = [], []
    for t in token(listed):
        (ini if len(t) == 1 else sur).append(t)
    return ini, sur


def name_agrees(abbrev: str, full: str) -> bool:
    """Does a resolved full name actually match the abbreviation it answers?

    Two conditions, and the second is the one that matters most:

    * every initial must start some word of the full name, and
    * every WRITTEN word of the abbreviation must appear in the full name.

    Without the second, the crossed-initial pass hands back plausible nonsense.
    Gorilla's "I. Sunday" resolved to "Albert Steven Ishimwe" -- the I matched
    Ishimwe and nothing objected, though the man is Inemesit Sunday Akang. A
    goal was one step from being credited to the wrong player.

    >>> name_agrees("J. Tuyisenge", "Jean Merveil Tuyisenge")
    True
    >>> name_agrees("A. Tuyisenge", "Jean Merveil Tuyisenge")
    False
    >>> name_agrees("U. Fidali", "Fidali Uwiyaremye")
    True
    >>> name_agrees("I. Sunday", "Albert Steven Ishimwe")
    False
    """
    ini, sur = initials_and_surnames(abbrev)
    words = token(full)
    firsts = {w[0] for w in words}
    return all(i in firsts for i in ini) and all(s in words for s in sur)


# The provider and the league's own site do not spell every club the same way.
CLUB_ALIASES = {
    "marines": "marine",
    "al hilal omdurman": "al hilal",
    "al merreikh": "al merrikh",
    "as kigali": "kigali",
    "police rwanda": "police",
    # Uganda: the provider spaces a name the directory runs together, and drops
    # the second word of another. Both verified against the directory's own club
    # list rather than guessed -- every other Ugandan club key matches exactly.
    "kigezi home boyz": "kigezi homeboyz",
    "lugazi municipal": "lugazi",
}


def tidy_name(name: str) -> str:
    """Even out the shouting the source does to some surnames.

    The directory writes "HAKIZIMANA Steven" and "Jean Merveil TUYISENGE". These
    names are going on a public page beside names from three other sources, so
    an all-capitals word is title-cased. Anything with its own internal capital
    or punctuation is left exactly alone -- "M'bareck" and "McCarthy" are how
    they are spelled, not shouting.

    >>> tidy_name("HAKIZIMANA Steven")
    'Hakizimana Steven'
    >>> tidy_name("Jean Merveil TUYISENGE")
    'Jean Merveil Tuyisenge'
    >>> tidy_name("Ahmed Salem M'bareck")
    "Ahmed Salem M'bareck"
    """
    out = []
    for w in name.split():
        letters = [c for c in w if c.isalpha()]
        if len(letters) > 1 and all(c.isupper() for c in letters):
            out.append(w.capitalize())
        else:
            out.append(w)
    return " ".join(out)


def club_key(name: str) -> str:
    """A club name reduced to something both sources agree on.

    >>> club_key("MARINE FC"), club_key("Marines")
    ('marine', 'marine')
    >>> club_key("Al Hilal Omdurman"), club_key("Al Hilal SC")
    ('al hilal', 'al hilal')
    """
    k = " ".join(w for w in token(name) if w not in ("fc", "sc", "vs"))
    return CLUB_ALIASES.get(k, k)


def sm_fixtures(tok: str, season: int):
    out, page = [], 1
    while page < 12:
        url = (
            f"{SM}/fixtures?filters=fixtureSeasons:{season}"
            "&include=participants;events.type&per_page=50&page=" + str(page)
        )
        req = urllib.request.Request(url, headers={"Authorization": tok})
        body = json.load(urllib.request.urlopen(req, timeout=60))
        out += body.get("data", [])
        if not (body.get("pagination") or {}).get("has_more"):
            break
        page += 1
    return out


def load_directory(paths):
    rows = {}
    for p in paths:
        for r in json.load(open(p, encoding="utf-8")):
            rows[r["id"]] = r
    index, crossed = {}, {}
    for r in rows.values():
        ini, sur = initials_and_surnames(r["listed"] or "")
        ck = club_key(r["club"] or "")
        for s in sur:
            index.setdefault((ck, s), set()).add(r["id"])
        # The two sources do not agree on which name is the surname: SportMonks
        # writes "U. Fidali" where the directory writes "F. Uwiyaremye", and both
        # mean Fidali Uwiyaremye. There is no shared token, but the initials
        # cross over -- each side's initial is the first letter of the other
        # side's surname. Indexed separately, and only used when the direct
        # match finds nothing, because initials alone are weak evidence.
        for i in ini:
            for s in sur:
                crossed.setdefault((ck, i, s[0]), set()).add(r["id"])
    return rows, index, crossed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("league", type=int)
    ap.add_argument("season", type=int)
    ap.add_argument("--directory", nargs="+",
                    default=["raw/rpl/players_2026-2027.json", "raw/rpl/players_2025-2026.json"])
    ap.add_argument("--source", default="rwandapremierleague",
                    help="data_sources.name the directory rows came from")
    ap.add_argument("--commit", action="store_true")
    ap.add_argument("--doctest", action="store_true")
    args = ap.parse_args()
    if args.doctest:
        import doctest
        print(doctest.testmod())
        return

    tok = None
    for line in open(os.path.join(os.path.dirname(__file__), "../../backend/.env")):
        if line.startswith("SPORTMONKS_TOKEN="):
            tok = line.split("=", 1)[1].strip()
    if not tok:
        raise SystemExit("SPORTMONKS_TOKEN not found in backend/.env")

    rows, index, crossed = load_directory(args.directory)
    print(f"directory: {len(rows)} players")

    conn = psycopg2.connect(DSN)
    conn.autocommit = False
    cur = conn.cursor()
    cur.execute("SET timezone='UTC'")

    # provider fixture id -> vault match id
    cur.execute("""
        SELECT external_id, entity_id FROM entity_source_map
         WHERE entity_type='match'
           AND data_source_id=(SELECT id FROM data_sources WHERE name='sportmonks')
    """)
    match_of = {e: i for e, i in cur.fetchall()}
    # provider team id -> vault team id
    cur.execute("""
        SELECT external_id, entity_id FROM entity_source_map
         WHERE entity_type='team'
           AND data_source_id=(SELECT id FROM data_sources WHERE name='sportmonks')
    """)
    team_of = {e: i for e, i in cur.fetchall()}

    fixtures = sm_fixtures(tok, args.season)
    print(f"provider fixtures: {len(fixtures)}")

    name_cache: dict[int, str | None] = {}
    plan, refused = [], []

    for f in fixtures:
        vault_match = match_of.get(str(f["id"]))
        if vault_match is None:
            continue
        clubs = {p["id"]: p["name"] for p in f.get("participants", [])}
        home = next((p["id"] for p in f.get("participants", []) if p["meta"]["location"] == "home"), None)
        for e in f.get("events", []) or []:
            tname = (e.get("type") or {}).get("name")
            if tname not in ("Goal", "Own Goal", "Penalty"):
                continue
            listed = e.get("player_name") or ""
            ini, sur = initials_and_surnames(listed)
            if e.get("player_id") or not ini or not sur:
                continue  # already resolvable, or nothing to work with

            # The vault stores an own goal under the SCORER's own team, and the
            # provider files it under the side it counts for (principle 5).
            credited = e["participant_id"]
            scorer_team = credited
            if tname == "Own Goal":
                scorer_team = next(
                    (p["id"] for p in f.get("participants", []) if p["id"] != credited), credited)
            vteam = team_of.get(str(scorer_team))
            if vteam is None:
                continue

            ck = club_key(clubs.get(scorer_team, ""))
            cands: set[int] = set()
            for s in sur:
                cands |= index.get((ck, s), set())
            if not cands:
                # Fall back to the crossed-initial reading, still requiring the
                # club to agree and the answer to be unique.
                for i in ini:
                    for s in sur:
                        cands |= crossed.get((ck, s[0], i), set())
            if not cands:
                refused.append(f"{listed!r} ({clubs.get(scorer_team)}): no directory row")
                continue

            # Resolve every candidate and keep the ones the abbreviation actually
            # agrees with. Requiring uniqueness BEFORE reading the names threw
            # away answers the initial settles: Blacks Power field both Richard
            # Oscar Otim and Daniel Otim, so "R. Otim" looked ambiguous on the
            # surname alone though only one of them has an R. The guard is
            # unchanged -- it is applied to each candidate rather than to the one
            # that happened to be alone -- and two men who BOTH agree are still
            # refused, which is what keeps a brother pair from being guessed at.
            agreed: list[tuple[int, str]] = []
            for pid in sorted(cands):
                if pid not in name_cache:
                    # A directory that already carries the full name needs no
                    # second request; Rwanda's abbreviates its own listing, so
                    # its answer is on the player's page.
                    listed_full = (rows[pid].get("full_name") or "").strip()
                    if listed_full:
                        name_cache[pid] = listed_full
                    else:
                        name_cache[pid] = title_of(rpl_get(f"/players.php?id={pid}"))
                        time.sleep(0.4)
                full = tidy_name(name_cache[pid]) if name_cache[pid] else None
                if not full or [t for t in token(full) if len(t) == 1]:
                    continue  # no name, or still an abbreviation
                if name_agrees(listed, full):
                    agreed.append((pid, full))

            if len(agreed) != 1:
                resolved = [full for _, full in
                            ((p, tidy_name(name_cache[p])) for p in sorted(cands))
                            if full]
                refused.append(
                    f"{listed!r} ({clubs.get(scorer_team)}): "
                    + (f"{len(agreed)} candidates agree" if agreed
                       else f"no candidate agrees, saw {resolved}"))
                continue
            pid, full = agreed[0]

            minute = e.get("minute")
            etype = {"Goal": "GOAL", "Penalty": "PENALTY_GOAL", "Own Goal": "OWN_GOAL"}[tname]
            plan.append({
                "match": vault_match, "team": vteam, "minute": minute,
                "type": etype, "listed": listed, "full": full, "directory_id": pid,
            })

    print(f"\nabbreviated goals the directory can name: {len(plan)}")
    for p in plan:
        print(f"   match {p['match']} {p['minute']}' {p['type']:<12} {p['listed']!r} -> {p['full']!r}")
    if refused:
        print(f"\nrefused ({len(refused)}):")
        for r in refused[:20]:
            print(f"   {r}")

    written = created = skipped = 0
    for p in plan:
        cur.execute("""
            SELECT id FROM match_events
             WHERE match_id=%s AND team_id=%s AND type=%s AND player_id IS NULL
               AND (minute IS NOT DISTINCT FROM %s)
             ORDER BY id LIMIT 1
        """, (p["match"], p["team"], p["type"], p["minute"]))
        row = cur.fetchone()
        if not row:
            skipped += 1
            continue
        event_id = row[0]

        cur.execute("""
            SELECT entity_id FROM entity_source_map
             WHERE entity_type='player'
               AND data_source_id=(SELECT id FROM data_sources WHERE name=%s)
               AND external_id=%s
        """, (args.source, str(p["directory_id"])))
        hit = cur.fetchone()
        if hit:
            player_id = hit[0]
        else:
            cur.execute("SELECT id FROM players WHERE full_name=%s", (p["full"],))
            same = cur.fetchall()
            if len(same) == 1:
                player_id = same[0][0]
            else:
                cur.execute("INSERT INTO players (full_name) VALUES (%s) RETURNING id", (p["full"],))
                player_id = cur.fetchone()[0]
                created += 1
            cur.execute("""
                INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
                VALUES ('player', %s, (SELECT id FROM data_sources WHERE name=%s), %s, 1.0)
                ON CONFLICT DO NOTHING
            """, (player_id, args.source, str(p["directory_id"])))

        cur.execute("UPDATE match_events SET player_id=%s WHERE id=%s AND player_id IS NULL",
                    (player_id, event_id))
        cur.execute("""
            INSERT INTO entity_source_map (entity_type, entity_id, data_source_id, external_id, confidence)
            VALUES ('match_event', %s, (SELECT id FROM data_sources WHERE name=%s), %s, 1.0)
            ON CONFLICT DO NOTHING
        """, (event_id, args.source, f"{p['match']}-{p['minute']}-{p['type']}"))
        written += 1

    print(f"\n{written} event(s) named, {created} player(s) created, "
          f"{skipped} had no matching unattributed event")
    if args.commit:
        conn.commit()
        print("COMMITTED")
    else:
        conn.rollback()
        print("rolled back (dry run) -- pass --commit to apply")
    conn.close()


if __name__ == "__main__":
    main()
