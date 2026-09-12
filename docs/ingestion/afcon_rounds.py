"""Work out which round each AFCON match belongs to.

WhoScored labels its stages inconsistently across the 13 tournaments:

  2002-2017   4 groups + 'quarter finals' + 'semi finals' + 'bronze match'
              + 'final'                                   -- round is given
  2019        6 groups + '1/8 Finals' + the same four     -- round is given
  2021,2023,  6 groups + a single 'Final Stage' holding
  2025        all 16 knockout matches                     -- round is NOT given

For the first two shapes the stage name is the answer. For 'Final Stage' the
round has to be derived, and a derived round that is merely plausible is not
good enough -- it decides whether a match is recorded as a final or as a
round-of-16 tie. So the derivation is ordered by kickoff and then **verified
against the bracket**: every quarter-finalist must have won a round-of-16 tie,
every semi-finalist a quarter-final, the finalists must be the two semi-final
winners and the third-place pair the two semi-final losers.

`derive_knockout_rounds` raises rather than guessing if any of that fails.
"""

GROUP = "GROUP"
R16 = "ROUND OF 16"
QF = "QUARTER FINAL"
SF = "SEMI FINAL"
THIRD = "THIRD PLACE"
FINAL = "FINAL"

# Stage-name spellings seen across the 13 tournaments, lowercased.
_STAGE_ROUNDS = {
    "quarter finals": QF,
    "semi finals": SF,
    "bronze match": THIRD,
    "final": FINAL,
    "1/8 finals": R16,
}

# The shape of a 24-team knockout: 8 ties, then 4, then 2, then the two
# one-off matches. Order matters -- it is consumed in sequence by date.
_LADDER = [(R16, 8), (QF, 4), (SF, 2)]


def stage_round(stage_name):
    """Round for a stage whose name states it, else None.

    None means the caller must derive it (the 'Final Stage' case).
    """
    s = stage_name.strip().lower()
    if s.startswith("grp."):
        return GROUP
    return _STAGE_ROUNDS.get(s)


def group_letter(stage_name):
    """'Grp. C' -> 'C'. None for anything that is not a group stage."""
    s = stage_name.strip()
    if s.lower().startswith("grp."):
        return s.split(".", 1)[1].strip().upper() or None
    return None


def winner(m):
    """Team that advanced, by score then shootout. None if genuinely drawn.

    A knockout tie that is level after extra time is settled on penalties, so
    the shootout is the tiebreak, never the goal total.
    """
    if m["home_score"] is None or m["away_score"] is None:
        return None
    if m["home_score"] != m["away_score"]:
        return m["home_team"] if m["home_score"] > m["away_score"] else m["away_team"]
    hp, ap = m.get("home_pens"), m.get("away_pens")
    if hp is None or ap is None or hp == ap:
        return None
    return m["home_team"] if hp > ap else m["away_team"]


def loser(m):
    w = winner(m)
    if w is None:
        return None
    return m["away_team"] if w == m["home_team"] else m["home_team"]


def derive_knockout_rounds(matches):
    """Assign rounds to one tournament's lumped 'Final Stage' matches.

    `matches` is every match in that stage, each a dict with kickoff_utc,
    home_team, away_team, home_score, away_score, home_pens, away_pens.
    Returns {match_id: round}. Raises ValueError if the bracket does not
    hold together, rather than returning a guess.
    """
    if len(matches) != 16:
        raise ValueError(f"expected 16 knockout matches, got {len(matches)}")

    ordered = sorted(matches, key=lambda m: (m["kickoff_utc"], m["match_id"]))
    assigned, i = {}, 0
    rounds = {}
    for name, count in _LADDER:
        chunk = ordered[i:i + count]
        rounds[name] = chunk
        for m in chunk:
            assigned[m["match_id"]] = name
        i += count

    # The last two are the third-place match and the final, in some order.
    tail = ordered[i:]
    if len(tail) != 2:
        raise ValueError(f"expected 2 matches after the semi-finals, got {len(tail)}")

    sf_winners = {winner(m) for m in rounds[SF]}
    sf_losers = {loser(m) for m in rounds[SF]}
    if None in sf_winners or None in sf_losers:
        raise ValueError("a semi-final has no decidable winner; cannot place the final")

    final_m = third_m = None
    for m in tail:
        pair = {m["home_team"], m["away_team"]}
        if pair == sf_winners:
            final_m = m
        elif pair == sf_losers:
            third_m = m
    if final_m is None or third_m is None:
        raise ValueError(
            "could not identify the final and third-place match from the "
            f"semi-final winners {sorted(sf_winners)} and losers {sorted(sf_losers)}; "
            f"tail pairs were {[sorted([m['home_team'], m['away_team']]) for m in tail]}"
        )
    assigned[final_m["match_id"]] = FINAL
    assigned[third_m["match_id"]] = THIRD

    _verify_ladder(rounds)
    return assigned


def _verify_ladder(rounds):
    """Each round's teams must be the previous round's winners."""
    for earlier, later in ((R16, QF), (QF, SF)):
        advanced = {winner(m) for m in rounds[earlier]}
        if None in advanced:
            raise ValueError(f"a {earlier} tie has no decidable winner")
        playing = set()
        for m in rounds[later]:
            playing.add(m["home_team"])
            playing.add(m["away_team"])
        if playing != advanced:
            raise ValueError(
                f"{later} line-up does not match {earlier} winners.\n"
                f"  only in {later}: {sorted(playing - advanced)}\n"
                f"  only in {earlier} winners: {sorted(advanced - playing)}"
            )
