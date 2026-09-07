'use client';

import { useActionState } from 'react';
import type { ActionState } from '@/app/admin/actions';

type Action = (prev: ActionState, formData: FormData) => Promise<ActionState>;

/**
 * A form bound to a server action, showing its pending state and result.
 * Every admin mutation goes through this so feedback is consistent.
 */
export function ActionForm({
  action,
  children,
  className,
  submitLabel,
  submitClassName,
  confirm,
}: {
  action: Action;
  children?: React.ReactNode;
  className?: string;
  submitLabel: string;
  submitClassName?: string;
  confirm?: string;
}) {
  const [state, formAction, pending] = useActionState(action, {});

  return (
    <form
      action={formAction}
      className={className}
      onSubmit={(e) => {
        if (confirm && !window.confirm(confirm)) e.preventDefault();
      }}
    >
      {children}
      <button
        type="submit"
        disabled={pending}
        className={
          submitClassName ??
          'rounded border border-border px-3 py-1.5 text-xs hover:border-accent disabled:opacity-50'
        }
      >
        {pending ? 'Working…' : submitLabel}
      </button>
      {state.error ? (
        <p className="mt-1 text-xs text-red-600">{state.error}</p>
      ) : null}
      {state.ok ? <p className="mt-1 text-xs text-accent">{state.ok}</p> : null}
    </form>
  );
}

export function SeverityTag({ severity }: { severity: string }) {
  const tone =
    severity === 'BLOCKER'
      ? 'border-red-500/50 text-red-600'
      : severity === 'WARNING'
        ? 'border-amber-500/50 text-amber-600'
        : 'border-border text-muted';
  return (
    <span className={`rounded border px-1.5 py-0.5 text-[10px] font-medium uppercase ${tone}`}>
      {severity}
    </span>
  );
}

/**
 * Marks a record as incomplete — currently, a goal whose scorer was never
 * recorded. Deliberately a filled dot rather than a colour on the text: it
 * survives being scanned quickly down a long list, and carries a title so it
 * is not colour-only.
 */
export function IncompleteDot({ count, what = 'goal' }: { count: number; what?: string }) {
  if (count <= 0) return null;
  const label = `${count} ${what}${count === 1 ? '' : 's'} with no scorer recorded`;
  return (
    <span className="inline-flex items-center gap-1" title={label}>
      <span aria-hidden className="inline-block h-2 w-2 rounded-full bg-loss" />
      <span className="sr-only">{label}</span>
      <span aria-hidden className="text-[10px] font-semibold text-loss">{count}</span>
    </span>
  );
}
