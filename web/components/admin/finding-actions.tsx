import { BadgeCheck, Flag as FlagIcon, RotateCcw, Wrench } from 'lucide-react';
import type { AuditFinding } from '@/lib/adminApi';
import { ConfirmForm } from './confirm-form';
import { Field } from './kit';
import { iconBtn, input } from './styles';
import { escalateFindingAction, reviewFindingAction } from '@/app/admin/actions';

const LABEL: Record<string, string> = { FIXED: 'fixed', ACCEPTED: 'accepted' };

/**
 * Review a finding: mark it fixed, accept it, take either back, or escalate it
 * to a BLOCKER flag. Shared by the audit list and every page a finding links
 * to, so the decision is the same wherever it is made.
 */
export function FindingActions({ finding: f }: { finding: AuditFinding }) {
  return (
    <div className="flex items-center justify-end gap-1">
      {f.status === 'OPEN' ? (
        <>
          <ConfirmForm
            action={reviewFindingAction}
            title="Mark this finding fixed?"
            description={<>“{f.detail}”. The next audit run confirms the fix, or reopens the finding if the problem is still there.</>}
            confirmLabel="Mark fixed"
            trigger={<Wrench />}
            triggerAriaLabel="Mark fixed"
            triggerClassName={iconBtn()}
            fields={<Field label="What was done?" hint="Optional."><input name="note" maxLength={1000} className={input} /></Field>}
          >
            <input type="hidden" name="findingId" value={f.id} />
            <input type="hidden" name="decision" value="FIXED" />
          </ConfirmForm>
          <ConfirmForm
            action={reviewFindingAction}
            title="Accept this finding as it is?"
            description="For a problem the sources can’t fix. It stays closed while unchanged and reopens if the data changes."
            confirmLabel="Accept"
            trigger={<BadgeCheck />}
            triggerAriaLabel="Accept"
            triggerClassName={iconBtn()}
            fields={<Field label="Why is it acceptable?" required><input name="note" required maxLength={1000} className={input} /></Field>}
          >
            <input type="hidden" name="findingId" value={f.id} />
            <input type="hidden" name="decision" value="ACCEPTED" />
          </ConfirmForm>
        </>
      ) : f.status === 'FIXED' || f.status === 'ACCEPTED' ? (
        <ConfirmForm
          action={reviewFindingAction}
          title="Reopen this finding?"
          description={`Takes back the “${LABEL[f.status]}” decision.`}
          confirmLabel="Reopen"
          trigger={<RotateCcw />}
          triggerAriaLabel="Reopen"
          triggerClassName={iconBtn()}
        >
          <input type="hidden" name="findingId" value={f.id} />
          <input type="hidden" name="decision" value="OPEN" />
        </ConfirmForm>
      ) : null}
      {f.status !== 'RESOLVED' && f.entity.type !== 'player' ? (
        <ConfirmForm
          action={escalateFindingAction}
          tone="danger"
          title="Escalate to a BLOCKER flag?"
          description={<>{f.entity.label}’s season can’t be published while the flag is open. Resolve the flag on the Flags page once it’s dealt with.</>}
          confirmLabel="Raise blocker"
          trigger={<FlagIcon />}
          triggerAriaLabel="Escalate to flag"
          triggerClassName={iconBtn('danger')}
        >
          <input type="hidden" name="findingId" value={f.id} />
        </ConfirmForm>
      ) : null}
    </div>
  );
}
