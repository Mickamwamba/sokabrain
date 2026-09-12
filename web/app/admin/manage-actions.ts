'use server';

import { revalidatePath } from 'next/cache';
import { adminFetch } from '@/lib/adminApi';
import { fail, id, intOrNull, mutate, text, textOrNull, type ActionState } from '@/lib/admin-actions';

/** Server actions for players, teams, seasons, participants and admin access. */

/* ---------------------------------------------------------------- players -- */

function playerBody(fd: FormData) {
  const height = intOrNull(fd, 'height_cm');
  return {
    full_name: text(fd, 'full_name'),
    first_name: textOrNull(fd, 'first_name'),
    last_name: textOrNull(fd, 'last_name'),
    dob: textOrNull(fd, 'dob'),
    nationality_id: text(fd, 'nationality_id') ? id(fd, 'nationality_id') : null,
    position: textOrNull(fd, 'position'),
    preferred_foot: textOrNull(fd, 'preferred_foot'),
    height_cm: height,
  };
}

export async function savePlayerAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const playerId = text(fd, 'playerId');
  const body = playerBody(fd);
  if (!body.full_name) return fail('A player needs a name.');
  if (Number.isNaN(body.height_cm)) return fail('Height must be a whole number of centimetres.');

  if (playerId) {
    const state = await mutate(
      () => adminFetch(`/api/admin/players/${playerId}`, { method: 'PATCH', body }),
      `Saved ${body.full_name}.`,
    );
    revalidatePath('/admin/players', 'layout');
    return state;
  }

  // Registration: the club they play for now, or none for a free agent.
  const atClub = text(fd, 'club_mode') === 'club';
  if (atClub && (!text(fd, 'club_team_id') || !text(fd, 'club_start'))) {
    return fail('Pick the club and the date they joined, or register them as a free agent.');
  }
  const shirt = intOrNull(fd, 'club_shirt');
  if (Number.isNaN(shirt)) return fail('Shirt number must be a whole number.');
  const club = atClub
    ? {
        teamId: id(fd, 'club_team_id'),
        startDate: text(fd, 'club_start'),
        type: text(fd, 'club_type') || 'PERMANENT',
        shirtNumber: shirt,
      }
    : null;

  const state = await mutate(
    () => adminFetch<{ player: { id: number } }>('/api/admin/players', { method: 'POST', body: { ...body, club } }),
    atClub ? `Registered ${body.full_name}.` : `Registered ${body.full_name} as a free agent.`,
    { redirectTo: (r) => `/admin/players/${(r as { player: { id: number } }).player.id}` },
  );
  revalidatePath('/admin/players', 'layout');
  return state;
}

export async function deletePlayerAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const state = await mutate(
    () => adminFetch(`/api/admin/players/${id(fd, 'playerId')}`, { method: 'DELETE' }),
    'Player deleted.',
    { redirectTo: '/admin/players' },
  );
  revalidatePath('/admin/players', 'layout');
  return state;
}

/* ------------------------------------------------------------------ teams -- */

function teamBody(fd: FormData) {
  return {
    name: text(fd, 'name'),
    short_name: textOrNull(fd, 'short_name'),
    type: text(fd, 'type'),
    country_id: id(fd, 'country_id'),
    stadium_id: text(fd, 'stadium_id') ? id(fd, 'stadium_id') : null,
  };
}

export async function saveTeamAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const teamId = text(fd, 'teamId');
  const body = teamBody(fd);
  if (!body.name) return fail('A team needs a name.');
  if (!body.country_id) return fail('Pick a country.');

  const state = teamId
    ? await mutate(
        () => adminFetch(`/api/admin/teams/${teamId}`, { method: 'PATCH', body }),
        `Saved ${body.name}.`,
      )
    : await mutate(
        () => adminFetch<{ team: { id: number } }>('/api/admin/teams', { method: 'POST', body }),
        `Added ${body.name}.`,
        { redirectTo: (r) => `/admin/teams/${(r as { team: { id: number } }).team.id}` },
      );
  revalidatePath('/admin/teams', 'layout');
  return state;
}

export async function deleteTeamAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const state = await mutate(
    () => adminFetch(`/api/admin/teams/${id(fd, 'teamId')}`, { method: 'DELETE' }),
    'Team deleted.',
    { redirectTo: '/admin/teams' },
  );
  revalidatePath('/admin/teams', 'layout');
  return state;
}

/* ---------------------------------------------------------------- seasons -- */

export async function saveSeasonAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const seasonId = text(fd, 'seasonId');
  const body = {
    label: text(fd, 'label'),
    start_date: textOrNull(fd, 'start_date'),
    end_date: textOrNull(fd, 'end_date'),
  };
  const state = seasonId
    ? await mutate(
        () => adminFetch(`/api/admin/seasons/${seasonId}`, { method: 'PATCH', body }),
        `Saved season ${body.label}.`,
      )
    : await mutate(
        () => adminFetch('/api/admin/seasons', { method: 'POST', body }),
        `Added season ${body.label}.`,
      );
  revalidatePath('/admin/seasons', 'layout');
  return state;
}

export async function deleteSeasonAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const state = await mutate(
    () => adminFetch(`/api/admin/seasons/${id(fd, 'seasonId')}`, { method: 'DELETE' }),
    'Season deleted.',
    { redirectTo: '/admin/seasons' },
  );
  revalidatePath('/admin/seasons', 'layout');
  return state;
}

/* ----------------------------------------------------------- participants -- */

export async function addParticipantAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const editionId = id(fd, 'editionId');
  if (!text(fd, 'teamId')) return fail('Pick a team.');
  const state = await mutate(
    () =>
      adminFetch(`/api/admin/editions/${editionId}/participants`, {
        method: 'POST',
        body: {
          teamId: id(fd, 'teamId'),
          ...(text(fd, 'groupId') && { groupId: id(fd, 'groupId') }),
        },
      }),
    'Team added to the season.',
  );
  revalidatePath('/admin/participants');
  return state;
}

export async function setParticipantGroupAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const editionId = id(fd, 'editionId');
  const state = await mutate(
    () =>
      adminFetch(`/api/admin/editions/${editionId}/participants/${id(fd, 'teamId')}`, {
        method: 'PATCH',
        body: { groupId: text(fd, 'groupId') ? id(fd, 'groupId') : null },
      }),
    'Group updated.',
  );
  revalidatePath('/admin/participants');
  return state;
}

export async function removeParticipantAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const editionId = id(fd, 'editionId');
  const state = await mutate(
    () => adminFetch(`/api/admin/editions/${editionId}/participants/${id(fd, 'teamId')}`, { method: 'DELETE' }),
    'Team removed from the season.',
  );
  revalidatePath('/admin/participants');
  return state;
}

/* ----------------------------------------------------------------- access -- */

export async function createAdminAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const password = String(fd.get('password') ?? '');
  if (password !== String(fd.get('confirmPassword') ?? '')) {
    return fail('The password and its confirmation do not match.');
  }
  const displayName = text(fd, 'displayName');
  const state = await mutate(
    () =>
      adminFetch('/api/admin/admins', {
        method: 'POST',
        body: { email: text(fd, 'email'), displayName, password },
      }),
    `${displayName} can now sign in. Share the password with them securely.`,
  );
  revalidatePath('/admin/access');
  return state;
}

export async function setAdminActiveAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const active = text(fd, 'isActive') === 'true';
  const state = await mutate(
    () => adminFetch(`/api/admin/admins/${id(fd, 'adminId')}`, { method: 'PATCH', body: { isActive: active } }),
    active ? 'Access restored.' : 'Access revoked. They are signed out immediately.',
  );
  revalidatePath('/admin/access');
  return state;
}

export async function renameAdminAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const state = await mutate(
    () =>
      adminFetch(`/api/admin/admins/${id(fd, 'adminId')}`, {
        method: 'PATCH',
        body: { displayName: text(fd, 'displayName') },
      }),
    'Name updated.',
  );
  revalidatePath('/admin', 'layout');
  return state;
}

export async function resetAdminPasswordAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const password = String(fd.get('password') ?? '');
  if (password !== String(fd.get('confirmPassword') ?? '')) {
    return fail('The password and its confirmation do not match.');
  }
  return mutate(
    () => adminFetch(`/api/admin/admins/${id(fd, 'adminId')}/password`, { method: 'POST', body: { password } }),
    'Password reset. Share the new one with them securely.',
  );
}

/* ---------------------------------------------------------------- careers -- */

function feeOrNull(fd: FormData, key: string): number | null {
  const raw = text(fd, key).replaceAll(',', '');
  if (raw === '') return null;
  const n = Number(raw);
  return Number.isFinite(n) && n >= 0 ? n : NaN;
}

export async function recordTransferAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const playerId = id(fd, 'playerId');
  const destination = text(fd, 'toTeamId');
  const release = destination === 'RELEASE';
  const shirt = intOrNull(fd, 'shirtNumber');
  const fee = feeOrNull(fd, 'fee');
  if (!destination) return fail('Pick where the player is going, or release them.');
  if (!text(fd, 'date')) return fail('Enter the date of the move.');
  if (Number.isNaN(shirt)) return fail('Shirt number must be a whole number.');
  if (Number.isNaN(fee)) return fail('The fee must be a number, or left blank.');

  const type = text(fd, 'type') || 'PERMANENT';
  const state = await mutate(
    () =>
      adminFetch(`/api/admin/players/${playerId}/transfers`, {
        method: 'POST',
        body: {
          toTeamId: release ? null : Number(destination),
          date: text(fd, 'date'),
          type,
          loanUntil: type === 'LOAN' ? textOrNull(fd, 'loanUntil') : null,
          shirtNumber: release ? null : shirt,
          fee: release ? null : fee,
        },
      }),
    release ? 'Player released — now a free agent.' : type === 'LOAN' ? 'Loan recorded.' : 'Transfer recorded.',
  );
  revalidatePath('/admin', 'layout');
  return state;
}

function spellBody(fd: FormData) {
  return {
    teamId: id(fd, 'teamId'),
    startDate: text(fd, 'startDate'),
    endDate: textOrNull(fd, 'endDate'),
    type: textOrNull(fd, 'type'),
    shirtNumber: intOrNull(fd, 'shirtNumber'),
    fee: feeOrNull(fd, 'fee'),
  };
}

export async function addSpellAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const body = spellBody(fd);
  if (!body.teamId || !body.startDate) return fail('Pick a team and a start date.');
  if (Number.isNaN(body.shirtNumber) || Number.isNaN(body.fee)) return fail('Shirt number and fee must be numbers.');
  const state = await mutate(
    () => adminFetch(`/api/admin/players/${id(fd, 'playerId')}/spells`, { method: 'POST', body }),
    'Spell added to the history.',
  );
  revalidatePath('/admin', 'layout');
  return state;
}

export async function updateSpellAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const body = spellBody(fd);
  if (Number.isNaN(body.shirtNumber) || Number.isNaN(body.fee)) return fail('Shirt number and fee must be numbers.');
  const state = await mutate(
    () => adminFetch(`/api/admin/spells/${id(fd, 'spellId')}`, { method: 'PATCH', body }),
    'Spell updated.',
  );
  revalidatePath('/admin', 'layout');
  return state;
}

/** One-click fix for an open spell a later spell contradicts. */
export async function endSpellAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const state = await mutate(
    () => adminFetch(`/api/admin/spells/${id(fd, 'spellId')}`, { method: 'PATCH', body: { endDate: text(fd, 'endDate') } }),
    'Spell ended.',
  );
  revalidatePath('/admin', 'layout');
  return state;
}

export async function deleteSpellAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const state = await mutate(
    () => adminFetch(`/api/admin/spells/${id(fd, 'spellId')}`, { method: 'DELETE' }),
    'Spell deleted.',
  );
  revalidatePath('/admin', 'layout');
  return state;
}
