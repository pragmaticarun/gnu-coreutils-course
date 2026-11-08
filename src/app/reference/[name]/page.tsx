import Link from "next/link";
import { notFound } from "next/navigation";
import { getCourse } from "@/lib/content";

export function generateStaticParams() {
  return getCourse().reference.map((entry) => ({ name: entry.slug }));
}

export function generateMetadata({ params }: { params: Promise<{ name: string }> }) {
  return params.then(({ name }) => ({ title: name }));
}

export default async function UtilityPage({ params }: { params: Promise<{ name: string }> }) {
  const { name } = await params;
  const course = getCourse();
  const entry = course.reference.find((item) => item.slug === name);
  if (!entry) notFound();
  return (
    <article className="mx-auto max-w-3xl">
      <p className="text-[11px] uppercase tracking-wide text-[var(--muted)]">{entry.section}</p>
      <h1 className="mt-2 font-mono text-4xl">{entry.name}</h1>
      <p className="mt-2 font-mono text-sm text-[var(--muted)]">{entry.versionLine}</p>
      <p className="mt-4 leading-7">{entry.summary}</p>
      <p className="mt-4 leading-7">{entry.note}</p>
      <p className="mt-4">
        <a className="text-[var(--accent)] underline" href={entry.manualUrl} target="_blank" rel="noreferrer">
          GNU manual
        </a>
      </p>
      {entry.lesson ? (
        <p className="mt-3">
          <Link className="underline" href={`/lessons/${entry.lesson}`}>
            Related lesson
          </Link>
        </p>
      ) : null}
      <p className="mt-8">
        <Link className="text-sm underline" href="/reference">
          All utilities
        </Link>
      </p>
    </article>
  );
}
