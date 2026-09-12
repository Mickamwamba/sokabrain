'use client';

import { useEffect, useState } from 'react';
import { CircleAlert, CircleCheck, X } from 'lucide-react';

/**
 * Transient success and error notices.
 *
 * A window event rather than a React context, so any client component can
 * raise one without being wrapped in a provider — and because the toaster
 * lives in the admin layout, a notice survives the navigation a successful
 * create triggers.
 */

type Toast = { id: number; message: string; tone: 'success' | 'error' };

const EVENT = 'admin:toast';

export function toast(message: string, tone: Toast['tone'] = 'success') {
  window.dispatchEvent(new CustomEvent(EVENT, { detail: { message, tone } }));
}

export function Toaster() {
  const [toasts, setToasts] = useState<Toast[]>([]);

  useEffect(() => {
    let seq = 0;
    const onToast = (e: Event) => {
      const { message, tone } = (e as CustomEvent<Omit<Toast, 'id'>>).detail;
      const id = ++seq;
      setToasts((t) => [...t, { id, message, tone }]);
      window.setTimeout(() => setToasts((t) => t.filter((x) => x.id !== id)), 4500);
    };
    window.addEventListener(EVENT, onToast);
    return () => window.removeEventListener(EVENT, onToast);
  }, []);

  return (
    <div
      aria-live="polite"
      className="pointer-events-none fixed inset-x-4 bottom-4 z-[60] flex flex-col items-end gap-2 sm:left-auto sm:right-6"
    >
      {toasts.map((t) => (
        <div
          key={t.id}
          role={t.tone === 'error' ? 'alert' : 'status'}
          className="pointer-events-auto flex w-full max-w-sm items-start gap-3 rounded-xl border border-line bg-paper px-4 py-3 text-sm shadow-lg"
        >
          {t.tone === 'success' ? (
            <CircleCheck className="mt-0.5 h-4 w-4 shrink-0 text-brand" />
          ) : (
            <CircleAlert className="mt-0.5 h-4 w-4 shrink-0 text-loss" />
          )}
          <p className="min-w-0 flex-1">{t.message}</p>
          <button
            type="button"
            aria-label="Dismiss"
            onClick={() => setToasts((all) => all.filter((x) => x.id !== t.id))}
            className="text-muted hover:text-ink"
          >
            <X className="h-4 w-4" />
          </button>
        </div>
      ))}
    </div>
  );
}
