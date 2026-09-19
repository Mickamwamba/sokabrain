import { NextResponse } from "next/server";
import {
  api,
  type Edition,
  type PlayerStat,
  type PlayerStatsCoverage,
  type TeamRefLite,
} from "@/lib/api";

export const dynamic = "force-dynamic";

type CachedData = {
  teams: TeamRefLite[];
  editions: Edition[];
  players: PlayerStat[];
  timestamp: number;
};

let cache: CachedData | null = null;
const CACHE_TTL_MS = 60 * 1000; // 1 minute

async function getData(): Promise<CachedData> {
  const now = Date.now();
  if (cache && now - cache.timestamp < CACHE_TTL_MS) {
    return cache;
  }

  try {
    const [teamsRes, editionsRes, playersRes] = await Promise.all([
      api.teams(),
      api.editions().catch(() => ({ editions: [] })),
      api
        .players({ limit: 100 })
        .catch(() => ({ players: [], coverage: {} as unknown as PlayerStatsCoverage })),
    ]);

    cache = {
      teams: teamsRes.teams || [],
      editions: editionsRes.editions || [],
      players: playersRes.players || [],
      timestamp: now,
    };
    return cache;
  } catch (err) {
    if (cache) return cache;
    throw err;
  }
}

export type SearchResultItem =
  | {
      type: "team";
      id: number;
      title: string;
      subtitle: string | null;
      badge?: string;
      href: string;
    }
  | {
      type: "player";
      id: number;
      title: string;
      subtitle: string | null;
      badge?: string;
      teamId: number | null;
      href: string;
    }
  | {
      type: "h2h";
      id: string;
      title: string;
      subtitle: string;
      href: string;
    }
  | {
      type: "edition";
      id: number;
      title: string;
      subtitle: string;
      href: string;
    }
  | {
      type: "nav";
      id: string;
      title: string;
      subtitle: string;
      href: string;
    };

const STATIC_SHORTCUTS: { title: string; subtitle: string; href: string }[] = [
  { title: "Matches & Fixtures", subtitle: "Latest scores, rounds and dates", href: "/" },
  { title: "League Standings", subtitle: "Full league table and qualification zones", href: "/table" },
  { title: "Vault Statistics", subtitle: "Overview of all-time East African stats", href: "/stats" },
  { title: "Top Goalscorers", subtitle: "All-time golden boot leaders and assists", href: "/stats/players" },
  { title: "Head to Head Comparison", subtitle: "Compare any two clubs in the vault", href: "/stats/head-to-head" },
  { title: "Clubs Leaderboard", subtitle: "All-time points, win rates and clean sheets", href: "/stats/clubs" },
  { title: "National Teams", subtitle: "Regional national teams records", href: "/stats/nations" },
];

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const q = (searchParams.get("q") || "").trim().toLowerCase();

  try {
    const data = await getData();
    const { teams, editions, players } = data;

    // Default view when query is empty: popular clubs, top derby, and shortcuts
    if (!q) {
      const popularClubNames = [
        "simba sc",
        "young africans",
        "yanga sc",
        "azam fc",
        "singida black stars",
        "coastal union",
        "namungo fc",
        "geita gold",
        "tanzania",
      ];

      const featuredTeams: SearchResultItem[] = [];
      for (const name of popularClubNames) {
        const found = teams.find(
          (t) => t.name.toLowerCase().includes(name) || (t.shortName && t.shortName.toLowerCase() === name)
        );
        if (found && !featuredTeams.some((f) => f.id === found.id)) {
          featuredTeams.push({
            type: "team",
            id: found.id,
            title: found.name,
            subtitle: found.country || (found.type === "NATIONAL" ? "National Team" : "Club"),
            badge: found.type === "NATIONAL" ? "National" : undefined,
            href: `/teams/${found.id}`,
          });
        }
      }

      // Add default derbies
      const simba = teams.find((t) => t.name.toLowerCase().includes("simba"));
      const yanga = teams.find((t) => t.name.toLowerCase().includes("yanga") || t.name.toLowerCase().includes("young africans"));
      const derbies: SearchResultItem[] = [];
      if (simba && yanga) {
        derbies.push({
          type: "h2h",
          id: `h2h-${simba.id}-${yanga.id}`,
          title: "🔥 Kariakoo Derby: Simba SC vs Yanga SC",
          subtitle: "Explore all-time meetings, wins, and derby history",
          href: `/stats/head-to-head?teamA=${simba.id}&teamB=${yanga.id}`,
        });
      }

      return NextResponse.json({
        teams: featuredTeams.slice(0, 6),
        players: [],
        derbies,
        editions: [],
        shortcuts: STATIC_SHORTCUTS.slice(0, 4).map((s) => ({
          type: "nav",
          id: s.href,
          title: s.title,
          subtitle: s.subtitle,
          href: s.href,
        })),
      });
    }

    // Check if query looks like a head-to-head search: e.g., "simba vs yanga", "simba yanga", "azam simba"
    const isVersus = q.includes(" vs ") || q.includes(" v ") || q.includes(" versus ");
    const matchedDerbies: SearchResultItem[] = [];

    if (isVersus) {
      const parts = q.split(/\s+(?:vs|v|versus)\s+/);
      if (parts.length >= 2) {
        const teamAPart = parts[0].trim();
        const teamBPart = parts[1].trim();
        const teamA = teams.find((t) => t.name.toLowerCase().includes(teamAPart));
        const teamB = teams.find((t) => t.name.toLowerCase().includes(teamBPart));

        if (teamA && teamB && teamA.id !== teamB.id) {
          matchedDerbies.push({
            type: "h2h",
            id: `h2h-${teamA.id}-${teamB.id}`,
            title: `⚔️ ${teamA.name} vs ${teamB.name}`,
            subtitle: "Head-to-head meetings, wins, and scoring records",
            href: `/stats/head-to-head?teamA=${teamA.id}&teamB=${teamB.id}`,
          });
        }
      }
    } else if (q.includes("derby") || q.includes("kariakoo")) {
      const simba = teams.find((t) => t.name.toLowerCase().includes("simba"));
      const yanga = teams.find((t) => t.name.toLowerCase().includes("yanga") || t.name.toLowerCase().includes("young africans"));
      if (simba && yanga) {
        matchedDerbies.push({
          type: "h2h",
          id: `h2h-${simba.id}-${yanga.id}`,
          title: "🔥 Kariakoo Derby: Simba SC vs Yanga SC",
          subtitle: "Explore all-time meetings, wins, and derby history",
          href: `/stats/head-to-head?teamA=${simba.id}&teamB=${yanga.id}`,
        });
      }
    }

    // Match teams
    const matchedTeams: SearchResultItem[] = teams
      .filter((t) => {
        const nameMatch = t.name.toLowerCase().includes(q);
        const shortMatch = t.shortName ? t.shortName.toLowerCase().includes(q) : false;
        const countryMatch = t.country ? t.country.toLowerCase().includes(q) : false;
        return nameMatch || shortMatch || countryMatch;
      })
      .slice(0, 6)
      .map((t) => ({
        type: "team",
        id: t.id,
        title: t.name,
        subtitle: t.country || (t.type === "NATIONAL" ? "National Team" : "Club"),
        badge: t.type === "NATIONAL" ? "National" : undefined,
        href: `/teams/${t.id}`,
      }));

    // Match players
    const matchedPlayers: SearchResultItem[] = players
      .filter((p) => {
        const nameMatch = p.playerName.toLowerCase().includes(q);
        const teamMatch = p.teamName ? p.teamName.toLowerCase().includes(q) : false;
        return nameMatch || teamMatch;
      })
      .slice(0, 5)
      .map((p) => ({
        type: "player",
        id: p.playerId,
        title: p.playerName,
        subtitle: `${p.teamName || "Free agent"} · ${p.goals} goals${p.assists ? ` · ${p.assists} assists` : ""}`,
        badge: `${p.goals} ⚽`,
        teamId: p.teamId,
        href: p.teamId ? `/teams/${p.teamId}` : `/stats/players`,
      }));

    // Match competitions / editions
    const matchedEditions: SearchResultItem[] = editions
      .filter((e) => {
        const compMatch = e.competition.toLowerCase().includes(q);
        const seasonMatch = e.season.toLowerCase().includes(q);
        return compMatch || seasonMatch;
      })
      .slice(0, 3)
      .map((e) => ({
        type: "edition",
        id: e.editionId,
        title: `${e.competition} (${e.season})`,
        subtitle: `${e.country || "East Africa"} · ${e.matchCount} matches`,
        href: `/table?editionId=${e.editionId}`,
      }));

    // Match static shortcuts
    const matchedShortcuts: SearchResultItem[] = STATIC_SHORTCUTS.filter(
      (s) => s.title.toLowerCase().includes(q) || s.subtitle.toLowerCase().includes(q)
    )
      .slice(0, 3)
      .map((s) => ({
        type: "nav",
        id: s.href,
        title: s.title,
        subtitle: s.subtitle,
        href: s.href,
      }));

    return NextResponse.json({
      teams: matchedTeams,
      players: matchedPlayers,
      derbies: matchedDerbies,
      editions: matchedEditions,
      shortcuts: matchedShortcuts,
    });
  } catch (err: unknown) {
    console.error("Search API error:", err);
    return NextResponse.json({ error: "Failed to perform search" }, { status: 500 });
  }
}
