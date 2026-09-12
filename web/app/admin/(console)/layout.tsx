import { redirect } from 'next/navigation';
import { LogOut } from 'lucide-react';
import { adminFetch, AdminApiError } from '@/lib/adminApi';
import { getSessionToken } from '@/lib/session';
import { AdminShell } from '@/components/admin/shell';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { btn } from '@/components/admin/styles';
import { signOutAction } from '../actions';

export const dynamic = 'force-dynamic';

/**
 * The signed-in console. Checks the session once, here, so no console page can
 * render for someone without a live account — a cookie being present is not
 * proof it is still valid, and a deactivated admin's token fails `/me`.
 */
export default async function ConsoleLayout({ children }: { children: React.ReactNode }) {
  if (!(await getSessionToken())) redirect('/admin/login');

  let admin: { id: number; email: string; displayName: string };
  try {
    admin = (await adminFetch<{ admin: typeof admin }>('/api/admin/me')).admin;
  } catch (err) {
    if (err instanceof AdminApiError && (err.status === 401 || err.status === 403)) {
      redirect('/admin/login');
    }
    throw err;
  }

  return (
    <AdminShell
      admin={admin}
      signOut={
        <ConfirmForm
          action={signOutAction}
          title="Sign out?"
          description="You will need your email and password to get back into the dashboard."
          confirmLabel="Sign out"
          trigger={<><LogOut /> <span className="hidden sm:inline">Sign out</span></>}
          triggerClassName={btn('ghost', 'sm')}
          triggerAriaLabel="Sign out"
        />
      }
    >
      {children}
    </AdminShell>
  );
}
