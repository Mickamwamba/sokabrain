import { KeyRound, Pencil, Power, RotateCcw, ShieldCheck, UserPlus } from 'lucide-react';
import { adminFetch, type AdminAccount } from '@/lib/adminApi';
import { load } from '@/lib/admin-page';
import { Badge, ErrorState, Field, PageHeader, Panel, fmtDateTime } from '@/components/admin/kit';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { iconBtn, input, td, th } from '@/components/admin/styles';
import {
  createAdminAction,
  renameAdminAction,
  resetAdminPasswordAction,
  setAdminActiveAction,
} from '../../manage-actions';

export const dynamic = 'force-dynamic';

const MIN = 12;

export default async function AccessPage() {
  const res = await load(() => adminFetch<{ admins: AdminAccount[]; currentAdminId: number }>('/api/admin/admins'));
  if (!res.ok) return <ErrorState message={res.error} />;
  const { admins, currentAdminId } = res.data;
  const activeCount = admins.filter((a) => a.isActive).length;

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<KeyRound />}
        title="Access management"
        description="Who can sign in to this dashboard. Every admin has full access — there are no roles."
      />

      <div className="grid gap-6 xl:grid-cols-3">
        <Panel
          className="xl:col-span-2"
          title={`${admins.length} account${admins.length === 1 ? '' : 's'}`}
          description={`${activeCount} active. Accounts are deactivated rather than deleted, so the record of who published what survives.`}
        >
          <div className="overflow-x-auto">
            <table className="w-full min-w-[680px] text-sm">
              <thead className="border-b border-line bg-wash/60">
                <tr>
                  <th className={th}>Admin</th>
                  <th className={th}>Status</th>
                  <th className={th}>Last sign-in</th>
                  <th className={`${th} text-right`}>Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-line">
                {admins.map((a) => {
                  const self = a.id === currentAdminId;
                  const lastActive = a.isActive && activeCount <= 1;
                  return (
                    <tr key={a.id} className={a.isActive ? 'hover:bg-wash/60' : 'bg-wash/40 text-muted'}>
                      <td className={td}>
                        <div className="flex items-center gap-3">
                          <span className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-[11px] font-bold ${a.isActive ? 'bg-ink text-white' : 'bg-line text-muted'}`}>
                            {a.displayName.split(/\s+/).slice(0, 2).map((w) => w[0]?.toUpperCase()).join('')}
                          </span>
                          <div className="min-w-0">
                            <p className="font-semibold text-ink">
                              {a.displayName}
                              {self ? <span className="ml-2 text-xs font-normal text-muted">(you)</span> : null}
                            </p>
                            <p className="truncate text-xs text-muted">{a.email}</p>
                          </div>
                        </div>
                      </td>
                      <td className={td}>
                        {a.isActive ? <Badge tone="green" dot>Active</Badge> : <Badge>Deactivated</Badge>}
                      </td>
                      <td className={`${td} text-xs text-muted`}>{a.lastLoginAt ? fmtDateTime(a.lastLoginAt) : 'Never'}</td>
                      <td className={td}>
                        <div className="flex items-center justify-end gap-1">
                          <ConfirmForm
                            action={renameAdminAction}
                            title={`Rename ${a.displayName}`}
                            description="The name is shown in the dashboard header and on flags they raise."
                            confirmLabel="Save name"
                            trigger={<Pencil />}
                            triggerAriaLabel={`Rename ${a.displayName}`}
                            triggerClassName={iconBtn()}
                            fields={
                              <Field label="Display name" required>
                                <input name="displayName" defaultValue={a.displayName} required maxLength={100} className={input} />
                              </Field>
                            }
                          >
                            <input type="hidden" name="adminId" value={a.id} />
                          </ConfirmForm>

                          {!self ? (
                            <ConfirmForm
                              action={resetAdminPasswordAction}
                              tone="danger"
                              title={`Set a new password for ${a.displayName}`}
                              description="Their current password stops working immediately. Tell them the new one through a secure channel."
                              confirmLabel="Reset password"
                              trigger={<RotateCcw />}
                              triggerAriaLabel={`Reset ${a.displayName}'s password`}
                              triggerClassName={iconBtn()}
                              fields={
                                <>
                                  <Field label="New password" required hint={`At least ${MIN} characters.`}>
                                    <input name="password" type="password" minLength={MIN} required autoComplete="new-password" className={input} />
                                  </Field>
                                  <Field label="Repeat it" required>
                                    <input name="confirmPassword" type="password" minLength={MIN} required autoComplete="new-password" className={input} />
                                  </Field>
                                </>
                              }
                            >
                              <input type="hidden" name="adminId" value={a.id} />
                            </ConfirmForm>
                          ) : null}

                          {!self ? (
                            <ConfirmForm
                              action={setAdminActiveAction}
                              tone={a.isActive ? 'danger' : 'primary'}
                              title={a.isActive ? `Revoke ${a.displayName}’s access?` : `Restore ${a.displayName}’s access?`}
                              description={
                                a.isActive
                                  ? 'They are signed out at once and cannot sign back in. Everything they published stays attributed to them.'
                                  : 'They can sign in again with their existing password.'
                              }
                              confirmLabel={a.isActive ? 'Revoke access' : 'Restore access'}
                              trigger={a.isActive ? <Power /> : <ShieldCheck />}
                              triggerAriaLabel={a.isActive ? `Deactivate ${a.displayName}` : `Reactivate ${a.displayName}`}
                              triggerClassName={iconBtn(a.isActive ? 'danger' : 'ghost')}
                              disabled={lastActive}
                            >
                              <input type="hidden" name="adminId" value={a.id} />
                              <input type="hidden" name="isActive" value={String(!a.isActive)} />
                            </ConfirmForm>
                          ) : null}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </Panel>

        <Panel title="Add an admin" description="They get full access to this dashboard." className="self-start">
          <ConfirmForm
            action={createAdminAction}
            title="Give this person admin access?"
            description="They will be able to edit and publish anything in the vault, and to manage other admins."
            confirmLabel="Create account"
            review="all"
            resetOnSuccess
            trigger={<><UserPlus /> Create account</>}
            className="space-y-4 p-5"
          >
            <Field label="Name" required>
              <input name="displayName" required maxLength={100} data-label="Name" className={input} />
            </Field>
            <Field label="Email" required>
              <input name="email" type="email" required autoComplete="off" data-label="Email" className={input} />
            </Field>
            <Field label="Initial password" required hint={`At least ${MIN} characters. Share it with them securely; they can change it under My account.`}>
              <input name="password" type="password" minLength={MIN} required autoComplete="new-password" data-label="Password" className={input} />
            </Field>
            <Field label="Repeat password" required>
              <input name="confirmPassword" type="password" minLength={MIN} required autoComplete="new-password" className={input} />
            </Field>
          </ConfirmForm>
        </Panel>
      </div>
    </div>
  );
}
