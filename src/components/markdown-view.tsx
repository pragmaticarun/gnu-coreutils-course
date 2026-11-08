"use client";

import type { ReactNode } from "react";
import Link from "next/link";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import type { Components } from "react-markdown";
import { Badge } from "@/components/ui/badge";
import { CopyButton } from "@/components/copy-button";
import { slugify, withBase } from "@/lib/utils";
import type { CapturedExample, CapturedExercise } from "@/lib/types";

function textOf(node: ReactNode): string {
  if (typeof node === "string" || typeof node === "number") return String(node);
  if (Array.isArray(node)) return node.map(textOf).join("");
  if (node && typeof node === "object" && "props" in node) {
    const props = node.props as { children?: ReactNode };
    return textOf(props.children);
  }
  return "";
}

function OutputBlock({ label, text }: { label: string; text: string }) {
  if (!text) return null;
  return (
    <div className="mt-3">
      <div className="mb-1 flex items-center justify-between gap-2">
        <p className="text-[11px] uppercase tracking-wider text-[var(--muted)]">{label}</p>
        <CopyButton text={text} label="Copy output" />
      </div>
      <pre className="overflow-x-auto rounded-md bg-[var(--code-bg)] p-3 text-[13px] leading-relaxed text-[var(--code-ink)]">
        <code>{text}</code>
      </pre>
    </div>
  );
}

export function ExampleCard({ example }: { example: CapturedExample }) {
  return (
    <figure className="my-5 overflow-hidden rounded-xl border border-[var(--line)] bg-[var(--bg-elev)]">
      <figcaption className="flex flex-wrap items-center justify-between gap-2 border-b border-[var(--line)] px-3 py-2">
        <div className="flex flex-wrap items-center gap-2">
          <span className="text-sm font-medium text-[var(--ink)]">
            {example.title || "Worked example"}
          </span>
          {example.companion ? (
            <Badge variant="warn">Not coreutils · {example.companion}</Badge>
          ) : (
            <Badge variant="ok">Captured</Badge>
          )}
          <Badge>exit {example.exitCode}</Badge>
        </div>
        <div className="flex flex-wrap gap-2">
          <CopyButton text={example.script} label="Copy script" />
          <a
            className="inline-flex h-8 items-center rounded-md border border-[var(--line)] px-2.5 text-xs hover:bg-[var(--bg-muted)]"
            href={withBase(example.download)}
            download
          >
            Download
          </a>
        </div>
      </figcaption>
      <div className="p-3">
        <pre className="overflow-x-auto rounded-md bg-[var(--code-bg)] p-3 text-[13px] leading-relaxed text-[var(--code-ink)]">
          <code>{example.script}</code>
        </pre>
        <OutputBlock label="stdout" text={example.stdout} />
        <OutputBlock label="stderr" text={example.stderr} />
        {example.truncated ? (
          <p className="mt-2 text-xs text-[var(--muted)]">
            Output was truncated in the page. The downloaded script is complete.
          </p>
        ) : null}
      </div>
    </figure>
  );
}

export function ExerciseCard({ exercise }: { exercise: CapturedExercise }) {
  return (
    <article className="my-4 rounded-xl border border-[var(--line)] bg-[var(--bg-elev)] p-4">
      <h3 className="font-serif text-xl text-[var(--ink)]">{exercise.title}</h3>
      <div className="prose-course mt-2">
        <ReactMarkdown remarkPlugins={[remarkGfm]}>{exercise.prompt}</ReactMarkdown>
      </div>
      <details className="mt-3 rounded-md border border-[var(--line)] px-3 py-2">
        <summary className="cursor-pointer text-sm font-medium">Hint</summary>
        <div className="prose-course mt-2 text-sm">
          <ReactMarkdown remarkPlugins={[remarkGfm]}>{exercise.hint}</ReactMarkdown>
        </div>
      </details>
      <details className="mt-2 rounded-md border border-[var(--line)] px-3 py-2">
        <summary className="cursor-pointer text-sm font-medium">Full solution</summary>
        <div className="prose-course mt-2 text-sm">
          <ReactMarkdown remarkPlugins={[remarkGfm]}>{exercise.solution}</ReactMarkdown>
        </div>
        <div className="mt-3 flex flex-wrap items-center gap-2">
          <Badge>exit {exercise.exitCode}</Badge>
          <CopyButton text={exercise.script} label="Copy solution" />
          <a
            className="text-xs underline decoration-[var(--line)] underline-offset-2"
            href={withBase(exercise.download)}
            download
          >
            Download script
          </a>
        </div>
        <pre className="mt-2 overflow-x-auto rounded-md bg-[var(--code-bg)] p-3 text-[13px] text-[var(--code-ink)]">
          <code>{exercise.script}</code>
        </pre>
        <OutputBlock label="stdout" text={exercise.stdout} />
        <OutputBlock label="stderr" text={exercise.stderr} />
      </details>
    </article>
  );
}

function parsePayload<T>(raw: string): T | null {
  try {
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

export function MarkdownView({ markdown }: { markdown: string }) {
  const components: Components = {
    a({ href, children }) {
      if (href && href.startsWith("/")) {
        return (
          <Link href={href} className="text-[var(--accent)] underline underline-offset-2">
            {children}
          </Link>
        );
      }
      return (
        <a
          href={href}
          className="text-[var(--accent)] underline underline-offset-2"
          rel="noreferrer"
          target="_blank"
        >
          {children}
        </a>
      );
    },
    h2({ children }) {
      const id = slugify(textOf(children));
      return (
        <h2 id={id} className="mt-10 scroll-mt-24 font-serif text-3xl text-[var(--ink)]">
          {children}
        </h2>
      );
    },
    h3({ children }) {
      const id = slugify(textOf(children));
      return (
        <h3 id={id} className="mt-6 scroll-mt-24 font-serif text-2xl text-[var(--ink)]">
          {children}
        </h3>
      );
    },
    p({ children }) {
      return <p className="my-3 leading-7 text-[var(--ink)]">{children}</p>;
    },
    ul({ children }) {
      return <ul className="my-3 list-disc space-y-1 pl-5">{children}</ul>;
    },
    ol({ children }) {
      return <ol className="my-3 list-decimal space-y-1 pl-5">{children}</ol>;
    },
    li({ children }) {
      return <li className="leading-7">{children}</li>;
    },
    blockquote({ children }) {
      return (
        <blockquote className="my-4 border-l-2 border-[var(--accent)] pl-4 text-[var(--muted)]">
          {children}
        </blockquote>
      );
    },
    table({ children }) {
      return (
        <div className="my-4 overflow-x-auto">
          <table className="w-full border-collapse text-sm">{children}</table>
        </div>
      );
    },
    th({ children }) {
      return (
        <th className="border border-[var(--line)] bg-[var(--bg-muted)] px-2 py-1 text-left font-medium">
          {children}
        </th>
      );
    },
    td({ children }) {
      return <td className="border border-[var(--line)] px-2 py-1 align-top">{children}</td>;
    },
    code({ className, children }) {
      const raw = String(children).replace(/\n$/, "");
      if (className === "language-example") {
        const example = parsePayload<CapturedExample>(raw);
        if (!example) return <pre>{raw}</pre>;
        return <ExampleCard example={example} />;
      }
      if (className === "language-exercise") {
        const exercise = parsePayload<CapturedExercise>(raw);
        if (!exercise) return <pre>{raw}</pre>;
        return <ExerciseCard exercise={exercise} />;
      }
      if (!className) {
        return (
          <code className="rounded bg-[var(--bg-muted)] px-1 py-0.5 font-mono text-[0.9em]">
            {children}
          </code>
        );
      }
      return (
        <span className="my-4 block">
          <span className="mb-1 flex justify-end">
            <CopyButton text={raw} />
          </span>
          <pre className="overflow-x-auto rounded-md bg-[var(--code-bg)] p-3 text-[13px] text-[var(--code-ink)]">
            <code>{raw}</code>
          </pre>
        </span>
      );
    },
    pre({ children }) {
      return <>{children}</>;
    },
  };

  return (
    <div className="prose-course">
      <ReactMarkdown remarkPlugins={[remarkGfm]} components={components}>
        {markdown}
      </ReactMarkdown>
    </div>
  );
}
