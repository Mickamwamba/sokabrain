'use client';

import { useActionState } from 'react';
import { CircleAlert, Lock } from 'lucide-react';
import { loginAction } from '../actions';
import { btn, input } from '@/components/admin/styles';

export default function AdminLoginPage() {
  const [state, formAction, pending] = useActionState(loginAction, {});

  return (
    <div className="grid min-h-screen lg:grid-cols-2">
      <div className="relative hidden flex-col justify-between overflow-hidden bg-ink p-12 text-white lg:flex">
        <span className="display text-xl font-extrabold tracking-tight">
          soka<span className="text-brand">brain</span>
        </span>
        <div>
          <p className="display text-4xl font-extrabold leading-tight">
            The vault, <br />kept honest.
          </p>
          <p className="mt-4 max-w-sm text-sm text-white/60">
            Competitions, seasons, teams and players — and nothing reaches the public site
            until an editor publishes it.
          </p>
        </div>
        <p className="text-xs text-white/40">Sokabrain admin console</p>
      </div>

      <div className="flex items-center justify-center bg-wash px-4 py-12">
        <div className="w-full max-w-sm">
          <div className="mb-8 lg:hidden">
            <span className="display text-xl font-extrabold tracking-tight">
              soka<span className="text-brand">brain</span>
            </span>
          </div>
          <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-paper shadow-sm ring-1 ring-line">
            <Lock className="h-5 w-5" />
          </span>
          <h1 className="display mt-4 text-2xl font-extrabold tracking-tight">Sign in</h1>
          <p className="mt-1 text-sm text-muted">Use the account an administrator gave you.</p>

          <form action={formAction} className="mt-6 space-y-4">
            <label className="block">
              <span className="mb-1.5 block text-xs font-semibold">Email</span>
              <input name="email" type="email" autoComplete="username" required className={input} />
            </label>
            <label className="block">
              <span className="mb-1.5 block text-xs font-semibold">Password</span>
              <input
                name="password"
                type="password"
                autoComplete="current-password"
                required
                className={input}
              />
            </label>
            {state.error ? (
              <p role="alert" className="flex items-start gap-2 rounded-lg bg-loss/10 px-3 py-2.5 text-sm text-loss">
                <CircleAlert className="mt-0.5 h-4 w-4 shrink-0" />
                {state.error}
              </p>
            ) : null}
            <button type="submit" disabled={pending} className={btn('primary', 'md', 'w-full')}>
              {pending ? 'Signing in…' : 'Sign in'}
            </button>
          </form>

          <p className="mt-8 text-xs text-muted">
            No account? Ask an existing admin to add you under Access management. There is
            no self sign-up.
          </p>
        </div>
      </div>
    </div>
  );
}
