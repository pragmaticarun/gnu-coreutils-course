import Link from "next/link";
import { getCourse } from "@/lib/content";
import { withBase } from "@/lib/utils";

export default function HomePage() {
  const course = getCourse();
  const modules = new Map<string, typeof course.lessons>();
  for (const lesson of course.lessons) {
    const list = modules.get(lesson.module) ?? [];
    list.push(lesson);
    modules.set(lesson.module, list);
  }
  const exampleCount = course.lessons.reduce((sum, lesson) => sum + lesson.examples.length, 0);
  const exerciseCount = course.lessons.reduce((sum, lesson) => sum + lesson.exercises.length, 0);

  return (
    <div className="mx-auto max-w-5xl">
      <p className="text-[11px] uppercase tracking-[0.18em] text-[var(--muted)]">
        {course.meta.coreutilsVersion} · package {course.meta.packageVersion}
      </p>
      <h1 className="mt-2 max-w-3xl font-serif text-4xl leading-tight md:text-6xl">
        GNU coreutils, taught as a working toolbox.
      </h1>
      <p className="mt-4 max-w-2xl text-lg leading-8 text-[var(--muted)]">
        A course for Arunkumar: Ubuntu, C++, Rust, and Android. The lessons stay with the
        tools that ship in GNU coreutils, show the bytes they actually emit, and treat
        speed as a bottleneck question instead of a slogan.
      </p>
      <dl className="mt-6 grid grid-cols-2 gap-3 md:grid-cols-4">
        {[
          ["Lessons", String(course.lessons.length)],
          ["Captured examples", String(exampleCount)],
          ["Exercises", String(exerciseCount)],
          ["Cookbook", String(course.cookbook.length)],
        ].map(([label, value]) => (
          <div key={label} className="rounded-xl border border-[var(--line)] bg-[var(--bg-elev)] p-3">
            <dt className="text-[11px] uppercase tracking-wide text-[var(--muted)]">{label}</dt>
            <dd className="font-serif text-3xl">{value}</dd>
          </div>
        ))}
      </dl>
      <div className="mt-6 flex flex-wrap gap-3 text-sm">
        <Link className="rounded-md bg-[var(--accent)] px-3 py-2 text-[var(--accent-ink)]" href="/lessons/orientation">
          Start with the manual
        </Link>
        <Link className="rounded-md border border-[var(--line)] px-3 py-2" href="/cookbook">
          Scenario cookbook
        </Link>
        <Link className="rounded-md border border-[var(--line)] px-3 py-2" href="/reference">
          Utility reference
        </Link>
        <a className="rounded-md border border-[var(--line)] px-3 py-2" href={withBase("/downloads/coreutils-examples.zip")}>
          Download every example
        </a>
        <a className="rounded-md border border-[var(--line)] px-3 py-2" href={withBase("/downloads/benchmarks/run_all.py")}>
          Benchmark scripts
        </a>
      </div>
      <section className="mt-10">
        <h2 className="font-serif text-3xl">How the course is arranged</h2>
        <div className="mt-4 grid gap-4 md:grid-cols-2">
          {[...modules.entries()].map(([module, lessons]) => (
            <section key={module} className="rounded-xl border border-[var(--line)] bg-[var(--bg-elev)] p-4">
              <h3 className="font-serif text-2xl">{module}</h3>
              <ol className="mt-2 space-y-1 text-sm">
                {lessons.map((lesson) => (
                  <li key={lesson.slug}>
                    <Link className="hover:underline" href={`/lessons/${lesson.slug}`}>
                      <span className="mr-2 font-mono text-[11px] text-[var(--muted)]">
                        {String(lesson.number).padStart(2, "0")}
                      </span>
                      {lesson.title}
                    </Link>
                  </li>
                ))}
              </ol>
            </section>
          ))}
        </div>
      </section>
      <section className="mt-10 max-w-3xl leading-7">
        <h2 className="font-serif text-3xl">What the numbers on this site are</h2>
        <p className="mt-3">
          Command output is captured, not typed from memory. Benchmarks are small,
          seeded, and repeated. They report elapsed time, user time, system time, and
          maximum resident set size when the kernel provides it. They do not drop the
          page cache, they do not need root, and a median from one warm run is not a
          ranking you can carry to another machine. The method page records the exact
          environment: {course.meta.uname}, locale {course.meta.locale}, filesystem{" "}
          {course.meta.filesystemDf} as reported by <code>df -T</code>.
        </p>
      </section>
    </div>
  );
}
