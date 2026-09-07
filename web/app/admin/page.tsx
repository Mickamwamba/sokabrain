import Link from 'next/link';
import { redirect } from 'next/navigation';
import { adminFetch, AdminApiError, type AdminEdition } from '@/lib/adminApi';
import { ActionForm, SeverityTag } from '@/components/admin-ui';
import { createFlagAction, publishEditionAction } from './actions';

export const dynamic = 'force-dynamic';

export default async function AdminCompetitionsPage() {
  let editions: AdminEdition[];
  try {
    editions = (await adminFetch<{ editions: AdminEdition[] }>('/api/admin/editions')).editions;
  } catch (err) {
    if (err instanceof AdminApiError && err.status === 401) redirect('/admin/login');
    if (err instanceof AdminApiError) {
      return <p className="text-sm text-red-600 dark:text-red-400">{err.message}</p>;
    }
    throw err;
  }

  const published = editions.filter((e) => e.isPublished).length;

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-xl font-semibold tracking-tight">Competitions</h1>
        <p className="mt-1 text-sm text-muted">
          {published} of {editions.length} editions are visible on the public site. An
          edition stays hidden until you publish it, and cannot be published while it
          carries an open <SeverityTag severity="BLOCKER" /> flag.
        </p>
      </div>

      <div className="space-y-2">
        {editions.map((e) => (
          <div
            key={e.editionId}
            className="rounded-lg border border-border p-4"
          >
            <div className="flex flex-wrap items-start justify-between gap-3">
              <div className="min-w-0">
                <p className="flex items-center gap-2 font-medium">
                  {e.competition}
                  <span className="text-sm font-normal text-muted">{e.season}</span>
                  {e.isPublished ? (
                    <span className="rounded border border-accent/50 px-1.5 py-0.5 text-[10px] font-medium uppercase text-accent">
                      Live
                    </span>
                  ) : (
                    <span className="rounded border border-border px-1.5 py-0.5 text-[10px] font-medium uppercase text-muted">
                      Hidden
                    </span>
                  )}
                </p>
                <p className="mt-1 text-xs text-muted">
                  {e.country ?? 'International'} · {e.matchCount} matches
                  {e.openFlags > 0 ? (
                    <>
                      {' · '}
                      <Link
                        href={`/admin/flags?editionId=${e.editionId}`}
                        className="underline underline-offset-2 hover:text-foreground"
                      >
                        {e.openFlags} open flag{e.openFlags === 1 ? '' : 's'}
                      </Link>
                      {e.flags.BLOCKER > 0 ? (
                        <span className="ml-1 text-red-600 dark:text-red-400">
                          ({e.flags.BLOCKER} blocking)
                        </span>
                      ) : null}
                    </>
                  ) : null}
                </p>
              </div>

              <div className="flex shrink-0 items-center gap-2">
                <Link
                  href={`/admin/matches?editionId=${e.editionId}`}
                  className="rounded border border-border px-3 py-1.5 text-xs hover:border-accent"
                >
                  Matches
                </Link>
                <ActionForm
                  action={publishEditionAction}
                  submitLabel={e.isPublished ? 'Hide' : 'Publish'}
                  submitClassName={
                    e.canPublish || e.isPublished
                      ? 'rounded border border-border px-3 py-1.5 text-xs hover:border-accent disabled:opacity-50'
                      : 'rounded border border-border px-3 py-1.5 text-xs opacity-40 cursor-not-allowed'
                  }
                >
                  <input type="hidden" name="editionId" value={e.editionId} />
                  <input type="hidden" name="publish" value={String(!e.isPublished)} />
                </ActionForm>
              </div>
            </div>

            {e.issues.length > 0 ? (
              <div className="mt-3 border-t border-border pt-3">
                <p className="text-xs text-muted">Detected in the data:</p>
                <ul className="mt-1.5 space-y-1.5">
                  {e.issues.map((i) => (
                    <li key={i.key} className="flex flex-wrap items-center gap-2 text-xs">
                      <SeverityTag severity={i.severity} />
                      <span className="text-muted">
                        <strong className="text-foreground">{i.count}</strong> {i.label}
                      </span>
                      {/* One click turns a detected issue into a tracked flag. */}
                      <ActionForm action={createFlagAction} submitLabel="Flag this" className="inline">
                        <input type="hidden" name="entityType" value="competition_edition" />
                        <input type="hidden" name="entityId" value={e.editionId} />
                        <input type="hidden" name="severity" value={i.severity} />
                        <input
                          type="hidden"
                          name="reason"
                          value={`${i.count} ${i.label}`}
                        />
                      </ActionForm>
                    </li>
                  ))}
                </ul>
              </div>
            ) : null}
          </div>
        ))}
      </div>
    </div>
  );
}
