---
number: 45
slug: awk-family
title: awk, mawk, and gawk
module: Companion Tools
level: intermediate
minutes: 40
summary: Ubuntu's awk is mawk. gawk is a second package with functions mawk does not have. A one-pass frequency count is the usual alternative to sort | uniq -c.
objectives:
  - State that awk is not coreutils and that this host's awk is mawk
  - Split fields and total them in one mawk process
  - Show gensub succeeding in gawk and failing in mawk
  - Compare a frequency count with sort | uniq -c without treating one sample as a ranking
manual: GNU awk manual | https://www.gnu.org/software/gawk/manual/html_node/index.html
manual: mawk | https://invisible-island.net/mawk/manpage/mawk.html
manual: Coreutils uniq | https://www.gnu.org/software/coreutils/manual/html_node/uniq-invocation.html
gnu_vs_bsd: |
  BSD awk is closer to the original awk and rejects many gawk extensions, including gensub. macOS /usr/bin/awk is not mawk and not gawk. This lesson ran Ubuntu mawk 1.3.4 and GNU awk 5.2.1 only. No BSD awk was executed.
---

awk is a field language. It is not GNU coreutils. Ubuntu's default awk is mawk. The package is `mawk`, upstream mawk. `/usr/bin/awk` on this capture host resolves to `/usr/bin/mawk` because the alternatives system was set back to mawk after gawk was installed. A stock install of the `gawk` package would have pointed `awk` at GNU awk, because gawk's priority is higher. Do not learn that lesson from a broken build. Run `readlink -f /usr/bin/awk`.

GNU awk is `/usr/bin/gawk`, Ubuntu package `gawk`, upstream GNU awk. It has `gensub`, `FPAT`, and a larger library. mawk does not define `gensub`. A script that works on a laptop where `awk` is gawk fails in CI where `awk` is mawk, with `function gensub never defined` and a non-zero status. The portable subset is fields, patterns, `NF`, arrays, and `printf`. Call `/usr/bin/gawk` when you need the GNU function, and write that path in the script.

`cut` is the coreutils field tool. It splits on a single character and does not evaluate expressions. awk splits on whitespace by default, or on `-F`. It still does not parse CSV quotes. A comma inside quotes is a field break if you set `-F,`. The cookbook recipe about `cut` and CSV applies to awk for the same reason.

The everyday Android and C++ job is a log line with a level and a count. One mawk process can total a column or count keys. `sort | uniq -c` does the count only after `sort` groups equal lines. `uniq` does not see duplicates that are not neighbors. If you only needed the count, the sort is extra work and extra memory. If you needed the lines in order, the sort is the product. The companion benchmark `awk-vs-sort` times mawk against `LC_ALL=C sort | uniq -c` on 200,000 short keys, 40 distinct values. On this host the mawk median was 0.0069s and the sort pipeline median was 0.0237s. The gap was 0.0168s and the widest trial spread was 0.0010s, so the medians separated on this warm-cache input. That is evidence about this file, not a universal ranking. mawk's `END` loop does not promise key order. Pipe it through `sort` when the exercise compares text.

awk reads records. The default record is a line. A file without newlines is one record. `RS` can be changed. It is the wrong place to handle NUL-separated file names. `find -print0` and `xargs -0` stay in the find lesson. You can set mawk's record separator, and you should not pretend that makes awk a safe `find`.

`BEGIN` runs before input. `END` runs after. Patterns select records. `NF` is the field count. `$1` is the first field. `$0` is the whole record. That is enough for most build logs. A program that shells out from inside awk, once per line, throws away the reason you used awk.

## Worked examples

### Fields

```run
# title: Second field and the field count
# companion: awk
/usr/bin/printf 'error 3 parser\nwarn 1 linker\n' | /usr/bin/awk '{print $2, NF}'
```

### One pass, then sort | uniq

```run
# title: Counts that agree on a small file
# companion: awk
/usr/bin/printf 'b\na\nb\n' > log
/usr/bin/awk '{c[$0]++} END {for (k in c) print c[k], k}' log | LC_ALL=C /usr/bin/sort
LC_ALL=C /usr/bin/sort log | /usr/bin/uniq -c | /usr/bin/sed 's/^ *//'
```

### gawk has gensub, mawk does not

```run
# title: gensub is a gawk function
# companion: gawk
/usr/bin/printf 'ab\n' | /usr/bin/gawk '{print gensub(/b/, "B", 1)}'
set +e
/usr/bin/printf 'ab\n' | /usr/bin/mawk '{print gensub(/b/, "B", 1)}' >mawk.out 2>mawk.err
status=$?
set -e
/usr/bin/printf 'mawk_status:%s\n' "$status"
/usr/bin/grep -F 'never defined' mawk.err
```

### A numeric total

```run
# title: Sum the second column
# companion: awk
/usr/bin/printf 'ok 2\nfail 5\nok 1\n' | /usr/bin/awk '{s += $2} END {print s}'
```

## Performance

`sort | uniq -c` is the right shape when the next step needs sorted output, and it is the expensive shape when you only needed a hash count. sort's memory and temporary files are the coreutils sort lesson. mawk keeps one slot per distinct key. Forty keys are nothing. Forty million keys are a memory question, and this course did not time that. The recorded run is 200,000 lines and 40 keys, id `awk-vs-sort`, five trials, warm cache, `LC_ALL=C`, Python starter included. Read the medians and the spread. If they do not separate, do not invent a winner in a code review.

Locale collation makes `sort` slower and changes order. The count does not need dictionary order. `LC_ALL=C` is the honest setting for byte keys. mawk's own scan is not free of locale, but the heavy locale cost in this pair is sort. The coreutils locale lesson measured sort alone.

Do not call `awk` once per file from a shell loop if one process can read all the names. Process startup dominates tiny files. `xargs` and GNU parallel are the batching tools, and they are not awk. Awk's job is the record, not the process pool.

gawk is sometimes faster and sometimes slower than mawk on the same program. This course does not publish that race. The feature gap is the part that breaks scripts. Time gawk on your program if you already require gawk. Do not switch the alternatives link in a shared image to win a benchmark.

## Tips and pitfalls

`awk '{print $2}'` on a line with one field prints a blank line. Check `NF` if a missing column should be an error.

mawk's `next` and gawk's `next` both skip to the next record. gawk-only functions do not fail until that line runs. A test file that never hits the function is a green build and a broken script.

`OFMT` and `printf` decide numeric text. The default print of a sum can surprise you when the sum is not an integer. Use `printf` when the log must be stable.

The examples that say `/usr/bin/awk` are mawk here. Copying them to a machine where `awk` is gawk still works for this subset. Copying a `gensub` one-liner to mawk does not.

## Exercises

```exercise
expect-exit: 0
---title---
Print field two
---prompt---
From the line `error 3 parser`, print `3`.
---hint---
Default field splitting is whitespace. Use `/usr/bin/awk`.
---hint2---
`{print $2}` is enough. This is mawk on this host, and it is not coreutils.
---solution---
The line is `3`.
---script---
/usr/bin/printf 'error 3 parser\n' | /usr/bin/awk '{print $2}'
```

```exercise
expect-exit: 0
---title---
Total a column
---prompt---
Sum the second field of `ok 2`, `fail 5`, and `ok 1`.
---hint---
Add `$2` into a variable and print it in `END`.
---hint2---
The total is 8. Initialize is unnecessary if you only add.
---solution---
The line is `8`.
---script---
/usr/bin/printf 'ok 2\nfail 5\nok 1\n' | /usr/bin/awk '{s += $2} END {print s}'
```

```exercise
expect-exit: 0
---title---
Prove gensub is missing in mawk
---prompt---
Run the same `gensub` program under `/usr/bin/mawk` and print the status. Do not let `set -e` hide it.
---hint---
`set +e` around mawk, then print `$?`.
---hint2---
The status is non-zero. gawk would have printed a replacement. You are not calling gawk.
---solution---
`mawk_status:2` on this host. The function is not defined.
---script---
set +e
/usr/bin/printf 'ab\n' | /usr/bin/mawk '{print gensub(/b/, "B", 1)}' >/dev/null
status=$?
set -e
/usr/bin/printf 'mawk_status:%s\n' "$status"
```
