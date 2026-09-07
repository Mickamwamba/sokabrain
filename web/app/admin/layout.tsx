import Link from 'next/link';
import { getSessionToken } from '@/lib/session';
import { logoutAction } from './actions';

/**
 * Admin shell. The login page renders without it (it has no session yet), so
 * this only decorates the authenticated screens — each of which independently
 * redirects on a 401, since a cookie being present is not proof it is valid.
 */
export default async function AdminLayout({ children }: LayoutProps<'/admin'>) {
  const signedIn = (await getSessionToken()) !== null;

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-border pb-3">
        <div className="flex items-center gap-4">
          <span className="text-sm font-semibold">Admin</span>
          {signedIn ? (
            <nav className="flex gap-3 text-sm text-muted">
              <Link href="/admin" className="hover:text-foreground">Competitions</Link>
              <Link href="/admin/matches" className="hover:text-foreground">Matches</Link>
              <Link href="/admin/flags" className="hover:text-foreground">Flags</Link>
            </nav>
          ) : null}
        </div>
        {signedIn ? (
          <form action={logoutAction}>
            <button type="submit" className="text-xs text-muted hover:text-foreground">
              Sign out
            </button>
          </form>
        ) : null}
      </div>
      {children}
    </div>
  );
}
