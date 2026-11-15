---
number: 50
slug: compression
title: gzip, pigz, bzip2, xz, and zstd
module: Companion Tools
level: advanced
minutes: 40
summary: Five compressors, five upstreams, none of them coreutils. pigz and zstd -T spend cores. Levels trade CPU for bytes. The companion benchmark records both on a repetitive log and on random bytes.
objectives:
  - Name the Ubuntu package and upstream for gzip, pigz, bzip2, xz, and zstd
  - Round-trip a file and keep gzip reproducible with -n
  - Explain pigz -p and zstd -T, including -T0
  - Read ratio and time from the recorded benchmark instead of a slogan
manual: GNU gzip | https://www.gnu.org/software/gzip/manual/gzip.html
manual: pigz | https://zlib.net/pigz/
manual: XZ Utils | https://man7.org/linux/man-pages/man1/xz.1.html
manual: Zstandard | https://facebook.github.io/zstd/zstd.1.html
manual: bzip2 | https://sourceware.org/bzip2/manual/manual.html
manual: Coreutils cksum | https://www.gnu.org/software/coreutils/manual/html_node/cksum-invocation.html
gnu_vs_bsd: |
  BSD ships its own gzip and often a different xz. pigz and zstd are third-party packages there as well. macOS gzip is not GNU gzip 1.12. This lesson ran the Ubuntu binaries only. Levels and thread flags are not identical across those builds.
---

Compression is not coreutils. `gzip` is GNU gzip, Ubuntu package `gzip`. `pigz` is pigz by Mark Adler, Ubuntu package `pigz`, and it writes the same format as gzip using several threads. `bzip2` is the bzip2 package, upstream bzip2. `xz` is XZ Utils, Ubuntu package `xz-utils`. `zstd` is Zstandard, Ubuntu package `zstd`, upstream Facebook's zstd. They differ in format. A file gzip wrote is not a file zstd can read. Round-trip with the same tool, and check the bytes with `cmp`, which is diffutils, or with `sha256sum`, which is coreutils.

`gzip -n` omits the original name and timestamp from the header. Two runs then produce the same bytes. Without `-n`, the header carries the clock and the hash changes. Release artifacts and any test that compares compressed bytes want `-n`. pigz accepts `-n` for the same reason. zstd and xz have their own headers. Do not assume `-n` is universal.

Levels buy ratio with CPU and sometimes with memory. gzip's `-1` is fast and larger, `-9` is slower and smaller, `-6` is a common default. zstd's negative and low levels are very fast, the middle levels are the usual default range, and levels past 19 require `--ultra` and more memory. This course does not time `--ultra`. xz's high levels are slow and memory-hungry. bzip2's block sorting is often the slow choice on both repetitive logs and random bytes, and sometimes still smaller. "Often" is not a number. The benchmark is the number.

Threads are a second axis. `pigz -p 1` uses one worker. `pigz -p 4` uses four. The format stays gzip, so a normal gzip can decompress it. `zstd -T1` is one thread. `zstd -T4` asks for four. `zstd -T0` means one thread per detected core, which changes meaning when you move the script from a laptop to a 64-core builder. Prefer an explicit count in a script. Stacking GNU parallel `-j 4` around `zstd -T4` multiplies the cores. Pick one pool.

The harness in `benchmarks/measure_companions.py` compressed 1 MiB two ways. `compress-compressible` is a repeated log line. `compress-random` is bytes from a seeded PRNG, which will not collapse. Each variant ran five times. The note records the compressed sizes from one extra pass using the same flags. Read both benches. A tool that looks wonderful on the log can tie the others on the random file, because there is no ratio left to win and only the CPU tax remains. Medians include the Python starter. The page cache was warm. Nothing was tuned. The performance section quotes the medians from that file.

Decompression is usually cheaper than compression and is single-threaded in several of these tools even when compression was threaded. A backup you restore often should be timed on the decode, not only on the encode. This course's timed trials are encodes to stdout, discarded by the harness. The lesson examples decode and `cmp` so the round trip is proven on a tiny file. That tiny file is not the benchmark.

## Worked examples

### gzip -n is stable

```run
# title: Two gzip -n streams match
# companion: gzip
/usr/bin/printf 'keep\n' > keep.txt
/usr/bin/gzip -n -c keep.txt > a.gz
/usr/bin/gzip -n -c keep.txt > b.gz
/usr/bin/cmp a.gz b.gz && /usr/bin/printf 'gzip-bytes-match\n'
/usr/bin/gzip -dc a.gz | /usr/bin/cmp - keep.txt
```

### pigz round-trips the gzip format

```run
# title: pigz writes bytes gzip can read
# companion: pigz
/usr/bin/printf 'keep\n' > keep.txt
/usr/bin/pigz -n -c keep.txt > a.gz
/usr/bin/gzip -dc a.gz | /usr/bin/cmp - keep.txt && /usr/bin/printf 'pigz-gzip-roundtrip\n'
```

### bzip2 and xz

```run
# title: bzip2 and xz round-trip
# companion: bzip2
/usr/bin/printf 'keep\n' > keep.txt
/usr/bin/bzip2 -c keep.txt > a.bz2
/usr/bin/bzip2 -dc a.bz2 | /usr/bin/cmp - keep.txt && /usr/bin/printf 'bzip2-ok\n'
/usr/bin/xz -c keep.txt > a.xz
/usr/bin/xz -dc a.xz | /usr/bin/cmp - keep.txt && /usr/bin/printf 'xz-ok\n'
```

### zstd threads on a small file

```run
# title: zstd -T0 still round-trips
# companion: zstd
/usr/bin/printf 'keep\n' > keep.txt
/usr/bin/zstd -q -T0 -c keep.txt > a.zst
/usr/bin/zstd -q -dc a.zst | /usr/bin/cmp - keep.txt && /usr/bin/printf 'zstd-ok\n'
```

## Performance

Ratio and speed move in opposite directions until the data is incompressible, and then speed is the only axis left. Both recorded inputs are 1048576 bytes, five trials, warm cache, thread cap 4 on a 4-CPU host. On the repetitive log, medians were zstd `-1 -T1` 0.0028s and `-1 -T4` 0.0028s (both 172 bytes), gzip `-6` 0.0043s (3141 bytes), xz `-1` 0.0055s (344 bytes), and bzip2 `-1` 0.1096s (2231 bytes). On the seeded random bytes, zstd `-1 -T1` was 0.0037s and `-1 -T4` was 0.0032s, both writing 1048614 bytes, while xz `-1` was 0.1414s and bzip2 `-1` was 0.0836s, both larger than the input. The note's gap is the fastest median versus the slowest, so it shows bzip2 and xz separating from zstd on these files. It does not by itself prove that `-T4` beat `-T1`: those two zstd medians sit on top of each other on the log. Read the rows in `companions.json` before you quote a thread speedup. A multi-gigabyte artifact is a different experiment, and this course did not allocate one.

Memory is the quiet cost. xz at a high level asks for a dictionary you may not want on a small CI runner. zstd `--ultra` does the same. The timed levels are `-6` for gzip and pigz, `-1` and `-6` for zstd, and `-1` for xz and bzip2. Those flags are in the variant names. They are not "maximum compression".

`gzip` without `-c` deletes the input after a successful compress. Scripts in this lesson use `-c` and keep the original. A backup script that deletes the only copy before the archive is safely stored is how people lose the tree. Write to a new name, `cmp` or checksum, then remove.

Pipe throughput is the compressor's write into the next process. `tar -c | zstd` holds the archive format and the compression in two processes, which overlaps tar's read with zstd's CPU when the disk is not the limit. On a warm cache the disk is not the limit. `pv` between them shows the rate and is itself a copy. The throughput lesson explains pv. It is not in these timings.

## Tips and pitfalls

`-T0` and "all the cores" are different numbers on different machines. Write the integer you measured.

pigz's output is gzip. zstd's output is not. Do not rename a `.zst` to `.gz`.

`bzip2` and `xz` exit non-zero on a short read or a corrupt stream. A script that must notice a truncated download should let that status fail the pipeline. `set -o pipefail` is the coreutils-track habit that makes the status visible.

gzip's `-n` does not make the uncompressed content reproducible if the input changed. It only stabilizes the header. The tar lesson stabilizes the archive members.

## Exercises

```exercise
expect-exit: 0
---title---
Round-trip gzip -n
---prompt---
Compress `keep` with `gzip -n -c`, decompress, and cmp against the original.
---hint---
`-dc` decompresses to stdout. cmp the stream with the file.
---hint2---
A successful cmp prints nothing. Add a label after `&&` if you want a word.
---solution---
`gzip-ok` after a silent cmp.
---script---
/usr/bin/printf 'keep\n' > keep
/usr/bin/gzip -n -c keep > keep.gz
/usr/bin/gzip -dc keep.gz | /usr/bin/cmp - keep && /usr/bin/printf 'gzip-ok\n'
```

```exercise
expect-exit: 0
---title---
Let gzip read pigz
---prompt---
Compress with pigz and decompress with gzip. cmp the result.
---hint---
pigz writes the gzip format. `gzip -dc` can read it.
---hint2---
Use `-n -c` so pigz writes to stdout and skips the timestamp.
---solution---
`pigz-ok`.
---script---
/usr/bin/printf 'keep\n' > keep
/usr/bin/pigz -n -c keep > keep.gz
/usr/bin/gzip -dc keep.gz | /usr/bin/cmp - keep && /usr/bin/printf 'pigz-ok\n'
```

```exercise
expect-exit: 0
---title---
Round-trip zstd with an explicit thread count
---prompt---
Compress with `zstd -q -T1 -c` and decompress with `zstd -q -dc`. cmp.
---hint---
`-T1` is one thread. `-T0` would mean all cores and is not what this exercise asks for.
---hint2---
`-q` keeps the banner off stderr.
---solution---
`zstd-ok`.
---script---
/usr/bin/printf 'keep\n' > keep
/usr/bin/zstd -q -T1 -c keep > keep.zst
/usr/bin/zstd -q -dc keep.zst | /usr/bin/cmp - keep && /usr/bin/printf 'zstd-ok\n'
```
