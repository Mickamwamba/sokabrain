'use client';

import { useActionState } from 'react';
import { loginAction } from '../actions';

export default function AdminLoginPage() {
  const [state, formAction, pending] = useActionState(loginAction, {});

  return (
    <div className="mx-auto max-w-sm py-16">
      <h1 className="text-xl font-semibold tracking-tight">Admin sign in</h1>
      <p className="mt-1 text-sm text-muted">
        Vault editing and publication control.
      </p>

      <form action={formAction} className="mt-6 space-y-3">
        <label className="block">
          <span className="text-xs text-muted">Email</span>
          <input
            name="email"
            type="email"
            autoComplete="username"
            required
            className="mt-1 w-full rounded border border-border bg-transparent px-3 py-2 text-sm"
          />
        </label>
        <label className="block">
          <span className="text-xs text-muted">Password</span>
          <input
            name="password"
            type="password"
            autoComplete="current-password"
            required
            className="mt-1 w-full rounded border border-border bg-transparent px-3 py-2 text-sm"
          />
        </label>
        <button
          type="submit"
          disabled={pending}
          className="w-full rounded bg-accent px-3 py-2 text-sm font-medium text-white disabled:opacity-50"
        >
          {pending ? 'Signing in…' : 'Sign in'}
        </button>
        {state.error ? (
          <p className="text-sm text-red-600">{state.error}</p>
        ) : null}
      </form>

      <p className="mt-6 text-xs text-muted">
        Accounts are created from the CLI: <code>npm run admin:create</code> in{' '}
        <code>backend/</code>. There is no self-signup.
      </p>
    </div>
  );
}
