import { redirect } from 'next/navigation';
import { AdminApiError } from './adminApi';

/**
 * Shared plumbing for admin server actions. Deliberately not a 'use server'
 * module: those may only export async functions, and this exports a type and
 * synchronous helpers too.
 */

export type ActionState = {
  error?: string;
  ok?: string;
  /** Changes on every settle, so the same message twice still registers. */
  at?: number;
  /** Where to go once the success toast is shown, e.g. a record just created. */
  redirectTo?: string;
};

/**
 * Run a mutation and report it as ActionState. An expired session sends the
 * editor to sign in rather than showing an error they cannot act on.
 */
export async function mutate(
  fn: () => Promise<unknown>,
  ok: string | ((result: unknown) => string),
  opts: { redirectTo?: string | ((result: unknown) => string) } = {},
): Promise<ActionState> {
  let result: unknown;
  try {
    result = await fn();
  } catch (err) {
    if (err instanceof AdminApiError) {
      if (err.status === 401) redirect('/admin/login');
      return { error: err.message, at: Date.now() };
    }
    throw err;
  }
  const to = typeof opts.redirectTo === 'function' ? opts.redirectTo(result) : opts.redirectTo;
  return {
    ok: typeof ok === 'function' ? ok(result) : ok,
    at: Date.now(),
    ...(to && { redirectTo: to }),
  };
}

export const fail = (error: string): ActionState => ({ error, at: Date.now() });

/* ----------------------------------------------------------- form readers -- */

export const text = (fd: FormData, key: string) => String(fd.get(key) ?? '').trim();

/** Blank means "clear it" — sent as null, never as an empty string. */
export const textOrNull = (fd: FormData, key: string) => text(fd, key) || null;

/** Blank means unknown, so null; never coerced to 0. */
export function intOrNull(fd: FormData, key: string): number | null {
  const raw = text(fd, key);
  if (raw === '') return null;
  const n = Number(raw);
  return Number.isInteger(n) ? n : NaN;
}

export const id = (fd: FormData, key: string) => Number(text(fd, key));
