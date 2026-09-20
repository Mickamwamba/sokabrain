/**
 * Bring a whole SportMonks league season into the vault: competition, edition,
 * clubs, participants and fixtures.
 *
 *   npm run sm:ingest -- --league 872                 # dry run, reports everything
 *   npm run sm:ingest -- --league 872 --apply
 *   npm run sm:ingest -- --league 872 --season 28542 --apply
 *
 * This is the "stand up a new league" script. `sm:map` and `sm:sync` take over
 * afterwards: the mapping rows are written here, so the live sync recognises
 * these fixtures immediately.
 *
 * Deliberate properties, each of which is a lesson from earlier ingestion work:
 *
 * **It reuses, it does not duplicate.** A competition already covering this
 * country's top tier is reused rather than created beside it — creating a second
 * one is how a league's history gets split in two. Same for the season, the
 * edition, every club and every fixture.
 *
 * **Club matching is scoped to the club's own country.** Kenya and Uganda both
 * field a club called simply "Police", and Tanzania has "Polisi Tanzania"; an
 * unscoped name match would merge them. A club's country comes from SportMonks'
 * own `country` include, NOT from the league — which is what keeps Al Hilal
 * Omdurman and Al Merreikh, two Sudanese clubs playing in the Rwandan league
 * while the war continues, filed under Sudan.
 *
 * **Nothing is published.** `competition_editions.is_published` stays false, so
 * none of this reaches the public site until someone reviews it in the dashboard.
 * That matters here: some of these seasons are very thin.
 *
 * **The score is never derived from events** (principle 3) and no events are
 * written at all — see `services/liveSync.ts` for why this provider's goal log is
 * not trusted for scorer names.
 */
import { parseArgs } from 'node:util';
import type { Prisma } from '@prisma/client';
import { prisma } from '../db.js';
import {
  sportmonks,
  SportmonksError,
  normaliseFixture,
  isAwarded,
  type SportmonksFixture,
} from '../services/sportmonks.js';
import { editionKey, normalizeName } from '../services/entityResolution.js';
import { recordProvenance } from '../services/provenance.js';
import { TEAM_ALIASES } from '../config/teamAliases.js';
import type { ProviderFixture } from '../services/providerFixture.js';

const { values } = parseArgs({
  options: {
    league: { type: 'string' },
    season: { type: 'string' },
    apply: { type: 'boolean', default: false },
  },
});

const leagueId = Number(values.league);
if (!Number.isInteger(leagueId)) {
  console.error('Usage: npm run sm:ingest -- --league <sportmonksLeagueId> [--season <id>] [--apply]');
  process.exit(1);
}

/**
 * Country names SportMonks spells differently from the vault.
 * Kept tiny and explicit; an unmapped country is reported, never guessed.
 */
const COUNTRY_ALIASES: Record<string, string> = {
  Tanzania: 'Tanzania, United Republic of',
};

function slugify(s: string): string {
  return s
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
}

try {
  /* ---------------------------------------------------------------- league */
  const leagues = await sportmonks.leagues();
  const league = leagues.find((l) => l.id === leagueId);
  if (!league) {
    console.error(
      `League ${leagueId} is not in this subscription. Granted: ${leagues
        .map((l) => `${l.id} (${l.name}, ${l.country?.name})`)
        .join('; ')}`,
    );
    process.exit(1);
  }

  const seasonId = Number.isInteger(Number(values.season))
    ? Number(values.season)
    : league.currentseason?.id;
  const seasonName =
    Number.isInteger(Number(values.season)) && league.currentseason?.id !== Number(values.season)
      ? (await sportmonks.seasons(leagueId)).find((s) => s.id === seasonId)?.name
      : league.currentseason?.name;

  if (seasonId === undefined || seasonName === undefined) {
    console.error(`Could not resolve a season for league ${leagueId}. Pass --season.`);
    process.exit(1);
  }

  console.log(`SportMonks league ${leagueId} "${league.name}" — ${league.country?.name}`);
  console.log(`Season ${seasonName} (id ${seasonId})\n`);

  /* --------------------------------------------------------------- country */
  const providerCountry = league.country?.name;
  if (!providerCountry) {
    console.error('League has no country; cannot place a competition. Aborting.');
    process.exit(1);
  }
  const vaultCountries = await prisma.countries.findMany({ select: { id: true, name: true } });
  const countryByName = new Map(vaultCountries.map((c) => [normalizeName(c.name), c]));
  const resolveCountry = (name: string | undefined) => {
    if (!name) return undefined;
    return countryByName.get(normalizeName(COUNTRY_ALIASES[name] ?? name));
  };
  const leagueCountry = resolveCountry(providerCountry);
  if (!leagueCountry) {
    console.error(
      `Country "${providerCountry}" is not in the vault's countries table. ` +
        'Add it first — a competition must sit in a real country (principle 4).',
    );
    process.exit(1);
  }

  /* ----------------------------------------------------------- competition */
  // Reuse the country's existing tier-1 league if there is one. Creating a
  // second competition beside it would split the league's history in two.
  const existingCompetition = await prisma.competitions.findFirst({
    where: { country_id: leagueCountry.id, type: 'LEAGUE', tier: 1 },
    select: { id: true, name: true, slug: true },
  });
  const competitionName = league.name;
  const competitionSlug = slugify(`${leagueCountry.name} ${competitionName}`);

  console.log('Competition');
  if (existingCompetition) {
    console.log(
      `  REUSE #${existingCompetition.id} "${existingCompetition.name}" (${existingCompetition.slug})`,
    );
  } else {
    console.log(`  CREATE "${competitionName}" (${competitionSlug}), ${leagueCountry.name}, LEAGUE tier 1`);
  }

  /* ---------------------------------------------------- season and edition */
  const existingSeason = await prisma.seasons.findFirst({
    where: { label: seasonName },
    select: { id: true },
  });
  console.log('Season');
  console.log(existingSeason ? `  REUSE #${existingSeason.id} "${seasonName}"` : `  CREATE "${seasonName}"`);

  /* ----------------------------------------------------------- fixtures in */
  const rawFixtures = await sportmonks.seasonFixtures(seasonId);
  const fixtures: { raw: SportmonksFixture; n: ProviderFixture }[] = [];
  let noParticipants = 0;
  for (const raw of rawFixtures) {
    const n = normaliseFixture(raw, league.name);
    if (!n) {
      noParticipants += 1;
      continue;
    }
    fixtures.push({ raw, n });
  }

  /* -------------------------------------------------------------- the clubs */
  // `teams/seasons` is the right source, but it comes back EMPTY for some
  // seasons (Kenya 2026/27), so fall back to the clubs the fixtures name.
  const seasonTeams = await sportmonks.teams(seasonId);
  type ProviderClub = { id: number; name: string; countryName?: string | undefined };
  let clubs: ProviderClub[];
  if (seasonTeams.length > 0) {
    // Re-fetch with the country include, which the squad endpoint supports.
    const withCountry = await sportmonks.teamsWithCountry(seasonId);
    clubs = withCountry.map((t) => ({ id: t.id, name: t.name, countryName: t.country?.name }));
    console.log(`\nClubs: ${clubs.length} from the season squad list`);
  } else {
    const seen = new Map<number, string>();
    for (const { raw } of fixtures) {
      for (const p of raw.participants ?? []) seen.set(p.id, p.name);
    }
    clubs = [...seen.entries()].map(([id, name]) => ({ id, name }));
    console.log(
      `\nClubs: ${clubs.length} derived from fixture participants ` +
        '(the season squad list is EMPTY for this season)',
    );
  }

  /* ------------------------------------------------- match clubs to the vault */
  const vaultTeams = await prisma.teams.findMany({
    select: { id: true, name: true, country_id: true, type: true },
  });
  // Index by (country, normalised name) so two countries' "Police" never collide.
  const byCountryName = new Map<string, { id: number; name: string }[]>();
  const push = (countryId: number, key: string, t: { id: number; name: string }) => {
    const k = `${countryId}:${key}`;
    const list = byCountryName.get(k);
    if (list) {
      if (!list.some((x) => x.id === t.id)) list.push(t);
    } else byCountryName.set(k, [t]);
  };
  for (const t of vaultTeams) push(t.country_id, normalizeName(t.name), t);
  for (const [canonical, aliases] of Object.entries(TEAM_ALIASES)) {
    const t = vaultTeams.find((x) => x.name === canonical);
    if (!t) continue;
    for (const a of aliases) push(t.country_id, normalizeName(a), t);
  }

  type Resolved = {
    club: ProviderClub;
    countryId: number;
    countryName: string;
    vaultId: number | null;
    vaultName: string | null;
    note: string;
  };
  const resolved: Resolved[] = clubs.map((club) => {
    const own = resolveCountry(club.countryName);
    const countryId = own?.id ?? leagueCountry.id;
    const countryName = own?.name ?? leagueCountry.name;
    const note =
      club.countryName === undefined
        ? 'country unknown — assumed the league’s'
        : own === undefined
          ? `country "${club.countryName}" not in the vault — assumed the league’s`
          : own.id === leagueCountry.id
            ? ''
            : `foreign club: ${own.name}`;
    const hits = byCountryName.get(`${countryId}:${normalizeName(club.name)}`) ?? [];
    const only = hits.length === 1 ? hits[0] : undefined;
    return {
      club,
      countryId,
      countryName,
      vaultId: only?.id ?? null,
      vaultName: only?.name ?? null,
      note: hits.length > 1 ? `${note} AMBIGUOUS: ${hits.length} vault teams share this name` : note,
    };
  });

  const reused = resolved.filter((r) => r.vaultId !== null);
  const created = resolved.filter((r) => r.vaultId === null);
  for (const r of reused) {
    console.log(`  REUSE  [${r.club.id}] ${r.club.name}  →  #${r.vaultId} ${r.vaultName}` + (r.note ? `  (${r.note})` : ''));
  }
  for (const r of created) {
    console.log(`  CREATE [${r.club.id}] ${r.club.name}  (${r.countryName}, CLUB)` + (r.note ? `  — ${r.note}` : ''));
  }

  // Near-miss detection. A club created beside one the vault already holds is the
  // worst outcome here -- it splits a club's history silently and the audit only
  // catches it later. "Bandari" came within one dry run of being created beside
  // "Bandari F.C." because the name normaliser mishandled the dots, so these are
  // reported loudly and a human decides. They do NOT block the load: a genuinely
  // new club often shares a word with an existing one.
  const nearMisses: string[] = [];
  for (const r of resolved) {
    const key = normalizeName(r.club.name);
    const firstToken = key.split(' ')[0] ?? '';
    const candidates = vaultTeams.filter((t) => {
      if (t.country_id !== r.countryId) return false;
      // A national side is never the same record as a club, however the names
      // read: "Police Rwanda" is not Rwanda. Comparing across types reported a
      // duplicate that cannot exist.
      if (t.type !== 'CLUB') return false;
      if (t.id === r.vaultId) return false; // the team we resolved to
      const k = normalizeName(t.name);
      if (k === key) return false; // an exact match is handled above
      return (
        k.includes(key) ||
        key.includes(k) ||
        (firstToken.length >= 4 && k.split(' ')[0] === firstToken)
      );
    });
    for (const c of candidates) {
      nearMisses.push(
        r.vaultId === null
          ? `"${r.club.name}" would be CREATED, but ${r.countryName} already has ` +
            `#${c.id} "${c.name}" — same club under another spelling?`
          : `"${r.club.name}" resolved to #${r.vaultId} "${r.vaultName}", but ${r.countryName} ` +
            `ALSO has #${c.id} "${c.name}" — the vault may hold this club twice.`,
      );
    }
  }
  if (nearMisses.length > 0) {
    console.log(`\n  NEAR MISSES (${nearMisses.length}) — check before applying:`);
    for (const n of nearMisses) console.log(`    ! ${n}`);
  }

  /* ------------------------------------------------------------- fixtures */
  const withScore = fixtures.filter((f) => f.n.homeScore !== null).length;
  const withRound = fixtures.filter((f) => f.n.round !== null).length;
  const withEvents = fixtures.filter((f) => (f.raw.events ?? []).length > 0).length;
  const awarded = fixtures.filter((f) => isAwarded(f.raw.state_id));
  const byStatus = new Map<string, number>();
  for (const f of fixtures) byStatus.set(f.n.status, (byStatus.get(f.n.status) ?? 0) + 1);

  console.log(`\nFixtures: ${fixtures.length}` + (noParticipants ? ` (+${noParticipants} with no two participants, skipped)` : ''));
  console.log(`  ${withScore} carry a score, ${withRound} a round, ${withEvents} an event log`);
  console.log(`  status: ${[...byStatus.entries()].map(([s, n]) => `${s} ${n}`).join(', ')}`);
  if (awarded.length > 0) {
    console.log(`  AWARDED (forfeited): ${awarded.map((f) => f.raw.name).join('; ')}`);
  }
  // A league fixture list must not name the same ordered club pair twice: in a
  // double round-robin an (home, away) pair meets exactly once. SportMonks'
  // Rwandan 2026/27 list breaks this -- it gives Police Rwanda v Al Merreikh in
  // both round 2 and round 19, and omits the reverse fixture entirely. Left
  // undetected the second entry silently collapsed onto the first, costing a
  // fixture and giving one match two provider ids. Duplicates are skipped and
  // reported; the first occurrence by kickoff is the one kept.
  const byPair = new Map<string, typeof fixtures>();
  for (const f of fixtures) {
    const k = `${f.n.home.id}:${f.n.away.id}`;
    const list = byPair.get(k);
    if (list) list.push(f);
    else byPair.set(k, [f]);
  }
  const duplicatePairs = [...byPair.entries()].filter(([, v]) => v.length > 1);
  const skipDuplicates = new Set<string>();
  if (duplicatePairs.length > 0) {
    console.log(`\n  DUPLICATE CLUB PAIRS in the source (${duplicatePairs.length}) — the extra entries are SKIPPED:`);
    for (const [, group] of duplicatePairs) {
      const ordered = [...group].sort((a, b) => a.n.kickoff.getTime() - b.n.kickoff.getTime());
      const [keep, ...drop] = ordered;
      console.log(
        `    ! ${keep!.n.home.name} v ${keep!.n.away.name} appears ${group.length} times; ` +
          `keeping round ${keep!.n.round ?? '?'} (${keep!.n.kickoff.toISOString().slice(0, 10)})`,
      );
      for (const d of drop) {
        skipDuplicates.add(d.n.id);
        console.log(`      dropping round ${d.n.round ?? '?'} (${d.n.kickoff.toISOString().slice(0, 10)}), fixture ${d.n.id}`);
      }
    }
  }

  const unresolvable = fixtures.filter((f) => {
    const h = resolved.find((r) => String(r.club.id) === f.n.home.id);
    const a = resolved.find((r) => String(r.club.id) === f.n.away.id);
    return h === undefined || a === undefined;
  });
  if (unresolvable.length > 0) {
    console.log(`  REFUSED: ${unresolvable.length} fixture(s) name a club absent from the club list:`);
    for (const f of unresolvable.slice(0, 5)) console.log(`    ${f.raw.name}`);
  }

  if (!values.apply) {
    console.log('\nDry run. Nothing written. Re-run with --apply.');
  } else if (unresolvable.length > 0) {
    console.error('\nRefusing to write: some fixtures name a club that is not in the club list.');
    process.exitCode = 1;
  } else {
    const result = await prisma.$transaction(
      async (tx: Prisma.TransactionClient) => {
        const competitionId =
          existingCompetition?.id ??
          (
            await tx.competitions.create({
              data: {
                name: competitionName,
                slug: competitionSlug,
                type: 'LEAGUE',
                country_id: leagueCountry.id,
                tier: 1,
              },
              select: { id: true },
            })
          ).id;
        if (!existingCompetition) {
          await recordProvenance(tx, 'competition', competitionId, 'sportmonks', String(leagueId));
        }

        const dbSeasonId =
          existingSeason?.id ??
          (await tx.seasons.create({ data: { label: seasonName }, select: { id: true } })).id;

        const edition = await tx.competition_editions.upsert({
          where: { competition_id_season_id: { competition_id: competitionId, season_id: dbSeasonId } },
          create: {
            competition_id: competitionId,
            season_id: dbSeasonId,
            format: 'ROUND_ROBIN',
            num_teams: clubs.length,
            // is_published stays false: nothing reaches the public site until
            // someone reviews it in the dashboard.
          },
          update: { num_teams: clubs.length },
          select: { id: true },
        });
        await recordProvenance(
          tx,
          'competition_edition',
          edition.id,
          'sportmonks',
          editionKey(leagueId, seasonId),
        );

        // Clubs
        const teamIdByProvider = new Map<string, number>();
        let teamsCreated = 0;
        for (const r of resolved) {
          let id = r.vaultId;
          if (id === null) {
            const t = await tx.teams.create({
              data: { name: r.club.name, type: 'CLUB', country_id: r.countryId },
              select: { id: true },
            });
            id = t.id;
            teamsCreated += 1;
          }
          teamIdByProvider.set(String(r.club.id), id);
          await recordProvenance(tx, 'team', id, 'sportmonks', String(r.club.id));
          await tx.competition_edition_teams.upsert({
            where: {
              competition_edition_id_team_id: { competition_edition_id: edition.id, team_id: id },
            },
            create: { competition_edition_id: edition.id, team_id: id },
            update: {},
          });
        }

        // Fixtures
        const providerMatchId = new Map<string, number>();
        let matchesCreated = 0;
        let matchesReused = 0;
        for (const { n } of fixtures) {
          if (skipDuplicates.has(n.id)) continue;
          const homeId = teamIdByProvider.get(n.home.id)!;
          const awayId = teamIdByProvider.get(n.away.id)!;
          const existing = await tx.matches.findFirst({
            where: {
              competition_edition_id: edition.id,
              home_team_id: homeId,
              away_team_id: awayId,
            },
            select: { id: true },
          });
          let matchId: number;
          if (existing) {
            matchId = existing.id;
            matchesReused += 1;
          } else {
            const m = await tx.matches.create({
              data: {
                competition_edition_id: edition.id,
                home_team_id: homeId,
                away_team_id: awayId,
                kickoff_at: n.kickoff,
                status: n.status,
                home_score: n.homeScore,
                away_score: n.awayScore,
                home_score_et: n.homeScoreEt,
                away_score_et: n.awayScoreEt,
                home_score_pens: n.homeScorePens,
                away_score_pens: n.awayScorePens,
                round: n.round,
              },
              select: { id: true },
            });
            matchId = m.id;
            matchesCreated += 1;
          }
          await recordProvenance(tx, 'match', matchId, 'sportmonks', n.id);
          providerMatchId.set(n.id, matchId);
        }

        // An AWARDED result was forfeited, not played: it has a real score and
        // an event log that can never reproduce it. Flagging it is what stops
        // every future audit and coverage report hunting for goals that were
        // never scored -- the vault has met this twice before and both times it
        // was found by hand.
        let awardedFlagged = 0;
        for (const f of awarded) {
          const matchId = providerMatchId.get(String(f.raw.id));
          if (matchId === undefined) continue;
          const already = await tx.data_flags.findFirst({
            where: { entity_type: 'match', entity_id: matchId, status: 'OPEN' },
            select: { id: true },
          });
          if (already) continue;
          await tx.data_flags.create({
            data: {
              entity_type: 'match',
              entity_id: matchId,
              severity: 'INFO',
              reason:
                `${f.raw.name} was AWARDED (forfeited), not played out. Its score stands but no ` +
                'event log can reproduce it — do not report its goals as missing.',
            },
          });
          awardedFlagged += 1;
        }

        return {
          competitionId,
          editionId: edition.id,
          teamsCreated,
          matchesCreated,
          matchesReused,
          awardedFlagged,
        };
      },
      { timeout: 120_000 },
    );

    console.log(
      `\nCOMMITTED — competition #${result.competitionId}, edition #${result.editionId}\n` +
        `  ${result.teamsCreated} club(s) created, ${resolved.length - result.teamsCreated} reused\n` +
        `  ${result.matchesCreated} fixture(s) created, ${result.matchesReused} reused\n` +
        (result.awardedFlagged > 0
          ? `  ${result.awardedFlagged} awarded result(s) flagged INFO\n`
          : '') +
        '  edition is UNPUBLISHED — publish it in the dashboard when the data is worth serving.',
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
