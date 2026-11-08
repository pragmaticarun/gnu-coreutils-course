---
number: 25
slug: uniq
title: uniq only sees neighbors
module: Order and uniqueness
level: intermediate
minutes: 26
summary: uniq collapses adjacent equal lines. It does not search the file. sort makes the equals adjacent, and the locale decides what equal means.
objectives:
  - Show a non-adjacent duplicate surviving uniq -d
  - Count, isolate duplicates, and isolate uniques with -c, -d, and -u
  - Fold case with -i after an LC_ALL=C sort
  - Contrast sort -u on a key with uniq on the whole line
manual: uniq invocation | https://www.gnu.org/software/coreutils/manual/html_node/uniq-invocation.html
manual: sort invocation | https://www.gnu.org/software/coreutils/manual/html_node/sort-invocation.html
gnu_vs_bsd: |
  POSIX uniq requires adjacent lines. GNU adds `-z`, `-D`, and a few field-skipping options (`-f`, `-s`, `-w`). BSD uniq has `-c`, `-d`, and `-u` and not the GNU NUL mode. `sort | uniq` versus `sort -u` diverges once keys are involved, on GNU, as the sort manual states. Captures are GNU 9.4.
---

`uniq` walks the file once and compares each line to the previous line. If you hand it `a`, `b`, `a`, the two `a` lines are not adjacent, so `-d` prints nothing and the default output keeps both `a` lines with `b` between them. Sort first if "unique in the whole file" is what you meant. The sort has to use the same notion of equality. `LC_ALL=C sort` then `LC_ALL=en_US.UTF-8 uniq` can fail to merge lines the first command separated, or merge lines it should not, depending on the bytes. Put the same `LC_ALL` on both.

`-c` prefixes a count of the adjacent run. `-d` prints one copy of lines that were repeated. `-u` prints lines that occurred once. `-D` prints all lines that were part of a repeated run. `-i` folds case for the comparison. After `LC_ALL=C sort` of `A` then `a`, `uniq -i` keeps `A`, the first of the run, because C order put `A` first and `-i` then called them equal. The survivor is the first line, not the lowercase one. If you needed the lowercase survivor, transform case before you uniq, and accept that `tr` is the wrong transform for non-ASCII.

`-f` skips fields and `-s` skips characters before comparing. `-w` limits the compare to N characters. Those options do not reorder the file. They only change which adjacent lines count as equal. If the file is not grouped by that key, the result is still wrong.

`sort -u` unique-sorts by the sort key and suppresses the last-resort compare. `sort | uniq` unique-sorts whole lines. For a two-field line where only the first field should define identity, `sort -k1,1 -u` is the operation and `uniq` is not, unless you cut the key out first. The manual's warning is the one to remember before you "simplify" a pipeline.

`-z` compares NUL-terminated records. Use it with `sort -z` on file names. A newline-uniq of a NUL stream does not see the record boundaries you created.

## Worked examples

### Neighbors only

```run
# title: A duplicate that is not adjacent
/usr/bin/printf 'a\nb\na\n' | /usr/bin/uniq -d | /usr/bin/wc -c
/usr/bin/printf 'a\na\nb\n' | /usr/bin/uniq -d
```

### Counts

```run
# title: uniq -c after a sort
/usr/bin/printf 'b\na\nb\n' | /usr/bin/sort | /usr/bin/uniq -c
```

### Case fold in the C locale

```run
# title: First line wins
# env: LC_ALL=C
/usr/bin/printf 'a\nA\n' | /usr/bin/sort | /usr/bin/uniq -i
```

### Key uniqueness is sort -u

```run
# title: sort -k1,1 -u versus uniq
/usr/bin/printf 'a x\na y\n' | /usr/bin/sort -k1,1 -u
/usr/bin/printf 'a x\na y\n' | /usr/bin/sort | /usr/bin/uniq
```

## Recipes

Count events in a log: `cut` the event field if it is delimiter-safe, `sort`, `uniq -c`, `sort -nr` to put the heavy counts first. The second sort is numeric on the count uniq printed. `LC_ALL=C` if the event ids are bytes.

For a set of package names, `sort -u` is enough and uniq is an extra process. Use uniq when you need the count or the `-d`/`-u` split.

## Tips and pitfalls

`uniq` without sort is valid when the producer already grouped rows, for example a database export that was ordered. Say that in the script. A future producer that changes order will silently break the report.

`-i` is not Unicode casefold. It uses the locale's case mapping on the bytes uniq compares. Test non-ASCII before you depend on it. The tr lesson showed how byte tools treat `é`.

The count format is space-padded. `cut` on that line is fragile. `awk` (not coreutils, and on this host it is mawk) is the usual field splitter. If you stay in coreutils, keep the count as the sort key and do not re-cut it unless you have frozen the format.

## Exercises

```exercise
expect-exit: 0
---title---
Collapse an adjacent run
---prompt---
uniq the lines `a`, `a`, `b`.
---hint---
They are already grouped.
---solution---
`a` once, then `b`.
---script---
/usr/bin/printf 'a\na\nb\n' | /usr/bin/uniq
```

```exercise
expect-exit: 0
---title---
Count after sorting
---prompt---
Count runs in `b`, `a`, `b`.
---hint---
sort then uniq -c.
---solution---
`a` once and `b` twice. The padding is part of uniq -c's format.
---script---
/usr/bin/printf 'b\na\nb\n' | /usr/bin/sort | /usr/bin/uniq -c
```

```exercise
expect-exit: 0
---title---
Show a non-adjacent duplicate ignored by -d
---prompt---
Run uniq -d on `a`, `b`, `a` and then wc -c the output.
---hint---
No sort.
---solution---
Zero bytes. The duplicate was not a neighbor.
---script---
/usr/bin/printf 'a\nb\na\n' | /usr/bin/uniq -d | /usr/bin/wc -c
```

## Performance

`uniq` is linear and cheap. The sort in front of it is the cost. A pipeline `sort | uniq -c | sort -nr` sorts twice. If you only needed the counts and not a ranked list, stop after uniq. `sort -u` is one process instead of two for the simple unique case, and it can be faster because it never writes the duplicate lines to a pipe. It is not faster when you needed the counts, because it throws the multiplicity away. Do not replace `uniq -c` with `sort -u` to "speed up" a frequency report. You get a different answer. Large sorts spill, as the sort lesson described. uniq itself does not spill; it only needs the previous line.
