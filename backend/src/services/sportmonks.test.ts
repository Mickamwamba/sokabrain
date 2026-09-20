/**
 * Unit tests for the SportMonks normaliser.
 *
 * No network and no database: these test the three things about this source that
 * had to be established against real data, and that would silently corrupt the
 * vault if they regressed.
 *
 *   npm test
 */
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  mapState,
  isAwarded,
  mapEventType,
  normaliseFixture,
  normaliseEvents,
  reconstructScore,
  type SportmonksFixture,
} from './sportmonks.js';

const HOME = 19222; // Kagera Sugar
const AWAY = 263664; // Fountain Gate

/**
 * Kagera Sugar 1-1 Fountain Gate, 13 September 2026 (SportMonks fixture
 * 19767556) — the real payload that established the own-goal convention.
 *
 * The own goal is filed on Fountain Gate, the side it COUNTS FOR, and the
 * running score moves 1-0 to 1-1. The vault holds the same scorer at the same
 * minute under Kagera Sugar, because the vault stores an own goal under the
 * scoring player's own team (design principle 5).
 */
function ownGoalFixture(): SportmonksFixture {
  return {
    id: 19767556,
    league_id: 884,
    season_id: 28598,
    round_id: 412766,
    state_id: 5,
    name: 'Kagera Sugar vs Fountain Gate',
    starting_at: '2026-09-13 16:00:00',
    result_info: null,
    participants: [
      { id: AWAY, name: 'Fountain Gate', meta: { location: 'away', winner: null } },
      { id: HOME, name: 'Kagera Sugar', meta: { location: 'home', winner: null } },
    ],
    scores: [
      { id: 1, description: 'CURRENT', score: { goals: 1, participant: 'home' } },
      { id: 2, description: 'CURRENT', score: { goals: 1, participant: 'away' } },
      { id: 3, description: '2ND_HALF_ONLY', score: { goals: 0, participant: 'home' } },
      { id: 4, description: '2ND_HALF_ONLY', score: { goals: 0, participant: 'away' } },
    ],
    events: [
      {
        id: 10,
        type_id: 14,
        participant_id: HOME,
        player_id: null,
        player_name: 'Masanja Jesto Kamli',
        related_player_name: null,
        minute: 27,
        extra_minute: null,
        result: '1-0',
        type: { id: 14, name: 'Goal' },
      },
      {
        id: 11,
        type_id: 15,
        participant_id: AWAY,
        player_id: null,
        player_name: 'Andrew Vincent Chikupe',
        related_player_name: null,
        minute: 34,
        extra_minute: null,
        result: '1-1',
        type: { id: 15, name: 'Own Goal' },
      },
      {
        id: 12,
        type_id: 19,
        participant_id: AWAY,
        player_id: null,
        player_name: null,
        related_player_name: null,
        minute: 11,
        extra_minute: null,
        result: null,
        type: { id: 19, name: 'Yellowcard' },
      },
    ],
    round: { id: 412766, name: '6' },
  };
}

describe('mapState', () => {
  it('maps the finished states onto FULL_TIME', () => {
    for (const id of [5, 7, 8]) assert.equal(mapState(id), 'FULL_TIME');
  });

  it('maps every in-play state, breaks included, onto LIVE', () => {
    for (const id of [2, 3, 4, 6, 9, 21, 22, 23, 25]) assert.equal(mapState(id), 'LIVE');
  });

  it('separates postponed, cancelled and abandoned', () => {
    assert.equal(mapState(10), 'POSTPONED');
    assert.equal(mapState(12), 'CANCELLED');
    assert.equal(mapState(15), 'ABANDONED');
  });

  it('treats an awarded result as finished, and flags it as awarded', () => {
    // A forfeit has a real score but no event log that can reproduce it. The
    // vault has two of these and both were found by hand; recognising the state
    // is what stops the third being hunted for.
    assert.equal(mapState(17), 'FULL_TIME');
    assert.ok(isAwarded(17));
    assert.ok(!isAwarded(5));
  });

  it('falls back to SCHEDULED for not-started, TBA and pending', () => {
    for (const id of [1, 13, 26]) assert.equal(mapState(id), 'SCHEDULED');
  });
});

describe('mapEventType', () => {
  it('maps the goal types the vault knows', () => {
    assert.equal(mapEventType('Goal'), 'GOAL');
    assert.equal(mapEventType('Own Goal'), 'OWN_GOAL');
    assert.equal(mapEventType('Penalty'), 'PENALTY_GOAL');
  });

  it('returns null for an unrecognised type rather than guessing one', () => {
    assert.equal(mapEventType('VAR'), null);
    assert.equal(mapEventType(undefined), null);
  });
});

describe('normaliseFixture', () => {
  it('takes the CURRENT score, not the cumulative half-time rows', () => {
    const f = normaliseFixture(ownGoalFixture(), 'Ligi kuu Bara');
    assert.ok(f);
    assert.equal(f.homeScore, 1);
    assert.equal(f.awayScore, 1);
  });

  it('reads starting_at as UTC, not as local time', () => {
    // A kickoff read with the server's offset lands on the wrong day. This
    // project has already fixed that defect once.
    const f = normaliseFixture(ownGoalFixture(), 'Ligi kuu Bara');
    assert.equal(f?.kickoff.toISOString(), '2026-09-13T16:00:00.000Z');
  });

  it('keys the competition on the season ID, not its label', () => {
    // The edition mapping is built with the season id, so a label here would
    // make every fixture read as an unmapped competition.
    const f = normaliseFixture(ownGoalFixture(), 'Ligi kuu Bara');
    assert.equal(f?.competition.season, '28598');
    assert.equal(f?.competition.id, '884');
  });

  it('carries the round through', () => {
    assert.equal(normaliseFixture(ownGoalFixture(), 'x')?.round, '6');
  });

  it('returns null when the two participants are not both present', () => {
    const f = ownGoalFixture();
    f.participants = [{ id: HOME, name: 'Kagera Sugar', meta: { location: 'home', winner: null } }];
    assert.equal(normaliseFixture(f, 'x'), null);
  });
});

describe('normaliseEvents', () => {
  it('flips an own goal onto the scoring player’s own team', () => {
    // SportMonks files it under the side it counts FOR. Verified against the
    // vault: this scorer is a Kagera Sugar player, and the vault holds the event
    // under Kagera Sugar.
    const events = normaliseEvents(ownGoalFixture());
    const og = events.find((e) => e.type === 'OWN_GOAL');
    assert.ok(og);
    assert.equal(og.team.id, String(HOME), 'own goal must move to the scorer’s own team');
    assert.equal(og.playerName, 'Andrew Vincent Chikupe');
    assert.equal(og.minute, 34);
  });

  it('leaves an ordinary goal on the side that scored it', () => {
    const goal = normaliseEvents(ownGoalFixture()).find((e) => e.type === 'GOAL');
    assert.equal(goal?.team.id, String(HOME));
  });

  it('drops event types the vault has no value for, rather than inventing one', () => {
    const events = normaliseEvents(ownGoalFixture());
    assert.ok(events.every((e) => e.type !== 'VAR'));
    assert.equal(events.filter((e) => e.type === 'YELLOW_CARD').length, 1);
  });

  it('keeps a null player name as null', () => {
    const card = normaliseEvents(ownGoalFixture()).find((e) => e.type === 'YELLOW_CARD');
    assert.equal(card?.playerName, null);
  });
});

describe('reconstructScore', () => {
  it('rebuilds the published score once the own goal is flipped', () => {
    const r = reconstructScore(ownGoalFixture());
    assert.equal(r.published, '1-1');
    assert.equal(r.reconstructed, '1-1');
    assert.equal(r.ownGoals, 1);
    assert.ok(r.agrees);
  });

  it('disagrees when the own goal is NOT flipped — the check has teeth', () => {
    // Guard against the flip being "simplified" away: with the own goal left on
    // the side it counts for, the same fixture reads 2-0 and the check fails.
    const f = ownGoalFixture();
    const og = f.events!.find((e) => e.type?.name === 'Own Goal')!;
    og.type = { id: 14, name: 'Goal' }; // as if it were an ordinary away goal
    og.participant_id = HOME; //           on the home side
    const r = reconstructScore(f);
    assert.equal(r.reconstructed, '2-0');
    assert.ok(!r.agrees);
  });
});
