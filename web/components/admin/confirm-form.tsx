'use client';

import { startTransition, useActionState, useEffect, useRef, useState, type ReactNode } from 'react';
import { useRouter } from 'next/navigation';
import { CircleAlert, TriangleAlert, ShieldCheck } from 'lucide-react';
import type { ActionState } from '@/lib/admin-actions';
import { btn, type ButtonSize, type ButtonVariant } from './styles';
import { toast } from './toaster';

type Action = (prev: ActionState, formData: FormData) => Promise<ActionState>;

type ReviewRow = { label: string; value: string; before?: string };

/**
 * The only way an admin change is submitted: a form gated behind a
 * confirmation dialog.
 *
 * The dialog does more than ask "are you sure?". Fields marked with
 * `data-label` are read back into it — every value for a new record, and
 * old → new for an edit — so the editor confirms what will actually be
 * written. An edit that changes nothing says so and cannot be confirmed.
 *
 * Every path to submission goes through the dialog: the trigger opens it, and
 * an Enter keypress in a field (which browsers turn into a submit) is caught
 * and opens it too, rather than writing straight through.
 *
 * On success the dialog closes and a toast reports it; on failure the dialog
 * stays open with the error and every field keeps what the editor typed.
 */
export function ConfirmForm({
  action,
  children,
  className,
  title,
  description,
  confirmLabel = 'Confirm',
  tone = 'primary',
  trigger,
  triggerVariant = 'primary',
  triggerSize = 'md',
  triggerClassName,
  triggerAriaLabel,
  review = 'none',
  fields,
  disabled = false,
  resetOnSuccess = false,
}: {
  action: Action;
  children?: ReactNode;
  className?: string;
  title: string;
  description?: ReactNode;
  confirmLabel?: string;
  tone?: 'primary' | 'danger';
  trigger: ReactNode;
  triggerVariant?: ButtonVariant;
  triggerSize?: ButtonSize;
  triggerClassName?: string;
  triggerAriaLabel?: string;
  /** 'all' lists every labelled field; 'changes' lists only what was edited. */
  review?: 'none' | 'all' | 'changes';
  /**
   * Inputs shown inside the dialog rather than on the page — for a short
   * prompt such as a new password, where the dialog is the whole form.
   * They are validated when the editor confirms, not when the dialog opens.
   */
  fields?: ReactNode;
  disabled?: boolean;
  resetOnSuccess?: boolean;
}) {
  const [state, formAction, pending] = useActionState(action, {});
  const formRef = useRef<HTMLFormElement>(null);
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [rows, setRows] = useState<ReviewRow[]>([]);
  const [open, setOpen] = useState(false);
  // The action result as it stood when the dialog opened. An error is shown
  // only once a newer result arrives, so reopening never replays an old one.
  const [stateAtOpen, setStateAtOpen] = useState<ActionState | null>(null);
  const lastSettled = useRef<number | undefined>(undefined);
  const router = useRouter();

  const openDialog = () => {
    const form = formRef.current;
    if (!form) return;
    // Fields on the page are checked before asking to confirm anything —
    // confirming a form that cannot be submitted is noise. Fields inside the
    // dialog are not filled in yet, so the browser checks those on confirm.
    const dialog = dialogRef.current;
    const invalid = Array.from(form.elements).find(
      (el) =>
        !dialog?.contains(el) &&
        'checkValidity' in el &&
        !(el as HTMLInputElement).checkValidity(),
    ) as HTMLInputElement | undefined;
    if (invalid) {
      invalid.reportValidity();
      return;
    }
    setRows(review === 'none' ? [] : readReview(form, review, dialogRef.current));
    setStateAtOpen(state);
    setOpen(true);
    dialogRef.current?.showModal();
  };

  // However the dialog closes — Cancel, Escape, the backdrop, or a successful
  // save — its native `close` event is what clears `open`.
  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    const onClose = () => setOpen(false);
    dialog.addEventListener('close', onClose);
    return () => dialog.removeEventListener('close', onClose);
  }, []);

  // Closing goes through the element; its `close` event resets `open`.
  const close = () => dialogRef.current?.close();

  useEffect(() => {
    if (pending || state.at === undefined || state.at === lastSettled.current) return;
    lastSettled.current = state.at;
    if (state.error) return; // stays open, showing the error
    close();
    if (state.ok) toast(state.ok);
    // Dialog-only inputs (a password) must not linger for the next opening.
    if (fields) dialogRef.current?.querySelectorAll('input').forEach((i) => { i.value = i.defaultValue; });
    if (resetOnSuccess) formRef.current?.reset();
    if (state.redirectTo) router.push(state.redirectTo);
  }, [pending, state, resetOnSuccess, router, fields]);

  const shownError = open && state !== stateAtOpen && state.error ? state.error : null;
  const nothingChanged = review === 'changes' && rows.length === 0;
  const Icon = tone === 'danger' ? TriangleAlert : ShieldCheck;

  return (
    <form
      ref={formRef}
      className={className}
      onSubmit={(e) => {
        e.preventDefault();
        // Implicit submission (Enter in a text field) must not skip the prompt.
        // The element is asked directly: it is the only thing that knows for
        // certain whether the dialog is showing.
        if (!dialogRef.current?.open) {
          openDialog();
          return;
        }
        // Dispatched by hand rather than through the form's `action` prop:
        // React resets a form after its action settles, and a rejected save
        // would otherwise wipe everything the editor typed.
        const data = new FormData(e.currentTarget, (e.nativeEvent as SubmitEvent).submitter);
        startTransition(() => formAction(data));
      }}
    >
      {children}

      <button
        type="button"
        disabled={disabled || pending}
        aria-label={triggerAriaLabel}
        onClick={openDialog}
        className={triggerClassName ?? btn(triggerVariant, triggerSize)}
      >
        {trigger}
      </button>

      <dialog
        ref={dialogRef}
        onClick={(e) => {
          if (e.target === dialogRef.current && !pending) close();
        }}
        className="m-auto w-[min(30rem,calc(100vw-2rem))] rounded-2xl border border-line bg-paper p-0 text-left text-ink shadow-2xl backdrop:bg-ink/50 backdrop:backdrop-blur-[2px]"
      >
        <div className="p-6">
          <div className="flex items-start gap-4">
            <span
              className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-full ${
                tone === 'danger' ? 'bg-loss/10 text-loss' : 'bg-ink/5 text-ink'
              }`}
            >
              <Icon className="h-5 w-5" />
            </span>
            <div className="min-w-0 flex-1">
              <h2 className="text-base font-bold">{title}</h2>
              {description ? (
                <div className="mt-1.5 text-sm leading-relaxed text-muted">{description}</div>
              ) : null}
            </div>
          </div>

          {fields ? <div className="mt-5 space-y-4">{fields}</div> : null}

          {review !== 'none' ? (
            nothingChanged ? (
              <p className="mt-4 rounded-lg bg-wash px-3 py-2.5 text-sm text-muted">
                Nothing has changed, so there is nothing to save.
              </p>
            ) : (
              <dl className="mt-4 max-h-64 divide-y divide-line overflow-y-auto rounded-lg border border-line">
                {rows.map((r) => (
                  <div key={r.label} className="flex items-baseline gap-3 px-3 py-2 text-sm">
                    <dt className="w-32 shrink-0 text-xs text-muted">{r.label}</dt>
                    <dd className="min-w-0 flex-1 break-words font-medium">
                      {r.before !== undefined ? (
                        <>
                          <span className="text-muted line-through decoration-muted/50">{r.before}</span>
                          <span className="mx-1.5 text-muted">→</span>
                        </>
                      ) : null}
                      {r.value}
                    </dd>
                  </div>
                ))}
              </dl>
            )
          ) : null}

          {shownError ? (
            <p role="alert" className="mt-4 flex items-start gap-2 rounded-lg bg-loss/10 px-3 py-2.5 text-sm text-loss">
              <CircleAlert className="mt-0.5 h-4 w-4 shrink-0" />
              <span>{shownError}</span>
            </p>
          ) : null}

          <div className="mt-6 flex justify-end gap-2">
            <button type="button" onClick={close} disabled={pending} className={btn('secondary')}>
              Cancel
            </button>
            <button
              type="submit"
              disabled={pending || nothingChanged}
              className={btn(tone === 'danger' ? 'danger' : 'primary')}
            >
              {pending ? 'Working…' : confirmLabel}
            </button>
          </div>
        </div>
      </dialog>
    </form>
  );
}

/** Read `data-label` fields back for the dialog. */
function readReview(
  form: HTMLFormElement,
  mode: 'all' | 'changes',
  dialog: HTMLDialogElement | null,
): ReviewRow[] {
  const rows: ReviewRow[] = [];
  const blank = '—';

  for (const el of Array.from(form.elements)) {
    const label = (el as HTMLElement).dataset?.label;
    // Disabled fields are not submitted, so they are not part of what is confirmed.
    if (!label || dialog?.contains(el) || (el as HTMLInputElement).disabled) continue;

    if (el instanceof HTMLSelectElement) {
      const now = el.selectedOptions[0]?.text.trim() || blank;
      const initial =
        Array.from(el.options).find((o) => o.defaultSelected) ?? el.options[0];
      const before = initial?.text.trim() || blank;
      if (mode === 'all' || now !== before) {
        rows.push({ label, value: now, ...(mode === 'changes' && { before }) });
      }
    } else if (el instanceof HTMLInputElement && el.type === 'checkbox') {
      const now = el.checked ? 'Yes' : 'No';
      const before = el.defaultChecked ? 'Yes' : 'No';
      if (mode === 'all' || now !== before) {
        rows.push({ label, value: now, ...(mode === 'changes' && { before }) });
      }
    } else if (el instanceof HTMLInputElement || el instanceof HTMLTextAreaElement) {
      const secret = el instanceof HTMLInputElement && el.type === 'password';
      const show = (v: string) => (v === '' ? blank : secret ? '•'.repeat(Math.min(v.length, 12)) : v);
      if (mode === 'all' || el.value !== el.defaultValue) {
        rows.push({
          label,
          value: show(el.value),
          // A password's previous value is never known here, so no "before".
          ...(mode === 'changes' && !secret && { before: show(el.defaultValue) }),
        });
      }
    }
  }
  return rows;
}
