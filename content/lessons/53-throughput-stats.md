---
number: 53
slug: throughput-stats
title: pv, iostat, vmstat, and pidstat
module: Companion Tools
level: intermediate
minutes: 30
summary: pv measures a pipe. iostat and pidstat are sysstat. vmstat is procps, not sysstat. None of them are coreutils. Live counters are not copied into the prose.
objectives:
  - Attribute each binary to its Ubuntu package and upstream
  - Show a stable byte count from pv
  - Read the column headers of iostat, vmstat, and pidstat
  - Refuse to treat one sample of CPU idle as a benchmark
manual: pv | https://www.ivarch.com/programs/pv.shtml
manual: iostat | https://man7.org/linux/man-pages/man1/iostat.1.html
manual: vmstat | https://man7.org/linux/man-pages/man1/vmstat.1.html
manual: pidstat | https://man7.org/linux/man-pages/man1/pidstat.1.html
manual: sysstat | https://sysstat.github.io/
manual: Coreutils dd | https://www.gnu.org/software/coreutils/manual/html_node/dd-invocation.html
gnu_vs_bsd: |
  pv is a third-party pipe viewer. BSD has no iostat from sysstat; it has its own iostat. vmstat exists on BSD with different columns. This lesson ran Ubuntu pv 1.8.5, sysstat 12.6.1, and procps vmstat only.
---

These four tools tell you where time went. None of them are GNU coreutils. `pv` is Pipe Viewer, Ubuntu package `pv`, upstream the ivarch program. It copies standard input to standard output and writes progress on standard error. `iostat` and `pidstat` are the Ubuntu package `sysstat`, upstream sysstat. `vmstat` looks similar and is not in that package. On this image `/usr/bin/vmstat` is `procps`, upstream procps-ng, the same family as `ps` and `free`. Filing vmstat under sysstat is the mistake this lesson exists to prevent.

`pv` is how you see the rate of a pipe. `tar -c dir | pv | zstd` shows bytes moving between tar and zstd. The progress is on stderr so it does not enter the archive. `-b` asks for a byte count. `-F` sets the format. `-q` copies with no progress, which is the right flag when you only wanted the splice and a later `cmp`. A progress bar uses carriage returns. The example uses `-F '%b'` so the capture is a single size for a 7-byte input. That size is the input's size, not a throughput ranking.

`iostat` reports CPU and device counters since boot, and then a sample if you pass an interval and a count. `iostat -c 1 1` is one CPU sample. The header names `%user`, `%nice`, `%system`, `%iowait`, `%steal`, and `%idle`. `%iowait` is time the CPU was idle and at least one process wanted disk. It is not "disk percent" by itself. `%steal` is time a hypervisor took. The numbers move every second. The example prints the header only.

`vmstat 1` prints a header and then lines of runnable processes, memory, swap, blocks in and out, interrupts, context switches, and CPU states. Two samples are the minimum if you want a rate, because the first line is an average since boot and the later lines are the interval. The example prints the two header rows, which do not contain a sample. `bi` and `bo` are blocks in and out. `wa` is I/O wait. `id` is idle. A backup that is disk bound shows up in `bi`/`bo` and `wa`, not in a high `%user`.

`pidstat` is per process. It can show CPU, and with `-d` disk, for tasks it can see. The header includes `%CPU` and `Command`. The first column of a data row is a clock. Clocks change, so the example rewrites the header line to start at `UID` and drops the average row. You learn the columns. You do not freeze this host's idle percentage into the paragraph.

Coreutils `dd` can report a byte count and a time with `status=progress`. That report is dd's own. pv is the tool when the program in the middle of the pipe has no progress flag. Neither one is a disk profiler. iostat is closer, and it still needs a sample window you chose, not a single boot-average line.

## Worked examples

### A byte count from pv

```run
# title: pv -F prints the size
# companion: pv
/usr/bin/printf 'abcdef\n' | /usr/bin/pv -F '%b' -f > /dev/null
```

### iostat's CPU header

```run
# title: iostat column names
# companion: iostat
/usr/bin/iostat -c 1 1 | /usr/bin/grep avg-cpu
```

### vmstat's headers

```run
# title: vmstat headers without a sample row
# companion: vmstat
/usr/bin/vmstat 1 1 > vm.txt
/usr/bin/head -n 2 vm.txt
```

### pidstat's columns

```run
# title: pidstat header, clock removed
# companion: pidstat
/usr/bin/pidstat 1 1 > pid.txt
/usr/bin/sed -n '/UID/{s/.*UID/UID/; p; q}' pid.txt
```

## Performance

A pipe's throughput is the minimum of the producer, the consumer, and the copy in between. pv sits in the middle and is an extra copy. On a fast zstd of a cached file, pv can become visible. On a disk-bound tar of a cold tree, pv is noise and iostat's `%iowait` and block counters are the signal. Measure the unadorned pipeline with the harness when you want a median. Insert pv when you want to see which stage is stalled. Remove it before you record the number.

`iostat` and `vmstat` without an interval print a long average. A machine that was idle all morning and busy for ten seconds still looks idle in the since-boot line. Pass an interval. One second is a coarse window. It is enough to tell "waiting on disk" from "burning a core". It is not a benchmark and it is not reproducible, so it is not in `companions.json`. The compression and grep rows are the reproducible numbers. They are CPU on a warm cache, which hides the disk case on purpose. The disclosure says the cache was not dropped.

`pidstat -d 1` during a copy shows which pid is writing. `pidstat` without `-d` is CPU. Asking the wrong subsystem is how a CPU chart gets blamed for a full disk. `free` in the procps lesson is the memory picture. Together they are a first look. They are not `perf`, and `perf` is not installed.

sysstat's `sadc` collector is a daemon this course does not enable and does not tune. The interactive binaries work without it.

## Tips and pitfalls

pv's progress on stderr uses terminal control codes when stderr is a terminal. `-f` forces the output even in a pipe. A captured log full of carriage returns is pv without a plain format.

`vmstat`'s first data line is not the interval. Ignore it or ask for two intervals and read the second.

`iostat` device names are host-specific. This lesson does not print them. `iostat -c` is the CPU line. Device lines are `-d`, and they name disks you should not hard-code.

pidstat needs permission to see other users' processes in detail. These examples only read the header.

## Exercises

```exercise
expect-exit: 0
---title---
Count seven bytes with pv
---prompt---
Send `abcdef` plus a newline through `pv -F '%b' -f` and discard the copy.
---hint---
The format `%b` is the byte count. The data must still be consumed.
---hint2---
Redirect stdout to `/dev/null`. The count is on pv's stderr, which is the terminal of the script unless pv writes it to the pipe of the format. In this pv, `-F` writes the format to stderr.
---solution---
The captured line reports 7 bytes. pv is not coreutils.
---script---
/usr/bin/printf 'abcdef\n' | /usr/bin/pv -F '%b' -f >/dev/null
```

```exercise
expect-exit: 0
---title---
Show the iostat CPU header
---prompt---
Print the `avg-cpu` header from one iostat CPU sample.
---hint---
`iostat -c 1 1` and grep the header.
---hint2---
Do not print the percentage row. It changes every run.
---solution---
A line that starts with `avg-cpu`.
---script---
/usr/bin/iostat -c 1 1 | /usr/bin/grep avg-cpu
```

```exercise
expect-exit: 0
---title---
Show vmstat's two header rows
---prompt---
Print the first two lines of `vmstat 1 1`.
---hint---
`head -n 2`. Those lines are labels.
---hint2---
The data row is line 3 and is not part of the exercise.
---solution---
The procs/memory header and the column header. vmstat is procps, not sysstat.
---script---
/usr/bin/vmstat 1 1 > vm.txt
/usr/bin/head -n 2 vm.txt
```
