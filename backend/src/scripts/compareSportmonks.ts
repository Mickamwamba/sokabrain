/**
 * Compare SportMonks against the vault, and write nothing.
 *
 *   npm run sm:compare -- --league 884
 *
 * This is the step that decides whether the provider can be trusted, and it runs
 * before any sync does. The vault's own data is the yardstick: for the Tanzanian
 * Premier League's current season every played match already reconciles with its
 * score and every goal names a scorer, built from three independent sources. A
 * provider that agrees with that is worth syncing; one that does not needs
 * explaining first.
 *
 * Five things are checked, and each one has cost this project real time before:
 *
 *  1. **Fixture identity** — the ordered club pair inside the edition. A pair
 *     meets once per double round-robin, which is a stronger key than a kickoff
 *     date two sources may disagree on.
 *  2. **Score.**
 *  3. **Kickoff date**, because a stale scheduled date once left 82 fixtures
 *     inside a COVID suspension.
 *  4. **Round.**
 *  5. **Events** — count, type, minute and scorer name, plus whether the event
 *     log reconstructs the published score under the vault's own-goal rule
 *     (design principle 5). That last one is the check that catches an own-goal
 *     convention read the wrong way round, which four sources have now needed.
 */
import { parseArgs } from 'node:util';
import { prisma } from '../db.js';
import {
  sportmonks,
  SportmonksError,
  normaliseFixture,
  normaliseEvents,
  reconstructScore,
  isAwarded,
} from '../services/sportmonks.js';
import { resolveVaultIds, editionKey, normalizeName } from '../services/entityResolution.js';
import { VAULT_COMPETITION_BY_PROVIDER_LEAGUE } from '../config/leagues.js';

const { values } = parseArgs({
  options: { league: { type: 'string' }, season: { type: 'string' }, verbose: { type: 'boolean', default: false } },
});

const leagueId = Number(values.league);
if (!Number.isInteger(leagueId)) {
  console.error('Usage: npm run sm:compare -- --league <sportmonksLeagueId> [--season <id>] [--verbose]');
  process.exit(1);
}

/** Compare two names the way the identity problem demands: shape, not spelling. */
function sameName(a: string | null, b: string | null): boolean {
  if (a === null || b === null) return false;
  const na = normalizeName(a);
  const nb = normalizeName(b);
  if (na === nb) return true;
  // Sources reorder given and family names ("Jesto Masanja" / "Masanja Jesto
  // Kamli"), so a token-subset match counts as the same man for reporting.
  // This is for a REPORT, never for writing — a merge needs a human.
  const ta = new Set(na.split(' ').filter(Boolean));
  const tb = new Set(nb.split(' ').filter(Boolean));
  if (ta.size === 0 || tb.size === 0) return false;
  const shared = [...ta].filter((t) => tb.has(t)).length;
  return shared >= Math.min(ta.size, tb.size);
}

try {
  const leagues = await sportmonks.leagues();
  const league = leagues.find((l) => l.id === leagueId);
  if (!league?.currentseason) {
    console.error(`League ${leagueId} is not in the plan, or has no current season.`);
    process.exit(1);
  }
  const seasonId = Number.isInteger(Number(values.season))
    ? Number(values.season)
    : league.currentseason.id;
  const seasonName = league.currentseason.name;

  const competitionId = VAULT_COMPETITION_BY_PROVIDER_LEAGUE[String(leagueId)];
  if (competitionId === undefined) {
    console.error(`No vault competition mapped to league ${leagueId}; nothing to compare against.`);
    process.exit(1);
  }

  const editionMap = await resolveVaultIds(
    'competition_edition',
    [editionKey(leagueId, seasonId)],
    'sportmonks',
  );
  const editionId = editionMap.get(editionKey(leagueId, seasonId));
  if (editionId === undefined) {
    console.error(`Edition not mapped. Run: npm run sm:map -- --league ${leagueId} --apply`);
    process.exit(1);
  }

  const raw = await sportmonks.seasonFixtures(seasonId);
  const teamMap = await resolveVaultIds(
    'team',
    raw.flatMap((f) => (f.participants ?? []).map((p) => p.id)),
    'sportmonks',
  );

  const vaultMatches = await prisma.matches.findMany({
    where: { competition_edition_id: editionId },
    include: {
      match_events: {
        include: { players_match_events_player_idToplayers: { select: { full_name: true } } },
      },
    },
  });
  const vaultByPair = new Map(vaultMatches.map((m) => [`${m.home_team_id}:${m.away_team_id}`, m]));

  const tally = {
    fixtures: raw.length,
    noParticipants: 0,
    unmappedTeam: 0,
    unmatchedFixture: 0,
    scoreAgree: 0,
    scoreDisagree: 0,
    providerOnlyScore: 0,
    vaultOnlyScore: 0,
    kickoffDiffer: 0,
    roundAgree: 0,
    roundDisagree: 0,
    roundNewToVault: 0,
    eventsAgree: 0,
    eventsDiffer: 0,
    ogReconstructOk: 0,
    ogReconstructBad: 0,
    awarded: 0,
    scorerAgree: 0,
    scorerDisagree: 0,
    scorerNewToVault: 0,
    scorerProviderUnnamed: 0,
    sideUnpairable: 0,
  };
  const notes: string[] = [];

  for (const f of raw) {
    const n = normaliseFixture(f, league.name);
    if (!n) {
      tally.noParticipants += 1;
      continue;
    }
    const homeId = teamMap.get(n.home.id);
    const awayId = teamMap.get(n.away.id);
    if (homeId === undefined || awayId === undefined) {
      tally.unmappedTeam += 1;
      notes.push(`unmapped team: ${n.home.name} v ${n.away.name}`);
      continue;
    }
    const m = vaultByPair.get(`${homeId}:${awayId}`);
    if (!m) {
      tally.unmatchedFixture += 1;
      notes.push(`no vault fixture: ${n.home.name} v ${n.away.name} (${n.kickoff.toISOString().slice(0, 10)})`);
      continue;
    }

    if (isAwarded(f.state_id)) {
      tally.awarded += 1;
      notes.push(
        `AWARDED: ${n.home.name} ${n.homeScore}-${n.awayScore} ${n.away.name} — ` +
          `forfeited, its event log will never reconcile (vault match ${m.id})`,
      );
    }

    /* ---- score ---- */
    const vHas = m.home_score !== null && m.away_score !== null;
    const pHas = n.homeScore !== null && n.awayScore !== null;
    if (vHas && pHas) {
      if (m.home_score === n.homeScore && m.away_score === n.awayScore) tally.scoreAgree += 1;
      else {
        tally.scoreDisagree += 1;
        notes.push(
          `SCORE: match ${m.id} ${n.home.name} v ${n.away.name} — ` +
            `vault ${m.home_score}-${m.away_score}, SportMonks ${n.homeScore}-${n.awayScore}`,
        );
      }
    } else if (pHas) tally.providerOnlyScore += 1;
    else if (vHas) tally.vaultOnlyScore += 1;

    /* ---- kickoff ---- */
    if (m.kickoff_at) {
      const vDate = m.kickoff_at.toISOString().slice(0, 10);
      const pDate = n.kickoff.toISOString().slice(0, 10);
      if (vDate !== pDate) {
        tally.kickoffDiffer += 1;
        notes.push(`KICKOFF: match ${m.id} ${n.home.name} v ${n.away.name} — vault ${vDate}, SportMonks ${pDate}`);
      }
    }

    /* ---- round ---- */
    if (n.round !== null) {
      if (m.round === null) tally.roundNewToVault += 1;
      else if (m.round === n.round) tally.roundAgree += 1;
      else {
        tally.roundDisagree += 1;
        notes.push(`ROUND: match ${m.id} ${n.home.name} v ${n.away.name} — vault ${m.round}, SportMonks ${n.round}`);
      }
    }

    /* ---- own-goal rule: does the event log rebuild the published score? ---- */
    const goalEvents = (f.events ?? []).filter((e) =>
      ['Goal', 'Own Goal', 'Penalty'].includes(e.type?.name ?? ''),
    );
    if (goalEvents.length > 0) {
      const r = reconstructScore(f);
      if (r.agrees) tally.ogReconstructOk += 1;
      else {
        tally.ogReconstructBad += 1;
        notes.push(
          `OWN-GOAL RULE: match ${m.id} ${n.home.name} v ${n.away.name} — published ${r.published}, ` +
            `events rebuild ${r.reconstructed} (${r.ownGoals} own goal(s))`,
        );
      }
    }

    /* ---- events: goals only, which is what this vault is for ---- */
    const GOAL_TYPES = new Set(['GOAL', 'OWN_GOAL', 'PENALTY_GOAL']);
    const pGoals = normaliseEvents(f).filter((e) => GOAL_TYPES.has(e.type));
    const vGoals = m.match_events.filter((e) => GOAL_TYPES.has(e.type));

    if (pGoals.length !== vGoals.length) {
      tally.eventsDiffer += 1;
      notes.push(
        `EVENT COUNT: match ${m.id} ${n.home.name} v ${n.away.name} — ` +
          `vault ${vGoals.length} goal events, SportMonks ${pGoals.length}`,
      );
    } else {
      tally.eventsAgree += 1;
    }

    // Scorer names, paired WITHIN EACH SIDE in chronological order.
    //
    // Pairing on the minute alone is wrong and was wrong here: Geita Gold 2-2
    // Azam has a goal for each side at 45' and another for each at 90', so a
    // minute-only pairing matched a Geita goal against an Azam one and reported
    // three disagreements that were artefacts of the pairing. Sources also
    // disagree on the minute of a late goal (the vault's flat 90' against
    // SportMonks' 90+18), so the minute cannot carry the pairing at all.
    //
    // Within one side, with the counts agreeing, chronological order is a
    // bijection between the same goals — which is the same argument the
    // whole-side naming rule rests on. It is used here for a REPORT only; it
    // never writes a name.
    const byTeam = (teamVaultId: number) => ({
      vault: vGoals
        .filter((e) => e.team_id === teamVaultId)
        .sort((a, b) => (a.minute ?? 999) - (b.minute ?? 999) || (a.added_time ?? 0) - (b.added_time ?? 0)),
      provider: pGoals
        .filter((e) => teamMap.get(e.team.id) === teamVaultId)
        .sort((a, b) => (a.minute ?? 999) - (b.minute ?? 999) || (a.extraMinute ?? 0) - (b.extraMinute ?? 0)),
    });

    for (const teamVaultId of [homeId, awayId]) {
      const { vault, provider } = byTeam(teamVaultId);
      if (vault.length !== provider.length) continue; // counts differ: no bijection
      // A side is only pairable when BOTH sides' events all carry a minute.
      // Otherwise the minuteless ones sort to the end while the provider's are
      // chronological, and the whole list shifts by one — which is how match
      // 17991 nearly had its scorers scrambled. Report it, don't guess at it.
      if (vault.some((e) => e.minute === null) || provider.some((e) => e.minute === null)) {
        tally.sideUnpairable += 1;
        continue;
      }
      for (let i = 0; i < provider.length; i += 1) {
        const pe = provider[i];
        const ve = vault[i];
        if (pe === undefined || ve === undefined) continue;
        const vName = ve.players_match_events_player_idToplayers?.full_name ?? null;
        if (pe.playerName === null) {
          if (vName !== null) tally.scorerProviderUnnamed += 1;
          continue;
        }
        if (vName === null) {
          tally.scorerNewToVault += 1;
          continue;
        }
        if (sameName(vName, pe.playerName)) tally.scorerAgree += 1;
        else {
          tally.scorerDisagree += 1;
          notes.push(
            `SCORER: match ${m.id} ${n.home.name} v ${n.away.name}, ` +
              `${pe.minute ?? '?'}'${pe.extraMinute ? `+${pe.extraMinute}` : ''} ${pe.type} — ` +
              `vault "${vName}", SportMonks "${pe.playerName}"`,
          );
        }
      }
    }
  }

  console.log(`SportMonks league ${leagueId} "${league.name}" season ${seasonName} (id ${seasonId})`);
  console.log(`against vault edition #${editionId} (${vaultMatches.length} fixtures)\n`);

  const line = (label: string, n: number, extra = '') =>
    console.log(`  ${String(n).padStart(4)}  ${label}${extra}`);

  console.log('Fixture matching');
  line('fixtures from SportMonks', tally.fixtures);
  line('no two participants yet (draw not made)', tally.noParticipants);
  line('skipped, team not mapped', tally.unmappedTeam);
  line('no matching vault fixture', tally.unmatchedFixture);

  console.log('\nScores');
  line('agree', tally.scoreAgree);
  line('DISAGREE', tally.scoreDisagree);
  line('SportMonks has one, vault does not', tally.providerOnlyScore);
  line('vault has one, SportMonks does not', tally.vaultOnlyScore);

  console.log('\nKickoff and round');
  line('kickoff dates differ', tally.kickoffDiffer);
  line('round agrees', tally.roundAgree);
  line('round DISAGREES', tally.roundDisagree);
  line('round new to the vault', tally.roundNewToVault);

  console.log('\nEvents');
  line('goal-event count agrees', tally.eventsAgree);
  line('goal-event count differs', tally.eventsDiffer);
  line('event log rebuilds the published score', tally.ogReconstructOk);
  line('event log does NOT rebuild it', tally.ogReconstructBad);
  line('awarded results (never reconcile)', tally.awarded);

  console.log('\nScorer names (paired within each side, chronologically)');
  line('agree', tally.scorerAgree);
  line('DISAGREE', tally.scorerDisagree);
  line('vault has the goal but no scorer', tally.scorerNewToVault);
  line('SportMonks has the goal but no scorer', tally.scorerProviderUnnamed);
  line('sides not pairable (a goal lacks a minute)', tally.sideUnpairable);

  if (notes.length > 0) {
    const show = values.verbose ? notes : notes.slice(0, 25);
    console.log(`\nFindings (${notes.length}${values.verbose ? '' : `, showing ${show.length}`}):`);
    for (const nt of show) console.log(`  - ${nt}`);
    if (!values.verbose && notes.length > show.length) {
      console.log('  ... re-run with --verbose for the rest');
    }
  }
  console.log('\nRead-only: nothing was written.');
} catch (err) {
  if (err instanceof SportmonksError) {
    console.error(`SportMonks request failed: ${err.message}`);
    process.exitCode = 1;
  } else {
    throw err;
  }
} finally {
  await prisma.$disconnect();
}
