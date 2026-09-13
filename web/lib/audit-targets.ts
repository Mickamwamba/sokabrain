import type { AuditFinding } from './adminApi';

/**
 * Where a finding gets fixed: the page, and the part of it to scroll to.
 *
 * One map, so the audit list and anything else linking to a fix agree. Each
 * target page gives the matching element an `id`, and the console highlights
 * whichever section the URL's hash names.
 */

type Target = { href: string; label: string };

const MATCH_RESULT = new Set([
  'MISSING_SCORE', 'SCORE_ON_UNPLAYED', 'SHOOTOUT_ON_UNLEVEL_SCORE',
  'STALE_SCHEDULED', 'MISSING_KICKOFF', 'KICKOFF_OUTSIDE_SEASON',
]);
const MATCH_EVENTS = new Set([
  'EVENTS_CONTRADICT_SCORE', 'EVENTS_EXCEED_SCORE', 'MISSING_GOAL_EVENTS',
  'UNNAMED_SCORER', 'ORPHAN_EVENT', 'EVENT_MINUTE_OUT_OF_RANGE',
]);
const SEASON_PARTICIPANTS = new Set(['UNLISTED_PARTICIPANTS', 'PARTICIPANTS_WITHOUT_MATCHES']);
const SEASON_SETTINGS = new Set(['TEAM_COUNT_MISMATCH']);

/** Only an audit URL may be offered as "back" — never an arbitrary redirect. */
export function safeReturn(from: string | undefined | null): string | null {
  return from && /^\/admin\/audit(\?|$)/.test(from) ? from : null;
}

export function fixTarget(f: AuditFinding, returnTo?: string | null): Target {
  const back = returnTo ? `from=${encodeURIComponent(returnTo)}` : '';
  const q = (extra = '') => {
    const parts = [extra, back].filter(Boolean).join('&');
    return parts ? `?${parts}` : '';
  };

  if (f.entity.type === 'match') {
    if (MATCH_RESULT.has(f.check.key)) return { href: `/admin/matches/${f.entity.id}${q()}#result`, label: 'Fix result' };
    if (MATCH_EVENTS.has(f.check.key)) return { href: `/admin/matches/${f.entity.id}${q()}#events`, label: 'Fix events' };
    return { href: `/admin/matches/${f.entity.id}${q()}`, label: 'Open match' };
  }
  if (f.entity.type === 'player') {
    return { href: `/admin/players/${f.entity.id}${q()}#career`, label: 'Fix career' };
  }
  const edition = f.edition;
  if (!edition) return { href: '/admin/competitions', label: 'Open' };
  if (SEASON_PARTICIPANTS.has(f.check.key)) {
    return { href: `/admin/participants${q(`editionId=${edition.id}`)}#participants`, label: 'Fix participants' };
  }
  if (SEASON_SETTINGS.has(f.check.key)) {
    return { href: `/admin/competitions/${edition.competitionId}${q(`season=${edition.id}`)}#season-settings`, label: 'Fix season settings' };
  }
  // Fixtures missing, uneven games, goals without events: the season's matches.
  return { href: `/admin/matches${q(`editionId=${edition.id}`)}#matches`, label: 'Open season matches' };
}
