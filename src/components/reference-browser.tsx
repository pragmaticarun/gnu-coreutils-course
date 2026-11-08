"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { Input } from "@/components/ui/input";
import type { ReferenceEntry } from "@/lib/types";

export function ReferenceBrowser({ entries }: { entries: ReferenceEntry[] }) {
  const [query, setQuery] = useState("");
  const [section, setSection] = useState("All");
  const sections = useMemo(
    () => ["All", ...Array.from(new Set(entries.map((entry) => entry.section)))],
    [entries],
  );
  const shown = entries.filter((entry) => {
    if (section !== "All" && entry.section !== section) return false;
    const hay = `${entry.name} ${entry.summary} ${entry.note}`.toLowerCase();
    return hay.includes(query.trim().toLowerCase());
  });

  return (
    <div className="mt-6">
      <div className="flex flex-col gap-3 md:flex-row">
        <Input
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="Filter by name or behavior"
          aria-label="Filter utilities"
        />
        <p className="self-center text-sm text-[var(--muted)]">{shown.length} utilities</p>
      </div>
      <div className="mt-3 flex gap-2 overflow-x-auto pb-1">
        {sections.map((item) => (
          <button
            key={item}
            type="button"
            onClick={() => setSection(item)}
            className={`shrink-0 rounded-full border px-3 py-1 text-xs ${
              section === item
                ? "border-[var(--accent)] bg-[var(--accent)] text-[var(--accent-ink)]"
                : "border-[var(--line)]"
            }`}
          >
            {item}
          </button>
        ))}
      </div>
      <ul className="mt-4 grid gap-3 md:grid-cols-2">
        {shown.map((entry) => (
          <li key={entry.name} className="rounded-xl border border-[var(--line)] bg-[var(--bg-elev)] p-4">
            <Link href={`/reference/${entry.slug}`} className="font-mono text-lg hover:underline">
              {entry.name}
            </Link>
            <p className="text-[11px] uppercase tracking-wide text-[var(--muted)]">{entry.section}</p>
            <p className="mt-2 text-sm leading-6">{entry.summary}</p>
          </li>
        ))}
      </ul>
    </div>
  );
}
