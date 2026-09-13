import Link from 'next/link';
import { CircleAlert, History, Pencil, Trash2 } from 'lucide-react';
import type { ActionState } from '@/lib/admin-actions';
import type { Career, CareerSpell, TeamOption } from '@/lib/adminApi';
import { Badge, EmptyState, Panel, type Tone } from './kit';
import { ConfirmForm } from './confirm-form';
import { SpellFields } from './spell-fields';
import { iconBtn, td, th } from './styles';

type Action = (prev: ActionState, formData: FormData) => Promise<ActionState>;

export const fmtDay = (iso: string | null) =>
  iso ? new Date(`${iso}T12:00:00Z`).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';

const TYPE: Record<string, { label: string; tone: Tone }> = {
  PERMANENT: { label: 'Permanent', tone: 'gray' },
  LOAN: { label: 'Loan', tone: 'blue' },
  FREE: { label: 'Free', tone: 'green' },
  YOUTH: { label: 'Youth', tone: 'amber' },
};

/** "3 yrs 2 mos", or "ongoing" arithmetic against today. */
function duration(start: string, end: string | null, today: string) {
  const a = new Date(`${start}T00:00:00Z`);
  const b = new Date(`${end ?? today}T00:00:00Z`);
  const months = (b.getUTCFullYear() - a.getUTCFullYear()) * 12 + (b.getUTCMonth() - a.getUTCMonth());
  if (months < 1) return '< 1 mo';
  const y = Math.floor(months / 12);
  const m = months % 12;
  return [y ? `${y} yr${y === 1 ? '' : 's'}` : '', m ? `${m} mo${m === 1 ? '' : 's'}` : ''].filter(Boolean).join(' ');
}

/** The one-line answer to "where does this player play?". */
export function CareerStatusLine({ career }: { career: Career }) {
  const s = career.status;
  const club = (spell: CareerSpell) => (
    <Link href={`/admin/teams/${spell.team.id}`} className="font-semibold text-ink hover:text-brand">{spell.team.name}</Link>
  );
  switch (s.kind) {
    case 'AT_CLUB':
      return (
        <span className="text-sm text-muted">
          <Badge tone="green" dot>At a club</Badge>{' '}
          {club(s.club)} since {fmtDay(s.club.start)}
          {s.loan ? <> · on loan at {club(s.loan)}{s.loan.end ? ` until ${fmtDay(s.loan.end)}` : ''}</> : null}
        </span>
      );
    case 'ON_LOAN_ONLY':
      return <span className="text-sm text-muted"><Badge tone="blue" dot>On loan</Badge> at {club(s.loan)} — no parent club recorded</span>;
    case 'FREE_AGENT':
      return (
        <span className="text-sm text-muted">
          <Badge tone="amber" dot>Free agent</Badge> Last at {club(s.lastClub)}
          {s.lastClub.end ? ` until ${fmtDay(s.lastClub.end)}` : ''}
        </span>
      );
    default:
      return <span className="text-sm text-muted"><Badge>No club history</Badge> None recorded — a gap in the sources, not necessarily a free agent.</span>;
  }
}

function SpellRows({
  spells,
  today,
  teams,
  playerId,
  actions,
}: {
  spells: CareerSpell[];
  today: string;
  teams: TeamOption[];
  playerId: number;
  actions: { update: Action; end: Action; remove: Action };
}) {
  const byId = new Map(spells.map((s) => [s.id, s]));
  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[720px] text-sm">
        <thead className="border-b border-line bg-wash/60">
          <tr>
            <th className={th}>Team</th>
            <th className={th}>From</th>
            <th className={th}>Until</th>
            <th className={th}>Type</th>
            <th className={`${th} text-right`}>No.</th>
            <th className={`${th} text-right`}>Fee</th>
            <th className={th}><span className="sr-only">Actions</span></th>
          </tr>
        </thead>
        <tbody className="divide-y divide-line">
          {spells.map((s) => {
            const t = s.type ? TYPE[s.type] : null;
            const clashes = s.conflictsWith.map((id) => byId.get(id)).filter(Boolean) as CareerSpell[];
            return (
              <tr key={s.id} className={clashes.length || s.staleSuggestedEnd ? 'bg-gold/10' : 'hover:bg-wash/60'}>
                <td className={td}>
                  <Link href={`/admin/teams/${s.team.id}`} className="font-semibold hover:text-brand">{s.team.name}</Link>
                  {s.staleSuggestedEnd ? (
                    <p className="mt-1 flex flex-wrap items-center gap-2 text-xs text-[#8a5a00]">
                      <CircleAlert className="h-3.5 w-3.5" />
                      Still open, but a later spell starts {fmtDay(s.staleSuggestedEnd)}.
                      <ConfirmForm
                        action={actions.end}
                        title={`End the spell at ${s.team.name}?`}
                        description={<>It will end on <strong className="text-ink">{fmtDay(s.staleSuggestedEnd)}</strong>, the day the next club spell begins — the same way the vault records every other move.</>}
                        confirmLabel="End spell"
                        trigger="End it then"
                        triggerVariant="secondary"
                        triggerSize="sm"
                      >
                        <input type="hidden" name="spellId" value={s.id} />
                        <input type="hidden" name="endDate" value={s.staleSuggestedEnd} />
                      </ConfirmForm>
                    </p>
                  ) : clashes.length ? (
                    <p className="mt-1 flex items-center gap-1.5 text-xs text-[#8a5a00]">
                      <CircleAlert className="h-3.5 w-3.5" />
                      Overlaps {clashes.map((c) => c.team.name).join(', ')}
                    </p>
                  ) : null}
                </td>
                <td className={`${td} whitespace-nowrap`}>{fmtDay(s.start)}</td>
                <td className={`${td} whitespace-nowrap`}>
                  {s.end ? fmtDay(s.end) : <Badge tone="green" dot>Current</Badge>}
                  <span className="block text-xs text-muted">{duration(s.start, s.end, today)}</span>
                </td>
                <td className={td}>{t ? <Badge tone={t.tone}>{t.label}</Badge> : <span className="text-muted">—</span>}</td>
                <td className={`${td} text-right nums`}>{s.shirtNumber ?? '—'}</td>
                <td className={`${td} text-right nums`}>{s.fee ? Number(s.fee).toLocaleString() : '—'}</td>
                <td className={td}>
                  <div className="flex items-center justify-end gap-1">
                    <ConfirmForm
                      action={actions.update}
                      title={`Edit the spell at ${s.team.name}`}
                      description="Corrections to history. For a move happening now, use Record move so the right spells end."
                      confirmLabel="Save spell"
                      trigger={<Pencil />}
                      triggerAriaLabel={`Edit spell at ${s.team.name}`}
                      triggerClassName={iconBtn()}
                      fields={<SpellFields teams={teams} initial={s} />}
                    >
                      <input type="hidden" name="spellId" value={s.id} />
                      <input type="hidden" name="playerId" value={playerId} />
                    </ConfirmForm>
                    <ConfirmForm
                      action={actions.remove}
                      tone="danger"
                      title={`Delete the spell at ${s.team.name}?`}
                      description={`${fmtDay(s.start)} – ${s.end ? fmtDay(s.end) : 'present'}. This removes it from the player’s history and cannot be undone.`}
                      confirmLabel="Delete spell"
                      trigger={<Trash2 />}
                      triggerAriaLabel={`Delete spell at ${s.team.name}`}
                      triggerClassName={iconBtn('danger')}
                    >
                      <input type="hidden" name="spellId" value={s.id} />
                    </ConfirmForm>
                  </div>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

export function CareerHistory({
  career,
  teams,
  actions,
}: {
  career: Career;
  teams: TeamOption[];
  actions: { update: Action; end: Action; remove: Action; add: Action };
}) {
  const problems = career.clubSpells.filter((s) => s.conflictsWith.length || s.staleSuggestedEnd).length;
  return (
    <div className="space-y-6">
      <Panel
        id="career"
        title="Club history"
        description={`${career.clubSpells.length} spell${career.clubSpells.length === 1 ? '' : 's'}, newest first`}
        actions={problems ? <Badge tone="amber">{problems} need{problems === 1 ? 's' : ''} attention</Badge> : null}
      >
        {career.clubSpells.length ? (
          <SpellRows spells={career.clubSpells} today={career.today} teams={teams} playerId={career.player.id} actions={actions} />
        ) : (
          <EmptyState icon={<History />} title="No club spells recorded" />
        )}
      </Panel>

      {career.nationalSpells.length ? (
        <Panel title="International" description="Call-ups are recorded as spells; transfers never end them.">
          <SpellRows spells={career.nationalSpells} today={career.today} teams={teams} playerId={career.player.id} actions={actions} />
        </Panel>
      ) : null}

      <Panel title="Add a past spell" description="For filling in history. A move happening now belongs in Record move.">
        <ConfirmForm
          action={actions.add}
          title="Add this spell to the history?"
          confirmLabel="Add spell"
          review="all"
          resetOnSuccess
          trigger={<><History /> Add spell</>}
          triggerVariant="secondary"
          className="space-y-4 p-5"
        >
          <input type="hidden" name="playerId" value={career.player.id} />
          <SpellFields teams={teams} />
        </ConfirmForm>
      </Panel>
    </div>
  );
}

