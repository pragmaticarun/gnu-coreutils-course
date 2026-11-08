---
number: 26
slug: shuf-and-random
title: shuf, random sources, and tsort
module: Order and uniqueness
level: advanced
minutes: 28
summary: shuf has no --seed. Reproducible draws come from --random-source. sort -R hashes keys. tsort orders a dependency graph.
objectives:
  - Draw a sample with shuf -n and repeat it with --random-source
  - State that --seed does not exist on this shuf
  - Contrast sort -R with shuf
  - Order a three-node dependency list with tsort
manual: shuf invocation | https://www.gnu.org/software/coreutils/manual/html_node/shuf-invocation.html
manual: Random sources | https://www.gnu.org/software/coreutils/manual/html_node/Random-sources.html
manual: tsort invocation | https://www.gnu.org/software/coreutils/manual/html_node/tsort-invocation.html
gnu_vs_bsd: |
  `shuf` is GNU. macOS has no shuf in the base system. There is no `--seed` in GNU shuf 9.4; reproducibility is `--random-source`. `sort -R` is GNU. `tsort` exists in BSD with the same pair-per-line idea and different diagnostics. `ptx` is the other specialized GNU text tool and is not required to sample a test suite. This lesson did not run BSD shuf because there is nothing to run.
---

`shuf` writes a permutation of its input, or of an integer range with `-i`. `-n` stops after N lines. `-r` repeats, which can generate duplicates and will run forever if you forget `-n`. The permutation is not a sort. Equal lines stay equal as values; their positions change.

GNU shuf does not accept `--seed`. Scripts that pass it fail. The manual's random-source node describes `--random-source=FILE`: the file supplies the bytes that drive the choice. The same file and the same input produce the same permutation. `/dev/zero` is a deterministic source of zero bytes and is enough to show repeatability in a lesson. It is a poor source for a statistical sample because it is not random. For a real sample, use the kernel's generator and accept that the run will not match next time, or store the source file next to the result if you must reproduce a bug. The benchmark seed in this course is for Python's `random.Random`, which is a different generator. Do not conflate it with shuf.

`sort -R` assigns a random hash to each key and sorts the hashes. Lines with the same key stay together. `--random-source` fixes the hash function the same way. It is not a shuffle of identical keys. Use shuf when every line is an independent item. Use `sort -R` when you need grouping. Neither is a cryptographic shuffle, and neither belongs in a secret-splitting scheme.

`tsort` reads pairs and prints a topological order. Input `a b` means `a` precedes `b`. A cycle is an error. It is the coreutils tool for "compile these in an order that respects edges" when you already have a pair list. It is not `make`, and it does not read a `Cargo.toml`. A small graph is a good test of a build-system idea. A large graph with cycles needs the diagnostic, not a forced order.

`ptx` builds a permuted index. It is in the reference. It is not part of the sampling path. Mentioning it here keeps it from being mistaken for `shuf`.

## Worked examples

### The same draw twice

```run
# title: --random-source repeats
/usr/bin/printf 'a\nb\nc\nd\n' > items
/usr/bin/shuf --random-source=/dev/zero -n 2 items > one
/usr/bin/shuf --random-source=/dev/zero -n 2 items > two
/usr/bin/cat one
/usr/bin/sha256sum one two
```

### An integer range

```run
# title: shuf -i
/usr/bin/shuf --random-source=/dev/zero -n 3 -i 1-5
```

### sort -R is stable for a fixed source

```run
# title: Two sort -R runs
/usr/bin/printf 'a\nb\nc\n' | /usr/bin/sort -R --random-source=/dev/zero > one
/usr/bin/printf 'a\nb\nc\n' | /usr/bin/sort -R --random-source=/dev/zero > two
/usr/bin/cat one
/usr/bin/sha256sum one two
```

### A dependency order

```run
# title: tsort
/usr/bin/printf 'a b\nb c\n' | /usr/bin/tsort
```

## Recipes

Pick three tests out of a list in CI when you need a short run, and check in the `--random-source` file if a failure must be reproducible. Otherwise record the chosen names in the log so the next run can repeat them without reconstructing the RNG.

Order a handful of build steps expressed as pairs with `tsort` when you are prototyping and do not want a full make graph yet. Move to a real build tool when the graph grows.

## Tips and pitfalls

`shuf file -n 2` reads the whole file. It is not a constant-memory sample of a multi-gigabyte line file. If you need a reservoir sample of a huge log, write it in the language that owns the log, or accept the memory cost knowingly.

`/dev/zero` as a random source makes the lesson deterministic and makes a statistical test meaningless. Do not publish a distribution you drew from zeros.

`tsort` on a cycle exits non-zero and prints a diagnostic. Feed it a cycle only when you are testing the failure.

## Exercises

```exercise
expect-exit: 0
---title---
Repeat a one-line draw
---prompt---
Shuffle `a b c` with `--random-source=/dev/zero` and `-n 1` twice, and print both results.
---hint---
Run shuf twice.
---solution---
The two lines match. That is the source file doing its job, not a property of /dev/zero as entropy.
---script---
/usr/bin/printf 'a\nb\nc\n' > items
/usr/bin/shuf --random-source=/dev/zero -n 1 items
/usr/bin/shuf --random-source=/dev/zero -n 1 items
```

```exercise
expect-exit: 0
---title---
Order three nodes
---prompt---
tsort the pairs `lib app` and `app test`, meaning lib before app before test.
---hint---
One pair per line.
---solution---
A valid order is lib, app, test. tsort prints one node per line.
---script---
/usr/bin/printf 'lib app\napp test\n' | /usr/bin/tsort
```

```exercise
expect-exit: 0
---title---
Hash two identical random sorts
---prompt---
Run `sort -R --random-source=/dev/zero` twice on `a b c` and sha256sum the two outputs.
---hint---
Write each output to a file.
---solution---
The digests match. The permutation is fixed by the source file.
---script---
/usr/bin/printf 'a\nb\nc\n' | /usr/bin/sort -R --random-source=/dev/zero > one
/usr/bin/printf 'a\nb\nc\n' | /usr/bin/sort -R --random-source=/dev/zero > two
/usr/bin/sha256sum one two
```

## Performance

`shuf` reads the whole input to permute it. Memory grows with the file. That is the limit to plan for, not CPU. `-n` does not save the read of a named file in the simple implementation you should assume; check `--help` and test a large file before you promise a streaming sample. `sort -R` is a full sort plus hashing, so it has the same spill behavior as sort. `--random-source` adds reads of the source file and does not change the big-O of the sort. `tsort` is for graphs that fit in memory. A dependency graph of a large monorepo belongs in a build tool that can persist it. None of these tools are cheaper than "do not shuffle the corpus on every test run". Shuffle once, record the sample, and reuse the names.
