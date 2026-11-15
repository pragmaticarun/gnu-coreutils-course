---
number: 26
slug: cpu-pinned-benchmark
title: CPU-pinned benchmarks
module: Cookbook
level: advanced
minutes: 20
summary: taskset pins a child to CPU 0. The shell's $$ is the wrong pid. sha256sum is coreutils. The pin's median is the taskset-pin bench, not a single hyperfine glance.
manual: taskset | https://man7.org/linux/man-pages/man1/taskset.1.html
manual: sha256sum invocation | https://www.gnu.org/software/coreutils/manual/html_node/sha256sum-invocation.html
manual: hyperfine | https://github.com/sharkdp/hyperfine
gnu_vs_bsd: |
  taskset is Linux util-linux. BSD cpuset is a different interface. This recipe ran taskset from util-linux 2.39.3 and GNU sha256sum. It did not change CPU frequency.
---

A benchmark that wanders across cores picks up another job's cache. `taskset` is util-linux, not coreutils. `taskset -c 0 command` runs that command on CPU 0. `$$` in the parent shell is the parent. The affinity you meant to read is the child's, so the query has to run inside the child. `sha256sum` is coreutils and is single-threaded. Pinning it does not give it more cores. It only stops it moving. The bench id `taskset-pin` is 8 MiB of the byte `a`, five trials, pinned and unpinned. Read whether the medians separated. This recipe proves the affinity is `0` and that the checksum still matches.

hyperfine can wrap the same command. A single short run is inside its noise warning. The harness median is the number this course keeps. No governor was changed. No root was used.

## Steps

```run
# title: The child is pinned to 0
# companion: taskset
/usr/bin/taskset -c 0 /usr/bin/bash --noprofile --norc -c 'taskset -c -p $$' | /usr/bin/sed 's/.*: //'
```

```run
# title: The checksum does not change
# companion: taskset
/usr/bin/printf 'abc\n' > blob
/usr/bin/sha256sum blob > free.sum
/usr/bin/taskset -c 0 /usr/bin/sha256sum blob > pinned.sum
/usr/bin/cmp free.sum pinned.sum && /usr/bin/printf 'sums-match\n'
```

## Check yourself

```exercise
expect-exit: 0
---title---
Print the pinned affinity
---prompt---
Run a child under `taskset -c 0` and print its affinity list.
---hint---
Ask taskset for the affinity from inside the child so `$$` is the child.
---hint2---
`sed` can drop the label and leave `0`.
---solution---
`0`.
---script---
/usr/bin/taskset -c 0 /usr/bin/bash --noprofile --norc -c 'taskset -c -p $$' | /usr/bin/sed 's/.*: //'
```

## Performance

If the `taskset-pin` note says the run did not separate the variants, the pin was free and also unpaid. That is a result. Quote it that way. A noisy shared machine is where the pin reduces variance, and this capture host was otherwise idle enough that the disclosure's spreads are the evidence. Do not set the CPU governor. Do not taskset a threaded `zstd -T4` down to one CPU and then wonder where the threads went. The pin is a mask. Threads inside the process share it. hyperfine `--shell=none` avoids counting the shell. It still should not be compared with the Python harness as if the timers were the same experiment.
