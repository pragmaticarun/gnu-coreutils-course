import Link from "next/link";
import { getCourse } from "@/lib/content";

export const metadata = { title: "Lessons" };

export default function LessonsPage() {
  const course = getCourse();
  return (
    <div className="mx-auto max-w-3xl">
      <h1 className="font-serif text-4xl">Lessons</h1>
      <p className="mt-3 leading-7 text-[var(--muted)]">
        {course.lessons.length} lessons from shell mechanics through external sort,
        checksums, and the tools that are easy to confuse with coreutils.
      </p>
      <ol className="mt-6 space-y-3">
        {course.lessons.map((lesson) => (
          <li key={lesson.slug} className="rounded-xl border border-[var(--line)] bg-[var(--bg-elev)] p-4">
            <p className="text-[11px] uppercase tracking-wide text-[var(--muted)]">
              {String(lesson.number).padStart(2, "0")} · {lesson.module} · {lesson.level}
            </p>
            <Link href={`/lessons/${lesson.slug}`} className="font-serif text-2xl hover:underline">
              {lesson.title}
            </Link>
            <p className="mt-1 text-sm leading-6 text-[var(--muted)]">{lesson.summary}</p>
          </li>
        ))}
      </ol>
    </div>
  );
}
