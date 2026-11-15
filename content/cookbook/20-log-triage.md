---
number: 20
slug: log-triage
title: Triage a build log
module: Cookbook
level: intermediate
minutes: 20
summary: grep -F finds the error lines, sed strips a prefix, and one awk counts them. sort and uniq are the coreutils view of the same count. None of grep, sed, or awk are coreutils.
manual: GNU grep | https://www.gnu.org/software/grep/manual/html_node/index.html
manual: uniq invocation | https://www.gnu.org/software/coreutils/manual/html_node/uniq-invocation.html
gnu_vs_bsd: |
  BSD grep and sed accept the same -F and a basic substitution, with the sed -i difference that does not matter here because this recipe does not use -i. This recipe ran GNU grep, GNU sed, and Ubuntu mawk only.
---

A C++ or Android build log repeats the same error. You want the lines, then the counts, then the noisiest one. `grep` is GNU grep, not coreutils. `-F` keeps the token literal. `sed` is GNU sed, not coreutils, and it strips a fixed prefix. `awk` is mawk on this host, not coreutils, and one process counts. `sort` and `uniq -c` are coreutils and need the lines sorted first. On a small fixture the two counts match after you normalize uniq's padding.

Do not `grep` the whole `out/` tree if the log you care about is one file. Point at the file. `LC_ALL=C` is appropriate for ASCII tags.

## Steps

```run
# title: Errors, stripped and counted
# companion: grep
/usr/bin/printf '%s\n' 'INFO start' 'ERROR linker missing libfoo' 'ERROR linker missing libfoo' 'ERROR parser unexpected token' > build.log
LC_ALL=C /usr/bin/grep -F ERROR build.log | /usr/bin/sed 's/^ERROR //' > errors.txt
/usr/bin/awk '{c[$0]++} END {for (k in c) print c[k], k}' errors.txt | LC_ALL=C /usr/bin/sort
```

```run
# title: The same count with sort and uniq
# companion: grep
/usr/bin/printf '%s\n' 'linker missing libfoo' 'linker missing libfoo' 'parser unexpected token' > errors.txt
LC_ALL=C /usr/bin/sort errors.txt | /usr/bin/uniq -c | /usr/bin/sed 's/^ *//'
```

## Check yourself

```exercise
expect-exit: 0
---title---
Count one error token
---prompt---
From three lines, two of them `ERROR disk full`, print the awk count for that stripped line.
---hint---
grep -F, sed to drop the prefix, awk to count, sort so the line is stable.
---hint2---
The count is 2 and the text is `disk full`. mawk is not coreutils. sort is.
---solution---
`2 disk full`.
---script---
/usr/bin/printf '%s\n' 'OK' 'ERROR disk full' 'ERROR disk full' > build.log
LC_ALL=C /usr/bin/grep -F ERROR build.log | /usr/bin/sed 's/^ERROR //' | /usr/bin/awk '{c[$0]++} END {print c[$0], $0}' | LC_ALL=C /usr/bin/sort
```

## Performance

The expensive part of a real log is reading it and, if you sort, ordering it. A one-pass awk count avoids the sort when you do not need order. The benchmark id `awk-vs-sort` records that comparison on 200,000 keys. This fixture is three lines and proves the text, not the clock. `grep` into `sed` into `awk` is three processes. On a gigabyte log the extra copies show up. If the only product is the count, one awk that both selects and counts is the tighter pipeline. The profile recipe measures the shape. Medians live in `companions.json` and are not repeated here.
