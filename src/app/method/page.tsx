import { getCourse } from "@/lib/content";

export const metadata = { title: "Method and limits" };

export default function MethodPage() {
  const { meta, companions } = getCourse();
  return (
    <article className="mx-auto max-w-3xl leading-7">
      <h1 className="font-serif text-4xl">Method and limits</h1>
      <p className="mt-4">
        This course was checked against {meta.coreutilsVersion}, Debian/Ubuntu package{" "}
        {meta.packageVersion}. The authoritative local text is {meta.manualLocal}, produced
        for coreutils 9.4. The introduction of that manual says the info document is the
        maintained documentation and that the man pages are no longer maintained. HTML links
        point at {meta.manualHtml}, which tracks the current GNU manual and may describe
        options newer than 9.4. Every flag used in a captured script was present in{" "}
        <code>--help</code> on this host.
      </p>
      <h2 className="mt-8 font-serif text-3xl">Capture environment</h2>
      <ul className="mt-3 list-disc space-y-1 pl-5">
        <li>User: {meta.user}</li>
        <li>uname: {meta.uname}</li>
        <li>Locale forced for examples: {meta.locale}</li>
        <li>umask: {meta.umask}</li>
        <li>df -T filesystem type: {meta.filesystemDf}</li>
        <li>stat -f -c %T type string: {meta.filesystemStat}</li>
        <li>Python used to capture output: {meta.python}</li>
        <li>stdbuf helper: {meta.stdbufLibrary}</li>
        <li>Captured at: {meta.capturedAt}</li>
      </ul>
      <p className="mt-3">{meta.kernelNote}</p>
      <h2 className="mt-8 font-serif text-3xl">What was deliberately not done</h2>
      <ul className="mt-3 list-disc space-y-1 pl-5">
        {meta.limits.map((item) => (
          <li key={item}>{item}</li>
        ))}
      </ul>
      <h2 className="mt-8 font-serif text-3xl">GNU behavior versus BSD behavior</h2>
      <p className="mt-3">
        BSD and macOS notes in each lesson are interface differences taken from
        documentation and from long-standing divergences (for example GNU{" "}
        <code>stat -c</code> versus BSD <code>stat -f</code>, GNU <code>date -d</code>{" "}
        versus BSD <code>date -v</code>, GNU <code>df -T</code> printing a type versus BSD{" "}
        <code>df -T</code> filtering by type). They were not executed on a BSD host in
        this project. Where Ubuntu does not ship the coreutils implementation of a name
        the GNU manual still documents, the lesson says which package owns the binary.
      </p>
      <h2 className="mt-8 font-serif text-3xl">Companions checked on this host</h2>
      <ul className="mt-3 list-disc space-y-1 pl-5">
        {companions.map((tool) => (
          <li key={tool.name}>
            {tool.name}: {tool.installed ? `${tool.package} (${tool.path})` : "not installed"}
          </li>
        ))}
      </ul>
      <h2 className="mt-8 font-serif text-3xl">Benchmarks</h2>
      <p className="mt-3">
        Trials are repeated and the reported center is the median, not the best sample.
        Inputs are written immediately before the reads, so the page cache is warm. That
        understates cold-disk I/O and it can hide a disk bottleneck entirely.{" "}
        <code>ru_maxrss</code> on Linux is kilobytes and is the high-water mark of
        waited-for children of the measurement helper, not a precise heap profile. If two
        medians sit inside each other’s trial spread, the script says the run does not
        separate them.
      </p>
    </article>
  );
}
