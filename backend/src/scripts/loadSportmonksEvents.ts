/**
 * Load goal events for a SportMonks league season, resolving every scorer to a
 * full name before writing it.
 *
 *   npm run sm:events -- --league 806           # dry run, reports everything
 *   npm run sm:events -- --league 806 --apply
 *
 * This is the one place this codebase writes events from SportMonks, and it is
 * deliberately narrow. The live sync writes scores and never events, because for
 * the Tanzanian Premier League the vault's own goal log is the better one. For a
 * league the vault holds NO events for, the calculus is different: something
 * beats nothing — but only if the names are real.
 *
 * **The event feed's `player_name` is a DISPLAY name and is often abbreviated.**
 * Across this provider's African leagues: 18 of Rwanda's 28 scorer names are
 * initials plus a surname, 13 of Uganda's 50, and 8 of South Africa's 84.
 * Writing those straight in would seed a brand-new player table with "K.
 * Nsanzimfura" — the identity defect this project has spent the most time
 * undoing, and with no second source for these leagues, nothing would catch it.
 *
 * So every scorer is resolved through `/players/{id}`, which carries the real
 * name: "S. Kammies" is Sergio Kammies, "B. Grobler" is Bradley Grobler. That is
 * the same technique as taking a Flashscore name from its player link rather
 * than its timeline. **A goal whose scorer cannot be resolved to a full name is
 * written UNATTRIBUTED rather than with an abbreviation** — a goal with no
 * scorer is the truth; a goal credited to "S. Kammies" is a second record for a
 * man the vault may already hold.
 *
 * Which is why this is worth running for South Africa (120 of 125 goals carry a
 * player id) and not for Rwanda (8 of 29).
 *
 * Two refusals, both borrowed from the loaders that came before:
 *
 * * **A match whose event log does not account for its score is not loaded.**
 *   Padding the rest with invented events would break the one invariant this
 *   data still holds.
 * * **A match that already has goal events is never added to.** Completing a log
 *   is a different job from creating one, and doing it blind duplicates goals.
 */
import { parseArgs } from 'node:util';
import type { Prisma } from '@prisma/client';
import { prisma } from '../db.js';
import {
  sportmonks,
  SportmonksError,
  normaliseFixture,
  normaliseEvents,
  reconstructScore,
  isAbbreviated,
  bestPlayerName,
} from '../services/sportmonks.js';
import { resolveVaultIds, editionKey } from '../services/entityResolution.js';
import { recordProvenance } from '../services/provenance.js';

const { values } = parseArgs({
  options: {
    league: { type: 'string' },
    season: { type: 'string' },
    apply: { type: 'boolean', default: false },
  },
});

const leagueId = Number(values.league);
if (!Number.isInteger(leagueId)) {
  console.error('Usage: npm run sm:events -- --league <sportmonksLeagueId> [--season <id>] [--apply]');
  process.exit(1);
}

const GOAL_TYPES = new Set(['GOAL', 'OWN_GOAL', 'PENALTY_GOAL']);

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

  const editionMap = await resolveVaultIds(
    'competition_edition',
    [editionKey(leagueId, seasonId)],
    'sportmonks',
  );
  const editionId = editionMap.get(editionKey(leagueId, seasonId));
  if (editionId === undefined) {
    console.error(`Edition not mapped. Run: npm run sm:ingest -- --league ${leagueId} --apply`);
    process.exit(1);
  }

  const raw = await sportmonks.seasonFixtures(seasonId);
  const teamMap = await resolveVaultIds(
    'team',
    raw.flatMap((f) => (f.participants ?? []).map((p) => p.id)),
    'sportmonks',
  );
  const matchMap = await resolveVaultIds('match', raw.map((f) => f.id), 'sportmonks');

  // Vault matches that already hold goal events — never added to.
  const alreadyLogged = new Set(
    (
      await prisma.match_events.findMany({
        where: { matches: { competition_edition_id: editionId }, type: { in: [...GOAL_TYPES] } },
        select: { match_id: true },
        distinct: ['match_id'],
      })
    ).map((r) => r.match_id),
  );

  /* ------------------------------------------------- resolve every scorer */
  const playerCache = new Map<string, { name: string; first: string | null; last: string | null; dob: string | null; country: string | null } | null>();
  const vaultCountries = await prisma.countries.findMany({ select: { id: true, name: true } });
  const countryByName = new Map(vaultCountries.map((c) => [c.name.toLowerCase(), c.id]));

  /**
   * One player, cached, named by `bestPlayerName` — which takes whichever of the
   * response's three name fields is not an abbreviation. Reading `name` alone
   * left South Africa's Giovanni Philander unattributed while the same response
   * carried his first name.
   */
  async function resolvePlayer(providerId: string) {
    if (playerCache.has(providerId)) return playerCache.get(providerId)!;
    const p = await sportmonks.player(Number(providerId));
    const rec = p
      ? {
          name: bestPlayerName(p),
          first: p.firstname ?? null,
          last: p.lastname ?? null,
          dob: p.date_of_birth ?? null,
          country: p.country?.name ?? null,
        }
      : null;
    playerCache.set(providerId, rec);
    return rec;
  }

  type Plan = {
    matchId: number;
    fixtureName: string;
    events: {
      type: string;
      minute: number | null;
      added: number | null;
      teamVaultId: number;
      providerPlayerId: string | null;
      resolvedName: string | null;
      rawName: string | null;
      reason: string;
    }[];
  };

  const plans: Plan[] = [];
  const refusals: string[] = [];
  let skippedNoGoals = 0;
  let skippedAlreadyLogged = 0;

  for (const f of raw) {
    const n = normaliseFixture(f, league.name);
    if (!n) continue;
    const matchId = matchMap.get(n.id);
    if (matchId === undefined) {
      refusals.push(`${f.name}: fixture not mapped to a vault match`);
      continue;
    }

    const goals = normaliseEvents(f).filter((e) => GOAL_TYPES.has(e.type));
    if (goals.length === 0) {
      skippedNoGoals += 1;
      continue;
    }
    if (alreadyLogged.has(matchId)) {
      skippedAlreadyLogged += 1;
      continue;
    }

    // The log must account for the score, under the vault's own-goal rule.
    const rec = reconstructScore(f);
    if (!rec.agrees) {
      refusals.push(
        `${f.name}: event log rebuilds ${rec.reconstructed} against a published ${rec.published}`,
      );
      continue;
    }
    // ...and against what the vault actually stores for this match.
    const vaultMatch = await prisma.matches.findUnique({
      where: { id: matchId },
      select: { home_score: true, away_score: true },
    });
    if (
      vaultMatch?.home_score !== n.homeScore ||
      vaultMatch?.away_score !== n.awayScore
    ) {
      refusals.push(
        `${f.name}: vault holds ${vaultMatch?.home_score}-${vaultMatch?.away_score}, ` +
          `source ${n.homeScore}-${n.awayScore}`,
      );
      continue;
    }

    const planned: Plan['events'] = [];
    for (const g of goals) {
      const teamVaultId = teamMap.get(g.team.id);
      if (teamVaultId === undefined) {
        refusals.push(`${f.name}: event on an unmapped team ${g.team.name}`);
        planned.length = 0;
        break;
      }
      // Take a real name from EITHER source, preferring the players endpoint.
      // Neither is reliably fuller than the other: it gives "Sergio Kammies"
      // where the event says "S. Kammies", but also "P. Kumalo" where the event
      // says "Philani Kumalo". Always trusting one throws away the other.
      let resolvedName: string | null = null;
      let reason = '';
      const endpointName = g.playerId ? (await resolvePlayer(g.playerId))?.name ?? null : null;
      const eventName = g.playerName;

      if (endpointName && !isAbbreviated(endpointName)) {
        resolvedName = endpointName;
        reason = 'players endpoint';
      } else if (eventName && !isAbbreviated(eventName)) {
        resolvedName = eventName;
        reason = endpointName
          ? `event feed (players endpoint gave "${endpointName}")`
          : 'event feed name, already full';
      } else if (endpointName || eventName) {
        reason = `abbreviated in both sources ("${eventName ?? '-'}" / "${endpointName ?? '-'}")`;
      } else {
        reason = 'source names no scorer';
      }
      planned.push({
        type: g.type,
        minute: g.minute,
        added: g.extraMinute,
        teamVaultId,
        providerPlayerId: g.playerId,
        resolvedName,
        rawName: g.playerName,
        reason,
      });
    }
    if (planned.length > 0) plans.push({ matchId, fixtureName: f.name, events: planned });
  }

  const allEvents = plans.flatMap((p) => p.events);
  const named = allEvents.filter((e) => e.resolvedName !== null);
  const unnamed = allEvents.filter((e) => e.resolvedName === null);

  console.log(`SportMonks league ${leagueId} "${league.name}", season id ${seasonId}`);
  console.log(`Vault edition #${editionId}\n`);
  console.log(`Matches: ${plans.length} to load, ${skippedAlreadyLogged} already have a goal log, ` +
    `${skippedNoGoals} have no goals in the source`);
  console.log(`Goal events: ${allEvents.length}`);
  console.log(`  ${named.length} resolved to a full name`);
  console.log(`  ${unnamed.length} will be written UNATTRIBUTED (a goal with no scorer is the truth)`);
  const byReason = new Map<string, number>();
  for (const e of unnamed) {
    const k = e.reason.replace(/\(".*"\)/, '(…)');
    byReason.set(k, (byReason.get(k) ?? 0) + 1);
  }
  for (const [k, v] of byReason) console.log(`     ${v}  ${k}`);
  if (refusals.length > 0) {
    console.log(`\nREFUSED (${refusals.length}):`);
    for (const r of refusals.slice(0, 15)) console.log(`  - ${r}`);
  }

  // Key a scorer by the provider's player id where there is one, and by the
  // resolved name where there is not. Keying on the id ALONE silently dropped
  // five South African goals that carried a full name but no id -- they were
  // resolved, reported as named, and then written unattributed.
  const playerKey = (e: { providerPlayerId: string | null; resolvedName: string | null }) =>
    e.providerPlayerId ? `id:${e.providerPlayerId}` : `name:${e.resolvedName}`;
  const distinctPlayers = new Map<string, string>();
  for (const e of named) distinctPlayers.set(playerKey(e), e.resolvedName!);
  console.log(`\nDistinct scorers to resolve against the vault: ${distinctPlayers.size}`);

  if (!values.apply) {
    console.log('\nDry run. Nothing written. Re-run with --apply.');
  } else {
    const existingPlayers = await resolveVaultIds(
      'player',
      [...distinctPlayers.keys()],
      'sportmonks',
    );
    const result = await prisma.$transaction(
      async (tx: Prisma.TransactionClient) => {
        // Players first, keyed on the provider's own id so a re-run reuses them
        // and two goals by one man can never make two records.
        const playerVaultId = new Map<string, number>();
        let playersCreated = 0;
        let playersReused = 0;
        for (const [key, fullName] of distinctPlayers) {
          const known = existingPlayers.get(key);
          if (known !== undefined) {
            playerVaultId.set(key, known);
            playersReused += 1;
            continue;
          }
          // A vault player with exactly this full name, and only one, is the
          // same man; anything less certain gets a new record, which the audit
          // raises as a duplicate rather than silently mis-crediting a goal.
          const sameName = await tx.players.findMany({
            where: { full_name: fullName },
            select: { id: true },
          });
          let id: number;
          if (sameName.length === 1) {
            id = sameName[0]!.id;
            playersReused += 1;
          } else {
            const p = key.startsWith('id:') ? await resolvePlayer(key.slice(3)) : null;
            const nationalityId =
              p?.country ? (countryByName.get(p.country.toLowerCase()) ?? null) : null;
            const created = await tx.players.create({
              data: {
                full_name: fullName,
                first_name: p?.first ?? null,
                last_name: p?.last ?? null,
                dob: p?.dob ? new Date(p.dob) : null,
                nationality_id: nationalityId,
              },
              select: { id: true },
            });
            id = created.id;
            playersCreated += 1;
          }
          playerVaultId.set(key, id);
          await recordProvenance(tx, 'player', id, 'sportmonks', key);
        }

        let eventsWritten = 0;
        for (const plan of plans) {
          for (const e of plan.events) {
            const pid = e.resolvedName ? (playerVaultId.get(playerKey(e)) ?? null) : null;
            const ev = await tx.match_events.create({
              data: {
                match_id: plan.matchId,
                team_id: e.teamVaultId,
                player_id: pid,
                minute: e.minute,
                added_time: e.added,
                type: e.type,
              },
              select: { id: true },
            });
            await recordProvenance(
              tx,
              'match_event',
              ev.id,
              'sportmonks',
              `${plan.matchId}-${e.minute ?? 'x'}-${e.type}`,
            );
            eventsWritten += 1;
          }
        }
        return { playersCreated, playersReused, eventsWritten };
      },
      { timeout: 180_000 },
    );

    console.log(
      `\nCOMMITTED\n` +
        `  ${result.playersCreated} player(s) created, ${result.playersReused} reused\n` +
        `  ${result.eventsWritten} goal event(s) written across ${plans.length} match(es)`,
    );
  }
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
