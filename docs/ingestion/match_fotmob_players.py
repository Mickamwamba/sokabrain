"""Decide whether a FotMob scorer is a player the vault already holds.

    python3 -m doctest match_fotmob_players.py

FotMob prints whole names ("Saidi Ntibazonkiza"), so unlike Flashscore there is
no slug to unpack. The risk is the opposite one: a name that reads complete can
still be a shorter or longer rendering of a man the vault already has, and
creating a second record for him is the defect this project has spent days
undoing.

Two names are the same man when one's tokens contain the other's, and only one
candidate from that club qualifies. Containment both ways is needed because
sources truncate in both directions -- FotMob's "Fiston Mayele" against the
vault's "Fiston Kalala Mayele", and FotMob's "Charles Ilanfya Mwakalinga"
against a vault record of "Charles Ilanfya".

A single shared token is never enough. "Prince Dube" and "Prince Mwanza" share a
forename and are two people; the shorter name must have at least two tokens
before it can absorb a longer one.

**The club pool is not enough on its own, because players transfer.** Narrowing
to a club is what makes containment safe, but the vault learns a player's club
from the events and squads it holds, and for a season it has no event log for it
knows nothing. Scoring for Geita Gold in 2022/23 and for Simba in 2023/24, a man
is absent from Geita Gold's pool entirely -- which is how a first pass over this
season proposed 68 new records for players already in the vault.

So `resolve_wide` is a second pass over the whole vault, and it is deliberately
stricter than the first: only an EXACT set of name tokens, matching exactly one
player, counts. Containment across clubs is not enough evidence -- "Hassan
Maulid" sits inside "Hassan Nassor Maulid" while the vault separately holds a
"Hassan Nassor", and no rule can tell those three apart.

Where neither pass decides, the caller creates a player. That is the cheaper
error on purpose: a duplicate record is raised by the audit's Identity checks for
a human to merge, whereas a wrong match silently moves goals onto another man.
"""
import re
import unicodedata


def toks(s):
    """Lowercase, unaccented name tokens.

    >>> toks("Saidi Ntibazonkiza")
    ['saidi', 'ntibazonkiza']
    >>> toks("Jumanne Elfadhili Nimkaza")
    ['jumanne', 'elfadhili', 'nimkaza']
    >>> toks("N'Diaye, Amadou")
    ['n', 'diaye', 'amadou']
    """
    s = unicodedata.normalize("NFKD", str(s or "")).encode("ascii", "ignore").decode().lower()
    return [t for t in re.split(r"[^a-z]+", s) if t]


def resolve(name, candidates):
    """The vault player this name refers to, or (None, why).

    `candidates` is [(id, full_name), ...] already narrowed to players who have
    turned out for the club the scorer played for.

    The vault holding a fuller name is the common case:

    >>> resolve('Fiston Mayele', [(1, 'Fiston Kalala Mayele'), (2, 'John Bocco')])
    (1, 'vault name is fuller')

    So is the reverse, when the new source is the fuller one:

    >>> resolve('Charles Ilanfya Mwakalinga', [(3, 'Charles Ilanfya')])
    (3, 'source name is fuller')

    An exact name is just the first of those:

    >>> resolve('John Bocco', [(2, 'John Bocco')])
    (2, 'vault name is fuller')

    A shared forename is not a match, in either direction. A one-token name is
    contained in half the league, so it only ever matches a vault record that is
    that same single name:

    >>> resolve('Prince Dube', [(4, 'Prince Mwanza')])
    (None, 'new')
    >>> resolve('Prince', [(4, 'Prince Mwanza')])
    (None, 'new')
    >>> resolve('Pokou', [(7, 'Pokou')])
    (7, 'vault name is fuller')

    Two candidates containing the name is nobody's call to make:

    >>> resolve('Juma Hassan', [(5, 'Juma Hassan'), (6, 'Juma Hassan Ally')])
    (None, 'ambiguous')

    An empty or unusable name never resolves:

    >>> resolve('', [(1, 'Fiston Kalala Mayele')])
    (None, 'new')
    """
    want = set(toks(name))
    if not want:
        return (None, "new")
    if len(want) == 1:
        # One token is a forename as often as a surname, and it is contained in
        # half the squad. Only an equally bare vault record can be the same man.
        hits = [pid for pid, nm in candidates if set(toks(nm)) == want]
    else:
        hits = [pid for pid, nm in candidates if want <= set(toks(nm))]
    if len(hits) == 1:
        return (hits[0], "vault name is fuller")
    if len(hits) > 1:
        return (None, "ambiguous")
    if len(want) >= 2:
        # The vault's record is the shorter one. It must still be a real name,
        # not a lone forename that half the league shares.
        back = [pid for pid, nm in candidates
                if len(set(toks(nm))) >= 2 and set(toks(nm)) <= want]
        if len(back) == 1:
            return (back[0], "source name is fuller")
        if len(back) > 1:
            return (None, "ambiguous")
    return (None, "new")


def resolve_wide(name, candidates):
    """The one player in the WHOLE vault whose name is exactly this one.

    Used only after `resolve` has found nothing at the club. Token order does
    not matter -- sources disagree about which part leads:

    >>> resolve_wide('Amza Moubarack', [(1, 'Moubarack Amza'), (2, 'John Bocco')])
    (1, 'same name, one in the vault')

    Containment is not enough this far from a club:

    >>> resolve_wide('Hassan Maulid', [(3, 'Hassan Nassor Maulid')])
    (None, 'new')

    Nor is a name the vault already holds twice -- that is a duplicate for a
    human to merge, and picking one of them would be a guess:

    >>> resolve_wide('Tariq Seif', [(4, 'Tariq Seif'), (5, 'Tariq Seif')])
    (None, 'ambiguous')

    A one-token name is never distinctive enough to cross clubs on:

    >>> resolve_wide('Pokou', [(6, 'Pokou')])
    (None, 'new')
    """
    want = set(toks(name))
    if len(want) < 2:
        return (None, "new")
    hits = [pid for pid, nm in candidates if set(toks(nm)) == want]
    if len(hits) == 1:
        return (hits[0], "same name, one in the vault")
    if len(hits) > 1:
        return (None, "ambiguous")
    return (None, "new")


def display(name):
    """The name to store when the player has to be created.

    FotMob's own casing is kept -- it is already a readable full name -- with
    surrounding whitespace collapsed.

    >>> display('  Saidi   Ntibazonkiza ')
    'Saidi Ntibazonkiza'
    """
    return " ".join(str(name or "").split())
