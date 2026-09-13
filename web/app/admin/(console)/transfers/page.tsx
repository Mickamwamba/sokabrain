import Link from 'next/link';
import {
  ArrowRight, ArrowRightLeft, CalendarClock, CircleAlert, LogOut as Departure, Pencil, Undo2, UserRoundX, Handshake, X,
} from 'lucide-react';
import {
  adminFetch, type Career, type CareerSpell, type MoveRow, type TeamOption, type TransferFeed,
} from '@/lib/adminApi';
import { load, one } from '@/lib/admin-page';
import {
  Badge, EmptyState, ErrorState, Field, FilterTabs, PageHeader, Pagination, Panel, StatCard, type Tone,
} from '@/components/admin/kit';
import { ConfirmForm } from '@/components/admin/confirm-form';
import { PlayerPicker } from '@/components/admin/player-picker';
import { TransferForm } from '@/components/admin/transfer-form';
import { CareerStatusLine, fmtDay } from '@/components/admin/career';
import { btn, iconBtn, input, td, th } from '@/components/admin/styles';
import {
  editMoveAction, recordTransferAction, searchPlayersAction, undoMoveAction,
} from '../../manage-actions';

export const dynamic = 'force-dynamic';

const KIND_TABS = [
  { value: 'MOVES', label: 'Transfers & loans' },
  { value: 'TRANSFER', label: 'Transfers' },
  { value: 'LOAN', label: 'Loans' },
  { value: 'RELEASE', label: 'Departures' },
  { value: 'FIRST_CLUB', label: 'First clubs' },
] as const;

function typeBadge(m: MoveRow): { label: string; tone: Tone } {
  if (m.kind === 'LOAN') return { label: 'Loan', tone: 'blue' };
  if (m.kind === 'RELEASE') return { label: 'Left', tone: 'amber' };
  if (m.kind === 'FIRST_CLUB') return { label: 'First club', tone: 'gray' };
  return m.to?.type === 'FREE' ? { label: 'Free', tone: 'green' }
    : m.to?.type === 'YOUTH' ? { label: 'Youth', tone: 'amber' }
    : { label: 'Transfer', tone: 'gray' };
}

/** What undoing a move will do, in words, for its confirmation. */
function undoDescription(m: MoveRow) {
  const to = m.to?.team.name;
  const from = m.from?.team.name;
  switch (m.kind) {
    case 'RELEASE':
      return <>The spell at <strong className="text-ink">{from}</strong> becomes ongoing again, as if {m.player.name} never left.</>;
    case 'LOAN':
      return <>Removes the loan at <strong className="text-ink">{to}</strong> from {fmtDay(m.date)}. The spell at {from ?? 'the parent club'} is not affected.</>;
    case 'FIRST_CLUB':
      return <>Removes the spell at <strong className="text-ink">{to}</strong> from {fmtDay(m.date)} — the earliest club on record for this player.</>;
    default:
      return m.reopens ? (
        <>Removes the spell at <strong className="text-ink">{to}</strong> and reopens the spell at <strong className="text-ink">{m.reopens.team.name}</strong>, so {m.player.name} is back where they were.</>
      ) : (
        <>Removes the spell at <strong className="text-ink">{to}</strong> from {fmtDay(m.date)}. The spell at {from} stays as recorded — it didn’t end on the day of this move, or later history depends on it.</>
      );
  }
}

export default async function TransferCentrePage(props: PageProps<'/admin/transfers'>) {
  const sp = await props.searchParams;
  const kind = KIND_TABS.some((k) => k.value === one(sp.kind)) ? one(sp.kind)! : 'MOVES';
  const q = one(sp.q) ?? '';
  const teamId = one(sp.teamId) ?? '';
  const from = one(sp.from) ?? '';
  const to = one(sp.to) ?? '';
  const page = Math.max(1, Number(one(sp.page)) || 1);
  const playerId = Number(one(sp.playerId)) || null;

  const feedParams = new URLSearchParams({ kind, page: String(page), pageSize: '30' });
  for (const [k, v] of Object.entries({ q, teamId, from, to })) if (v) feedParams.set(k, v);

  const res = await load(() =>
    Promise.all([
      adminFetch<TransferFeed>(`/api/admin/transfers?${feedParams}`),
      adminFetch<{ teams: TeamOption[] }>('/api/admin/team-options?type=CLUB').then((r) => r.teams),
      playerId ? adminFetch<Career>(`/api/admin/players/${playerId}/career`) : Promise.resolve(null),
    ]),
  );
  if (!res.ok) return <ErrorState message={res.error} />;
  const [feed, clubs, career] = res.data;

  /** This page's URL with some parameters changed — filters and selection survive each other. */
  const href = (patch: Record<string, string | null>) => {
    const u = new URLSearchParams();
    const base: Record<string, string | null> = {
      kind: kind === 'MOVES' ? null : kind, q: q || null, teamId: teamId || null, from: from || null, to: to || null,
      playerId: playerId ? String(playerId) : null, page: null, ...patch,
    };
    for (const [k, v] of Object.entries(base)) if (v) u.set(k, v);
    const s = u.toString();
    return `/admin/transfers${s ? `?${s}` : ''}`;
  };
  const countFor = (v: string) =>
    v === 'MOVES' ? feed.counts.TRANSFER + feed.counts.LOAN : feed.counts[v as keyof typeof feed.counts];
  const filtered = Boolean(q || teamId || from || to);

  let running: CareerSpell[] = [];
  if (career) {
    const s = career.status;
    running = s.kind === 'AT_CLUB' ? [s.club, ...(s.loan ? [s.loan] : [])] : s.kind === 'ON_LOAN_ONLY' ? [s.loan] : [];
  }

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<ArrowRightLeft />}
        title="Transfer centre"
        description="Every move in the vault — transfers, loans and departures — and the place to record new ones."
      />

      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard label="Moves in the last 30 days" value={feed.summary.movesLast30Days} icon={<CalendarClock />} tone="blue" />
        <StatCard label="Players on loan" value={feed.summary.activeLoans} icon={<Handshake />} tone="green" />
        <StatCard label="Free agents" value={feed.summary.freeAgents} icon={<UserRoundX />} tone="amber"
          hint="Club spells on record, none current" />
        <StatCard label="Departures" value={feed.counts.RELEASE} icon={<Departure />}
          hint={filtered ? 'In the current filter' : 'Destination not recorded'} />
      </div>

      <div className="grid gap-6 xl:grid-cols-3">
        <Panel
          className="xl:col-span-2"
          title={
            <FilterTabs items={KIND_TABS.map((k) => ({
              href: href({ kind: k.value === 'MOVES' ? null : k.value }),
              label: k.label, active: kind === k.value, count: countFor(k.value),
            }))} />
          }
        >
          <form method="get" action="/admin/transfers" className="flex flex-wrap items-end gap-3 border-b border-line bg-wash/40 px-5 py-4">
            {kind !== 'MOVES' ? <input type="hidden" name="kind" value={kind} /> : null}
            {playerId ? <input type="hidden" name="playerId" value={playerId} /> : null}
            <Field label="Player" className="min-w-44 flex-1">
              <input name="q" defaultValue={q} placeholder="Name contains…" className={input} />
            </Field>
            <Field label="Club" className="min-w-44 flex-1">
              <select name="teamId" defaultValue={teamId} className={input}>
                <option value="">Any club</option>
                {clubs.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
            </Field>
            <Field label="From">
              <input name="from" type="date" defaultValue={from} className={input} />
            </Field>
            <Field label="To">
              <input name="to" type="date" defaultValue={to} className={input} />
            </Field>
            <button type="submit" className={btn('secondary')}>Apply</button>
            {filtered ? (
              <Link href={href({ q: null, teamId: null, from: null, to: null })} className={btn('ghost')}><X /> Clear</Link>
            ) : null}
          </form>

          {feed.moves.length === 0 ? (
            <EmptyState icon={<ArrowRightLeft />} title="No moves match">
              {filtered ? 'Try widening the dates or clearing the filters.' : 'Record the first one from the panel alongside.'}
            </EmptyState>
          ) : (
            <>
              <div className="overflow-x-auto">
                <table className="w-full min-w-[760px] text-sm">
                  <thead className="border-b border-line bg-wash/60">
                    <tr>
                      <th className={th}>Date</th>
                      <th className={th}>Player</th>
                      <th className={th}>Move</th>
                      <th className={th}>Type</th>
                      <th className={`${th} text-right`}>Fee</th>
                      <th className={th}><span className="sr-only">Actions</span></th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-line">
                    {feed.moves.map((m) => {
                      const badge = typeBadge(m);
                      const spellId = m.kind === 'RELEASE' ? m.from!.spellId : m.to!.spellId;
                      const linked = m.kind === 'TRANSFER' && m.from?.end === m.date;
                      return (
                        <tr key={m.key} className="hover:bg-wash/60">
                          <td className={`${td} whitespace-nowrap text-muted`}>{fmtDay(m.date)}</td>
                          <td className={td}>
                            <Link href={href({ playerId: String(m.player.id) })} className="font-semibold hover:text-brand">
                              {m.player.name}
                            </Link>
                          </td>
                          <td className={td}>
                            <span className="flex flex-wrap items-center gap-1.5">
                              {m.from ? (
                                <Link href={`/admin/teams/${m.from.team.id}`} className={m.kind === 'LOAN' ? 'text-muted hover:text-brand' : 'hover:text-brand'}>
                                  {m.from.team.name}
                                </Link>
                              ) : (
                                <span className="text-muted italic">Not recorded</span>
                              )}
                              <ArrowRight className="h-3.5 w-3.5 shrink-0 text-muted" />
                              {m.to ? (
                                <Link href={`/admin/teams/${m.to.team.id}`} className="font-medium hover:text-brand">{m.to.team.name}</Link>
                              ) : (
                                <span className="text-muted italic">Destination unknown</span>
                              )}
                              {m.kind === 'LOAN' && m.to?.end ? <span className="text-xs text-muted">until {fmtDay(m.to.end)}</span> : null}
                            </span>
                          </td>
                          <td className={td}><Badge tone={badge.tone}>{badge.label}</Badge></td>
                          <td className={`${td} text-right nums`}>{m.to?.fee ? Number(m.to.fee).toLocaleString() : '—'}</td>
                          <td className={td}>
                            <div className="flex items-center justify-end gap-1">
                              <ConfirmForm
                                action={editMoveAction}
                                title={`Edit ${m.player.name}’s ${badge.label.toLowerCase()}`}
                                description={
                                  linked
                                    ? <>The spell at {m.from!.team.name} ended the day this move began, so changing the date moves its end too — no gap, no overlap.</>
                                    : m.kind === 'RELEASE'
                                      ? <>The date the spell at {m.from!.team.name} ended.</>
                                      : undefined
                                }
                                confirmLabel="Save move"
                                trigger={<Pencil />}
                                triggerAriaLabel={`Edit move for ${m.player.name}`}
                                triggerClassName={iconBtn()}
                                fields={
                                  <div className="grid gap-4 sm:grid-cols-2">
                                    <Field label="Date" required>
                                      <input name="date" type="date" required defaultValue={m.date} className={input} />
                                    </Field>
                                    {m.kind === 'TRANSFER' || m.kind === 'FIRST_CLUB' ? (
                                      <Field label="Type">
                                        <select name="type" defaultValue={m.to?.type ?? ''} className={input}>
                                          <option value="">Not recorded</option>
                                          <option value="PERMANENT">Permanent</option>
                                          <option value="FREE">Free transfer</option>
                                          <option value="YOUTH">Youth</option>
                                        </select>
                                      </Field>
                                    ) : null}
                                    {m.kind !== 'RELEASE' ? (
                                      <>
                                        <Field label="Shirt number">
                                          <input name="shirtNumber" type="number" min={0} max={99} defaultValue={m.to?.shirtNumber ?? ''} className={input} />
                                        </Field>
                                        <Field label="Fee" hint="Amount only — no currency is recorded.">
                                          <input name="fee" inputMode="decimal" defaultValue={m.to?.fee ?? ''} className={input} />
                                        </Field>
                                      </>
                                    ) : null}
                                  </div>
                                }
                              >
                                <input type="hidden" name="kind" value={m.kind} />
                                <input type="hidden" name="spellId" value={spellId} />
                              </ConfirmForm>
                              <ConfirmForm
                                action={undoMoveAction}
                                tone="danger"
                                title={`Undo this ${badge.label.toLowerCase()}?`}
                                description={undoDescription(m)}
                                confirmLabel="Undo move"
                                trigger={<Undo2 />}
                                triggerAriaLabel={`Undo move for ${m.player.name}`}
                                triggerClassName={iconBtn('danger')}
                              >
                                <input type="hidden" name="kind" value={m.kind} />
                                <input type="hidden" name="spellId" value={spellId} />
                              </ConfirmForm>
                            </div>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
              <Pagination page={page} pageSize={feed.pageSize} total={feed.total} href={(p) => href({ page: p > 1 ? String(p) : null })} />
            </>
          )}
        </Panel>

        <div className="space-y-6">
          <Panel
            title="Record a move"
            description={career ? undefined : 'Pick the player first. You can also start from any player’s page.'}
            actions={career ? <Link href={href({ playerId: null })} className={btn('ghost', 'sm')}>Change player</Link> : null}
            className="xl:sticky xl:top-20"
          >
            {career ? (
              <>
                <div className="space-y-1.5 border-b border-line px-5 py-4">
                  <Link href={`/admin/players/${career.player.id}`} className="text-base font-bold hover:text-brand">
                    {career.player.name}
                  </Link>
                  <div><CareerStatusLine career={career} /></div>
                  {career.clubSpells.some((x) => x.staleSuggestedEnd || x.conflictsWith.length) ? (
                    <p className="flex items-start gap-2 rounded-lg bg-gold/15 px-3 py-2 text-xs text-[#8a5a00]">
                      <CircleAlert className="mt-0.5 h-3.5 w-3.5 shrink-0" />
                      <span>
                        This player’s club history has spells that contradict each other, so the current club
                        above may be wrong.{' '}
                        <Link href={`/admin/players/${career.player.id}`} className="font-semibold underline">Fix it on their page</Link>{' '}
                        before recording a move.
                      </span>
                    </p>
                  ) : null}
                </div>
                <TransferForm
                  playerId={career.player.id}
                  playerName={career.player.name}
                  clubs={clubs}
                  running={running.filter((r) => r.team.type === 'CLUB')}
                  today={career.today}
                  action={recordTransferAction}
                />
              </>
            ) : (
              <div className="p-5">
                <PlayerPicker search={searchPlayersAction} />
              </div>
            )}
          </Panel>
        </div>
      </div>
    </div>
  );
}
