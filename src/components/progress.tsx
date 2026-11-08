"use client";

import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";

const KEY = "coreutils-workbench-v1";

type Store = { done: string[] };

type Ctx = {
  ready: boolean;
  done: Set<string>;
  toggle: (slug: string) => void;
  mark: (slug: string) => void;
  clear: () => void;
};

const ProgressContext = createContext<Ctx | null>(null);

function load(): Store {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return { done: [] };
    const parsed = JSON.parse(raw) as Store;
    if (!parsed || !Array.isArray(parsed.done)) return { done: [] };
    return { done: parsed.done.filter((item) => typeof item === "string") };
  } catch {
    return { done: [] };
  }
}

export function ProgressProvider({ children }: { children: ReactNode }) {
  const [done, setDone] = useState<string[]>([]);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    setDone(load().done);
    setReady(true);
  }, []);

  useEffect(() => {
    if (!ready) return;
    localStorage.setItem(KEY, JSON.stringify({ done }));
  }, [done, ready]);

  const value = useMemo<Ctx>(
    () => ({
      ready,
      done: new Set(done),
      toggle: (slug) =>
        setDone((prev) =>
          prev.includes(slug) ? prev.filter((item) => item !== slug) : [...prev, slug],
        ),
      mark: (slug) =>
        setDone((prev) => (prev.includes(slug) ? prev : [...prev, slug])),
      clear: () => setDone([]),
    }),
    [done, ready],
  );

  return (
    <ProgressContext.Provider value={value}>{children}</ProgressContext.Provider>
  );
}

export function useProgress() {
  const ctx = useContext(ProgressContext);
  if (!ctx) throw new Error("useProgress requires ProgressProvider");
  return ctx;
}
