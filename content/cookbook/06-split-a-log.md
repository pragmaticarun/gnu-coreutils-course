---
number: 6
slug: split-a-log
title: Split a log into fixed line counts
module: Cookbook
level: beginner
minutes: 14
summary: split -l writes pieces with a prefix. split -n and split -n r/N do not mean the same thing when lines are uneven.
manual: split invocation | https://www.gnu.org/software/coreutils/manual/html_node/split-invocation.html
gnu_vs_bsd: |
  POSIX `split` supports line and byte counts. GNU `split -n` and `-n r/N` are GNU extensions for byte chunks and line round-robin. BSD split does not accept the same `-n` syntax. A one-line input given to `-n r/3` stays in the first piece. This recipe ran GNU split.
---

`split -l 2` reads a text file and writes new files with at most two lines each. The prefix you pass becomes the start of each name, and the suffix is `aa`, `ab`, and so on unless you change it. The pieces are ordinary files. Nothing in split deletes the original. You can checksum the pieces, upload them, or feed them to workers. You should also know how you will put them back: `cat part_*` works when the names sort in order, which they do for the default suffixes until you pass a few hundred pieces and need `-d` numeric suffixes to keep lexical order honest. `split -d` uses numbers. Prefer it when a later `sort` of the names would otherwise surprise you. The default alphabetic suffixes are fine for a handful of chunks.

`split -n 3` divides the file into three byte ranges. It can cut a line in half. `split -n r/3` round-robins lines, and a file with one line puts that entire line in the first piece. The split lesson captured both. Use `-l` or `-n l/N` when the consumer must see whole lines. Use byte splits only when the consumer is a byte tool, such as a parallel checksum of ranges you will concatenate in order.

An empty input creates no glory and may create empty pieces depending on the mode. Check the names with `ls` and the line counts with `wc -l` before you launch a fleet of workers on empty files.

## Steps

```run
# title: Two lines per piece
/usr/bin/printf '1\n2\n3\n4\n5\n' > log
/usr/bin/split -l 2 log part_
/usr/bin/ls part_*
/usr/bin/wc -l part_*
```

```run
# title: One line round-robin stays in the first piece
/usr/bin/printf 'only\n' > one
/usr/bin/split -n r/3 one rr_
/usr/bin/wc -c rr_*
```

## Check yourself

```exercise
expect-exit: 0
---title---
Split five lines
---prompt---
Split a file of five lines into pieces of two lines and list the piece names.
---hint---
`split -l 2` and a prefix.
---solution---
Three pieces. The last one holds the leftover line.
---script---
/usr/bin/printf '1\n2\n3\n4\n5\n' > log
/usr/bin/split -l 2 log part_
/usr/bin/ls part_*
```

## Performance

`split` reads the input once and writes the pieces once. It is disk-bound on a large log and cheap on a small one. Splitting into thousands of tiny files creates a metadata storm that can cost more than the bytes. Choose a piece size that a worker can process without drowning the directory. Round-robin line split is still one read. It does not parallelize the split itself. The parallelism, if any, is the later workers. Concatenating the pieces in the wrong order is a correctness bug, not a performance feature. Numeric suffixes (`-d`) keep the order obvious.
