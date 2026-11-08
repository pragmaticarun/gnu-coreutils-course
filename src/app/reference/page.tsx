import { ReferenceBrowser } from "@/components/reference-browser";
import { getCourse } from "@/lib/content";

export const metadata = { title: "Utility reference" };

export default function ReferencePage() {
  const course = getCourse();
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
      <h2 className="mt-12 font-serif text-3xl">Often mistaken for coreutils</h2>
      <ul className="mt-4 space-y-3">
        {course.companions.map((tool) => (
          <li key={tool.name} className="rounded-xl border border-[var(--line)] bg-[var(--bg-elev)] p-4">
            <p className="font-mono text-sm">{tool.name}</p>
            <p className="text-sm text-[var(--muted)]">
              {tool.installed
                ? `${tool.path} · package ${tool.package}`
                : "Not installed in the capture environment"}
            </p>
            <p className="mt-1 leading-6">{tool.note}</p>
          </li>
        ))}
      </ul>
    </div>
  );
}
