/**
 * Class recipes for the admin dashboard.
 *
 * Plain strings rather than components so the same look is available to server
 * pages, client forms and native elements (a <Link>, a submit <button>, a
 * <select>) without wrapping each in a component that has to forward refs.
 */

export type ButtonVariant = 'primary' | 'secondary' | 'danger' | 'ghost' | 'success';
export type ButtonSize = 'sm' | 'md';

const BASE =
  'inline-flex items-center justify-center gap-1.5 whitespace-nowrap rounded-lg font-semibold ' +
  'transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ink ' +
  'disabled:pointer-events-none disabled:opacity-50';

const VARIANT: Record<ButtonVariant, string> = {
  primary: 'bg-ink text-white hover:bg-ink-soft',
  secondary: 'border border-line bg-paper text-ink hover:border-ink/40 hover:bg-wash',
  danger: 'bg-loss text-white hover:bg-loss/90',
  success: 'bg-brand text-white hover:bg-brand-dark',
  ghost: 'text-muted hover:bg-wash hover:text-ink',
};

const SIZE: Record<ButtonSize, string> = {
  sm: 'h-8 px-2.5 text-xs [&_svg]:h-3.5 [&_svg]:w-3.5',
  md: 'h-9 px-3.5 text-sm [&_svg]:h-4 [&_svg]:w-4',
};

export function btn(variant: ButtonVariant = 'primary', size: ButtonSize = 'md', extra = '') {
  return `${BASE} ${VARIANT[variant]} ${SIZE[size]} ${extra}`.trim();
}

/** Square icon-only button, e.g. a row's delete action. */
export function iconBtn(variant: 'ghost' | 'danger' = 'ghost') {
  return `${BASE} h-8 w-8 [&_svg]:h-4 [&_svg]:w-4 ${
    variant === 'danger' ? 'text-muted hover:bg-loss/10 hover:text-loss' : VARIANT.ghost
  }`;
}

export const input =
  'block w-full rounded-lg border border-line bg-paper px-3 py-2 text-sm text-ink ' +
  'placeholder:text-muted/70 focus:border-ink focus:outline-none focus:ring-2 focus:ring-ink/10 ' +
  'disabled:bg-wash disabled:text-muted';

export const th =
  'px-4 py-2.5 text-left text-[11px] font-semibold uppercase tracking-wide text-muted first:pl-5 last:pr-5';

export const td = 'px-4 py-3 align-middle first:pl-5 last:pr-5';
