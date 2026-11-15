import { getBenchmarks, getCompanionBenchmarks, getCourse, getSupplementBenchmarks } from "@/lib/content";
import type { BenchFile } from "@/lib/types";
import { withBase } from "@/lib/utils";

export const metadata = { title: "Benchmarks" };

function fmt(value: number, digits = 4) {
  return value.toFixed(digits);
}

function BenchTables({ data, label }: { data: BenchFile; label: string }) {
  return (
    <div className="mt-8 space-y-8">
      <section className="rounded-xl border border-[var(--line)] bg-[var(--bg-elev)] p-4 text-sm leading-6">
        <h2 className="font-serif text-2xl">{label}</h2>
        <dl className="mt-3 grid gap-2 md:grid-cols-2">
          {Object.entries(data.disclosure).map(([key, value]) => (
            <div key={key}>
              <dt className="font-mono text-[11px] text-[var(--muted)]">{key}</dt>
              <dd>{String(value)}</dd>
            </div>
          ))}
        </dl>
      </section>
      {data.benches.map((bench) => (
        <section key={bench.id} className="rounded-xl border border-[var(--line)] p-4">
          <h2 className="font-serif text-2xl">{bench.title}</h2>
          <p className="mt-2 leading-7">{bench.question}</p>
          <p className="mt-2 text-sm text-[var(--muted)]">{bench.input}</p>
          <div className="mt-3 overflow-x-auto">
            <table className="w-full border-collapse text-sm">
              <thead>
                <tr>
                  {["Variant", "Median elapsed", "User", "System", "Max RSS KiB", "Spread"].map(
                    (heading) => (
                      <th
                        key={heading}
                        className="border border-[var(--line)] bg-[var(--bg-muted)] px-2 py-1 text-left"
                      >
                        {heading}
                      </th>
                    ),
                  )}
                </tr>
              </thead>
              <tbody>
                {bench.variants.map((variant) => {
                  const elapsed = variant.trials.map((trial) => trial.elapsed);
                  const spread = Math.max(...elapsed) - Math.min(...elapsed);
                  return (
                    <tr key={variant.name}>
                      <td className="border border-[var(--line)] px-2 py-1">{variant.name}</td>
                      <td className="border border-[var(--line)] px-2 py-1 font-mono">
                        {fmt(variant.median.elapsed)} s
                      </td>
                      <td className="border border-[var(--line)] px-2 py-1 font-mono">
                        {fmt(variant.median.user)} s
                      </td>
                      <td className="border border-[var(--line)] px-2 py-1 font-mono">
                        {fmt(variant.median.system)} s
                      </td>
                      <td className="border border-[var(--line)] px-2 py-1 font-mono">
                        {variant.median.maxRssKb}
                      </td>
                      <td className="border border-[var(--line)] px-2 py-1 font-mono">
                        {fmt(spread)} s
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          <p className="mt-3 leading-7">{bench.note}</p>
        </section>
      ))}
    </div>
  );
}

export default function BenchmarksPage() {
  const course = getCourse();
  const data = getBenchmarks();
  const supplements = getSupplementBenchmarks();
  const companions = getCompanionBenchmarks();
  return (
    <div className="mx-auto max-w-4xl">
      <h1 className="font-serif text-4xl">Bounded benchmarks</h1>
      <p className="mt-3 leading-7">
        These scripts fix the input, the seed, and the trial count. They record elapsed,
        user, and system time, plus <code>ru_maxrss</code> of waited-for children. They do
        not drop caches and they do not ask for root. A result is evidence about this run
        only.
      </p>
      <p className="mt-3 text-sm text-[var(--muted)]">
        Capture host: {course.meta.uname}. Package {course.meta.packageVersion}. Locale{" "}
        {course.meta.locale}. Filesystem via <code>df -T</code>: {course.meta.filesystemDf}.
      </p>
      <ul className="mt-4 space-y-1 text-sm">
        {[
          "run_all.py",
          "libbench.py",
          "bench_sort_locale.py",
          "bench_sort_parallel.py",
          "bench_sort_buffer.py",
          "bench_checksums.py",
          "bench_wc.py",
          "bench_copy.py",
          "bench_buffering.py",
          "stdio_lines.c",
          "bench_pipeline.py",
          "bench_startup.py",
          "bench_sparse.py",
          "measure_supplements.py",
          "measure_companions.py",
          "bench_grep_mode.py",
          "bench_awk_vs_sort.py",
          "bench_compress.py",
          "bench_xargs_p.py",
          "bench_sed_rewrite.py",
          "bench_sparse_tar.py",
          "bench_taskset.py",
        ].map((name) => (
          <li key={name}>
            <a className="underline" href={withBase(`/downloads/benchmarks/${name}`)}>
              {name}
            </a>
          </li>
        ))}
      </ul>
      {!data ? (
        <p className="mt-6">No sample run was recorded.</p>
      ) : (
        <BenchTables data={data} label="Disclosure for the sample run" />
      )}
      <h2 className="mt-12 font-serif text-3xl">Later measurements, kept separate</h2>
      <p className="mt-3 leading-7">
        Pipeline overhead, process startup, and sparse copy were measured with the same
        style of harness and written to{" "}
        <a className="underline" href={withBase("/benchmarks/supplements.json")}>
          supplements.json
        </a>
        . Their disclosure is their own. They are not a continuation of the sample run
        above, and they are not a prediction for another computer.
      </p>
      {supplements ? (
        <BenchTables data={supplements} label="Disclosure for the supplement run" />
      ) : (
        <p className="mt-4 text-sm text-[var(--muted)]">No supplement run was recorded.</p>
      )}
      <h2 className="mt-12 font-serif text-3xl">Companion tools, measured separately</h2>
      <p className="mt-3 leading-7">
        grep, awk, compression, xargs, sed -i, sparse tar, and a CPU pin were measured
        with the same style of harness and written to{" "}
        <a className="underline" href={withBase("/benchmarks/companions.json")}>
          companions.json
        </a>
        . None of those tools are GNU coreutils. The disclosure in that file is the one
        that applies, including the tool versions. These medians are not part of the
        sample run or the supplement run. Tools that were not installed, including perf,
        are described in the lessons without a timing.
      </p>
      {companions ? (
        <BenchTables data={companions} label="Disclosure for the companion run" />
      ) : (
        <p className="mt-4 text-sm text-[var(--muted)]">No companion run was recorded.</p>
      )}
    </div>
  );
}
