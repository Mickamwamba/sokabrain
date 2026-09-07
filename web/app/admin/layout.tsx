import Link from 'next/link';
import { getSessionToken } from '@/lib/session';
import { AdminNav } from '@/components/admin-nav';
import { logoutAction } from './actions';

/**
 * Admin shell: persistent left sidebar beside the working area.
 *
 * The login page renders inside this too but without the sidebar, since it has
 * no session yet. Each authenticated page independently redirects on a 401 — a
 * cookie being present is not proof it is still valid.
 */
export default async function AdminLayout({ children }: LayoutProps<'/admin'>) {
  const signedIn = (await getSessionToken()) !== null;

  if (!signedIn) return <>{children}</>;

  return (
    <div className="flex gap-6">
      <aside className="hidden w-52 shrink-0 md:block">
        <div className="sticky top-6 space-y-4">
          <div>
            <p className="display px-3 text-xs font-bold uppercase tracking-wider text-muted">
              Admin
            </p>
          </div>
          <AdminNav />
          <div className="border-t border-line pt-4">
            <Link
              href="/"
              className="block rounded-lg px-3 py-2 text-sm text-muted hover:bg-wash hover:text-ink"
            >
              View public site
            </Link>
            <form action={logoutAction}>
              <button
                type="submit"
                className="w-full rounded-lg px-3 py-2 text-left text-sm text-muted hover:bg-wash hover:text-ink"
              >
                Sign out
              </button>
            </form>
          </div>
        </div>
      </aside>

      <div className="min-w-0 flex-1">
        {/* Sidebar collapses on small screens; these keep it navigable there. */}
        <div className="mb-4 flex gap-1.5 overflow-x-auto md:hidden">
          {['/admin', '/admin/competitions', '/admin/matches', '/admin/flags'].map((h) => (
            <Link
              key={h}
              href={h}
              className="whitespace-nowrap rounded-full border border-line bg-paper px-3 py-1.5 text-xs font-medium"
            >
              {h === '/admin' ? 'Overview' : h.split('/').pop()}
            </Link>
          ))}
        </div>
        {children}
      </div>
    </div>
  );
}
