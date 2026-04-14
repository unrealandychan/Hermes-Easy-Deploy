"use client";

import { useEffect } from "react";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div
      className="min-h-screen flex flex-col items-center justify-center px-6 text-center"
      style={{ background: "var(--bg)" }}
    >
      <p className="text-5xl mb-4">⚠️</p>
      <h2 className="text-2xl font-bold text-white mb-2">Something went wrong</h2>
      <p className="text-sm mb-8" style={{ color: "var(--text-muted)" }}>
        {error.message || "An unexpected error occurred."}
      </p>
      <button
        onClick={reset}
        className="px-5 py-2.5 rounded-lg text-sm font-semibold text-black transition-all"
        style={{ background: "var(--amber)" }}
      >
        Try again
      </button>
    </div>
  );
}
