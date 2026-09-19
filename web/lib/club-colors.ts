/**
 * Curated color identities for East African clubs and national teams.
 *
 * Team logos are not hosted in the vault, so distinctive two-tone color palettes
 * and typographic crests give each club an unmistakable identity that fans
 * immediately recognize.
 */

export type ClubTheme = {
  bg: string;
  text: string;
  border?: string;
  accent?: string;
};

// Normalized lowercase club name matching keys
const CLUB_THEMES: Record<string, ClubTheme> = {
  // Tanzania Premier League Giants
  "yanga sc": { bg: "#006837", text: "#ffd700", border: "#ffd700", accent: "#ffd700" },
  "young africans": { bg: "#006837", text: "#ffd700", border: "#ffd700", accent: "#ffd700" },
  "simba sc": { bg: "#d90429", text: "#ffffff", border: "#ef233c", accent: "#ffffff" },
  "azam fc": { bg: "#0052cc", text: "#ffffff", border: "#4c9aff", accent: "#00b4d8" },
  "coastal union": { bg: "#0c2340", text: "#00b4d8", border: "#0077b6", accent: "#00b4d8" },
  "singida black stars": { bg: "#141414", text: "#f0a202", border: "#f0a202", accent: "#f0a202" },
  "singida big stars": { bg: "#141414", text: "#f0a202", border: "#f0a202", accent: "#f0a202" },
  "geita gold fc": { bg: "#d4a373", text: "#1a1a24", border: "#faedcd", accent: "#faedcd" },
  "pamba jiji": { bg: "#1d3557", text: "#f4a261", border: "#457b9d", accent: "#f4a261" },
  "dodoma jiji fc": { bg: "#6b1124", text: "#ffffff", border: "#9b1d36", accent: "#ffd166" },
  "namungo": { bg: "#1b4332", text: "#d8f3dc", border: "#40916c", accent: "#52b788" },
  "namungo fc": { bg: "#1b4332", text: "#d8f3dc", border: "#40916c", accent: "#52b788" },
  "mashujaa fc": { bg: "#283618", text: "#dda15e", border: "#606c38", accent: "#dda15e" },
  "polisi tanzania": { bg: "#1e3d59", text: "#f5f0e1", border: "#17b978", accent: "#17b978" },
  "jkt tanzania": { bg: "#2d4a22", text: "#fefae0", border: "#606c38", accent: "#bc6c25" },
  "kagera sugar": { bg: "#0077b6", text: "#ffb703", border: "#ffb703", accent: "#fb8500" },
  "tabora united": { bg: "#005f73", text: "#ee9b00", border: "#0a9396", accent: "#ee9b00" },
  "tra united": { bg: "#005f73", text: "#ee9b00", border: "#0a9396", accent: "#ee9b00" },
  "kmc fc": { bg: "#b7094c", text: "#ffffff", border: "#892b64", accent: "#ffb4a2" },
  "tanzania prisons": { bg: "#0b525b", text: "#ffffff", border: "#144552", accent: "#48cae4" },
  "prisons": { bg: "#0b525b", text: "#ffffff", border: "#144552", accent: "#48cae4" },
  "mtibwa sugar": { bg: "#2b9348", text: "#ffff3f", border: "#55a630", accent: "#ffff3f" },
  "mbeya city": { bg: "#7b2cbf", text: "#ffffff", border: "#9d4edd", accent: "#e0aaff" },
  "fountain gate fc": { bg: "#007f5f", text: "#ffff3f", border: "#2b9348", accent: "#ffff3f" },
  "ihefu sc": { bg: "#1a759f", text: "#ffffff", border: "#168aad", accent: "#52b69a" },
  "ruvu shooting": { bg: "#d00000", text: "#ffba08", border: "#dc2f02", accent: "#ffba08" },
  "biashara united": { bg: "#023e8a", text: "#caf0f8", border: "#0077b6", accent: "#90e0ef" },
  "stand united": { bg: "#3a0ca3", text: "#4cc9f0", border: "#4361ee", accent: "#4cc9f0" },
  "lipuli fc": { bg: "#b5179e", text: "#ffffff", border: "#7209b7", accent: "#f72585" },
  "toto african": { bg: "#0077b6", text: "#ffffff", border: "#0096c7", accent: "#48cae4" },
  "african sports": { bg: "#1b263b", text: "#e0e1dd", border: "#415a77", accent: "#778da9" },
  "majimaji fc": { bg: "#386641", text: "#f2e8cf", border: "#6a994e", accent: "#a7c957" },
  "ken gold": { bg: "#b5838d", text: "#ffffff", border: "#6d6875", accent: "#ffb4a2" },

  // Kenya & East African Rivals
  "gor mahia": { bg: "#155724", text: "#ffffff", border: "#28a745", accent: "#80e27e" },
  "afc leopards": { bg: "#004085", text: "#ffffff", border: "#007bff", accent: "#b8daff" },
  "tusker fc": { bg: "#d4af37", text: "#111111", border: "#ffee55", accent: "#ffee55" },

  // National Teams
  "tanzania": { bg: "#1b9aaa", text: "#ffc43d", border: "#06d6a0", accent: "#ffc43d" },
  "kenya": { bg: "#ba181b", text: "#ffffff", border: "#161a1d", accent: "#2d6a4f" },
  "uganda": { bg: "#161a1d", text: "#ffd166", border: "#d90429", accent: "#ffd166" },
  "senegal": { bg: "#007f5f", text: "#ffff3f", border: "#d00000", accent: "#ffff3f" },
  "egypt": { bg: "#c1121f", text: "#ffffff", border: "#000000", accent: "#fdf0d5" },
  "morocco": { bg: "#a4161a", text: "#2d6a4f", border: "#1b4332", accent: "#d8f3dc" },
  "nigeria": { bg: "#00875a", text: "#ffffff", border: "#2d6a4f", accent: "#52b788" },
  "algeria": { bg: "#2d6a4f", text: "#ffffff", border: "#ba181b", accent: "#d8f3dc" },
  "cameroon": { bg: "#1b4332", text: "#ffff3f", border: "#d90429", accent: "#ffff3f" },
  "ivory coast": { bg: "#f77f00", text: "#ffffff", border: "#2d6a4f", accent: "#eae2b7" },
  "cote d'ivoire": { bg: "#f77f00", text: "#ffffff", border: "#2d6a4f", accent: "#eae2b7" },
  "ghana": { bg: "#d90429", text: "#ffd166", border: "#111111", accent: "#ffd166" },
  "dr congo": { bg: "#0077b6", text: "#ffd166", border: "#d90429", accent: "#ffd166" },
  "congo dr": { bg: "#0077b6", text: "#ffd166", border: "#d90429", accent: "#ffd166" },
  "zambia": { bg: "#2b9348", text: "#f77f00", border: "#1b4332", accent: "#f77f00" },
  "south africa": { bg: "#e9c46a", text: "#264653", border: "#2a9d8f", accent: "#2a9d8f" },
};

/** Simple string hash to pick consistent pleasing sports hues for unknown clubs */
function hashString(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = (hash << 5) - hash + str.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash);
}

const FALLBACK_PALETTES: ClubTheme[] = [
  { bg: "#1d3557", text: "#ffffff", border: "#457b9d" },
  { bg: "#005f73", text: "#ffffff", border: "#0a9396" },
  { bg: "#2b2d42", text: "#edf2f4", border: "#8d99ae" },
  { bg: "#3d405b", text: "#f4f1de", border: "#e07a5f" },
  { bg: "#0b525b", text: "#ffffff", border: "#144552" },
  { bg: "#14213d", text: "#fca311", border: "#e5e5e5" },
  { bg: "#3a506b", text: "#ffffff", border: "#5bc0be" },
  { bg: "#264653", text: "#ffffff", border: "#2a9d8f" },
  { bg: "#2f3e46", text: "#cad2c5", border: "#52796f" },
  { bg: "#1e3d59", text: "#f5f0e1", border: "#ff6e40" },
];

export function getClubTheme(name: string): ClubTheme {
  const norm = name.trim().toLowerCase().replace(/\s+/g, " ");
  if (CLUB_THEMES[norm]) {
    return CLUB_THEMES[norm];
  }
  // Try partial matching for common club prefixes
  for (const [key, theme] of Object.entries(CLUB_THEMES)) {
    if (norm.includes(key) || key.includes(norm)) {
      return theme;
    }
  }
  const idx = hashString(norm) % FALLBACK_PALETTES.length;
  return FALLBACK_PALETTES[idx]!;
}
