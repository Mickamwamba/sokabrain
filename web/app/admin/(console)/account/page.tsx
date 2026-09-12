import { KeyRound, UserCog } from 'lucide-react';
import { adminFetch } from '@/lib/adminApi';
import { load } from '@/lib/admin-page';
import { ErrorState, Facts, Field, PageHeader, Panel } from '@/components/admin/kit';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { input } from '@/components/admin/styles';
import { changeOwnPasswordAction } from '../../actions';

export const dynamic = 'force-dynamic';

export default async function AccountPage() {
  const res = await load(() =>
    adminFetch<{ admin: { id: number; email: string; displayName: string } }>('/api/admin/me').then((r) => r.admin),
  );
  if (!res.ok) return <ErrorState message={res.error} />;
  const me = res.data;

  return (
    <div className="max-w-3xl space-y-6">
      <PageHeader icon={<UserCog />} title="My account" description="Your sign-in details." />

      <Panel title="Profile" description="Another admin can change your name from Access management.">
        <Facts items={[{ label: 'Name', value: me.displayName }, { label: 'Email', value: me.email }]} />
      </Panel>

      <Panel title="Change password" bodyClassName="p-5">
        <ConfirmForm
          action={changeOwnPasswordAction}
          title="Change your password?"
          description="Use the new one next time you sign in. You stay signed in on this device."
          confirmLabel="Change password"
          resetOnSuccess
          trigger={<><KeyRound /> Change password</>}
          className="space-y-4"
        >
          <Field label="Current password" required>
            <input name="currentPassword" type="password" required autoComplete="current-password" className={`${input} max-w-sm`} />
          </Field>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="New password" required hint="At least 12 characters.">
              <input name="newPassword" type="password" minLength={12} required autoComplete="new-password" className={input} />
            </Field>
            <Field label="Repeat new password" required>
              <input name="confirmPassword" type="password" minLength={12} required autoComplete="new-password" className={input} />
            </Field>
          </div>
        </ConfirmForm>
      </Panel>
    </div>
  );
}
