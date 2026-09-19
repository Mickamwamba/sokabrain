"""One canonical name per club, so three sources can be joined on it.

Clubs in this league are written many ways -- "Yanga SC" and "Young Africans"
are the same club, as are "Kinondoni MC" and "KMC FC". Matching on a normalised
string alone is not enough, so genuinely different names are listed as aliases
and everything else is reduced to a comparable form.
"""
import re
import unicodedata

# Different names for the same club. Key is the canonical vault name.
#
# Two of these are renames rather than spelling variants, and the club was
# merged in the vault on 2026-09-08 (see reconciliation/fixes/): JKT Ruvu Stars
# became JKT Tanzania, and Singida United became Singida Black Stars. Their old
# names stay listed here so ingesting an old season resolves to the same club
# instead of splitting its history in half again.
ALIASES = {
    "Yanga SC":           ["Young Africans", "Yanga", "Yanga Sc"],
    "KMC FC":             ["Kinondoni MC", "KMC", "Kinondoni Municipal Council"],
    "Namungo":            ["Namungo FC"],
    "Biashara United":    ["Biashara Mara United", "Biashara Utd"],
    "Polisi Tanzania":    ["Polisi Tanzania FC", "Polisi"],
    "Fountain Gate FC":   ["Fountain Gate", "Singida FG FC", "Singida Fountain Gate"],
    "Geita Gold FC":      ["Geita Gold"],
    "Mashujaa FC":        ["Mashujaa"],
    "Pamba Jiji":         ["Pamba Jiji FC", "Pamba"],
    "KenGold":            ["Kengold FC", "Kengold"],
    "Gwambina FC":        ["Gwambina"],
    "Mbeya Kwanza FC":    ["Mbeya Kwanza"],
    "JKT Tanzania":       ["JKT Tanzania FC", "JKT Ruvu Stars", "JKT Ruvu"],
    # Variants RSSSF uses, which no other source does.
    "JKT Mgambo":         ["Mgambo JKT", "Mgambo"],
    "JKT Oljoro FC":      ["Oljoro JKT", "JKT Oljoro"],
    "Maji Maji FC":       ["Majimaji", "Maji Maji"],
    "Toto Africa":        ["Toto Africans", "Toto African"],
    "Dodoma Jiji FC":     ["Dodoma", "Dodoma Jiji", "Dodoma Mji", "Dodoma City"],
    "Ihefu FC":           ["Ihefu", "Ihefu SC"],
    "Manyema":            ["Manyema Rangers"],
    "AFC Arusha":         ["AFC", "Arusha AFC"],
    "TRA United":         ["TRA", "Tra United", "Tabora United", "Kitayosce"],
    "Ashanti United FC":  ["Ashanti United", "Ashanti"],
    "Njombe Mji FC":      ["Njombe Mji", "Njombe"],
    "Singida Black Stars":["Singida BS", "Singida Big Stars", "Singida United", "Singida Utd",
                          # footballdatabase.eu labels this club "DT Bank"; its 2019/20
                          # fixtures match the vault's Singida Black Stars exactly.
                          "DT Bank", "Diamond Trust Bank", "Singida Fountain Gate"],
    # Flashscore abbreviates this one in its fixture list.
    "Stand United":       ["Stand U.", "Stand Utd"],
    # footballdatabase.eu's renderings of clubs the vault names differently.
    "Tanzania Prisons":   ["Prisons", "Prisons Mbeya"],
    "Mbao FC":            ["Mbao", "Mbao Mwanza"],
    "Alliance FC":        ["Alliance", "Alliance Mwanza"],
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
