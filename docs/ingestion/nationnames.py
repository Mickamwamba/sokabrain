"""One canonical name per national team, so WhoScored joins onto the vault.

The club-side equivalent is `teamnames.py`. This file exists for the same
reason and one extra one: the vault's national teams came in with the legacy
SokaFC migration and several are **misspelled**. Those spellings are the
canonical ones here, because they are what `teams.name` actually holds -- the
job of this map is to join, not to correct. Renaming them is a separate change
that would have to move `entity_source_map` rows with it.

Check this file before adding a national team, or a spelling variant will
silently split one country's history in two.
"""
import re
import unicodedata

# Key is the canonical vault name, exactly as `teams.name` spells it.
# Values are the spellings other sources use.
ALIASES = {
    # -- vault misspellings. The alias is the correct spelling. --
    "Morroco":            ["Morocco"],
    "Equtorial Guinea":   ["Equatorial Guinea"],
    "Sierra Leon":        ["Sierra Leone"],
    # -- genuine naming variants --
    "Cape Verde":         ["Cabo Verde", "Cape Verde Islands"],
    "DR Congo":           ["Congo DR", "Congo-Kinshasa", "Zaire"],
    "Congo":              ["Congo-Brazzaville", "Rep. Congo"],
    "Ivory Coast":        ["Cote d'Ivoire", "Côte d'Ivoire"],
    "Swaziland":          ["Eswatini"],
}

# Tanzania exists TWICE in the vault: "Taifa Stars" (id 23) and "Tanzania"
# (id 91), both NATIONAL, both pointing at Tanzania. They are the same team.
# The legacy AFCON 2019 edition uses 91, so 91 is canonical here and 23 is
# left alone rather than merged -- merging is a data fix, not an ingest
# decision, and is recorded as an open item in the ingestion README.
CANONICAL_DUPLICATE = {"Taifa Stars": "Tanzania"}

# Age-group sides share a country with the senior team and must never absorb a
# senior fixture. Anything matching this is refused outright.
AGE_GROUP = re.compile(r"-(U\d{2})$|\bU\d{2}\b", re.I)


def _norm(s):
    """Lowercase, strip accents and punctuation, so 'Cote d'Ivoire' == 'cotedivoire'."""
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z]", "", s.lower())


_LOOKUP = {}
for canon, variants in ALIASES.items():
    _LOOKUP[_norm(canon)] = canon
    for v in variants:
        _LOOKUP[_norm(v)] = canon
for dupe, canon in CANONICAL_DUPLICATE.items():
    _LOOKUP[_norm(dupe)] = canon


def canonical(name):
    """Canonical vault spelling for a national team name, or None if unknown.

    A name that is already a vault spelling passes through unchanged; the
    caller resolves it against `teams` and decides what an unknown means.
    """
    if not name:
        return None
    if AGE_GROUP.search(name):
        return None
    return _LOOKUP.get(_norm(name), name)


def is_age_group(name):
    return bool(name) and bool(AGE_GROUP.search(name))
