"use client";

export default function Error({ reset }: { error: Error; reset: () => void }) {
  return (
    <div className="rounded-md border border-dashed border-border px-4 py-12 text-center">
      <p className="font-medium">Something went wrong loading this page.</p>
      <button
        onClick={reset}
        className="mt-4 rounded border border-border px-3 py-1.5 text-sm hover:border-accent"
      >
        Try again
      </button>
    </div>
  );
}
