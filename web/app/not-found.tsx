import Link from "next/link";

export default function NotFound() {
  return (
    <div className="rounded-md border border-dashed border-border px-4 py-12 text-center">
      <p className="font-medium">Not in the vault.</p>
      <p className="mt-1 text-sm text-muted">
        That competition edition doesn’t exist.
      </p>
      <Link href="/" className="mt-4 inline-block text-sm text-accent underline underline-offset-2">
        Browse competitions
      </Link>
    </div>
  );
}
