---
number: 51
slug: timing-tools
title: GNU time and hyperfine
module: Companion Tools
level: intermediate
minutes: 30
summary: The bash keyword time is not GNU time. /usr/bin/time -v reports RSS and faults. hyperfine repeats a command. Neither tool is coreutils, and a sub-millisecond sample is not a ranking.
objectives:
  - Separate the shell keyword from /usr/bin/time in the time package
  - List the -v fields without treating one run of true as a benchmark
  - Show hyperfine's report shape with the digits removed
  - Send comparative questions to the companion harness
manual: GNU time | https://www.gnu.org/software/time/manual/time.html
manual: hyperfine | https://github.com/sharkdp/hyperfine
manual: Coreutils time is not this binary | https://www.gnu.org/software/coreutils/manual/html_node/Introduction.html
gnu_vs_bsd: |
  BSD time is a different binary with a different -l flag for resource usage. The bash keyword exists on macOS too and is still not GNU time. This lesson ran Ubuntu's GNU time 1.9 package and hyperfine 1.18.0. No BSD time was executed.
---

There are two commands named time, and only one of them is a program. Bash has a keyword `time`. `type time` prints `time is a shell keyword`. The keyword times a pipeline in the shell's own way and prints `real`, `user`, and `sys`. It does not accept GNU time's `-f` or `-v`. If you write `time -f %x true`, bash tries to execute a command named `-f` and reports `command not found`. It may still print a timing line afterward. That combination is the usual reason a copied snippet "almost" works.

`/usr/bin/time` is the Ubuntu package `time`, upstream GNU time. The package version on this host is 1.9. The binary's own version string says `UNKNOWN`, which is a packaging quirk, not a reason to ignore `dpkg -S`. GNU time's `-f` takes a format. `%x` is the child's exit status. `%e` is elapsed wall time. `%M` is maximum resident set size in kilobytes. `-v` prints a long list: user time, system time, percent CPU, elapsed time, maximum RSS, page faults, context switches, and more. Those fields are why you wanted the binary. The keyword does not print maximum RSS.

The `-v` values for `/usr/bin/true` are tiny and noisy. A single capture would put a page-fault count and a CPU percent on the page that the next run would not repeat. The example strips everything after the last colon so you can see the field names and not a fake measurement. When you need numbers, use the harness. It runs five trials, takes the median, records user, system, and `ru_maxrss`, and writes `public/benchmarks/companions.json` with the CPU model, the memory total, and the tool versions. The Python process that starts the command is included in the elapsed time. Compare variants with each other. Do not treat the absolute seconds as a shell-only figure, and do not compare them with `sample-run.json` or `supplements.json`. Those files are other runs.

hyperfine is the Ubuntu package `hyperfine`, upstream sharkdp/hyperfine, version 1.18.0 here. It warms up, repeats, and reports a mean and a spread. `--shell=none` executes the argv directly so the shell is not inside the number. Commands that finish in a few hundred microseconds trigger its warning that the result is inside calibration noise. `/usr/bin/true` is such a command. The example runs hyperfine and then replaces digit runs with `N`, so the shape of the report and the warning are visible and the microseconds are not quoted as a result. Use hyperfine when you are comparing two commands that run long enough for the warning to stay quiet. Use the course harness when the result has to sit in the benchmark file next to a disclosure.

Neither tool is coreutils. Coreutils `date` can difference two timestamps and is the wrong profiler. `timeout` bounds a hung command and does not report RSS.

## Worked examples

### The keyword rejects -f

```run
# title: Keyword time is not GNU time
# companion: time
type time
set +e
{ time -f %x /usr/bin/true; } >kw.out 2>kw.err
status=$?
set -e
/usr/bin/printf 'keyword_status:%s\n' "$status"
/usr/bin/grep -F 'command not found' kw.err
```

### A format string that stays stable

```run
# title: GNU time prints the child status
# companion: time
/usr/bin/time -f 'exit:%x' /usr/bin/true >/dev/null 2>gnu.err
/usr/bin/cat gnu.err
```

### Field names from -v

```run
# title: What -v knows how to print
# companion: time
/usr/bin/time -v /usr/bin/true >/dev/null 2>verbose.txt
/usr/bin/sed -E 's/[0-9][0-9.:%]*//g' verbose.txt
```

### hyperfine's shape, digits removed

```run
# title: A noisy command, shown as a shape
# companion: hyperfine
/usr/bin/hyperfine --shell=none --warmup 1 --runs 3 -- /usr/bin/true >hyp.txt 2>&1 || true
/usr/bin/sed -E 's/[0-9]+([.][0-9]+)?/N/g' hyp.txt
```

## Performance

Wall time, user time, and system time answer different questions. Wall time includes waiting. User time is CPU in the process. System time is CPU in the kernel on its behalf. A grep that looks slow on the wall and idle in user time is waiting on a pipe or a disk. A gzip that burns user time is CPU bound. Maximum RSS tells you whether the process grew. GNU time's `-v` is one sample of all of those. The harness median is the sample this course is willing to keep.

hyperfine's mean is not the harness median. Do not average them. Do not paste a hyperfine table for `/usr/bin/true` into a slide. The warning in the captured shape is the tool telling you the command was too short.

What this course did time, with five trials and a disclosure, is in the companion file: grep modes, mawk against sort, compressors, xargs against parallel, sed `-i`, sparse tar, and a CPU pin. GNU time was not the timer for those rows. Python's `resource` counters were. The method page explains why. Using two timers for one claim is how people double-count.

`perf stat` would add cycles and instructions. It is not installed. The tracing lesson says what the command line would be and stops before a number. Do not fill the hole with a guessed IPC.

## Tips and pitfalls

Redirections on the keyword apply to the timed command, not always to the keyword's own report. The group `{ time ...; } 2>file` is the form that caught the report in the example. `/usr/bin/time` is an ordinary program and follows ordinary redirection. Its report is on stderr so it does not mix with the child's stdout.

`TIMEFORMAT` changes the keyword. It does not change `/usr/bin/time`.

hyperfine `--runs` without a warmup times the cold start of the page cache as if it were the command. For a command that reads a big file, warm the cache on purpose or say that you did not. This course's harness says it did not drop caches and that the inputs were just written.

A format string in single quotes does not expand shell variables. That is what you want for `%x`.

## Exercises

```exercise
expect-exit: 0
---title---
Show that time is a keyword
---prompt---
Print the shell's description of `time`.
---hint---
`type time` in bash.
---hint2---
The line says it is a shell keyword. That is not `/usr/bin/time`.
---solution---
`time is a shell keyword`.
---script---
type time
```

```exercise
expect-exit: 0
---title---
Print exit 0 from GNU time
---prompt---
Time `/usr/bin/true` with `/usr/bin/time -f 'exit:%x'` and show the report.
---hint---
The report is on stderr. Redirect it to a file and cat the file.
---hint2---
Stdout of true is empty. Do not use the keyword.
---solution---
`exit:0`.
---script---
/usr/bin/time -f 'exit:%x' /usr/bin/true >/dev/null 2>gnu.err
/usr/bin/cat gnu.err
```

```exercise
expect-exit: 0
---title---
Confirm hyperfine can run
---prompt---
Run hyperfine with `--shell=none` for one run of `/usr/bin/true`, discard the timing text, and print `hyperfine-ran` if the file is non-empty.
---hint---
The report is text. You do not need to display the microseconds.
---hint2---
`test -s` checks that the file is non-empty. hyperfine is not coreutils.
---solution---
`hyperfine-ran`.
---script---
/usr/bin/hyperfine --shell=none --runs 1 -- /usr/bin/true >hyp.txt 2>&1
/usr/bin/test -s hyp.txt && /usr/bin/printf 'hyperfine-ran\n'
```
