---
number: 22
slug: join-and-comm
title: join and comm
module: Reading and shaping text
level: advanced
minutes: 32
summary: join and comm require the same sort order. GNU checks by default. --nocheck-order will happily drop rows and exit 0.
objectives:
  - Join two sorted files on a key
  - Read the partial output and non-zero status of an unsorted join
  - Show --nocheck-order returning 0 with a wrong answer
  - Read comm's three columns, including the tabs, with cat -A
manual: join invocation | https://www.gnu.org/software/coreutils/manual/html_node/join-invocation.html
manual: comm invocation | https://www.gnu.org/software/coreutils/manual/html_node/comm-invocation.html
gnu_vs_bsd: |
  POSIX join and comm require sorted inputs. GNU join checks order unless you pass `--nocheck-order`, and it can still emit a partial line before exiting 1. BSD join often does not diagnose disorder and can mis-join quietly. `comm --check-order` is GNU. Column suppression `-1`, `-2`, `-3` is widely available. The unsorted captures below are GNU 9.4. They were not repeated on BSD.
---

`join` merges lines that share a key. The default key is the first field, fields split on blanks. Both files must be sorted on the key with the same locale rules. `-t` sets a delimiter. `-1` and `-2` pick the key field on each side. `-a 1` keeps unpairable lines from file 1. `-e` fills a missing field. `-o` selects the output fields. This is a relational join only in the small sense of "sorted equijoin". It is not SQL.

GNU join checks that the input is sorted. On the unsorted file `b` then `a` joined to a sorted partner, this 9.4 build printed a joined line for `b`, wrote a diagnostic to stderr, and exited 1. You can see a plausible row and a failure in the same run. If a script discards stderr and does not check the status, it keeps the plausible row. `--nocheck-order` disables the check. The same unsorted input then exits 0 and still does not contain the row for `a`. That is a silent wrong answer. The flag is for the case where you have proved the order by some other means, not for making the error go away.

`comm` compares two sorted files line by line. Column 1 is lines only in file 1, column 2 is lines only in file 2, column 3 is lines in both. The columns are indented with tabs. A display that collapses tabs hides the structure. `cat -A` shows `^I`. `-1` suppresses column 1, so `comm -12` prints the intersection and `comm -13` prints lines only in file 2. GNU comm also checks order. An unsorted file produces a diagnostic and status 1, and it may already have printed something. Sort both files with the same `LC_ALL` before you comm them. `sort -u` if you need set semantics. comm does not unique the files for you; duplicate lines are part of the comparison.

Header lines break both tools. A header is an unsorted extra line at the top. Strip it with `tail -n +2` before sorting, or the check fails on line 1 for a boring reason.

## Worked examples

### A sorted join

```run
# title: Both inputs sorted on field 1
/usr/bin/printf 'a 1\nb 2\n' > left
/usr/bin/printf 'a x\nb y\n' > right
/usr/bin/join left right
```

### The check catches disorder and still prints

```run
# title: Unsorted join
# expect-exit: 1
/usr/bin/printf 'b 1\na 2\n' > messy
/usr/bin/printf 'a x\nb y\n' > tidy
/usr/bin/join messy tidy
```

### nocheck-order is a wrong answer with status 0

```run
# title: --nocheck-order hides the bug
/usr/bin/printf 'b 1\na 2\n' > messy
/usr/bin/printf 'a x\nb y\n' > tidy
/usr/bin/join --nocheck-order messy tidy
/usr/bin/printf 'status-was-zero\n'
```

### comm columns

```run
# title: Three columns, tabs made visible
/usr/bin/printf 'a\nb\nc\n' > one
/usr/bin/printf 'b\nc\nd\n' > two
/usr/bin/comm one two | /usr/bin/cat -A
```

## Recipes

Compare two package lists: `sort -u` each, then `comm -13 old new` for additions and `comm -23 old new` for removals. Keep `LC_ALL=C` if the lists are byte identifiers such as package names that should not be collated as dictionary words. Document the locale next to the sort.

Join a two-column size table onto a two-column name table only after both are `sort -k1,1`. If the key is numeric and the other fields must keep their original order among ties, `sort -k1,1 -s`.

## Tips and pitfalls

A join key with extra spaces is a different key. `-t $'\t'` is the strict separator if the fields are tab-separated. The default blank splitting collapses runs of spaces and will glue a sentence into the wrong fields.

`comm` of files that are sorted in different locales fails the check or, if you disable it, lies. One `LC_ALL` for both sorts and the comm.

Do not pipe `comm` to `cut` on tabs without looking at `cat -A` first. The leading tabs are the column identity.

## Exercises

```exercise
expect-exit: 0
---title---
Join two sorted tables
---prompt---
Join `a 1` / `b 2` with `a X` / `b Y`.
---hint---
Both already sorted.
---solution---
Two output lines, key plus the two payloads.
---script---
/usr/bin/printf 'a 1\nb 2\n' > l
/usr/bin/printf 'a X\nb Y\n' > r
/usr/bin/join l r
```

```exercise
expect-exit: 1
---title---
Hand join an unsorted file
---prompt---
Join `b 1` then `a 2` to a sorted partner `a x` / `b y` with the default check. Let it fail.
---hint---
Do not pass `--nocheck-order`.
---solution---
Status 1 and a diagnostic. Any stdout line is not a complete answer.
---script---
/usr/bin/printf 'b 1\na 2\n' > l
/usr/bin/printf 'a x\nb y\n' > r
/usr/bin/join l r
```

```exercise
expect-exit: 0
---title---
Intersection only
---prompt---
`comm` files containing `a b c` and `b c d`, suppress columns 1 and 2, so only the common lines remain.
---hint---
`comm -12`. Both inputs must be sorted. These letters already are.
---solution---
`b` and `c`.
---script---
/usr/bin/printf 'a\nb\nc\n' > l
/usr/bin/printf 'b\nc\nd\n' > r
/usr/bin/comm -12 l r
```

## Performance

Both tools are linear after the sort. The sort is the expensive part and it is the part with `-S`, `-T`, and `--parallel`. A join that re-sorts on every run of a build is paying N log N to avoid storing the data in order. If the producer can emit sorted output, skip the sort. `--nocheck-order` is not a performance feature you turn on to save the check. The check is cheap next to a wrong release diff. Locale collation makes the sort slower and the join correct only if both sides match. The sort benchmark measures collation cost. Use it before you claim `LC_ALL=C` is required for speed; use `LC_ALL=C` anyway when the keys are bytes.
