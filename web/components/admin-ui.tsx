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
        <p className="mt-1 text-xs text-red-600 dark:text-red-400">{state.error}</p>
      ) : null}
      {state.ok ? <p className="mt-1 text-xs text-accent">{state.ok}</p> : null}
    </form>
  );
}

export function SeverityTag({ severity }: { severity: string }) {
  const tone =
    severity === 'BLOCKER'
      ? 'border-red-500/50 text-red-600 dark:text-red-400'
      : severity === 'WARNING'
        ? 'border-amber-500/50 text-amber-600 dark:text-amber-400'
        : 'border-border text-muted';
  return (
    <span className={`rounded border px-1.5 py-0.5 text-[10px] font-medium uppercase ${tone}`}>
      {severity}
    </span>
  );
}
