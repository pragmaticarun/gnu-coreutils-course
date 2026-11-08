"use client";

import Link from "next/link";
import { useEffect, useMemo, useState, type ReactNode } from "react";
import { usePathname } from "next/navigation";
import { BookOpen, Download, Menu, Moon, Search, Sun } from "lucide-react";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Button } from "@/components/ui/button";
import { useProgress } from "@/components/progress";
import { withBase } from "@/lib/utils";

export type NavLesson = { slug: string; title: string; number: number; kind: string };
export type NavGroup = { module: string; lessons: NavLesson[] };

type SearchHit = {
  kind: string;
  slug: string;
  title: string;
  module: string;
  summary: string;
  text: string;
};

function hrefFor(hit: { kind: string; slug: string }) {
  if (hit.kind === "cookbook") return `/cookbook/${hit.slug}`;
  if (hit.kind === "reference") return `/reference/${hit.slug}`;
  if (hit.kind === "page") return `/${hit.slug}`;
  return `/lessons/${hit.slug}`;
}

export function SiteShell({
  nav,
  lessonCount,
  children,
}: {
  nav: NavGroup[];
  lessonCount: number;
  children: ReactNode;
}) {
  const pathname = usePathname();
  const progress = useProgress();
  const [openNav, setOpenNav] = useState(false);
  const [openSearch, setOpenSearch] = useState(false);
  const [query, setQuery] = useState("");
  const [index, setIndex] = useState<SearchHit[]>([]);
  const [dark, setDark] = useState(false);

  useEffect(() => {
    setDark(document.documentElement.classList.contains("dark"));
    fetch(withBase("/search-index.json"))
      .then((response) => response.json())
      .then((data: SearchHit[]) => setIndex(data))
      .catch(() => setIndex([]));
  }, []);

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      const target = event.target as HTMLElement | null;
      const typing =
        target &&
        (target.tagName === "INPUT" ||
          target.tagName === "TEXTAREA" ||
          target.isContentEditable);
      if (event.key === "/" && !typing) {
        event.preventDefault();
        setOpenSearch(true);
      }
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
        event.preventDefault();
        setOpenSearch(true);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  const results = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return index.slice(0, 8);
    return index
      .map((hit) => {
        const hay = `${hit.title} ${hit.module} ${hit.summary} ${hit.text}`.toLowerCase();
        let score = 0;
        if (hit.title.toLowerCase().includes(q)) score += 5;
        if (hit.summary.toLowerCase().includes(q)) score += 2;
        if (hay.includes(q)) score += 1;
        return { hit, score };
      })
      .filter((item) => item.score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, 12)
      .map((item) => item.hit);
  }, [index, query]);

  const doneCount = nav
    .flatMap((group) => group.lessons)
    .filter((lesson) => lesson.kind === "lesson" && progress.done.has(lesson.slug)).length;

  const sidebar = (
    <nav aria-label="Course">
      <p className="px-2 pb-2 text-[11px] uppercase tracking-[0.16em] text-[var(--muted)]">
        Lessons
      </p>
      {nav.map((group) => (
        <div key={group.module} className="mb-4">
          <p className="px-2 pb-1 text-xs font-medium text-[var(--ink)]">{group.module}</p>
          <ul className="space-y-0.5">
            {group.lessons.map((lesson) => {
              const href =
                lesson.kind === "cookbook"
                  ? `/cookbook/${lesson.slug}`
                  : `/lessons/${lesson.slug}`;
              const active = pathname === href || pathname === `${href}/`;
              const complete = progress.done.has(lesson.slug);
              return (
                <li key={lesson.slug}>
                  <Link
                    href={href}
                    onClick={() => setOpenNav(false)}
                    className={`flex items-start gap-2 rounded-md px-2 py-1.5 text-sm leading-snug ${
                      active
                        ? "bg-[var(--bg-muted)] text-[var(--ink)]"
                        : "text-[var(--muted)] hover:bg-[var(--bg-muted)] hover:text-[var(--ink)]"
                    }`}
                  >
                    <span className="mt-0.5 w-6 shrink-0 font-mono text-[11px]">
                      {String(lesson.number).padStart(2, "0")}
                    </span>
                    <span className="flex-1">{lesson.title}</span>
                    {complete ? (
                      <span className="mt-1 h-1.5 w-1.5 shrink-0 rounded-full bg-[var(--ok)]" />
                    ) : null}
                  </Link>
                </li>
              );
            })}
          </ul>
        </div>
      ))}
      <div className="mt-2 space-y-1 border-t border-[var(--line)] pt-3 text-sm">
        <Link className="block rounded-md px-2 py-1.5 hover:bg-[var(--bg-muted)]" href="/cookbook">
          Scenario cookbook
        </Link>
        <Link className="block rounded-md px-2 py-1.5 hover:bg-[var(--bg-muted)]" href="/reference">
          Utility reference
        </Link>
        <Link className="block rounded-md px-2 py-1.5 hover:bg-[var(--bg-muted)]" href="/benchmarks">
          Benchmarks
        </Link>
        <Link className="block rounded-md px-2 py-1.5 hover:bg-[var(--bg-muted)]" href="/progress">
          Your progress
        </Link>
        <Link className="block rounded-md px-2 py-1.5 hover:bg-[var(--bg-muted)]" href="/method">
          Method and limits
        </Link>
      </div>
    </nav>
  );

  return (
    <div className="min-h-screen">
      <a
        href="#content"
        className="sr-only focus:not-sr-only focus:absolute focus:left-3 focus:top-3 focus:z-50 focus:rounded-md focus:bg-[var(--bg-elev)] focus:px-3 focus:py-2"
      >
        Skip to content
      </a>
      <header className="sticky top-0 z-40 border-b border-[var(--line)] bg-[var(--bg)]/90 backdrop-blur">
        <div className="flex items-center gap-2 px-3 py-2 md:px-5">
          <Button
            variant="ghost"
            size="icon"
            className="md:hidden"
            aria-label="Open navigation"
            onClick={() => setOpenNav(true)}
          >
            <Menu className="h-4 w-4" />
          </Button>
          <Link href="/" className="flex items-center gap-2 pr-2">
            <BookOpen className="h-4 w-4 text-[var(--accent)]" />
            <span className="font-serif text-lg leading-none">Workbench</span>
          </Link>
          <button
            type="button"
            onClick={() => setOpenSearch(true)}
            className="ml-auto flex h-9 min-w-0 flex-1 items-center gap-2 rounded-md border border-[var(--line)] bg-[var(--bg-elev)] px-3 text-left text-sm text-[var(--muted)] md:max-w-md"
          >
            <Search className="h-3.5 w-3.5" />
            <span className="truncate">Search lessons, tools, recipes</span>
            <span className="ml-auto hidden font-mono text-[10px] md:inline">/</span>
          </button>
          <a
            href={withBase("/downloads/coreutils-examples.zip")}
            className="hidden items-center gap-1 rounded-md border border-[var(--line)] px-2 py-1.5 text-xs sm:inline-flex"
          >
            <Download className="h-3.5 w-3.5" />
            Examples
          </a>
          <span className="hidden font-mono text-[11px] text-[var(--muted)] lg:inline">
            {progress.ready ? `${doneCount}/${lessonCount}` : "—"} done
          </span>
          <Button
            variant="ghost"
            size="icon"
            aria-label={dark ? "Switch to light mode" : "Switch to dark mode"}
            onClick={() => {
              const next = !document.documentElement.classList.contains("dark");
              document.documentElement.classList.toggle("dark", next);
              localStorage.setItem("theme", next ? "dark" : "light");
              setDark(next);
            }}
          >
            {dark ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
          </Button>
        </div>
      </header>
      <div className="mx-auto grid max-w-[1400px] md:grid-cols-[280px_minmax(0,1fr)]">
        <aside className="sticky top-14 hidden h-[calc(100vh-3.5rem)] border-r border-[var(--line)] md:block">
          <ScrollArea className="h-full">
            <div className="p-3">{sidebar}</div>
          </ScrollArea>
        </aside>
        <main id="content" className="min-w-0 px-4 py-6 md:px-8 md:py-8">
          {children}
        </main>
      </div>

      <Dialog open={openNav} onOpenChange={setOpenNav}>
        <DialogContent className="max-h-[85vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Course navigation</DialogTitle>
          </DialogHeader>
          {sidebar}
        </DialogContent>
      </Dialog>

      <Dialog
        open={openSearch}
        onOpenChange={(value) => {
          setOpenSearch(value);
          if (!value) setQuery("");
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Search the workbench</DialogTitle>
          </DialogHeader>
          <Input
            autoFocus
            placeholder="sort, reflink, NUL, sha256sum…"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            aria-label="Search"
          />
          <ul className="mt-3 max-h-80 space-y-1 overflow-y-auto">
            {results.length === 0 ? (
              <li className="px-2 py-3 text-sm text-[var(--muted)]">No matching pages.</li>
            ) : (
              results.map((hit) => (
                <li key={`${hit.kind}-${hit.slug}`}>
                  <Link
                    href={hrefFor(hit)}
                    onClick={() => setOpenSearch(false)}
                    className="block rounded-md px-2 py-2 hover:bg-[var(--bg-muted)]"
                  >
                    <span className="text-[11px] uppercase tracking-wide text-[var(--muted)]">
                      {hit.kind} · {hit.module}
                    </span>
                    <span className="block text-sm text-[var(--ink)]">{hit.title}</span>
                  </Link>
                </li>
              ))
            )}
          </ul>
        </DialogContent>
      </Dialog>
    </div>
  );
}
