/**
 * Club names that differ between a provider and the vault.
 *
 * Name matching after normalisation handles the cosmetic differences ("Simba SC"
 * against "Simba"), but it cannot handle a club with two genuinely different
 * names — "Yanga SC" and "Young Africans" share no token at all. Those have to
 * be written down by a human, which is exactly the point: an alias here is an
 * assertion someone made, not something a matcher inferred.
 *
 * **`docs/ingestion/teamnames.py` is the source of truth** for this league's
 * naming and has the fuller list, including former names of renamed clubs. Check
 * it before adding an entry — a rename recorded in one place and not the other
 * is how a club's history gets split in two.
 *
 * Keyed by the vault's canonical `teams.name`; values are the other spellings a
 * provider may use. Matching is done on the normalised form of both.
 */
export const TEAM_ALIASES: Record<string, string[]> = {
  'Yanga SC': ['Young Africans', 'Yanga'],
  'KMC FC': ['Kinondoni MC', 'KMC', 'Kinondoni Municipal Council'],
  'Biashara United': ['Biashara Mara United', 'Biashara Utd'],
  'Singida Black Stars': ['Singida United', 'Singida Fountain Gate', 'DT Bank'],
  'JKT Tanzania': ['JKT Ruvu Stars', 'JKT Ruvu'],
  'Tanzania Prisons': ['Prisons', 'Prisons Mbeya'],
  'Stand United': ['Stand U.', 'Stand Utd'],
  'Mbao FC': ['Mbao', 'Mbao Mwanza'],
  'Alliance FC': ['Alliance', 'Alliance Mwanza'],
};
