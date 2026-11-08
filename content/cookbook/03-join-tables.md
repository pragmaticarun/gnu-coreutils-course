---
number: 3
slug: join-tables
title: Join two sorted tables on a key
module: Cookbook
level: intermediate
minutes: 16
summary: join merges sorted files on a field. Unsorted input is diagnosed. --nocheck-order hides the diagnosis and can emit a wrong join.
manual: join invocation | https://www.gnu.org/software/coreutils/manual/html_node/join-invocation.html
gnu_vs_bsd: |
  POSIX `join` requires sorted inputs. GNU join checks order by default, writes a diagnostic, and exits 1, sometimes after partial stdout. BSD join may omit that check. Field numbers and the default separator are shared. This recipe used GNU join.
---

`join` matches lines that share a key and writes one line with the key and the remaining fields. The default key is field one. The default separator is whitespace. Both files must be sorted on that key. `printf '1 red\n2 blue\n'` joined with `printf '1 apple\n2 berry\n'` yields two lines. The same files with a key out of order make GNU join complain. The complaint can arrive after some output has already been written, and the status is 1. `--nocheck-order` suppresses the check, exits 0, and can miss pairs. A green status from that flag is not evidence the join is complete.

Keys that appear only on one side are omitted by default. `-a 1` or `-a 2` keeps the unpaired lines, which is the closest join has to an outer join. It is still not SQL. There is no quoting, no numeric coercion, and no "last field" syntax. If the key is field 2 you pass `-1 2 -2 2` and you sort on field 2 as well, with `sort -k2,2`. Sorting on the whole line and joining on field 2 is a mismatch.

Empty fields and repeated keys multiply rows. Two left rows with key `1` and two right rows with key `1` produce four output rows. Know your cardinality before you treat the output as a lookup.

## Steps

```run
# title: Join on field one
/usr/bin/printf '1 red\n2 blue\n' > colors
/usr/bin/printf '1 apple\n2 berry\n' > fruit
/usr/bin/join colors fruit
```

```run
# title: Unsorted input is an error
set +e
/usr/bin/printf '2 blue\n1 red\n' > colors
/usr/bin/printf '1 apple\n2 berry\n' > fruit
/usr/bin/join colors fruit
/usr/bin/printf 'status:%s\n' $?
set -e
```

## Check yourself

```exercise
expect-exit: 0
---title---
Join two sorted pairs
---prompt---
Join `1 red` / `2 blue` with `1 apple` / `2 berry`.
---hint---
Both files are already sorted on the first field.
---solution---
Two lines, `1 red apple` and `2 blue berry`.
---script---
/usr/bin/printf '1 red\n2 blue\n' > colors
/usr/bin/printf '1 apple\n2 berry\n' > fruit
/usr/bin/join colors fruit
```

## Performance

`join` is a merge, linear in the number of lines, after the sorts. The sort is the part that spills. Do the sort once and keep the files if you will join them again. A database is the right tool when you need indexes, unsorted inserts, and repeated joins. Coreutils join is the right tool when you already have two sorted exports and you want no server. `--nocheck-order` does not make the merge faster in a way that pays for a wrong answer. Leave the check on. If it fires, sort the input and rerun rather than timing the broken run.
