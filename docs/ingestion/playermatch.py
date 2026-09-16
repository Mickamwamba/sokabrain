"""Decide whether a full name from a new source IS a player the vault holds.

    python3 -m doctest playermatch.py -v

The vault's pre-2002 players are mostly bare surnames, because RSSSF's match
reports print surnames. A source with full names can therefore either repair
those records or double them, and the difference is this file.

The rule is deliberately reluctant. Refusing a true match costs a duplicate
record that the audit's Identity checks will raise for a human; accepting a
false one silently moves goals onto the wrong man, which is what left André Ayew
a goal short and Kalusha Bwalya credited with four goals in a career of ten.
Zambia really did field Kalusha Bwalya and Johnson Bwalya in the same era, and
Zambia's "K.Malitoli" is Kenneth, not the Mordon Malitoli who also played.

So a surname alone is never enough on its own terms: it has to be the only
candidate, no other incoming player may share it, and where the vault records
any forename or initial it must agree.

>>> cands = [(1, 'Tiéhi')]
>>> resolve('Joël Tiéhi', cands, {'tiehi': 1})
('surname', 1)

An initial agrees with the forename it abbreviates, and refuses another:

>>> cands = [(2, 'K.Malitoli')]
>>> resolve('Kenneth Malitoli', cands, {'malitoli': 2})
('initial', 2)
>>> resolve('Mordon Malitoli', cands, {'malitoli': 2})
('new', None)

A recorded forename must actually match:

>>> cands = [(3, 'Kalusha Bwalya')]
>>> resolve('Johnson Bwalya', cands, {'bwalya': 2})
('new', None)
>>> resolve('Kalusha Bwalya', cands, {'bwalya': 2})
('exact', 3)

A forename the vault spells slightly differently still counts, as long as one
spelling leads the other:

>>> resolve('Tchiressoua Guel', [(4, 'Tchiresso Guel'), (5, 'Guel')], {'guel': 1})
('forename', 4)

Two incoming players sharing a surname can never take a bare-surname record,
because there is nothing to say which of them it was:

>>> resolve('Ahmed Ouattara', [(6, 'Ouattara')], {'ouattara': 2})
('new', None)

Nor can an ambiguous surname with no forename agreement:

>>> resolve('Y. Traoré', [(7, 'Alain Traoré'), (8, 'Bertrand Traoré')], {'traore': 1})
('new', None)
"""
import re
import unicodedata


def fold(s):
    """Lowercase, unaccented, punctuation to spaces.

    >>> fold("Joël Tiéhi")
    'joel tiehi'
    >>> fold("K.Malitoli")
    'k malitoli'
    >>> fold("Omam-Biyik")
    'omam biyik'
    """
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode().lower()
    return " ".join(re.sub(r"[^a-z]", " ", s).split())


def words(s):
    return fold(s).split()


def _forename_agrees(incoming, existing):
    """Do two forenames describe the same person?

    >>> _forename_agrees('kenneth', 'k')
    True
    >>> _forename_agrees('mordon', 'k')
    False
    >>> _forename_agrees('tchiressoua', 'tchiresso')
    True
    >>> _forename_agrees('johnson', 'kalusha')
    False
    """
    if not incoming or not existing:
        return False
    if len(existing) == 1 or len(incoming) == 1:
        return incoming[0] == existing[0]
    return incoming.startswith(existing) or existing.startswith(incoming)


def resolve(name, candidates, surname_counts):
    """Match `name` against vault `candidates` [(id, full_name), ...].

    `candidates` must already be narrowed to players who played for the same
    national team, so a Ghanaian Ayew can never absorb a Senegalese one.
    `surname_counts` maps a folded surname to how many DIFFERENT incoming
    players carry it, which is what stops two of them claiming one record.

    Returns (how, player_id), where how is 'exact', 'forename', 'initial',
    'surname' or 'new'.
    """
    w = words(name)
    if not w:
        return ("new", None)
    target = fold(name)
    for pid, existing in candidates:
        if fold(existing) == target:
            return ("exact", pid)

    surname = w[-1]
    same_surname = [(pid, existing) for pid, existing in candidates
                    if words(existing) and words(existing)[-1] == surname]
    if not same_surname:
        return ("new", None)

    incoming_forename = w[0] if len(w) > 1 else ""
    named = [(pid, e) for pid, e in same_surname if len(words(e)) > 1]
    bare = [(pid, e) for pid, e in same_surname if len(words(e)) == 1]

    agreeing = [(pid, e) for pid, e in named
                if _forename_agrees(incoming_forename, words(e)[0])]
    if len(agreeing) == 1:
        pid, existing = agreeing[0]
        initial = len(words(existing)[0]) == 1
        return ("initial" if initial else "forename", pid)
    if agreeing:
        return ("new", None)              # two plausible people; choose neither

    # No forename to go on. A bare surname can only be claimed by one incoming
    # player, and only when the vault holds exactly one such record.
    if len(bare) == 1 and not named and surname_counts.get(surname, 0) == 1:
        return ("surname", bare[0][0])
    return ("new", None)
