/**
 * How a competition is named for display.
 *
 * The vault holds three competitions called plainly "Premier League" — Tanzania's,
 * South Africa's and Uganda's — so a bare name no longer identifies one. Every
 * place the API emits a competition name for display puts its country in front.
 *
 * This lives at the API boundary rather than in the stored name, for two reasons:
 * `competitions.country_id` already carries the country and duplicating it into
 * the name would let the two drift, and a competition added later through the
 * admin console gets the same treatment without anyone remembering to name it
 * carefully.
 *
 * The raw `competitions.name` is still what the admin console edits and saves —
 * an edit form must round-trip the stored value, not a decorated one.
 */

/**
 * A country's name as a person would write it.
 *
 * The countries table holds ISO 3166 long forms, so Tanzania is stored as
 * "Tanzania, United Republic of". Prefixing a competition with that reads badly
 * ("Tanzania, United Republic of Premier League"), and the part before the comma
 * is the common name in every case the vault holds — Tanzania, and
 * "Congo, the Democratic Republic of the".
 *
 *   countryShortName('Tanzania, United Republic of')  // 'Tanzania'
 *   countryShortName('Kenya')                         // 'Kenya'
 *   countryShortName(null)                            // null
 */
export function countryShortName(name: string | null | undefined): string | null {
  if (!name) return null;
  const short = name.split(',')[0]?.trim();
  return short && short.length > 0 ? short : name.trim();
}

/**
 * The competition's display name, prefixed with its country.
 *
 * Three cases it deliberately leaves alone:
 *
 *  - **no country** — a continental competition like the Africa Cup of Nations
 *    belongs to no one country and is already unambiguous;
 *  - **the name already begins with the country** — the legacy record is called
 *    "Kenya premier league", and "Kenya Kenya premier league" helps nobody;
 *  - **the name already contains the country anywhere** — "KENYA FA CUP".
 *
 * Matching is case- and punctuation-insensitive, so "KENYA FA CUP" is caught
 * despite the casing.
 *
 *   competitionDisplayName('Premier League', 'Uganda')        // 'Uganda Premier League'
 *   competitionDisplayName('Premier League', 'Tanzania, United Republic of')
 *                                                             // 'Tanzania Premier League'
 *   competitionDisplayName('Kenya premier league', 'Kenya')   // 'Kenya premier league'
 *   competitionDisplayName('Africa Cup of Nations', null)     // 'Africa Cup of Nations'
 */
export function competitionDisplayName(
  name: string,
  country: string | null | undefined,
): string {
  const short = countryShortName(country);
  if (!short) return name;

  const simplify = (s: string) => s.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
  const haystack = ` ${simplify(name)} `;
  const needle = ` ${simplify(short)} `;
  if (haystack.includes(needle)) return name;

  return `${short} ${name}`;
}
