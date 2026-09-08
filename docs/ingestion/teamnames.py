"""One canonical name per club, so three sources can be joined on it.

Clubs in this league are written many ways -- "Yanga SC" and "Young Africans"
are the same club, as are "Kinondoni MC" and "KMC FC". Matching on a normalised
string alone is not enough, so genuinely different names are listed as aliases
and everything else is reduced to a comparable form.
"""
import re
import unicodedata

# Different names for the same club. Key is the canonical vault name.
ALIASES = {
    "Yanga SC":           ["Young Africans", "Yanga", "Yanga Sc"],
    "KMC FC":             ["Kinondoni MC", "KMC", "Kinondoni Municipal Council"],
    "Namungo":            ["Namungo FC"],
    "Biashara United":    ["Biashara Mara United", "Biashara Utd"],
    "Polisi Tanzania":    ["Polisi Tanzania FC", "Polisi"],
    "Singida United":     ["Singida Utd"],
    "Singida Black Stars":["Singida BS", "Singida Big Stars"],
    "Dodoma Jiji FC":     ["Dodoma Jiji", "Dodoma Mji", "Dodoma City"],
    "Fountain Gate FC":   ["Fountain Gate", "Singida FG FC", "Singida Fountain Gate"],
    "Geita Gold FC":      ["Geita Gold"],
    "Mashujaa FC":        ["Mashujaa"],
    "Pamba Jiji":         ["Pamba Jiji FC", "Pamba"],
    "KenGold":            ["Kengold FC", "Kengold"],
    "Ihefu SC":           ["Ihefu Sc", "Ihefu"],
    "Gwambina FC":        ["Gwambina"],
    "Mbeya Kwanza FC":    ["Mbeya Kwanza"],
    "TRA United":         ["TRA", "Tra United"],
    "JKT Tanzania":       ["JKT Tanzania FC"],
}

# Suffixes that carry no identity, stripped before comparing.
NOISE = re.compile(r"\b(fc|sc|f\.c\.|s\.c\.|club)\b", re.I)


def slug(name):
    """A comparable form: lowercase, unaccented, no club-suffix noise."""
    s = unicodedata.normalize("NFKD", str(name or ""))
    s = "".join(c for c in s if not unicodedata.combining(c))
    s = NOISE.sub(" ", s.lower())
    s = re.sub(r"[^a-z0-9]+", " ", s).strip()
    return re.sub(r"\s+", " ", s)


_LOOKUP = {}
for canon, alts in ALIASES.items():
    _LOOKUP[slug(canon)] = canon
    for a in alts:
        _LOOKUP[slug(a)] = canon


def canonical(name):
    """Canonical club name, or the cleaned original when it is not a known alias."""
    return _LOOKUP.get(slug(name), str(name or "").strip())


def key(name):
    """The join key -- canonical name reduced to its comparable form."""
    return slug(canonical(name))
