---
number: 2
slug: compare-sets
title: Compare two sorted sets with comm
module: Cookbook
level: intermediate
minutes: 15
summary: comm prints lines only in the first file, only in the second, and in both. The inputs have to be sorted or the result is a partial lie.
manual: comm invocation | https://www.gnu.org/software/coreutils/manual/html_node/comm-invocation.html
gnu_vs_bsd: |
  POSIX `comm` is shared. GNU comm checks that the inputs look ordered and can exit 1 while still printing. `--nocheck-order` disables the check and can pair the wrong lines. BSD comm may not perform the same check. This recipe ran GNU comm on sorted inputs.
---

`comm` is the set operation for line-oriented files. Column one is lines only in the first file. Column two is lines only in the second. Column three is lines in both. `-1`, `-2`, and `-3` suppress columns, so `comm -12` is the intersection and `comm -13` is "in the second file but not the first" when you remember which digit you deleted. The files must be sorted with the same locale you use for `comm`. A file sorted under `en_US.UTF-8` and compared under `LC_ALL=C` is not ordered in the way comm expects.

GNU comm notices unsorted input, prints a diagnostic, and exits 1. It may already have printed some lines. That partial output is not a complete answer. `--nocheck-order` exits 0 and can still pair lines incorrectly. Do not use it to silence a real order bug. Sort both files in the pipeline that feeds comm, with an explicit `LC_ALL` so the CI locale matches your laptop.

Blank lines and duplicate lines are data. `comm` does not unique them unless you did. If you wanted sets, run `sort -u` first and accept that you threw away multiplicity.

## Steps

```run
# title: Three columns
/usr/bin/printf 'a\nb\nc\n' > left
/usr/bin/printf 'b\nc\nd\n' > right
/usr/bin/comm left right
```

```run
# title: Intersection only
/usr/bin/printf 'a\nb\nc\n' > left
/usr/bin/printf 'b\nc\nd\n' > right
/usr/bin/comm -12 left right
```

## Check yourself

```exercise
expect-exit: 0
---title---
Lines only on the right
---prompt---
Print lines that are in `right` and not in `left` for the sets a,b,c and b,c,d.
---hint---
Suppress columns 1 and 3.
---solution---
The remaining line is `d`.
---script---
/usr/bin/printf 'a\nb\nc\n' > left
/usr/bin/printf 'b\nc\nd\n' > right
/usr/bin/comm -13 left right
```

## Performance

`comm` is a linear merge. It does not build a hash set. The cost is the two sorts you did to prepare the files, plus a single pass. Sorting twice and then comm is cheaper than a nested shell loop that greps one file per line of the other, and it is correct for duplicates in a way the loop usually is not. The files should already be sorted from the producer when you can arrange that, so you do not pay the sort again. There is no parallel flag worth reaching for at this size. If the inputs are huge, the sort spill is the bill. Point `sort -T` at a disk with space and read the sort lesson before you add `--parallel`.
