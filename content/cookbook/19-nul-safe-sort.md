---
number: 19
slug: nul-safe-sort
title: Sort names that may contain newlines
module: Cookbook
level: advanced
minutes: 18
summary: sort -z keeps a newline inside a filename. A line-oriented sort splits that name into two records. find -print0 is findutils; sort -z is coreutils.
manual: sort invocation | https://www.gnu.org/software/coreutils/manual/html_node/sort-invocation.html
gnu_vs_bsd: |
  GNU `sort -z` uses NUL as the record separator. BSD sort does not take that flag. `LC_ALL=C` is byte order on both GNU and a locale-aware libc, and it is the order this recipe asks for. `find -print0` is findutils, not coreutils, on Ubuntu. This recipe did not run a BSD sort.
---

An inventory of ordinary names can be one line per name. The compare-sets recipe is that case, and it says the inputs have to be sorted. A filename may contain a newline. The moment it does, `find | sort` counts two records for one file and the later `comm` compares pieces of a name. `find -print0` emits NUL-terminated paths. `sort -z` orders those records. `uniq -z` would collapse duplicates. Stop there if the next tool reads lines.

`LC_ALL=C` is byte order. A UTF-8 locale is a different order, and a NUL-safe pipeline that changes locale between `sort` and a later check is not one contract. `tr '\0' '\n'` is a display step for humans, and it lies when a name contains a newline. Count the NULs, or use `od`, until you have proved the names are one line each.

The line-oriented counterexample is the same directory fed to `find | wc -l`. Two files, one of them with a newline in the name, are three lines. `sort -z` of the NUL stream still has two records. The assertion script is [sandbox/nul-safe-sort.sh](/sandbox/nul-safe-sort.sh). `find` in that script is findutils. The badge on the worked example says so.

## Steps

```run
# title: Three NUL records stay three
printf 'b\0a\nname\0a\0' | LC_ALL=C sort -z | tr -cd '\0' | wc -c
printf 'b\0a\nname\0a\0' | LC_ALL=C sort -z | od -An -tx1
```

```run
# title: find produces, sort orders
# companion: findutils find
mkdir -p names
printf x > names/b.txt
printf x > "names/a
name.txt"
find names -type f -print0 | LC_ALL=C sort -z | tr -cd '\0' | wc -c
find names -type f | wc -l
```

## Check yourself

```exercise
expect-exit: 0
---title---
Three records, byte order
---prompt---
Sort the NUL records `b`, `a<newline>name`, and `a` with `LC_ALL=C sort -z`. Count the NUL bytes in the output.
---hint---
`printf 'b\0a\nname\0a\0'` is three terminated records. `sort -z` does not drop the terminators.
---hint2---
`tr -cd '\0'` keeps only NUL bytes. `wc -c` counts them. The count is the number of records, not the number of lines a terminal would draw.
---solution---
The count is 3. `od` shows `61 00` (`a` and NUL) before the record that contains `0a`, then `62 00` (`b` and NUL). Byte order puts `a` before `a\nname` before `b`.
---script---
printf 'b\0a\nname\0a\0' | LC_ALL=C sort -z | tr -cd '\0' | wc -c
```

```exercise
expect-exit: 0
---title---
findutils produces, coreutils orders
---prompt---
Create `names/b.txt` and a file whose name contains a newline. Count NUL records from `find -print0 | LC_ALL=C sort -z`, then count lines from `find` without `-print0`.
---hint---
`find` is findutils. `sort -z` is coreutils. Say so when you use both.
---hint2---
`-type f` skips the directory. A newline in one name adds a line and does not add a file. The NUL count stays at the file count.
---solution---
The NUL count is 2. The line count is 3. The line-oriented sort would order fragments. The NUL sort orders names.
---script---
mkdir -p names
printf x > names/b.txt
printf x > "names/a
name.txt"
find names -type f -print0 | LC_ALL=C sort -z | tr -cd '\0' | wc -c
find names -type f | wc -l
```

## Performance

`sort -z` is not a faster sort. It is the sort that does not split the key on a newline. The comparison work is the same order of cost as a line sort of the same bytes, and the benchmark page's locale and buffer trials are about that cost on newline-terminated text. A pipeline that converts NULs to newlines so a tool without `-z` can run is the expensive one in the sense that it is wrong and then gets rerun. Do not add `-z` to a sort of a million ordinary lines to make it quicker. Add it when the records are names.
