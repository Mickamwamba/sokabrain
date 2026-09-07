import { Prisma } from '@prisma/client';
import { prisma } from '../db.js';
import type { Severity } from './flags.js';

/**
 * Per-match data problems, derived from the data rather than recorded by hand.
 *
 * These are computed on every read, so they clear themselves the moment the
 * underlying data is fixed — an editor never has to remember to close them.
 * `data_flags` remains for the other kind of problem: something a person knows
 * that the data cannot reveal on its own (a date contradicted by an external
 * source, a score disputed by a match report).
 */

export type IssueKind =
  | 'MISSING_SCORE'
  | 'GOALS_WITHOUT_EVENTS'
  | 'UNNAMED_SCORER'
  | 'EVENTS_CONTRADICT_SCORE'
  | 'ORPHAN_EVENT'
  | 'SELF_FIXTURE';

export type MatchIssue = { kind: IssueKind; severity: Severity; detail: string };

export type MatchWithIssues = {
  matchId: number;
  kickoffAt: Date | null;
  status: string;
  round: string | null;
  homeTeam: string;
  awayTeam: string;
  homeScore: number | null;
  awayScore: number | null;
  issues: MatchIssue[];
  openFlags: { id: number; severity: string; reason: string }[];
};

type Row = {
  id: number;
  kickoff_at: Date | null;
  status: string;
  round: string | null;
  home: string;
  away: string;
  home_score: number | null;
  away_score: number | null;
  home_team_id: number;
  away_team_id: number;
  goal_events: number;
  unnamed_goals: number;
  orphan_events: number;
  credited_home: number;
  credited_away: number;
};

/**
 * Every match in an edition that has at least one detectable problem.
 *
 * The goal arithmetic mirrors the read side: an OWN_GOAL counts for the
 * opposing team (design principle 5), so a match is only reported as
 * contradicting its score when it genuinely does.
 */
export async function detectMatchIssues(editionId: number): Promise<MatchWithIssues[]> {
  const rows = await prisma.$queryRaw<Row[]>(Prisma.sql`
    SELECT
      m.id, m.kickoff_at, m.status, m.round,
      th.name AS home, ta.name AS away,
      m.home_score, m.away_score, m.home_team_id, m.away_team_id,
      (SELECT count(*) FROM match_events e
         WHERE e.match_id = m.id AND e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL'))::int AS goal_events,
      (SELECT count(*) FROM match_events e
         WHERE e.match_id = m.id AND e.type IN ('GOAL','PENALTY_GOAL')
           AND e.player_id IS NULL)::int AS unnamed_goals,
      (SELECT count(*) FROM match_events e
         WHERE e.match_id = m.id AND e.team_id IS NULL)::int AS orphan_events,
      (SELECT count(*) FROM match_events e WHERE e.match_id = m.id
         AND e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL')
         AND (CASE WHEN e.type = 'OWN_GOAL'
                   THEN CASE WHEN e.team_id = m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
                   ELSE e.team_id END) = m.home_team_id)::int AS credited_home,
      (SELECT count(*) FROM match_events e WHERE e.match_id = m.id
         AND e.type IN ('GOAL','PENALTY_GOAL','OWN_GOAL')
         AND (CASE WHEN e.type = 'OWN_GOAL'
                   THEN CASE WHEN e.team_id = m.home_team_id THEN m.away_team_id ELSE m.home_team_id END
                   ELSE e.team_id END) = m.away_team_id)::int AS credited_away
    FROM matches m
    JOIN teams th ON th.id = m.home_team_id
    JOIN teams ta ON ta.id = m.away_team_id
    WHERE m.competition_edition_id = ${editionId}
    ORDER BY m.kickoff_at NULLS LAST, m.id
  `);

  const flags = await prisma.data_flags.findMany({
    where: { status: 'OPEN', entity_type: 'match', entity_id: { in: rows.map((r) => r.id) } },
    select: { id: true, entity_id: true, severity: true, reason: true },
  });
  const flagsByMatch = new Map<number, { id: number; severity: string; reason: string }[]>();
  for (const f of flags) {
    const list = flagsByMatch.get(f.entity_id) ?? [];
    list.push({ id: f.id, severity: f.severity, reason: f.reason });
    flagsByMatch.set(f.entity_id, list);
  }

  const out: MatchWithIssues[] = [];
  for (const r of rows) {
    const issues: MatchIssue[] = [];
    const scored = (r.home_score ?? 0) + (r.away_score ?? 0);
    const hasScore = r.home_score !== null && r.away_score !== null;

    if (r.status === 'FULL_TIME' && !hasScore) {
      issues.push({
        kind: 'MISSING_SCORE',
        severity: 'BLOCKER',
        detail: 'Completed match with no score recorded',
      });
    }
    if (r.home_team_id === r.away_team_id) {
      issues.push({ kind: 'SELF_FIXTURE', severity: 'BLOCKER', detail: 'A team is listed against itself' });
    }
    if (hasScore && scored > r.goal_events) {
      issues.push({
        kind: 'GOALS_WITHOUT_EVENTS',
        severity: 'WARNING',
        detail: `${scored} goal${scored === 1 ? '' : 's'} in the score but ${r.goal_events} in the event log`,
      });
    }
    // Only meaningful once the event log is complete for the match; otherwise
    // GOALS_WITHOUT_EVENTS already describes the problem.
    if (hasScore && scored === r.goal_events && r.goal_events > 0
        && (r.credited_home !== r.home_score || r.credited_away !== r.away_score)) {
      issues.push({
        kind: 'EVENTS_CONTRADICT_SCORE',
        severity: 'BLOCKER',
        detail: `Events read ${r.credited_home}-${r.credited_away} but the score says ${r.home_score}-${r.away_score}`,
      });
    }
    if (r.unnamed_goals > 0) {
      issues.push({
        kind: 'UNNAMED_SCORER',
        severity: 'WARNING',
        detail: `${r.unnamed_goals} goal${r.unnamed_goals === 1 ? '' : 's'} with no scorer named`,
      });
    }
    if (r.orphan_events > 0) {
      issues.push({
        kind: 'ORPHAN_EVENT',
        severity: 'INFO',
        detail: `${r.orphan_events} event${r.orphan_events === 1 ? '' : 's'} not attached to either team`,
      });
    }

    const openFlags = flagsByMatch.get(r.id) ?? [];
    if (issues.length === 0 && openFlags.length === 0) continue;

    out.push({
      matchId: r.id,
      kickoffAt: r.kickoff_at,
      status: r.status,
      round: r.round,
      homeTeam: r.home,
      awayTeam: r.away,
      homeScore: r.home_score,
      awayScore: r.away_score,
      issues,
      openFlags,
    });
  }
  return out;
}
