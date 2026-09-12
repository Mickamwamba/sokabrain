import { notFound, redirect } from 'next/navigation';
import { AdminApiError } from './adminApi';

/**
 * Load a console page's data. A dead session goes to sign-in and a missing
 * record to the 404 page; any other API failure comes back as a message the
 * page shows in place, rather than as a crashed route.
 */
export async function load<T>(fn: () => Promise<T>): Promise<{ ok: true; data: T } | { ok: false; error: string }> {
  try {
    return { ok: true, data: await fn() };
  } catch (err) {
    if (err instanceof AdminApiError) {
      if (err.status === 401) redirect('/admin/login');
      if (err.status === 404) notFound();
      return { ok: false, error: err.message };
    }
    throw err;
  }
}

export const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
