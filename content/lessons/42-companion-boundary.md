---
number: 42
slug: companion-boundary
title: The package boundary
module: Companion Tools
level: beginner
minutes: 25
summary: None of the tools in this module are GNU coreutils. Ubuntu's awk is mawk unless you switched the alternative, the shell keyword time is not /usr/bin/time, and util-linux and procps are different upstreams from coreutils.
objectives:
  - Name the Ubuntu package and the upstream project before trusting a flag
  - Show that /usr/bin/awk is mawk here while gawk is a separate binary
  - Separate the bash keyword time from /usr/bin/time
  - Place vmstat in procps and iostat in sysstat, and place column and script in the util-linux source with different binary packages
manual: Coreutils introduction | https://www.gnu.org/software/coreutils/manual/html_node/Introduction.html
manual: GNU time | https://www.gnu.org/software/time/manual/time.html
manual: procps-ng | https://gitlab.com/procps-ng/procps
manual: util-linux flock | https://man7.org/linux/man-pages/man1/flock.1.html
gnu_vs_bsd: |
  BSD base systems ship their own awk, time, and process tools under different package names. macOS awk is often a BSD awk, and macOS has no dpkg. This lesson queries dpkg on Ubuntu only. No BSD binary was executed. The GNU coreutils manual still documents hostname, kill, and uptime, which Ubuntu packages elsewhere.
---

None of the tools in this module are GNU coreutils. Coreutils copies, lists, checksums, and slices bytes. The programs beside it search, edit streams, archive, compress, trace, and inspect processes. They have their own manuals, their own bug trackers, and their own flags. Calling them coreutils sends the next reader to the wrong document.

The check is mechanical. `dpkg -S` on an absolute path prints the Ubuntu binary package that owns that path. The upstream project is the group that writes the manual. Those two names often differ. `column` is the binary package `bsdextrautils` and the source package `util-linux`. `script` and `logger` are the binary package `bsdutils` and the same source. `flock`, `taskset`, `ionice`, `fallocate`, `findmnt`, `lsblk`, `setsid`, `prlimit`, and `rev` are the binary package `util-linux`. One upstream, three Ubuntu packages. Coreutils is none of them.

`vmstat` is easy to file with `iostat` and `pidstat` because the three screens look alike. On this Ubuntu image `vmstat` is the `procps` package, upstream procps-ng, the same family as `ps`, `top`, `free`, `pgrep`, and `pkill`. `iostat` and `pidstat` are `sysstat`. `fuser` is `psmisc`. `lsof` is its own package. The lesson for each family repeats the package so a script comment can carry it.

Ubuntu's default `awk` is mawk. `/usr/bin/awk` is an alternatives symlink. The mawk package has priority 5. The gawk package has priority 10, so installing gawk normally takes the name `awk`. This capture host was set back to mawk after gawk was installed, so examples that say `awk` still show the default Ubuntu implementation. Check `readlink -f /usr/bin/awk` on your machine before you paste a gawk function. Call `/usr/bin/gawk` when you need GNU awk. mawk will reject `gensub`.

`time` is a bash keyword. `type time` says so. The keyword does not accept GNU time's `-f` or `-v`. It tries to run a command named `-f`, fails, and then prints its own `real` / `user` / `sys` lines. `/usr/bin/time` is the `time` package, upstream GNU time. That binary accepts `-f 'exit:%x'` and `-v`. The keyword and the binary can both be present. Test the path `/usr/bin/time`, not `command -v time`.

`rsync` is not installed here, so this course does not demonstrate it. `perf` is not installed either. Ubuntu 24.04 publishes `linux-tools` builds for kernel 6.8. This host's kernel is 6.12.113+. There is no matching `perf` binary, and the tracing lesson describes `perf stat` and `perf record` without counters. A missing tool is a fact to print, not a number to invent.

## Worked examples

### Who owns the path

```run
# title: Packages that are not coreutils
# companion: dpkg
dpkg -S /usr/bin/grep
dpkg -S /usr/bin/sed
dpkg -S /usr/bin/mawk
dpkg -S /usr/bin/gawk
dpkg -S /usr/bin/tar
dpkg -S /usr/bin/vmstat
dpkg -S /usr/bin/iostat
dpkg -S /usr/bin/flock
dpkg -S /usr/bin/script
dpkg -S /usr/bin/column
```

### The keyword and the binary

```run
# title: time keyword versus /usr/bin/time
# companion: time
type time
set +e
{ time -f %x /usr/bin/true; } >kw.out 2>kw.err
status=$?
set -e
printf 'keyword_status:%s\n' "$status"
grep -F 'command not found' kw.err
/usr/bin/time -f 'exit:%x' /usr/bin/true >/dev/null 2>gnu.err
cat gnu.err
```

### Which awk answers

```run
# title: awk is mawk, gawk is beside it
# companion: awk
readlink -f /usr/bin/awk
/usr/bin/awk -W version | /usr/bin/head -n 1
/usr/bin/gawk --version | /usr/bin/head -n 1
```

### Present, absent, still not coreutils

```run
# title: Status of rsync, perf, and GNU time
# companion: time
set +e
command -v rsync >/dev/null
printf 'rsync_status:%s\n' $?
command -v perf >/dev/null
printf 'perf_status:%s\n' $?
command -v /usr/bin/time >/dev/null
printf 'gnu_time_status:%s\n' $?
set -e
```

## Performance

Package identity does not make a command fast. It stops you from timing the wrong program. A blog that says "awk is slow" may have timed gawk, mawk, or a one-liner that spawned `sort` per line. This host's one-pass mawk count against `sort | uniq -c` is the `awk-vs-sort` row in the companion benchmark file, not a sentence to memorize. The Python harness is included in every median. Caches were not dropped. No root, no sysctl.

The shell keyword `time` is the wrong tool when you want maximum resident set size. `/usr/bin/time -v` prints that field. The timing lesson shows the field names with the digits removed so one noisy run of `true` is not mistaken for a result. Comparative medians live in `public/benchmarks/companions.json`.

`perf` would answer a different question, cycles and instructions, and it is not installed. Describing `perf stat -e cycles,instructions -- command` is the method. Inventing a cycle count would be a lie. Do not install a 6.8 `perf` and point it at a 6.12 kernel to fill the gap.

## Tips and pitfalls

`dpkg -S` on a fragment can match several packages. Pass the absolute path. Diversion lines, such as the ones GNU parallel adds for `/usr/bin/parallel`, are not the package name. Read the line that ends in the path.

`command -v time` succeeds because of the keyword. That success does not mean `-v` will work.

Installing gawk on a stock Ubuntu changes `/usr/bin/awk`. Scripts that assumed mawk then start accepting gawk extensions, and scripts that assumed gawk still fail on a machine where nobody installed it. Pin the path in a build script.

`kill` and `uptime` have coreutils manual nodes and procps binaries on this image. The manual node is not proof of the package. `dpkg -S /usr/bin/kill` is the proof.

## Exercises

```exercise
expect-exit: 0
---title---
Name the package that owns vmstat
---prompt---
Run `dpkg -S` on `/usr/bin/vmstat` and leave the package line as the output.
---hint---
The path is absolute. vmstat is not sysstat on this image.
---hint2---
procps is the Ubuntu package. The upstream project is procps-ng.
---solution---
The captured line names procps. vmstat is not coreutils and it is not iostat.
---script---
dpkg -S /usr/bin/vmstat
```

```exercise
expect-exit: 0
---title---
Resolve awk
---prompt---
Print the real path of `/usr/bin/awk`.
---hint---
`readlink -f` follows the alternatives symlink.
---hint2---
On this capture host the target is `/usr/bin/mawk`. Another machine that installed gawk and left the alternative alone will differ.
---solution---
The line is the binary that the name `awk` currently selects.
---script---
readlink -f /usr/bin/awk
```

```exercise
expect-exit: 0
---title---
Ask GNU time for an exit code
---prompt---
Run `/usr/bin/true` under `/usr/bin/time` and print `exit:` plus the child's status. Do not use the shell keyword.
---hint---
The format string is `-f 'exit:%x'`. The report is on stderr.
---hint2---
Redirect stdout away and show the stderr file. The keyword `time` does not understand `-f`.
---solution---
The line is `exit:0`. The binary is the time package, not coreutils.
---script---
/usr/bin/time -f 'exit:%x' /usr/bin/true >/dev/null 2>gnu.err
cat gnu.err
```
