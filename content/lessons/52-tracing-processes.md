---
number: 52
slug: tracing-processes
title: strace, ltrace, and perf
module: Companion Tools
level: advanced
minutes: 35
summary: strace sees system calls. ltrace sees library calls. perf would see hardware counters and is not installed for this kernel. None of them are coreutils.
objectives:
  - Use strace -e and -c without publishing a one-run timing table
  - Follow a child with -f
  - List library calls ltrace saw, without ASLR addresses
  - Describe perf stat and perf record and explain why this host has no numbers
manual: strace | https://man7.org/linux/man-pages/man1/strace.1.html
manual: ltrace | https://man7.org/linux/man-pages/man1/ltrace.1.html
manual: perf | https://man7.org/linux/man-pages/man1/perf-stat.1.html
manual: Coreutils introduction | https://www.gnu.org/software/coreutils/manual/html_node/Introduction.html
gnu_vs_bsd: |
  strace and ltrace are Linux tools. BSD uses ktrace and truss. macOS uses dtruss or Instruments. perf is Linux only. This lesson ran Ubuntu strace 6.8 and ltrace 0.7.3. perf was not executed because it is not installed.
---

strace traces system calls. It is not coreutils. Ubuntu package `strace`, upstream strace, version 6.8 here. A system call is the boundary between the process and the kernel: `write`, `read`, `openat`, `execve`, `clone`. When a pipeline is slow or a program fails with a surprising `ENOENT`, strace shows the calls and the errors. It does not show which C++ function burned the CPU. That is a profiler question.

`-e trace=write` keeps one family of calls so the log is readable. `-o` writes the trace to a file instead of mixing it with the program's stderr. Addresses and file-descriptor details are in that log. The example rewrites hex addresses to `ADDR` and the return count's trailing integer so the capture shows `write(1, "hello\n", 6)` without a number that changes. `-c` prints a summary table: calls, errors, and time per syscall. The times in that table are a single run's accounting. They are useful at the terminal and they are the wrong thing to freeze into a lesson as a ranking. The example checks that the summary mentions `write` and prints a stable line.

`-f` follows children. A shell pipeline is several processes. Without `-f` you see the shell and miss `grep`. With `-f` you see each child's calls, tagged with a pid. Pids change every run, so the example filters to the `write` lines and strips addresses. You are looking for the call, not the pid.

ltrace traces dynamic library calls. Ubuntu package `ltrace`, version 0.7.3. It is the view one level above strace. `/usr/bin/echo` ends in `write` at the syscall layer and in `fputs_unlocked` at the libc layer. ltrace's raw lines contain load addresses. ASLR changes them every execution. The example keeps only the function names, sorted and unique. That list is the teaching artifact. ltrace misses statically linked calls and it can miss functions the compiler inlined. A quiet ltrace is not proof that nothing ran.

perf is the Linux performance-counter tool, upstream the kernel's `tools/perf`, documented in `perf-stat(1)` and on the kernel wiki. The method, which this host cannot execute, is `perf stat -e cycles,instructions -- command` for a count, and `perf record -g -- command` followed by `perf report` for a sample of call stacks. Those commands need a `perf` binary built for the running kernel. Ubuntu 24.04's `linux-tools` packages in the archive track kernel 6.8. This host runs 6.12.113+. There is no matching package to install, and a mismatched binary is not a measurement. The example prints `perf-absent`. No cycle count appears anywhere in this course.

strace and ltrace slow the target. They add context switches on every call. A `-c` summary of a program that was traced is not the speed of the untraced program. Use them to see what happened. Use the harness, GNU time, or hyperfine to see how long an untraced command took. Do not leave a strace attached to a production process to "just look". The overhead is the look.

## Worked examples

### One write, addresses removed

```run
# title: strace -e write
# companion: strace
/usr/bin/strace -e write -o trace /usr/bin/echo hello >/dev/null
/usr/bin/sed -E 's/0x[0-9a-f]+/ADDR/g; s/= [0-9]+$/= N/' trace
```

### A summary that only confirms the call

```run
# title: strace -c saw write
# companion: strace
/usr/bin/strace -c -e trace=write -o summary /usr/bin/echo hello >/dev/null
/usr/bin/grep -q write summary && /usr/bin/printf 'strace-c-saw-write\n'
```

### Follow the child

```run
# title: strace -f sees the child's write
# companion: strace
/usr/bin/strace -f -e write -o trace /usr/bin/bash --noprofile --norc -c '/usr/bin/echo hi' >/dev/null
/usr/bin/grep write trace | /usr/bin/sed -E 's/^[0-9]+ //; s/0x[0-9a-f]+/ADDR/g; s/= [0-9]+$/= N/'
```

### Library names, and no perf binary

```run
# title: ltrace names and an absent perf
# companion: ltrace
/usr/bin/ltrace -o lt /usr/bin/echo hello >/dev/null
/usr/bin/sed -E 's/\(.*/(/' lt | /usr/bin/grep -E '^[A-Za-z_]' | /usr/bin/sort -u
if [ -x /usr/bin/perf ]; then /usr/bin/printf 'perf-present\n'; else /usr/bin/printf 'perf-absent\n'; fi
```

## Performance

Tracing answers "which call", not "how fast would it have been". The cost is roughly proportional to the number of calls. A `write` of one byte in a loop becomes a different program under strace. `-e` limits the tax and the log. `-c` avoids storing every line and still perturbs time. For a pipeline, start with `strace -c -f` at the terminal, read the busiest calls, then drop the tracer and time the untraced command with the harness.

I/O wait shows up as time in `read` and `write` that does not match user CPU from GNU time. CPU-bound compression shows up as user time with few syscalls. That pairing is the method. This lesson's examples are `echo`, which is too small to time. The compression and grep benches are the untraced numbers.

ltrace is heavier and less complete than strace on modern binaries. Prefer strace when the question is the kernel. Prefer a real profiler when the question is a hot function. perf would be that profiler. Because it is absent, a sampling profiler you already have in a language runtime (a Rust build with `perf` later, or a C++ profile on a machine with matching tools) is the honest next step. Do not fabricate a flame graph.

`strace -e trace=file` or `trace=openat` is the usual way to see a missing config file. It is chatty. Send it to `-o`.

## Tips and pitfalls

strace attaches with ptrace. Some sandboxes block that. If strace exits with "Operation not permitted", you are in one of those sandboxes. This capture host allowed it for the user's own processes. Do not try to strace another user's process.

`-f` across a `setuid` helper is restricted. These examples trace `echo` and `bash` only.

ltrace output is not a stable API. Filtering to names is how the page stays meaningful. Do not snapshot raw ltrace into a test.

`perf record` writes a `perf.data` file that is specific to the machine and the binary. Even on a host where perf works, that file is not a portable artifact, and this host cannot create one.

## Exercises

```exercise
expect-exit: 0
---title---
Confirm a write summary
---prompt---
Run `strace -c -e trace=write` on `/usr/bin/echo hi` and print `saw-write` if the summary mentions write.
---hint---
`-o` keeps the table in a file. `-c` is the summary.
---hint2---
`grep -q write` and then printf. Do not cat the time columns.
---solution---
`saw-write`.
---script---
/usr/bin/strace -c -e trace=write -o summary /usr/bin/echo hi >/dev/null
/usr/bin/grep -q write summary && /usr/bin/printf 'saw-write\n'
```

```exercise
expect-exit: 0
---title---
See fputs_unlocked
---prompt---
Run ltrace on `/usr/bin/echo hello` and print `saw-fputs` if that function name appears.
---hint---
Write the trace with `-o`. Search the file.
---hint2---
The libc write path is `fputs_unlocked` in this build. The syscall `write` is strace's view, not ltrace's.
---solution---
`saw-fputs`.
---script---
/usr/bin/ltrace -o lt /usr/bin/echo hello >/dev/null
/usr/bin/grep -q fputs_unlocked lt && /usr/bin/printf 'saw-fputs\n'
```

```exercise
expect-exit: 0
---title---
Record that perf is missing
---prompt---
Print `perf-absent` when `/usr/bin/perf` is not executable.
---hint---
`[ -x /usr/bin/perf ]` is the test.
---hint2---
This kernel has no matching linux-tools package. Absence is the correct result here.
---solution---
`perf-absent`.
---script---
if [ -x /usr/bin/perf ]; then /usr/bin/printf 'perf-present\n'; else /usr/bin/printf 'perf-absent\n'; fi
```
