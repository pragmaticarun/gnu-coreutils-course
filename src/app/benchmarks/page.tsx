import { getBenchmarks, getCourse } from "@/lib/content";
import { withBase } from "@/lib/utils";

export const metadata = { title: "Benchmarks" };

function fmt(value: number, digits = 4) {
  return value.toFixed(digits);
}

export default function BenchmarksPage() {
  const course = getCourse();
  const data = getBenchmarks();
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
        <div className="mt-8 space-y-8">
          <section className="rounded-xl border border-[var(--line)] bg-[var(--bg-elev)] p-4 text-sm leading-6">
            <h2 className="font-serif text-2xl">Disclosure for the sample run</h2>
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
      )}
    </div>
  );
}
