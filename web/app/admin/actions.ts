'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { adminFetch } from '@/lib/adminApi';
import { clearSessionToken, setSessionToken } from '@/lib/session';
import { fail, id, intOrNull, mutate, text, textOrNull, type ActionState } from '@/lib/admin-actions';

/**
 * Server actions for the admin dashboard. Every one of them is reached through
 * a ConfirmForm, so each runs only after the editor has seen a confirmation of
 * what it will do. They call the backend with the session token server-side;
 * the token never reaches the browser.
 */

const API_URL = process.env.API_URL ?? 'http://localhost:4010';

/* ------------------------------------------------------------------- auth -- */

export async function loginAction(_prev: ActionState, formData: FormData): Promise<ActionState> {
  const email = text(formData, 'email');
  const password = String(formData.get('password') ?? '');
  if (!email || !password) return fail('Email and password are required.');

  let res: Response;
  try {
    res = await fetch(`${API_URL}/api/admin/auth/login`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email, password }),
      cache: 'no-store',
    });
  } catch {
    return fail(`Cannot reach the API at ${API_URL} — is the backend running?`);
  }

  // The backend returns the same 401 for an unknown email, a wrong password and
  // a deactivated account; inventing a more specific message would leak which.
  if (!res.ok) return fail('Invalid email or password.');

  const { token } = (await res.json()) as { token: string };
  await setSessionToken(token);
  redirect('/admin');
}

export async function signOutAction(): Promise<ActionState> {
  await clearSessionToken();
  redirect('/admin/login');
}

export async function changeOwnPasswordAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const currentPassword = String(fd.get('currentPassword') ?? '');
  const newPassword = String(fd.get('newPassword') ?? '');
  if (newPassword !== String(fd.get('confirmPassword') ?? '')) {
    return fail('The new password and its confirmation do not match.');
  }
  return mutate(
    () => adminFetch('/api/admin/me/password', { method: 'POST', body: { currentPassword, newPassword } }),
    'Password changed.',
  );
}

/* -------------------------------------------------------------- editorial -- */

export async function publishEditionAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const editionId = id(fd, 'editionId');
  const publish = text(fd, 'publish') === 'true';
  const state = await mutate(
    () => adminFetch(`/api/admin/editions/${editionId}/${publish ? 'publish' : 'unpublish'}`, { method: 'POST' }),
    publish ? 'Published — it is now live on the public site.' : 'Hidden from the public site.',
  );
  revalidatePath('/admin', 'layout');
  return state;
}

export async function createFlagAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const reason = text(fd, 'reason');
  if (!reason) return fail('A reason is required — a flag with no reason helps nobody.');
  const state = await mutate(
    () =>
      adminFetch('/api/admin/flags', {
        method: 'POST',
        body: {
          entityType: text(fd, 'entityType'),
          entityId: id(fd, 'entityId'),
          severity: text(fd, 'severity') || 'WARNING',
          reason,
        },
      }),
    'Flag raised.',
  );
  revalidatePath('/admin', 'layout');
  return state;
}

export async function resolveFlagAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const note = text(fd, 'note');
  const state = await mutate(
    () =>
      adminFetch(`/api/admin/flags/${id(fd, 'flagId')}/resolve`, {
        method: 'POST',
        body: note ? { note } : {},
      }),
    'Flag resolved.',
  );
  revalidatePath('/admin', 'layout');
  return state;
}

/* ---------------------------------------------------------------- matches -- */

export async function saveMatchAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const matchId = id(fd, 'matchId');
  // A blank score box means "still unknown" — null, never 0, which would record
  // an unplayed or unrecorded match as a goalless draw.
  const home = intOrNull(fd, 'homeScore');
  const away = intOrNull(fd, 'awayScore');
  const attendance = intOrNull(fd, 'attendance');
  for (const v of [home, away, attendance]) {
    if (Number.isNaN(v)) return fail('Scores and attendance must be whole numbers, or left blank if unknown.');
    if (v !== null && v < 0) return fail('Scores and attendance cannot be negative.');
  }
  const state = await mutate(
    () =>
      adminFetch(`/api/admin/matches/${matchId}`, {
        method: 'PATCH',
        body: { status: text(fd, 'status'), home_score: home, away_score: away, attendance },
      }),
    'Match saved.',
  );
  revalidatePath('/admin', 'layout');
  return state;
}

export async function addEventAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const matchId = id(fd, 'matchId');
  const body: Record<string, unknown> = { team_id: id(fd, 'teamId'), type: text(fd, 'type') };
  const minute = intOrNull(fd, 'minute');
  if (Number.isNaN(minute)) return fail('The minute must be a whole number.');
  if (minute !== null) body.minute = minute;
  if (text(fd, 'playerId')) body.player_id = id(fd, 'playerId');

  const state = await mutate(
    () => adminFetch(`/api/admin/matches/${matchId}/events`, { method: 'POST', body }),
    'Event added. The stored score is unchanged — update the result if it should move.',
  );
  revalidatePath(`/admin/matches/${matchId}`);
  return state;
}

export async function deleteEventAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const matchId = id(fd, 'matchId');
  const state = await mutate(
    () => adminFetch(`/api/admin/matches/${matchId}/events/${id(fd, 'eventId')}`, { method: 'DELETE' }),
    'Event deleted.',
  );
  revalidatePath(`/admin/matches/${matchId}`);
  return state;
}

export async function setScorerAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const matchId = id(fd, 'matchId');
  if (!text(fd, 'playerId')) return fail('Pick a player.');
  const state = await mutate(
    () =>
      adminFetch(`/api/admin/matches/${matchId}/events/${id(fd, 'eventId')}`, {
        method: 'PATCH',
        body: { player_id: id(fd, 'playerId') },
      }),
    'Scorer recorded.',
  );
  revalidatePath('/admin', 'layout');
  return state;
}

/* ----------------------------------------------------------- competitions -- */

function competitionBody(fd: FormData) {
  const tier = intOrNull(fd, 'tier');
  return {
    name: text(fd, 'name'),
    type: text(fd, 'type'),
    countryId: text(fd, 'countryId') ? id(fd, 'countryId') : null,
    tier,
  };
}

export async function createCompetitionAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const body = competitionBody(fd);
  if (!body.name) return fail('A competition needs a name.');
  if (Number.isNaN(body.tier)) return fail('Tier must be a whole number.');
  const state = await mutate(
    () =>
      adminFetch<{ competition: { id: number } }>('/api/admin/competitions', {
        method: 'POST',
        // The create endpoint omits absent keys rather than accepting nulls.
        body: {
          name: body.name,
          type: body.type,
          ...(body.countryId && { countryId: body.countryId }),
          ...(body.tier !== null && { tier: body.tier }),
        },
      }),
    `Created “${body.name}”.`,
    { redirectTo: (r) => `/admin/competitions/${(r as { competition: { id: number } }).competition.id}` },
  );
  revalidatePath('/admin/competitions');
  return state;
}

export async function updateCompetitionAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const competitionId = id(fd, 'competitionId');
  const body = competitionBody(fd);
  if (Number.isNaN(body.tier)) return fail('Tier must be a whole number.');
  const state = await mutate(
    () => adminFetch(`/api/admin/competitions/${competitionId}`, { method: 'PATCH', body }),
    'Competition saved.',
  );
  revalidatePath('/admin', 'layout');
  return state;
}

export async function deleteCompetitionAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const state = await mutate(
    () => adminFetch(`/api/admin/competitions/${id(fd, 'competitionId')}`, { method: 'DELETE' }),
    'Competition deleted.',
    { redirectTo: '/admin/competitions' },
  );
  revalidatePath('/admin/competitions');
  return state;
}

/* --------------------------------------------------------------- editions -- */

export async function createEditionAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const competitionId = id(fd, 'competitionId');
  const numTeams = intOrNull(fd, 'numTeams');
  if (Number.isNaN(numTeams)) return fail('Number of teams must be a whole number.');
  if (!text(fd, 'seasonId')) return fail('Pick a season.');
  const state = await mutate(
    () =>
      adminFetch<{ edition: { id: number } }>(`/api/admin/competitions/${competitionId}/editions`, {
        method: 'POST',
        body: { seasonId: id(fd, 'seasonId'), format: textOrNull(fd, 'format'), numTeams },
      }),
    'Season added. It stays hidden until you publish it.',
    {
      redirectTo: (r) =>
        `/admin/competitions/${competitionId}?season=${(r as { edition: { id: number } }).edition.id}`,
    },
  );
  revalidatePath('/admin', 'layout');
  return state;
}

export async function updateEditionAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const numTeams = intOrNull(fd, 'numTeams');
  if (Number.isNaN(numTeams)) return fail('Number of teams must be a whole number.');
  const state = await mutate(
    () =>
      adminFetch(`/api/admin/editions/${id(fd, 'editionId')}`, {
        method: 'PATCH',
        body: { format: textOrNull(fd, 'format'), numTeams },
      }),
    'Season details saved.',
  );
  revalidatePath('/admin', 'layout');
  return state;
}

export async function deleteEditionAction(_prev: ActionState, fd: FormData): Promise<ActionState> {
  const competitionId = id(fd, 'competitionId');
  const state = await mutate(
    () => adminFetch(`/api/admin/editions/${id(fd, 'editionId')}`, { method: 'DELETE' }),
    'Season removed from the competition.',
    { redirectTo: `/admin/competitions/${competitionId}` },
  );
  revalidatePath('/admin', 'layout');
  return state;
}
