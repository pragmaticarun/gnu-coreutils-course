---
number: 35
slug: process-wrappers
title: env, timeout, stdbuf, nice, nohup, nproc
module: Space, time, and processes
level: advanced
minutes: 34
summary: These six programs do not transform files. They change the environment, the clock, the stdio policy, the niceness, the hangup signal, or they report how many processors the scheduler will give you.
objectives:
  - Run one command in another directory and with a variable removed
  - Bound a sleep with timeout and read statuses 124 and 143
  - Explain why stdbuf -iL is rejected and where libstdbuf.so comes in
  - Treat nproc as a hint for job count, not as a benchmark result
manual: env invocation | https://www.gnu.org/software/coreutils/manual/html_node/env-invocation.html
manual: timeout invocation | https://www.gnu.org/software/coreutils/manual/html_node/timeout-invocation.html
manual: stdbuf invocation | https://www.gnu.org/software/coreutils/manual/html_node/stdbuf-invocation.html
manual: nice invocation | https://www.gnu.org/software/coreutils/manual/html_node/nice-invocation.html
manual: nohup invocation | https://www.gnu.org/software/coreutils/manual/html_node/nohup-invocation.html
manual: nproc invocation | https://www.gnu.org/software/coreutils/manual/html_node/nproc-invocation.html
gnu_vs_bsd: |
  `timeout`, `stdbuf`, `nproc`, and GNU `env -C` / `-S` are GNU extensions. macOS needs Homebrew `gtimeout` and has no `stdbuf`. `nice` and `nohup` exist in both userlands, but a negative niceness adjustment needs privilege on both, and the diagnostic text differs. This lesson captured GNU coreutils 9.4. The niceness warning and the 124/143 statuses are from this host, not from a BSD run.
---

`env` is how you exec a program with a different environment without editing the parent shell. `-C` changes the working directory for that child only. `-u NAME` removes one variable. `-i` starts from an empty environment, which is the right way to prove a build does not depend on a stray `CFLAGS` from your prompt. You must then pass `PATH` if the child needs to find binaries. `-S` splits a single argument into a command, which is useful in a shebang line and easy to quote wrong in a lesson, so the examples use `-C`, `-u`, and `-i` instead.

`timeout` starts a command and sends it a signal when the duration elapses. The default signal is TERM. The default status, when timeout itself decides the command ran too long, is 124. `--preserve-status` makes timeout exit with the status the signal produced. On this host `timeout --preserve-status 1 sleep 3` exits 143, which is 128 plus SIGTERM (15). That distinction matters in a test harness: 124 means "the wrapper fired", and 143 means "the child died of TERM" if you asked to preserve status. A command that finishes in time returns its own status, and timeout stays out of the way.

`stdbuf` adjusts buffering for programs that use stdio. It does this by arranging `LD_PRELOAD` of `libstdbuf.so` from the coreutils libexec directory before the child starts. `-oL` requests line buffering on stdout, which is the setting you want when a progress line should appear before the pipe fills. `-iL` is rejected: the manual and the binary agree that line buffering stdin is meaningless, and the status is 125, one of the special statuses the exit-status node lists for `stdbuf`. `cat` and `dd` are called out in the manual because they do not use stdio for the data path, so stdbuf does not change their block size. `tee` resets buffering on its own. The buffering benchmark in this course measures a program that does use stdio, and it reports the numbers it measured. It does not claim a universal speedup.

`nice` adds to the niceness of a command. A positive adjustment makes the process more willing to yield. On this host `nice -n 5 true` exits 0. A negative adjustment asks to be less nice, which an ordinary user cannot do. `nice -n -1 true` prints "cannot set niceness: Permission denied" and still runs the command. The status is the command's status, so `true` yields 0 and `false` yields 1. The warning is not a failed command unless you treat stderr as fatal. Do not wrap `nice` around a benchmark and then claim the elapsed time changed because of the warning. This course does not rank nice levels.

`nohup` arranges for the child to ignore SIGHUP and, if stdout is a terminal, redirects it to `nohup.out`. When stdout is already redirected, `nohup` does not create that file. The example redirects to `redirected.out` and lists the directory so you can see the absence. `nohup` is not a service manager. A child that ignores hangup still dies when the machine reboots, and it still needs `timeout` if it can hang.

`nproc` prints how many processors are available to the current process, after considering affinity and cgroup limits the kernel reports. `--all` prints the installed count. `--ignore=N` subtracts N, which is the usual way to leave one processor for the desktop while a compile runs. On the capture host the three numbers were 4, 4, and 3 in the order `nproc`, `nproc --all`, `nproc --ignore=1`. Your laptop can differ. Use the value as a starting `-j` for a build. It is not a measurement of memory bandwidth, and a machine with 4 processors and 2 GiB of RAM will thrash if every job is a linking C++ binary. The performance lesson and the benchmark page are where resource tradeoffs are stated with inputs attached.

## Worked examples

### A different directory and a removed variable

```run
# title: env -C, -u, and -i
/usr/bin/env -C /tmp /usr/bin/pwd
set +e
/usr/bin/env -u HOME /usr/bin/printenv HOME
/usr/bin/printf 'home_status:%s\n' $?
set -e
/usr/bin/env -i PATH=/usr/bin /usr/bin/printf 'clean\n'
```

### timeout statuses

```run
# title: 124 versus preserve-status
set +e
/usr/bin/timeout 1 /usr/bin/sleep 3
/usr/bin/printf 'default:%s\n' $?
/usr/bin/timeout --preserve-status 1 /usr/bin/sleep 3
/usr/bin/printf 'preserved:%s\n' $?
set -e
```

### nice without privilege

```run
# title: Positive nice works, negative nice warns
/usr/bin/nice -n 5 /usr/bin/true
/usr/bin/printf 'raised:%s\n' $?
set +e
/usr/bin/nice -n -1 /usr/bin/true
/usr/bin/printf 'lower:%s\n' $?
set -e
```

### nohup does not invent nohup.out when stdout is redirected

```run
# title: Redirected nohup
/usr/bin/nohup /usr/bin/printf 'hi\n' > redirected.out
/usr/bin/ls -1
/usr/bin/cat redirected.out
```

### Processor count and the stdbuf library

```run
# title: nproc and libstdbuf.so
/usr/bin/nproc
/usr/bin/nproc --all
/usr/bin/nproc --ignore=1
/usr/bin/ls -l /usr/libexec/coreutils/libstdbuf.so
```

## Recipes

Wrap a flaky integration test with `timeout 30` and treat 124 as "the test hung", which is a failure, not a skip. Use `--preserve-status` only when you need to distinguish the signal the child actually died from.

Start a one-off data transform from a service directory with `env -C "$workdir" -u DISPLAY` so the child cannot see a variable it should not, and so relative paths resolve where you think they do. Clear the environment with `-i` in a packaging script, then add back the four variables you intend.

Pick a build job count with `nproc --ignore=1` on a workstation and plain `nproc` in CI where the cgroup is already the limit. Write it into a variable once. Do not call `nproc` inside the inner loop.

## Tips and pitfalls

`timeout` of a pipeline applies to the command you named, not to every stage, unless you pass a shell. `timeout 1 bash -c 'sleep 10 | sleep 10'` is the form that covers both. `timeout 1 sleep 10 | sleep 10` only bounds the first sleep.

`stdbuf` cannot line-buffer a program that writes with `write(2)` and never calls stdio. If the progress line still arrives late, the program is not a stdio program. Read the manual's list before you file a bug.

`nohup command &` in an interactive shell still leaves a job. Redirect stdin from `/dev/null` as well if the child might try to read a terminal that is going away.

`env -i` without `PATH` cannot find `printf` by name. The example passes `PATH=/usr/bin` and an absolute `printf` so either spelling works.

## Exercises

```exercise
expect-exit: 0
---title---
Change directory for one command
---prompt---
Print the working directory of `pwd` when `env -C /tmp` runs it.
---hint---
The parent shell's directory does not change.
---solution---
The printed path is `/tmp`.
---script---
/usr/bin/env -C /tmp /usr/bin/pwd
```

```exercise
expect-exit: 124
---title---
Let timeout fire
---prompt---
Run `timeout 1 sleep 3` and allow the wrapper status.
---hint---
124 means the duration elapsed. It is not sleep's own status.
---solution---
Status 124. The command is stopped because of the wrapper.
---script---
/usr/bin/timeout 1 /usr/bin/sleep 3
```

```exercise
expect-exit: 125
---title---
Reject line-buffered stdin
---prompt---
Run `stdbuf -iL true` and let it fail.
---hint---
Status 125 is the stdbuf usage error.
---solution---
stderr says line buffering stdin is meaningless.
---script---
/usr/bin/stdbuf -iL /usr/bin/true
```

## Performance

`env`, `nice`, and `nohup` add one process and almost no steady-state cost. They are not levers for a tight loop. `timeout` adds a process that sleeps until the deadline or until the child exits. The cost is the extra process and the signal, which is noise next to a compile and relevant next to a microbenchmark that times a millisecond command. Do not put `timeout` inside the timed section of a benchmark unless the deadline is the subject.

`stdbuf` changes when bytes cross into the pipe, which changes latency and can change how much CPU a downstream reader spends waking up. It does not change how many bytes a checksum must read. The buffering benchmark is the place that records a first-byte delay with a fixed program. Read that page before you generalize. A line-buffered producer can be slower in throughput because it writes more often. "Faster" depends on whether you are waiting for the first line or for the last byte.

`nproc` is a number of processors, not a number of jobs that will finish sooner. Past the point where jobs fit in cache and RAM, more jobs increase elapsed time. This course does not publish a universal `-j` winner. It tells you to start from `nproc`, watch RSS, and stop raising the count when the machine swaps.
