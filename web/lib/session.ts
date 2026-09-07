import { cookies } from 'next/headers';

/**
 * Admin session token, kept in an httpOnly cookie.
 *
 * httpOnly means page JavaScript cannot read it, so an XSS bug in the dashboard
 * cannot exfiltrate the admin's token. Every authenticated call is made from the
 * server, with the token read out of the cookie here.
 */
export const SESSION_COOKIE = 'sokabrain_admin';

export async function getSessionToken(): Promise<string | null> {
  const store = await cookies();
  return store.get(SESSION_COOKIE)?.value ?? null;
}

export async function setSessionToken(token: string): Promise<void> {
  const store = await cookies();
  store.set(SESSION_COOKIE, token, {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    path: '/',
    // Matches the backend's 12-hour token lifetime.
    maxAge: 12 * 60 * 60,
  });
}

export async function clearSessionToken(): Promise<void> {
  const store = await cookies();
  store.delete(SESSION_COOKIE);
}
