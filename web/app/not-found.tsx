import Link from "next/link";

export default function NotFound() {
  return (
    <div className="rounded-xl border border-line bg-paper px-6 py-16 text-center">
      <p className="display text-xl font-extrabold">Not in the vault</p>
      <p className="mt-1.5 text-sm text-muted">
        That page doesn’t exist, or the competition hasn’t been published yet.
      </p>
      <Link
        href="/"
        className="mt-5 inline-block rounded-full bg-ink px-5 py-2 text-sm font-semibold text-white"
      >
        Back to stats
      </Link>
    </div>
  );
}
