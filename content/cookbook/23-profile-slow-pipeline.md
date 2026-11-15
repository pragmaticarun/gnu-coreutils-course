---
number: 23
slug: profile-slow-pipeline
title: Profile a slow pipeline
module: Cookbook
level: advanced
minutes: 20
summary: Three processes can do what one awk does. GNU time reports the child's status. strace -c shows the calls without becoming the ranking. The harness holds the medians.
manual: GNU time | https://www.gnu.org/software/time/manual/time.html
manual: strace | https://man7.org/linux/man-pages/man1/strace.1.html
manual: awk | https://www.gnu.org/software/gawk/manual/html_node/index.html
manual: printf invocation | https://www.gnu.org/software/coreutils/manual/html_node/printf-invocation.html
gnu_vs_bsd: |
  The bash keyword time is not GNU time on either platform. BSD has no strace. This recipe ran /usr/bin/time from the time package, strace, mawk, and GNU grep. perf is not installed, so no hardware counters are quoted.
---

A pipeline that feels slow is often more processes than work. `grep | sed | awk` reads and writes the stream three times. One awk can select and total. The bytes at the end should match, or you optimized the wrong program. `grep` and `sed` and `awk` are not coreutils. `/usr/bin/time` is not coreutils and is not the shell keyword. `-f 'exit:%x'` proves the child succeeded without pasting a wall-clock sample into the page. `strace -c` shows that writes happened. The summary's microseconds are one traced run, so the recipe only checks that the word `write` is present.

Comparative medians for this class of question are `awk-vs-sort` and the grep rows in `companions.json`. They were taken without strace attached. A traced time is a different experiment.

## Steps

```run
# title: Two shapes, one total
# companion: awk
/usr/bin/printf '%s\n' 'INFO 1' 'ERROR 2' 'ERROR 5' > log
pipe=$(LC_ALL=C /usr/bin/grep -F ERROR log | /usr/bin/sed 's/^ERROR //' | /usr/bin/awk '{s+=$1} END {print s}')
one=$(/usr/bin/awk '/^ERROR / {s+=$2} END {print s}' log)
/usr/bin/printf 'pipe:%s\none:%s\n' "$pipe" "$one"
/usr/bin/test "$pipe" = "$one" && /usr/bin/printf 'totals-match\n'
```

```run
# title: Status from GNU time, calls from strace
# companion: time
/usr/bin/printf '%s\n' 'INFO 1' 'ERROR 2' 'ERROR 5' > log
/usr/bin/time -f 'exit:%x' /usr/bin/awk '/^ERROR / {s+=$2} END {print s}' log >/dev/null 2>time.err
/usr/bin/cat time.err
/usr/bin/strace -c -e trace=write -o summary /usr/bin/awk '/^ERROR / {s+=$2} END {print s}' log >/dev/null
/usr/bin/grep -q write summary && /usr/bin/printf 'saw-write\n'
```

## Check yourself

```exercise
expect-exit: 0
---title---
Total the error column in one awk
---prompt---
Sum the numbers on lines that start with `ERROR` and print the total.
---hint---
One awk, a pattern, `$2`.
---hint2---
The lines are `ERROR 2` and `ERROR 5`. The total is 7.
---solution---
`7`.
---script---
/usr/bin/printf '%s\n' 'INFO 1' 'ERROR 2' 'ERROR 5' | /usr/bin/awk '/^ERROR / {s+=$2} END {print s}'
```

## Performance

Process startup and extra copies dominate short logs. They stop dominating when each stage does real work, such as a compression. The `xargs-parallel` bench is the startup end. The compression benches are the CPU end. GNU time's `-v` can show RSS on a real run at your terminal. This recipe does not record that sample, because one shot is not a median. strace slows the thing it traces. Take it off before you accept a number. perf would separate cycles from stalls and is not installed for kernel 6.12.113+. The method is `perf stat -e cycles,instructions -- command`. There is no figure to quote.
