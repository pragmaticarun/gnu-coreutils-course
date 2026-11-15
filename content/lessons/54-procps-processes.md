---
number: 54
slug: procps-processes
title: ps, top, free, pgrep, and pkill
module: Companion Tools
level: intermediate
minutes: 35
summary: ps, top, free, pgrep, and pkill are procps, upstream procps-ng. They are not coreutils. pkill matches a name, and a careless pattern matches your shell.
objectives:
  - Attribute the five binaries to the procps package
  - Read free and top headers without freezing a sample
  - Find and stop a process you started, by an exact comm name
  - Keep the pattern out of the shell's own command line
manual: ps | https://man7.org/linux/man-pages/man1/ps.1.html
manual: top | https://man7.org/linux/man-pages/man1/top.1.html
manual: free | https://man7.org/linux/man-pages/man1/free.1.html
manual: pgrep | https://man7.org/linux/man-pages/man1/pgrep.1.html
manual: procps-ng | https://gitlab.com/procps-ng/procps
manual: Coreutils kill is not this topic | https://www.gnu.org/software/coreutils/manual/html_node/Introduction.html
gnu_vs_bsd: |
  BSD ps uses different flags. BSD top and Linux top do not share a batch syntax. macOS has no procps-ng. This lesson ran procps-ng 4.0.4 from Ubuntu's procps package. The shell also has a kill builtin, which is not pkill.
---

`ps`, `top`, `free`, `pgrep`, and `pkill` are the Ubuntu package `procps`, upstream procps-ng. They are not GNU coreutils. The GNU coreutils manual documents a `kill` and an `uptime` that Ubuntu ships from this same procps package, which is why those names feel like coreutils and are not. `pgrep` selects processes. `pkill` sends them a signal. Default signal is TERM. `ps` is a snapshot. `top` repeats a snapshot. `free` reads the kernel's memory totals.

`ps -o comm= -p $$` prints the command name of the current shell, which is `bash` in these scripts. `comm` is the short name, not the full argument list. `args` is the full list and will contain your script text. That difference matters the moment you search.

`free -b` prints totals in bytes. The columns are total, used, free, shared, buff/cache, and available. `available` is the estimate of memory a new program can have without swapping. `free` alone is not that estimate, because caches are reclaimable. The example prints the header and the row labels `Mem:` and `Swap:` and drops the integers. The integers are a live sample. They are not a benchmark of your C++ allocator. RSS of one process is GNU time's `%M` or `ps -o rss=`, not the machine total.

`top -b -n 1` is one batch frame, safe in a script. Without `-b`, top takes the terminal. The PID header lists the columns: PID, USER, PR, NI, VIRT, RES, SHR, S, %CPU, %MEM, TIME+, COMMAND. `%CPU` in one frame is a short sample and it lies for a process that started a moment ago. The example prints that header only.

`pgrep -x` matches the exact comm name. A pattern without `-x` is a regular expression against the name, and `-f` matches the full argument list. `-f` is how a script kills itself: the pattern appears in the shell's argv, `pgrep -f` sees the shell, `pkill -f` signals the shell. The safe demo copies `/usr/bin/sleep` to a file named `cuwbnap` and matches `-x cuwbnap`. The shell's comm stays `bash`. The script text never needs to be the pattern that `-f` would scan. Start it, check that `pgrep -x` finds it, `pkill -x` it, and check that it is gone. `pgrep` exits 1 when nothing matches. An `if` absorbs that status. `wait` on a killed sleep returns non-zero. `wait || true` records the child without failing the script.

Do not point `pkill` at `sleep`, `java`, `python`, or `bash` on a shared machine. Those names are other people's processes. A unique comm, or a pid you just printed from a child you spawned, is the whole safety story.

`ps` and `top` can see more processes than your user, depending on hidepid mounts. They cannot see inside another user's address space. `lsof` is the next lesson when the question is "who holds this file".

## Worked examples

### The shell's short name

```run
# title: ps comm of this shell
# companion: ps
/usr/bin/ps -o comm= -p $$ | /usr/bin/tr -d ' '
```

### free's labels

```run
# title: free columns without the sample
# companion: free
/usr/bin/free -b | /usr/bin/awk 'NR==1 {print} NR>1 {print $1}'
```

### One batch frame's header

```run
# title: top -b -n 1 column names
# companion: top
/usr/bin/top -b -n 1 > top.txt
/usr/bin/grep -m 1 PID top.txt
```

### Find and stop a private name

```run
# title: pgrep and pkill on cuwbnap
# companion: pgrep
/usr/bin/cp /usr/bin/sleep ./cuwbnap
./cuwbnap 5 &
nap=$!
/usr/bin/sleep 0.2
if /usr/bin/pgrep -x cuwbnap >/dev/null; then /usr/bin/printf 'found\n'; else /usr/bin/printf 'missing\n'; fi
/usr/bin/pkill -x cuwbnap
wait "$nap" || true
if /usr/bin/pgrep -x cuwbnap >/dev/null; then /usr/bin/printf 'still\n'; else /usr/bin/printf 'gone\n'; fi
```

## Performance

`ps` and `pgrep` read the process table. On a quiet machine they are cheap. On a host with a huge number of tasks they are still metadata, not a profiler. Running `ps` in a loop to watch a build is how you spend a core printing. `pidstat 1` from sysstat is the sampler built for that, and it is not procps. `top -d 5` is a coarse repeat. None of these replace a median from the harness.

`free` is a single read of kernel counters. It does not show which process to blame. A process with a large RSS shows up in `ps -o rss`. The companion harness records `ru_maxrss` of the children it waited for, which is the peak of those children, not the machine total from `free`. Do not add them.

`pkill` is not a performance tool. A script that restarts a worker by killing a name pays the process startup the startup benchmark already measured for `/usr/bin/true`. Killing and respawning a compiler to "free memory" is that cost plus lost caches. Measure the leak before you automate the kill.

The captured `found` / `gone` lines contain no timing. Sleep of 0.2 seconds is only there so the child exists before `pgrep`. It is not a measurement.

## Tips and pitfalls

`pgrep` and `pkill` share an implementation. On this image `pkill` is the procps binary. `dpkg -S` may name the path `pgrep` if the two names are one file. Read the package, which is procps.

`pkill` without `-x` matches a substring. `pkill nap` would also match `cuwbnap`, and it would match anything else with those letters. `-x` is the tighter switch. It still matches every process with that exact comm, including one you forgot in another terminal.

`top` without `-b` will not exit. A captured script must pass `-n`.

`free -h` prints human units that round. `free -b` is exact and wide. `numfmt` from coreutils can format a single number later if a report needs units. Do the arithmetic on bytes.

The shell builtin `kill` takes a pid. `pkill` takes a pattern. Mixing them up is how a pid that looks like a pattern fails, or a pattern that looks like a pid is sent to the wrong place.

## Exercises

```exercise
expect-exit: 0
---title---
Print the shell's comm
---prompt---
Print the short command name of the current process.
---hint---
`ps -o comm= -p $$` and strip spaces.
---hint2---
In this sandbox the name is `bash`.
---solution---
`bash`.
---script---
/usr/bin/ps -o comm= -p $$ | /usr/bin/tr -d ' '
```

```exercise
expect-exit: 0
---title---
Show free's header
---prompt---
Print the first line of `free -b`.
---hint---
`head -n 1`.
---hint2---
The line names the columns and does not include the Mem totals.
---solution---
The header that contains `total` and `available`.
---script---
/usr/bin/free -b > free.txt
/usr/bin/head -n 1 free.txt
```

```exercise
expect-exit: 0
---title---
Stop cuwbnap
---prompt---
Start a copy of sleep named `cuwbnap`, confirm `pgrep -x` sees it, `pkill -x` it, and print `found` then `gone`.
---hint---
Copy `/usr/bin/sleep` to `./cuwbnap`. Do not use `pgrep -f`.
---hint2---
`wait || true` after pkill so the killed child's status does not fail the script.
---solution---
`found` and `gone`.
---script---
/usr/bin/cp /usr/bin/sleep ./cuwbnap
./cuwbnap 5 &
nap=$!
/usr/bin/sleep 0.2
if /usr/bin/pgrep -x cuwbnap >/dev/null; then /usr/bin/printf 'found\n'; else /usr/bin/printf 'missing\n'; fi
/usr/bin/pkill -x cuwbnap
wait "$nap" || true
if /usr/bin/pgrep -x cuwbnap >/dev/null; then /usr/bin/printf 'still\n'; else /usr/bin/printf 'gone\n'; fi
```
