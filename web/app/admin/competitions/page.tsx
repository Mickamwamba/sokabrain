import Link from 'next/link';
import { redirect } from 'next/navigation';
import {
  adminFetch,
  AdminApiError,
  type AdminCompetition,
  type AdminReference,
} from '@/lib/adminApi';
import { Card } from '@/components/ui';
import { ActionForm } from '@/components/admin-ui';
import { createCompetitionAction } from '../actions';

export const dynamic = 'force-dynamic';

const field =
  'w-full rounded-lg border border-line bg-paper px-3 py-2 text-sm focus:border-ink focus:outline-none';

export default async function AdminCompetitionsPage(
  props: PageProps<'/admin/competitions'>,
) {
  const sp = await props.searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  const q = one(sp.q) ?? '';
  const adding = one(sp.add) === '1';

  let competitions: AdminCompetition[];
  let reference: AdminReference;
  try {
    [competitions, reference] = await Promise.all([
      adminFetch<{ competitions: AdminCompetition[] }>(
        `/api/admin/competitions${q ? `?q=${encodeURIComponent(q)}` : ''}`,
      ).then((r) => r.competitions),
      adminFetch<AdminReference>('/api/admin/reference'),
    ]);
  } catch (err) {
    if (err instanceof AdminApiError && err.status === 401) redirect('/admin/login');
    if (err instanceof AdminApiError) return <p className="text-sm text-loss">{err.message}</p>;
    throw err;
  }

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="display text-2xl font-extrabold tracking-tight">Competitions</h1>
          <p className="mt-1 text-sm text-muted">
            {competitions.length} competition{competitions.length === 1 ? '' : 's'}
            {q ? ` matching “${q}”` : ''}
          </p>
        </div>
        <Link
          href={adding ? '/admin/competitions' : '/admin/competitions?add=1'}
          className="rounded-lg bg-ink px-4 py-2 text-sm font-semibold text-white hover:bg-ink-soft"
        >
          {adding ? 'Cancel' : 'Add competition'}
        </Link>
      </div>

      {adding ? (
        <Card className="p-5">
          <h2 className="display mb-3 text-sm font-bold uppercase tracking-wide">
            New competition
          </h2>
          <ActionForm action={createCompetitionAction} submitLabel="Create competition"
            submitClassName="rounded-lg bg-ink px-4 py-2 text-sm font-semibold text-white hover:bg-ink-soft disabled:opacity-50">
            <div className="mb-3 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
              <label className="block">
                <span className="text-xs font-semibold text-muted">Name</span>
                <input name="name" required placeholder="e.g. Championship" className={`mt-1 ${field}`} />
              </label>
              <label className="block">
                <span className="text-xs font-semibold text-muted">Type</span>
                <select name="type" defaultValue="LEAGUE" className={`mt-1 ${field}`}>
                  {reference.competitionTypes.map((t) => (
                    <option key={t} value={t}>{t.replaceAll('_', ' ')}</option>
                  ))}
                </select>
              </label>
              <label className="block">
                <span className="text-xs font-semibold text-muted">Country</span>
                <select name="countryId" defaultValue="" className={`mt-1 ${field}`}>
                  {/* Continental and international competitions have none. */}
                  <option value="">None (continental / international)</option>
                  {reference.countries.map((c) => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
              </label>
              <label className="block">
                <span className="text-xs font-semibold text-muted">Tier (leagues only)</span>
                <input name="tier" type="number" min="1" max="10" placeholder="1" className={`mt-1 ${field}`} />
              </label>
            </div>
          </ActionForm>
          <p className="mt-2 text-xs text-muted">
            Seasons are added to a competition afterwards, from its own page.
          </p>
        </Card>
      ) : null}

      {/* Plain GET form: search stays a shareable URL and needs no JavaScript. */}
      <form method="get" action="/admin/competitions" className="flex gap-2">
        <input
          name="q"
          defaultValue={q}
          placeholder="Search competitions or countries…"
          className={`${field} max-w-sm`}
        />
        <button type="submit" className="rounded-lg border border-line bg-paper px-4 py-2 text-sm font-semibold hover:border-ink">
          Search
        </button>
        {q ? (
          <Link href="/admin/competitions" className="self-center text-sm text-muted hover:text-ink">
            Clear
          </Link>
        ) : null}
      </form>

      {competitions.length === 0 ? (
        <Card className="px-6 py-12 text-center text-sm text-muted">
          No competitions match “{q}”.
        </Card>
      ) : (
        <Card className="overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[620px] border-collapse text-sm">
              <thead>
                <tr className="border-b border-line bg-wash text-left text-[11px] font-semibold uppercase tracking-wide text-muted">
                  <th className="px-5 py-2.5">Competition</th>
                  <th className="px-2 py-2.5">Country</th>
                  <th className="px-2 py-2.5">Type</th>
                  <th className="px-2 py-2.5 text-right">Seasons</th>
                  <th className="px-2 py-2.5 text-right">Matches</th>
                  <th className="py-2.5 pl-2 pr-5 text-right">Public</th>
                </tr>
              </thead>
              <tbody>
                {competitions.map((c) => (
                  <tr key={c.id} className="border-b border-line last:border-0 hover:bg-wash">
                    <td className="px-5 py-2.5">
                      <Link href={`/admin/competitions/${c.id}`} className="font-semibold hover:text-brand">
                        {c.name}
                      </Link>
                      {c.tier ? (
                        <span className="ml-2 rounded bg-wash px-1.5 py-0.5 text-[10px] font-semibold text-muted">
                          Tier {c.tier}
                        </span>
                      ) : null}
                    </td>
                    <td className="px-2 py-2.5 text-muted">{c.country ?? '—'}</td>
                    <td className="px-2 py-2.5 text-xs text-muted">{c.type.replaceAll('_', ' ')}</td>
                    <td className="px-2 py-2.5 text-right nums text-muted">{c.seasonCount}</td>
                    <td className="px-2 py-2.5 text-right nums text-muted">{c.matchCount}</td>
                    <td className="py-2.5 pl-2 pr-5 text-right">
                      {c.publishedCount > 0 ? (
                        <span className="rounded-full bg-brand px-2 py-0.5 text-[10px] font-bold uppercase text-white">
                          {c.publishedCount} live
                        </span>
                      ) : (
                        <span className="text-xs text-muted">—</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}
    </div>
  );
}
