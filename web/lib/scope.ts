import { api, type Edition } from "@/lib/api";

/**
 * What every public page is scoped to: one competition, and one season within
 * it.
 *
 * Season alone stopped being enough the day the site carried more than the
 * league. "2018/19" names a Premier League season and an Africa Cup of Nations
 * at the same time, and an all-time top scorer list spanning both answers a
 * question nobody asked — Meddie Kagere's 42 league goals are not comparable
 * with Samuel Eto'o's 13 at AFCON.
 *
 * So the URL carries both. `competitionId` picks the competition; `editionId`
 * picks the season inside it, or `all` for that competition's whole history.
 * An edition belongs to exactly one competition, so the two can never
 * contradict each other — if they do, the competition wins and the season
 * falls back to that competition's most recent.
 */

/** The URL value meaning "every season of this competition". */
export const ALL_TIME = "all";

export type CompetitionRef = { id: number; name: string };

export type ResolvedScope = {
  /** Always resolved: there is no "all competitions" view. */
  competitionId: number;
  competitionName: string;
  /** Undefined when showing all time, so it passes straight to the API. */
  editionId: number | undefined;
  /** What the season selector should show as chosen. */
  value: string;
  allTime: boolean;
  /** Every competition that has a published edition, for the picker. */
  competitions: CompetitionRef[];
  /** This competition's editions, newest season first. */
  editions: Edition[];
};

function competitionsOf(editions: Edition[]): CompetitionRef[] {
  const seen = new Map<number, string>();
  for (const e of editions) seen.set(e.competitionId, e.competition);
  return [...seen.entries()]
    .map(([id, name]) => ({ id, name }))
    .sort((a, b) => a.name.localeCompare(b.name));
}

/**
 * Resolve the competition and season a page should show.
 *
 * With nothing in the URL this lands on the season in play, which is what a fan
 * opening the site wants — not an archive index, and not a competition they did
 * not ask for.
 */
export async function resolveScope(
  competitionParam: string | undefined,
  editionParam: string | undefined,
  editionsIn?: Edition[],
  /** Narrows which competitions are on offer, e.g. only national-team ones. */
  only?: (e: Edition) => boolean,
): Promise<ResolvedScope> {
  const all = editionsIn ?? (await api.editions()).editions;
  const editions = only ? all.filter(only) : all;
  const competitions = competitionsOf(editions);

  // Which competition? An explicit choice, else the one the named edition
  // belongs to, else whatever is in season, else the first alphabetically.
  const named = Number(competitionParam);
  const byEdition = editions.find((e) => String(e.editionId) === editionParam);
  let competitionId =
    competitions.find((c) => c.id === named)?.id ?? byEdition?.competitionId;

  if (competitionId === undefined) {
    const ctx = await api.context().catch(() => null);
    competitionId =
      editions.find((e) => e.editionId === ctx?.editionId)?.competitionId ??
      competitions[0]?.id;
  }

  const mine = editions
    .filter((e) => e.competitionId === competitionId)
    .sort((a, b) => b.season.localeCompare(a.season));

  const competitionName =
    competitions.find((c) => c.id === competitionId)?.name ?? "";

  if (editionParam === ALL_TIME) {
    return {
      competitionId: competitionId!, competitionName, editionId: undefined,
      value: ALL_TIME, allTime: true, competitions, editions: mine,
    };
  }

  // A season only counts if it belongs to the chosen competition — otherwise
  // changing competition while a season is in the URL would show the old one.
  const chosen =
    mine.find((e) => String(e.editionId) === editionParam) ?? mine[0];

  return {
    competitionId: competitionId!,
    competitionName,
    editionId: chosen?.editionId,
    value: chosen ? String(chosen.editionId) : ALL_TIME,
    allTime: false,
    competitions,
    editions: mine,
  };
}

/** Season options for the selector: this competition's seasons, newest first. */
export function seasonOptionsFor(scope: ResolvedScope) {
  return scope.editions.map((e) => ({
    value: String(e.editionId),
    label: e.season.replace("/20", "/"),
  }));
}

/**
 * Competition types by the kind of team that plays in them.
 *
 * The nations leaderboard should not offer the Premier League, and the clubs
 * one should not offer AFCON — picking either would just produce an empty
 * table.
 */
const NATIONAL_TEAM_TYPES = ["CONTINENTAL_NATIONAL", "WORLD_CUP", "QUALIFIER"];

export const isNationalTeamEdition = (e: Edition) =>
  NATIONAL_TEAM_TYPES.includes(e.competitionType);

export const isClubEdition = (e: Edition) => !isNationalTeamEdition(e);
