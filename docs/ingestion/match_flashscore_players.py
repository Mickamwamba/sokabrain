"""Resolve a Flashscore scorer to the player the vault already holds.

Flashscore's timeline abbreviates ("Mwalimu S.") but its player link carries the
whole name as a slug ("mwalimu-seleman"). The vault, for these seasons, already
holds the same men under full names from ligikuu. So the job is to recognise
them, not to create them: a new record for a player the vault has is the defect
this project spent days undoing.

A slug's tokens are the man's name in some order, so a vault player whose name
contains ALL of them, and who has played for that same club, is the same person.
That is strict enough to be safe -- "mwalimu seleman" matches "Seleman Mwalimu"
and nothing else -- and it needs no guess about which token is the surname,
which Flashscore's slugs do not settle ("yonta-camara-abdoulaye").
"""
import re
import unicodedata


def fold(s):
    s = unicodedata.normalize("NFKD", str(s or "")).encode("ascii", "ignore").decode().lower()
    return [t for t in re.split(r"[^a-z]+", s) if t]


def name_from(slug, display=None):
    """A readable full name, used only when the player must be created.

    The slug orders tokens surname-first, so reversing it reads naturally; where
    Flashscore's display name shows the surname, that settles a multi-word one.

    >>> name_from('mwalimu-seleman', 'Mwalimu S.')
    'Seleman Mwalimu'
    >>> name_from('yonta-camara-abdoulaye', 'Yonta Camara A.')
    'Abdoulaye Yonta Camara'
    >>> name_from('zouzoua-peodoh-pacome', 'Zouzoua P.')
    'Peodoh Pacome Zouzoua'
    """
    toks = fold(slug)
    if not toks:
        return None
    surname_toks = []
    if display:
        # The display is "Surname X." -- everything before the final initial.
        d = re.sub(r"\s+[A-Z]\.?$", "", display.strip())
        surname_toks = fold(d)
    if not surname_toks or not all(t in toks for t in surname_toks):
        surname_toks = toks[:1]
    given = [t for t in toks if t not in surname_toks]
    parts = given + surname_toks
    return " ".join(p.capitalize() for p in parts)


def resolve(slug, candidates):
    """The vault player whose name contains every token of the slug.

    `candidates` is [(id, full_name), ...] already narrowed to players who have
    played for the relevant club. Returns (id, how) or (None, 'new').

    >>> resolve('mwalimu-seleman', [(1, 'Seleman Mwalimu'), (2, 'John Mwalimu')])
    (1, 'all tokens')
    >>> resolve('mwalimu-seleman', [(2, 'John Mwalimu')])
    (None, 'new')

    Two vault players containing every token is not a match anyone can make:

    >>> resolve('juma-hassan', [(1, 'Hassan Juma'), (2, 'Juma Hassan')])
    (None, 'ambiguous')
    """
    want = set(fold(slug))
    if not want:
        return (None, "new")
    hits = [pid for pid, nm in candidates if want <= set(fold(nm))]
    if len(hits) == 1:
        return (hits[0], "all tokens")
    if len(hits) > 1:
        return (None, "ambiguous")
    return (None, "new")
