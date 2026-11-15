import Link from "next/link";
import { ReferenceBrowser } from "@/components/reference-browser";
import { getCourse } from "@/lib/content";

export const metadata = { title: "Utility reference" };

const COMPANION_ORDER = [
  "Text",
  "Finding and batching",
  "Archives and compression",
  "Timing and tracing",
  "Process and memory",
  "Open files",
  "util-linux",
  "Helpers",
  "Boundary",
];

export default function ReferencePage() {
  const course = getCourse();
  const groups = new Map<string, typeof course.companions>();
  for (const tool of course.companions) {
    const list = groups.get(tool.group) ?? [];
    list.push(tool);
    groups.set(tool.group, list);
  }
  const ordered = [
    ...COMPANION_ORDER.filter((name) => groups.has(name)),
    ...[...groups.keys()].filter((name) => !COMPANION_ORDER.includes(name)),
  ];
  return (
    <div className="mx-auto max-w-5xl">
      <h1 className="font-serif text-4xl">Utility reference</h1>
      <p className="mt-3 max-w-3xl leading-7 text-[var(--muted)]">
        Every binary in the installed coreutils {course.meta.packageVersion} package,
        except the <code>md5sum.textutils</code> compatibility symlink. Summaries come
        from <code>--help</code> on this machine. The notes are course guidance, not a
        second manual.
      </p>
      <ReferenceBrowser entries={course.reference} />
      <h2 className="mt-12 font-serif text-3xl">Companion tools, not coreutils</h2>
      <p className="mt-3 max-w-3xl leading-7">
        None of these tools are GNU coreutils. The Ubuntu package name is the binary
        package <code>dpkg -S</code> reported for the path. The project is the upstream
        that publishes the manual. A lesson link jumps to the worked examples.
      </p>
      {ordered.map((group) => (
        <section key={group} className="mt-8">
          <h3 className="font-serif text-2xl">{group}</h3>
          <ul className="mt-3 space-y-3">
            {(groups.get(group) ?? []).map((tool) => (
              <li key={tool.name} className="rounded-xl border border-[var(--line)] bg-[var(--bg-elev)] p-4">
                <p className="font-mono text-sm">{tool.name}</p>
                <p className="text-sm text-[var(--muted)]">
                  {tool.installed
                    ? `${tool.path} · Ubuntu package ${tool.package}`
                    : `${tool.path} · not installed in the capture environment`}
                  {" · "}
                  {tool.project}
                </p>
                <p className="mt-1 leading-6">{tool.note}</p>
                {tool.lesson ? (
                  <p className="mt-2 text-sm">
                    <Link className="underline" href={`/lessons/${tool.lesson}`}>
                      Open the lesson
                    </Link>
                  </p>
                ) : null}
              </li>
            ))}
          </ul>
        </section>
      ))}
    </div>
  );
}
