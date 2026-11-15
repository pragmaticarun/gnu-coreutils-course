---
number: 48
slug: gnu-parallel
title: GNU parallel and xargs -P
module: Companion Tools
level: advanced
minutes: 30
summary: GNU parallel schedules jobs across inputs. It is not coreutils, and it is not the moreutils command of the same name. xargs -P is the smaller pool.
objectives:
  - Identify /usr/bin/parallel as GNU parallel and the diversion of moreutils parallel
  - Run a NUL-safe parallel command with --will-cite
  - Write xargs -P output to separate files so order does not matter
  - Read the tiny-process benchmark before adding workers
manual: GNU parallel | https://www.gnu.org/software/parallel/parallel.html
manual: GNU parallel man page | https://www.gnu.org/software/parallel/man.html
manual: Coreutils nproc | https://www.gnu.org/software/coreutils/manual/html_node/nproc-invocation.html
gnu_vs_bsd: |
  BSD systems do not ship GNU parallel. xargs -P is a GNU findutils extension and is not POSIX. moreutils parallel is a different, simpler program and Ubuntu diverts it when the GNU package is installed. This lesson ran GNU parallel 20231122 and GNU xargs only.
---

GNU parallel runs a command across a list of arguments, a list of files, or a set of records. It is not GNU coreutils. The Ubuntu package is `parallel`. The upstream project is GNU parallel. `/usr/bin/parallel --version` prints the GNU banner. moreutils also ships a command named `parallel`, a much smaller loop. Installing the GNU package diverts that binary to `/usr/bin/parallel.moreutils`. `dpkg -S /usr/bin/parallel` mentions the diversion. If a script wanted the moreutils loop, the diverted name is the one that still is that loop. This lesson uses the GNU binary.

GNU parallel prints a citation notice until you tell it you have seen it. In a sandbox, `HOME` is the scratch directory, so the notice would come back on every run. `--will-cite` acknowledges it for that invocation. Use it in scripts. Do not pretend the notice is part of the job's stderr.

The input methods that matter next to findutils are `:::` for arguments and `--null` (`-0`) for NUL-separated names on stdin. `find -print0 | parallel --will-cite -0 command` is the parallel form of `xargs -0`. A name with a space stays one argument. `-j` sets the number of jobs. The default is one job per core, which is a lot when each job is a compiler that already uses every core. For a C++ or Rust build, the build system should own the pool. parallel is for the jobs the build system does not schedule: compressing artifacts, checksums of a download directory, resizing a pile of independent files.

`xargs -P` is the smaller tool from findutils. It has no citation notice and fewer input languages. `-P 4 -n 1` runs four commands, one input each. Completion order is not input order. If two workers write the same stdout, the lines interleave. Give each worker its own output file, or accept a scramble. The example copies into an output directory and then lists that directory with `sort`, so the captured names are stable.

Process overhead decides whether the pool helps. A `sha256sum` of a few bytes spends its time in `exec`, not in the hash. Adding workers adds scheduler time. The benchmark id `xargs-parallel` runs 120 such checksums with `xargs -P 1`, `xargs -P` at a cap of 4, and `parallel -j` at the same cap. Five trials, median, warm cache, no root. The note says whether they separated. On a tiny job, "more parallel" can be slower or tied. That result is allowed. A job that compresses a multi-megabyte file per input is the case where the pool pays, and the compression lesson measures threads inside one process, which is a different knob.

`nproc` from coreutils reports how many processors the process may use. It is the input to `-j`, not a reason to always pass that number. A laptop that is also compiling does not have those cores free. Cap the pool.

## Worked examples

### Version and diversion

```run
# title: GNU parallel owns the name
# companion: parallel
/usr/bin/parallel --version | /usr/bin/head -n 1
dpkg -S /usr/bin/parallel
```

### Arguments in order for a trivial command

```run
# title: --will-cite and :::
# companion: parallel
/usr/bin/parallel --will-cite /usr/bin/printf '%s\n' ::: a b
```

### NUL names

```run
# title: parallel -0 keeps a space
# companion: parallel
/usr/bin/mkdir names
/usr/bin/printf '1\n' > "names/my file"
/usr/bin/find names -type f -print0 | /usr/bin/parallel --will-cite -0 /usr/bin/wc -c
```

### xargs -P writes separate files

```run
# title: A pool whose outputs can be sorted
# companion: xargs
/usr/bin/mkdir in out
/usr/bin/printf 'a\n' > in/a.txt
/usr/bin/printf 'b\n' > in/b.txt
/usr/bin/find in -type f -print0 | /usr/bin/xargs -0 -P 2 -I {} /usr/bin/cp {} out/
/usr/bin/find out -type f -print | LC_ALL=C /usr/bin/sort
```

## Performance

GNU parallel is a Perl program. It starts slower than xargs. On a job of tens of milliseconds the startup can dominate. On a job of seconds it disappears. The benchmark id `xargs-parallel` checksums 120 one-line files. On this host `xargs -P4` median elapsed time was 0.0298s, `xargs -P1` was 0.0913s, and GNU parallel `-j4` was 0.2969s. The gap was 0.2671s and the widest trial spread was 0.0781s, so the medians separated. The Perl startup is the cost on this input. Do not cite that row as the speed of parallel compression. Pigz and `zstd -T` thread inside one process and do not pay one Perl startup per file. Use them when the files are few and large. Use parallel or `xargs -P` when the files are many and each compression is independent.

`-j` higher than the useful CPU count adds context switches. `nproc` is an upper bound, not a target, when the job is single-threaded and the machine is quiet. When the job is already threaded, `-j 1` is often right and the threads belong inside the job. Stacking `parallel -j 4` around `zstd -T 4` asks for 16 workers. The compression benchmark varies `-T` inside one zstd and `-p` inside one pigz so that stacking is not hidden in the number.

Stdout from parallel is serialized per job when you use its grouping, and it is still data you have to read. Discard it, or write files, when the consumer is slower than the pool. A pool that produces more lines than `sort` can swallow just moves the wait.

No frequency scaling was changed. The numbers do not predict a laptop on battery or a CI runner with two cores.

## Tips and pitfalls

`--will-cite` is for scripts. An interactive user can acknowledge the notice once. A sandbox with a fresh `HOME` has not acknowledged it.

The moreutils binary is `parallel.moreutils` after the diversion. Its interface is not GNU parallel's interface. A snippet from a moreutils blog will not run on `/usr/bin/parallel` here, and the reverse is also true.

`:::` splits on the shell first. A file name with a space must not be passed through an unquoted command substitution into `:::`. Use `-0` and a NUL list.

`-P` and `-I` together in GNU xargs imply one argument per command. That is what the copy example wants. It is the opposite of batching a hundred names into one `sha256sum`.

## Exercises

```exercise
expect-exit: 0
---title---
Print the GNU banner
---prompt---
Print the first line of `parallel --version`.
---hint---
Call `/usr/bin/parallel` so the shell does not pick another name.
---hint2---
`head -n 1` keeps the copyright lines out of the capture.
---solution---
The line starts with `GNU parallel`. The tool is not coreutils.
---script---
/usr/bin/parallel --version | /usr/bin/head -n 1
```

```exercise
expect-exit: 0
---title---
Run two arguments
---prompt---
Use GNU parallel with `--will-cite` to printf `a` and `b` on their own lines.
---hint---
`:::` passes the arguments. The command is printf.
---hint2---
`parallel --will-cite /usr/bin/printf '%s\n' ::: a b`.
---solution---
Two lines, `a` then `b`.
---script---
/usr/bin/parallel --will-cite /usr/bin/printf '%s\n' ::: a b
```

```exercise
expect-exit: 0
---title---
Copy with a pool and sort the names
---prompt---
Copy `in/a.txt` and `in/b.txt` into `out/` with `xargs -P 2`, then list `out` in C locale order.
---hint---
`-I {}` and `cp {} out/`. Sort the result so the pool's finish order cannot change the capture.
---hint2---
`find in -type f -print0` feeds NUL names.
---solution---
`out/a.txt` and `out/b.txt`, sorted.
---script---
/usr/bin/mkdir in out
/usr/bin/printf 'a\n' > in/a.txt
/usr/bin/printf 'b\n' > in/b.txt
/usr/bin/find in -type f -print0 | /usr/bin/xargs -0 -P 2 -I {} /usr/bin/cp {} out/
/usr/bin/find out -type f -print | LC_ALL=C /usr/bin/sort
```
