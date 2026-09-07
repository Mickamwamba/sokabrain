'use client';

import { useActionState, useEffect, useRef } from 'react';
import type { ActionState } from '@/app/admin/actions';

type Action = (prev: ActionState, formData: FormData) => Promise<ActionState>;

/**
 * A form whose submission is gated behind a confirmation dialog.
 *
 * Uses the native <dialog> element rather than window.confirm so the prompt can
 * state exactly what is about to change — "Delete the 23' goal by John Bocco?"
 * reads very differently from a generic "Are you sure?", and event edits are
 * writes to records nobody may notice are wrong later.
 *
 * The real submit button lives inside the dialog, so a stray Enter keypress in
 * the form cannot bypass the prompt.
 */
export function ConfirmForm({
  action,
  children,
  title,
  message,
  triggerLabel,
  triggerClassName,
  confirmLabel = 'Confirm',
  danger = false,
  className,
  disabled = false,
}: {
  action: Action;
  children?: React.ReactNode;
  title: string;
  message: React.ReactNode;
  triggerLabel: React.ReactNode;
  triggerClassName?: string;
  confirmLabel?: string;
  danger?: boolean;
  className?: string;
  disabled?: boolean;
}) {
  const [state, formAction, pending] = useActionState(action, {});
  const formRef = useRef<HTMLFormElement>(null);
  const dialogRef = useRef<HTMLDialogElement>(null);

  // Close the dialog once the action settles, so a success or error is read on
  // the page rather than behind a modal.
  useEffect(() => {
    if (!pending) dialogRef.current?.close();
  }, [pending, state]);

  return (
    <form ref={formRef} action={formAction} className={className}>
      {children}

      <button
        type="button"
        disabled={disabled || pending}
        onClick={() => dialogRef.current?.showModal()}
        className={
          triggerClassName ??
          'rounded-lg border border-line bg-paper px-3 py-1.5 text-xs font-semibold hover:border-ink disabled:opacity-50'
        }
      >
        {pending ? 'Working…' : triggerLabel}
      </button>

      <dialog
        ref={dialogRef}
        onClick={(e) => {
          // Click on the backdrop (the dialog element itself) dismisses.
          if (e.target === dialogRef.current) dialogRef.current?.close();
        }}
        className="m-auto w-[min(28rem,92vw)] rounded-xl border border-line bg-paper p-0 text-ink backdrop:bg-ink/40"
      >
        <div className="p-5">
          <h2 className="display text-base font-bold">{title}</h2>
          <div className="mt-2 text-sm text-muted">{message}</div>
          <div className="mt-5 flex justify-end gap-2">
            <button
              type="button"
              onClick={() => dialogRef.current?.close()}
              className="rounded-lg border border-line px-4 py-2 text-sm font-semibold hover:border-ink"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={pending}
              className={`rounded-lg px-4 py-2 text-sm font-semibold text-white disabled:opacity-50 ${
                danger ? 'bg-loss' : 'bg-ink hover:bg-ink-soft'
              }`}
            >
              {pending ? 'Working…' : confirmLabel}
            </button>
          </div>
        </div>
      </dialog>

      {state.error ? <p className="mt-1 text-xs text-loss">{state.error}</p> : null}
      {state.ok ? <p className="mt-1 text-xs text-brand">{state.ok}</p> : null}
    </form>
  );
}
