import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { MarkdownView } from "@/components/markdown-view";
import { LessonActions } from "@/components/lesson-actions";
import type { Lesson } from "@/lib/types";

export function Article({
  lesson,
  prev,
  next,
}: {
  lesson: Lesson;
  prev: Lesson | null;
  next: Lesson | null;
}) {
  const base = lesson.kind === "cookbook" ? "/cookbook" : "/lessons";
  return (
    <article className="mx-auto max-w-3xl">
      <p className="text-[11px] uppercase tracking-[0.16em] text-[var(--muted)]">
        {lesson.module} · {lesson.level} · {lesson.minutes} min
      </p>
      <h1 className="mt-2 font-serif text-4xl leading-tight md:text-5xl">{lesson.title}</h1>
      <p className="mt-4 text-lg leading-8 text-[var(--muted)]">{lesson.summary}</p>
      <div className="mt-4 flex flex-wrap gap-2">
        <Badge>{lesson.examples.length} captured examples</Badge>
        <Badge>{lesson.exercises.length} exercises</Badge>
        <Badge>{lesson.wordCount} words of notes</Badge>
      </div>
      {lesson.objectives.length > 0 ? (
        <section className="mt-6 rounded-xl border border-[var(--line)] bg-[var(--bg-elev)] p-4">
          <h2 className="font-serif text-2xl">Objectives</h2>
          <ul className="mt-2 list-disc space-y-1 pl-5">
            {lesson.objectives.map((objective) => (
              <li key={objective}>{objective}</li>
            ))}
          </ul>
        </section>
      ) : null}
      <p className="mt-4 text-sm leading-6 text-[var(--muted)]">
        Examples run in a fresh temporary directory. Unless a script overrides it,{" "}
        <code>LC_ALL=en_US.UTF-8</code>, and both <code>HOME</code> and <code>TMPDIR</code>{" "}
        point at that directory. Stdout, stderr, and the exit status are the bytes captured
        on the build machine. BSD notes are documented differences and were not executed here.
      </p>
      <div className="mt-6 lg:grid lg:grid-cols-[minmax(0,1fr)_180px] lg:gap-8">
        <MarkdownView markdown={lesson.markdown} />
        <aside className="mb-6 lg:sticky lg:top-20 lg:mb-0 lg:self-start">
          <p className="text-[11px] uppercase tracking-wider text-[var(--muted)]">On this page</p>
          <ul className="mt-2 space-y-1 text-sm">
            {lesson.headings
              .filter((heading) => heading.level === 2)
              .map((heading) => (
                <li key={heading.id}>
                  <a className="text-[var(--muted)] hover:text-[var(--ink)]" href={`#${heading.id}`}>
                    {heading.text}
                  </a>
                </li>
              ))}
          </ul>
        </aside>
      </div>
      <section className="mt-8 rounded-xl border border-[var(--line)] bg-[var(--bg-muted)] p-4">
        <h2 className="font-serif text-2xl">GNU and BSD</h2>
        <p className="mt-2 whitespace-pre-wrap leading-7">{lesson.gnuVsBsd}</p>
      </section>
      <section className="mt-4">
        <h2 className="font-serif text-2xl">Manual</h2>
        <ul className="mt-2 space-y-1">
          {lesson.manual.map((item) => (
            <li key={item.url}>
              <a
                className="text-[var(--accent)] underline underline-offset-2"
                href={item.url}
                rel="noreferrer"
                target="_blank"
              >
                {item.title}
              </a>
            </li>
          ))}
        </ul>
        <p className="mt-2 text-sm text-[var(--muted)]">
          HTML links open the GNU project manual, which can move ahead of the 9.4 manual
          installed on the capture machine. Flags in the examples were checked with{" "}
          <code>--help</code> and the local 9.4 info file.
        </p>
      </section>
      <div className="mt-6">
        <LessonActions slug={lesson.slug} />
      </div>
      <div className="mt-8 flex justify-between gap-3 text-sm">
        {prev ? (
          <Link href={`${base}/${prev.slug}`} className="hover:underline">
            ← {prev.title}
          </Link>
        ) : (
          <span />
        )}
        {next ? (
          <Link href={`${base}/${next.slug}`} className="hover:underline">
            {next.title} →
          </Link>
        ) : null}
      </div>
    </article>
  );
}
