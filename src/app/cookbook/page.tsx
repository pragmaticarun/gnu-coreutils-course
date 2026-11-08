import Link from "next/link";
import { getCourse } from "@/lib/content";

export const metadata = { title: "Cookbook" };

export default function CookbookPage() {
  const course = getCourse();
  return (
    <div className="mx-auto max-w-3xl">
      <h1 className="font-serif text-4xl">Scenario cookbook</h1>
      <p className="mt-3 leading-7 text-[var(--muted)]">
        Short jobs you actually meet in a tree of logs, firmware blobs, and build
        artifacts. Each one was executed in a sandbox. Where coreutils is the wrong
        tool, the recipe says so.
      </p>
      {course.cookbook.length === 0 ? (
        <p className="mt-6 text-sm text-[var(--muted)]">No recipes have been captured yet.</p>
      ) : null}
      <ol className="mt-6 space-y-3">
        {course.cookbook.map((recipe) => (
          <li key={recipe.slug} className="rounded-xl border border-[var(--line)] bg-[var(--bg-elev)] p-4">
            <p className="text-[11px] uppercase tracking-wide text-[var(--muted)]">
              {String(recipe.number).padStart(2, "0")} · {recipe.level}
            </p>
            <Link href={`/cookbook/${recipe.slug}`} className="font-serif text-2xl hover:underline">
              {recipe.title}
            </Link>
            <p className="mt-1 text-sm leading-6 text-[var(--muted)]">{recipe.summary}</p>
          </li>
        ))}
      </ol>
    </div>
  );
}
