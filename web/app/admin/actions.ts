'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { adminFetch, AdminApiError } from '@/lib/adminApi';
import { clearSessionToken, setSessionToken } from '@/lib/session';

const API_URL = process.env.API_URL ?? 'http://localhost:4010';

export type ActionState = { error?: string; ok?: string };

export async function loginAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const email = String(formData.get('email') ?? '').trim();
  const password = String(formData.get('password') ?? '');
  if (!email || !password) return { error: 'Email and password are required.' };

  let res: Response;
  try {
    res = await fetch(`${API_URL}/api/admin/auth/login`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email, password }),
      cache: 'no-store',
    });
  } catch {
    return { error: `Cannot reach the API at ${API_URL} — is the backend running?` };
  }

  if (!res.ok) {
    // The backend deliberately returns the same 401 for unknown email, wrong
    // password and deactivated account; don't invent a more specific message.
    return { error: 'Invalid credentials.' };
  }

  const { token } = (await res.json()) as { token: string };
  await setSessionToken(token);
  redirect('/admin');
}

export async function logoutAction(): Promise<void> {
  await clearSessionToken();
  redirect('/admin/login');
}

/** Wraps a mutation so an expired session sends the user to login, not an error page. */
async function mutate<T>(fn: () => Promise<T>): Promise<ActionState> {
  try {
    await fn();
    return {};
  } catch (err) {
    if (err instanceof AdminApiError) {
      if (err.status === 401) redirect('/admin/login');
      return { error: err.message };
    }
    throw err;
  }
}

export async function publishEditionAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const editionId = Number(formData.get('editionId'));
  const publish = formData.get('publish') === 'true';

  const state = await mutate(() =>
    adminFetch(`/api/admin/editions/${editionId}/${publish ? 'publish' : 'unpublish'}`, {
      method: 'POST',
    }),
  );
  revalidatePath('/admin');
  return state.error ? state : { ok: publish ? 'Published.' : 'Hidden from the public site.' };
}

export async function createFlagAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const entityType = String(formData.get('entityType') ?? '');
  const entityId = Number(formData.get('entityId'));
  const severity = String(formData.get('severity') ?? 'WARNING');
  const reason = String(formData.get('reason') ?? '').trim();
  if (!reason) return { error: 'A reason is required — a flag with no reason helps nobody.' };

  const state = await mutate(() =>
    adminFetch('/api/admin/flags', {
      method: 'POST',
      body: { entityType, entityId, severity, reason },
    }),
  );
  revalidatePath('/admin');
  revalidatePath('/admin/flags');
  revalidatePath(`/admin/matches/${entityId}`);
  return state.error ? state : { ok: 'Flag raised.' };
}

export async function resolveFlagAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const flagId = Number(formData.get('flagId'));
  const note = String(formData.get('note') ?? '').trim();

  const state = await mutate(() =>
    adminFetch(`/api/admin/flags/${flagId}/resolve`, {
      method: 'POST',
      body: note ? { note } : {},
    }),
  );
  revalidatePath('/admin');
  revalidatePath('/admin/flags');
  return state.error ? state : { ok: 'Flag resolved.' };
}

export async function saveMatchAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const matchId = Number(formData.get('matchId'));
  const raw = (k: string) => String(formData.get(k) ?? '').trim();

  // An empty score box means "still unknown" — send null, never 0, which would
  // record an unplayed or unrecorded match as a goalless draw.
  const score = (k: string) => (raw(k) === '' ? null : Number(raw(k)));
  const home = score('homeScore');
  const away = score('awayScore');
  if ((home !== null && !Number.isInteger(home)) || (away !== null && !Number.isInteger(away))) {
    return { error: 'Scores must be whole numbers, or left blank if unknown.' };
  }
  if ((home !== null && home < 0) || (away !== null && away < 0)) {
    return { error: 'Scores cannot be negative.' };
  }

  const body: Record<string, unknown> = {
    status: raw('status'),
    home_score: home,
    away_score: away,
  };
  const attendance = raw('attendance');
  if (attendance !== '') body.attendance = Number(attendance);

  const state = await mutate(() =>
    adminFetch(`/api/admin/matches/${matchId}`, { method: 'PATCH', body }),
  );
  revalidatePath(`/admin/matches/${matchId}`);
  revalidatePath('/admin/matches');
  return state.error ? state : { ok: 'Match saved.' };
}

export async function addEventAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const matchId = Number(formData.get('matchId'));
  const raw = (k: string) => String(formData.get(k) ?? '').trim();

  const body: Record<string, unknown> = {
    team_id: Number(raw('teamId')),
    type: raw('type'),
  };
  if (raw('minute') !== '') body.minute = Number(raw('minute'));
  if (raw('playerId') !== '') body.player_id = Number(raw('playerId'));

  const state = await mutate(() =>
    adminFetch(`/api/admin/matches/${matchId}/events`, { method: 'POST', body }),
  );
  revalidatePath(`/admin/matches/${matchId}`);
  return state.error
    ? state
    : { ok: 'Event added. The stored score is unchanged — update it above if it should move.' };
}

export async function deleteEventAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const matchId = Number(formData.get('matchId'));
  const eventId = Number(formData.get('eventId'));

  const state = await mutate(() =>
    adminFetch(`/api/admin/matches/${matchId}/events/${eventId}`, { method: 'DELETE' }),
  );
  revalidatePath(`/admin/matches/${matchId}`);
  return state.error ? state : { ok: 'Event deleted.' };
}

export async function createCompetitionAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const name = String(formData.get('name') ?? '').trim();
  const type = String(formData.get('type') ?? '');
  const countryRaw = String(formData.get('countryId') ?? '').trim();
  const tierRaw = String(formData.get('tier') ?? '').trim();
  if (!name) return { error: 'A competition needs a name.' };
  if (!type) return { error: 'Pick a competition type.' };

  const body: Record<string, unknown> = { name, type };
  // Continental and international competitions have no country of their own.
  if (countryRaw) body.countryId = Number(countryRaw);
  if (tierRaw) body.tier = Number(tierRaw);

  const state = await mutate(() =>
    adminFetch('/api/admin/competitions', { method: 'POST', body }),
  );
  revalidatePath('/admin/competitions');
  return state.error ? state : { ok: `Created “${name}”.` };
}

export async function setScorerAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const matchId = Number(formData.get('matchId'));
  const eventId = Number(formData.get('eventId'));
  const raw = String(formData.get('playerId') ?? '').trim();
  if (!raw) return { error: 'Pick a player.' };

  const state = await mutate(() =>
    adminFetch(`/api/admin/matches/${matchId}/events/${eventId}`, {
      method: 'PATCH',
      body: { player_id: Number(raw) },
    }),
  );
  revalidatePath(`/admin/matches/${matchId}`);
  revalidatePath('/admin/matches');
  return state.error ? state : { ok: 'Scorer recorded.' };
}

export async function setEventMinuteAction(
  _prev: ActionState,
  formData: FormData,
): Promise<ActionState> {
  const matchId = Number(formData.get('matchId'));
  const eventId = Number(formData.get('eventId'));
  const raw = String(formData.get('minute') ?? '').trim();
  if (!raw) return { error: 'Enter a minute.' };

  const state = await mutate(() =>
    adminFetch(`/api/admin/matches/${matchId}/events/${eventId}`, {
      method: 'PATCH',
      body: { minute: Number(raw) },
    }),
  );
  revalidatePath(`/admin/matches/${matchId}`);
  return state.error ? state : { ok: 'Minute recorded.' };
}
