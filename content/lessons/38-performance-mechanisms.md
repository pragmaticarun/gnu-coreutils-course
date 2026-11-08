---
number: 38
slug: performance-mechanisms
title: Mechanisms that decide speed
module: How the toolbox thinks
level: advanced
minutes: 32
summary: Locale collation, stdio buffering, external sort, sparse files, and reflink decide cost. This lesson shows the mechanisms with captured behavior and points at the benchmark page for numbers.
objectives:
  - Contrast LC_ALL=C byte order with a locale sort of the same four lines
  - Read wc -l as a newline count, including a file that has none
  - Show a sparse file's apparent size against its allocated size
  - Watch cp --reflink=always fail on this filesystem and --reflink=auto fall back
manual: sort invocation | https://www.gnu.org/software/coreutils/manual/html_node/sort-invocation.html
manual: wc invocation | https://www.gnu.org/software/coreutils/manual/html_node/wc-invocation.html
manual: cp invocation | https://www.gnu.org/software/coreutils/manual/html_node/cp-invocation.html
manual: du invocation | https://www.gnu.org/software/coreutils/manual/html_node/du-invocation.html
gnu_vs_bsd: |
  `LC_ALL=C` selects the POSIX collation on both GNU and BSD, but the name of the UTF-8 locale and the default sort differ. GNU `cp --reflink` is a GNU and Linux feature. BSD `cp` on macOS uses `clonefile` under different flags, and a failure mode from ext4 does not transfer. GNU `wc` and BSD `wc` both count newlines for `-l`, which is the fact this lesson uses. No timing number in this lesson was copied from a BSD machine, and none was invented. Measured trials live on the benchmark page.
---

Speed in coreutils is a property of a bottleneck, not a property of a flag you can memorize as "the fast one". The same `sort` is cheap on a thousand integers and expensive when it spills. The same `cp` is a metadata operation when the filesystem can share extents, and a full read-write when it cannot. The same `wc -l` is a streaming scan that never builds a line list. This lesson fixes the mechanisms. The benchmark page is where a fixed input, a seed, five trials, and a median are recorded, with the version, the filesystem, and the warm-cache limit written next to the numbers. If a gap there is smaller than the spread of the trials, the page says not to rank the variants. This lesson does not add a second, quieter ranking.

Collation is the first mechanism people trip over. `LC_ALL=C` compares bytes. `en_US.UTF-8` groups case and applies the locale's weights, so the same four letters come out in a different order. The work is not "more flags". The work is a heavier comparison function, called once per pair the algorithm needs, and it cannot be skipped by `-S` or `--parallel`. Those flags change memory and thread count for the external merge. They do not switch the comparator. `sort -S` sets the main buffer. The manual's unit rules are picky: a bare number is 1024-byte units, `K` is 1024, `M` is 1048576, `%` is a percent of memory. The buffer can still grow to hold a long line. `-T` chooses the spill directory and overrides `TMPDIR`. `--parallel` defaults to the available processors and is capped at 8, and the manual warns that the merge wants memory that grows with the thread count. `--compress-program` must compress stdin to stdout and decompress with `-d`. All of that is in the sort lesson with a captured spill log. The benchmark page repeats the comparison on a fixed input and reports medians. A single interactive run is not that page.

Buffering is the second mechanism. A program that uses stdio and writes to a pipe uses a large block buffer by default. The reader sees nothing until the block fills or the writer exits. `stdbuf -oL` requests a line buffer by preloading `libstdbuf.so`. It does not apply to `cat` and `dd`, which do not use stdio for their data, and `tee` resets its own buffering. The latency you care about in a progress pipe is time-to-first-byte. The throughput you care about in a checksum is bytes per second of the hash, and line buffering can make that worse by issuing more writes. The buffering benchmark records a first-byte delay. Read it as a delay, not as a claim that line buffering is faster.

`wc` is the model of a streaming tool. `wc -l` counts newline bytes. `printf 'abc' | wc -l` is 0. `wc -c` on the same bytes is 3. `wc -m` counts characters and has to decode UTF-8, so it is the slower mode when the locale is multibyte and the file is large. The benchmark page runs `-c`, `-l`, and `-m` on one generated ASCII file so the difference is the scan, not a different input. Do not quote those medians as the cost of Unicode. The input is ASCII on purpose.

Filesystem shape is the fourth mechanism. `truncate -s 1M` creates a hole. `stat` shows a large size and zero allocated blocks on this filesystem. `du -b` reports the apparent size. `du -B1` reports the allocation, which is 0 for that fresh hole. A backup tool that reads the apparent size copies a megabyte of zeros. A tool that copies extents can keep the hole. `cp --reflink=always` on this ext4 asks for a clone and fails with "Operation not supported". `--reflink=auto` falls back to a copy and exits 0. The benchmark page compares a plain copy with `dd` on an 8 MiB file and says the filesystem up front. It does not claim reflink won, because reflink did not work here.

Caches sit under all of this. The course creates inputs and rereads them. The page cache holds the data. Nobody ran `drop_caches`, and an ordinary user cannot. A second trial is warmer than a first trial on a quiet machine and still not a cold-disk number. RSS is Linux `ru_maxrss` in kibibytes, taken from a short Python helper that waits for the child, so the elapsed time includes the helper. Compare variants that share the helper. Do not publish the absolute seconds as the cost of `sort` alone.

NUL-terminated names, `sort -z`, and `find -print0` (find is findutils) avoid a class of correctness bugs that become performance bugs when a script splits names on newlines and then reruns. They are not faster. They are the version that processes the names you actually have.

## Worked examples

### The same four lines, two collations

```run
# title: C byte order and locale order
/usr/bin/printf 'b\nA\na\nB\n' | LC_ALL=C /usr/bin/sort
/usr/bin/printf '---\n'
/usr/bin/printf 'b\nA\na\nB\n' | LC_ALL=en_US.UTF-8 /usr/bin/sort
```

### wc counts newlines

```run
# title: No newline means zero lines
/usr/bin/printf 'abc' | /usr/bin/wc -l
/usr/bin/printf 'abc' | /usr/bin/wc -c
```

### A hole is not a megabyte of allocation

```run
# title: truncate, stat, and du
/usr/bin/truncate -s 1M hole
/usr/bin/stat -c 'size=%s blocks=%b' hole
/usr/bin/du -b hole
/usr/bin/du -B1 hole
```

### Reflink is a request, not a promise

```run
# title: cp --reflink=always and --reflink=auto
/usr/bin/printf 'data\n' > src
set +e
/usr/bin/cp --reflink=always src dst
/usr/bin/printf 'always:%s\n' $?
set -e
/usr/bin/cp --reflink=auto src dst2
/usr/bin/wc -c dst2
```

## Recipes

When a sort in a script starts hitting the disk, look at `-S` and `-T` and the comparator before you look at `--parallel`. A locale comparator on short keys is a different bottleneck from a merge that spilled to a small `/tmp`. The sort lesson's compress-program example shows the spill as a count of compressor invocations, not as a made-up duration.

When a copy of a build tree is slow, check whether the files are many and small. The cost is metadata. Reflink would not have removed the per-file syscall even on a filesystem that supports it. `du -d 1` tells you which directory dominates. `df` tells you whether the filesystem has room. They answer different questions, and the du lesson keeps them apart.

When a pipeline "hangs" and the CPU is idle, suspect a block buffer. Reproduce with a slow producer and `stdbuf -oL` on the stage that uses stdio. If nothing changes, the stage is not an stdio program.

## Tips and pitfalls

A flag that helps a spill hurts a sort that already fit in RAM, because compression and threads have overhead. The benchmark page is allowed to show a tie. A tie is a result.

`LC_ALL=C` changes more than sort. It changes `ls` order, character classes, and the decimal point. Set it for the one command that needs byte order, not for an entire build, unless you mean it.

Apparent size and allocated size are both "the size". Say which one you measured. A chart that mixes `du -b` and `du -B1` without labels is how a sparse image looks like it doubled.

## Exercises

```exercise
expect-exit: 0
---title---
Sort four letters in the C locale
---prompt---
Sort `b`, `A`, `a`, `B` with `LC_ALL=C`.
---hint---
Byte order puts uppercase before lowercase.
---solution---
`A`, `B`, `a`, `b` on four lines.
---script---
/usr/bin/printf 'b\nA\na\nB\n' | LC_ALL=C /usr/bin/sort
```

```exercise
expect-exit: 0
---title---
Count lines of a string with no newline
---prompt---
Pipe `printf 'abc'` through `wc -l` and `wc -c`.
---hint---
`-l` counts newline bytes.
---solution---
The line count is 0. The byte count is 3.
---script---
/usr/bin/printf 'abc' | /usr/bin/wc -l
/usr/bin/printf 'abc' | /usr/bin/wc -c
```

```exercise
expect-exit: 0
---title---
Ask for a clone and record the fallback
---prompt---
Copy `src` with `--reflink=auto` after writing `data` and a newline. Print the byte count of the destination.
---hint---
`auto` may copy. `always` is allowed to fail on this filesystem.
---solution---
The destination is 5 bytes. The status of `--reflink=auto` is 0 here even though a forced clone is not supported.
---script---
/usr/bin/printf 'data\n' > src
/usr/bin/cp --reflink=auto src dst
/usr/bin/wc -c dst
```

## Performance

There is no closing trick that makes every coreutils command faster. The levers that exist are real and local. Use a byte-order locale when the comparator is the cost and the order is allowed to be byte order. Give `sort` a buffer and a spill disk when the input does not fit, and do not assume more threads help once the cap and the memory formula are against you. Stream with `wc`, `cut`, and `tr` instead of loading the file. Copy extents only when the filesystem says yes, and time the fallback you will actually run. Keep names NUL-terminated so you do not redo the job after a split. Measure with the benchmark scripts, five trials, a median, and the disclosure block. A number without that block is a story. This course refuses the story.
