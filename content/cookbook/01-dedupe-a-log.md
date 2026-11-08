---
number: 1
slug: dedupe-a-log
title: Collapse repeated log lines
module: Cookbook
level: intermediate
minutes: 15
summary: sort and uniq -c show which lines repeat. sort -u drops duplicates when the whole line is the key.
manual: sort invocation | https://www.gnu.org/software/coreutils/manual/html_node/sort-invocation.html
manual: uniq invocation | https://www.gnu.org/software/coreutils/manual/html_node/uniq-invocation.html
gnu_vs_bsd: |
  POSIX `sort` and `uniq` exist on BSD. GNU `sort -u` is not the same as `sort | uniq` when the sort key is narrower than the whole line. BSD sort keys use a different flag spelling for field separators. This recipe ran GNU sort and uniq only.
---

A log that repeats the same line a thousand times is hard to read and easy to count. `sort` groups identical lines together. `uniq -c` prefixes each group with the count. `sort -u` prints each distinct line once and is the right tool when you want the set of lines and you are sorting the whole line. It is the wrong tool when a key flag ignores part of the line: `sort -u` still emits one row per key, and `sort | uniq` only collapses rows that are entirely identical after the sort. The sort lesson demonstrates that difference. This recipe uses the whole line, so the two forms agree.

The input has to be sorted for `uniq` to see a run of duplicates. `uniq` does not search the whole file for a match that occurred earlier. That is why the pipeline is `sort | uniq` and not `uniq` alone on a raw log. If you need the original order, you are outside what this pair promises. A language with an ordered set is the honest tool then, or `awk` (a companion, and mawk on this host) with an associative array.

Counts from `uniq -c` are padded. `sort -n` orders those count lines numerically if you want the noisiest line first. The padding is spaces, so a plain lexical sort of the count output is the wrong order once counts reach two digits.

## Steps

```run
# title: Count duplicate lines
/usr/bin/printf 'b\na\nb\nb\na\n' > log
/usr/bin/sort log | /usr/bin/uniq -c
```

```run
# title: One copy of each line
/usr/bin/printf 'b\na\nb\nb\na\n' > log
/usr/bin/sort -u log
```

## Check yourself

```exercise
expect-exit: 0
---title---
Count three identical lines
---prompt---
Write `err` three times and print `uniq -c` after sorting.
---hint---
The count is the first field.
---solution---
One output line, count 3, text `err`.
---script---
/usr/bin/printf 'err\nerr\nerr\n' > log
/usr/bin/sort log | /usr/bin/uniq -c
```

## Performance

Sorting is the expensive part once the log no longer fits in the sort buffer. `uniq` is a linear scan of an already ordered stream. Do not run `sort | uniq` and then `sort -u` on the same huge file if you only needed one of them. Give `sort` a `-T` directory on a filesystem with room when the log is large. The benchmark page measures sort with a fixed input and does not measure your production log. Locale collation changes both the order and the CPU cost. `LC_ALL=C` is appropriate when the lines are byte strings and you do not need dictionary order.
