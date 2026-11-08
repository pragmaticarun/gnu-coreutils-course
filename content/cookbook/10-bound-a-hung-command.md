---
number: 10
slug: bound-a-hung-command
title: Stop a command that ignores the clock
module: Cookbook
level: intermediate
minutes: 14
summary: timeout returns 124 when it kills the child. --preserve-status returns 143 for SIGTERM on this host. A command that finishes in time keeps its own status.
manual: timeout invocation | https://www.gnu.org/software/coreutils/manual/html_node/timeout-invocation.html
gnu_vs_bsd: |
  `timeout` is GNU. macOS does not ship it in the base system. Status 124 is GNU timeout's "timed out" code. `--preserve-status` instead reports the signal status, 143 for SIGTERM here (128+15). BSD has no identical wrapper. This recipe ran GNU timeout.
---

A test that waits forever is a stuck CI job. `timeout DURATION COMMAND` starts the command and sends TERM when the duration elapses. If the command is still running when the signal fires, timeout exits 124 unless you passed `--preserve-status`. With that flag, this host exits 143, because the child died from SIGTERM and 128+15 is 143. If the command finishes early, you see the command's status and timeout does not invent 124.

Pick the status your harness can branch on. 124 is easier to recognize as "the wrapper fired". 143 is easier when you already have a signal table and you want the wrapper to be invisible. Use one convention in a repository and document it. Do not treat both as "non-zero, so the build failed" without a message. A compiler error and a hang want different retries.

`timeout` applies to the process it execs. A pipeline is not one process. `timeout 1 sleep 5 | sleep 5` bounds only the first sleep. Wrap the pipeline in `timeout 1 bash -c '...'` when every stage must share the deadline. The process-wrapper lesson records the same statuses. This recipe is the short form you can paste above a test binary.

The examples use `sleep` because it is predictable. A real test binary replaces `sleep`. Keep the duration longer than a healthy run and shorter than the job's overall budget.

## Steps

```run
# title: Default status is 124
set +e
/usr/bin/timeout 1 /usr/bin/sleep 3
/usr/bin/printf 'timed_out:%s\n' $?
/usr/bin/timeout 2 /usr/bin/true
/usr/bin/printf 'finished:%s\n' $?
set -e
```

```run
# title: preserve-status reports the signal
set +e
/usr/bin/timeout --preserve-status 1 /usr/bin/sleep 3
/usr/bin/printf 'preserved:%s\n' $?
set -e
```

## Check yourself

```exercise
expect-exit: 124
---title---
Let the wrapper fire
---prompt---
Run `timeout 1 sleep 3`.
---hint---
124 is timeout's own status.
---solution---
The command does not sleep for three seconds. The status is 124.
---script---
/usr/bin/timeout 1 /usr/bin/sleep 3
```

## Performance

`timeout` costs one extra process and a sleep until the child exits or the deadline hits. Next to a multi-minute test, that is noise. Next to a microbenchmark, it is part of the number, so keep it outside the timed region. The one-second examples in this recipe spend about one second each because that is the deadline. They are not a measurement of `sleep` accuracy. A deadline that is tighter than the scheduler's jitter will flake. Leave margin. Killing a process does not roll back its partial output. If the hung command was writing an artifact, delete the artifact in the 124 branch before the next retry, or the next step will trust a short file.
