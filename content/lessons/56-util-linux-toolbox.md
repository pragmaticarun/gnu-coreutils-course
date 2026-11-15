---
number: 56
slug: util-linux-toolbox
title: The util-linux toolbox
module: Companion Tools
level: advanced
minutes: 45
summary: column, rev, flock, taskset, ionice, fallocate, findmnt, lsblk, script, logger, setsid, and prlimit come from util-linux. Ubuntu splits that source into util-linux, bsdutils, and bsdextrautils. None of them are coreutils.
objectives:
  - Map each binary to its Ubuntu package and to the util-linux upstream
  - Lock, pin, and limit a child without pinning the wrong pid
  - Punch a hole with fallocate and read it back with du and stat
  - Record that logger has no syslog socket on this host
manual: util-linux | https://github.com/util-linux/util-linux
manual: flock | https://man7.org/linux/man-pages/man1/flock.1.html
manual: taskset | https://man7.org/linux/man-pages/man1/taskset.1.html
manual: fallocate | https://man7.org/linux/man-pages/man1/fallocate.2.html
manual: Coreutils du | https://www.gnu.org/software/coreutils/manual/html_node/du-invocation.html
gnu_vs_bsd: |
  Several of these names exist in BSD with different flags. BSD column and logger are not this util-linux. flock(1) is a Linux wrapper around flock(2). macOS has no taskset. This lesson ran Ubuntu util-linux 2.39.3, bsdutils, and bsdextrautils only.
---

util-linux is an upstream project, not a single Ubuntu binary package, and it is not GNU coreutils. `dpkg-query -W -f '${source:Package}'` on `bsdutils` and `bsdextrautils` prints `util-linux`. The binaries are split. `column` is `bsdextrautils`. `script` and `logger` are `bsdutils`. `rev`, `flock`, `taskset`, `ionice`, `fallocate`, `findmnt`, `lsblk`, `setsid`, and `prlimit` are the `util-linux` binary package. Learn the binary package, because that is what `dpkg -S` prints and what an install line needs. Learn the source, because that is where the manual and the bugs live.

`column -t` aligns whitespace-separated fields into a table. It is a presentation tool. It does not parse CSV quotes. `rev` reverses each line. Both are byte tools with locale edges. They are the right hammer for a quick look at `ps` output and the wrong hammer for a file format.

`flock` takes an advisory lock on a file and runs a command. Two backup scripts can share one lock file so they do not run at once. `-n` fails immediately if the lock is held, which is what a cron job wants. The example holds the lock in a background `sleep` and shows the second `flock -n` failing. Advisory means a program that never calls flock is not stopped. It is a contract, not a kernel denial of writes.

`taskset -c 0` pins a process to CPU 0. The shell expands `$$` before `taskset` starts, so `taskset -c -p $$` reports the shell, not the child. Run the query inside the child: `taskset -c 0 bash -c 'taskset -c -p $$'`. The affinity list is then `0`. The benchmark id `taskset-pin` times `sha256sum` of 8 MiB with and without that pin. Read the note. A single-threaded checksum often does not separate. The pin is still real, and the example proves the affinity. No frequency scaling was changed. `taskset` is not a performance boost by itself.

`ionice -c 3` asks for the idle I/O class. The child in the example prints `idle`. The class is a hint to the kernel scheduler. It is not a bandwidth cap in bytes per second. On a quiet disk you will not see a difference. On a disk a backup is saturating, idle I/O waits. This course does not saturate a disk and does not time ionice.

`fallocate -l` reserves blocks. `fallocate --punch-hole` releases them in the middle of a file and leaves the apparent size from `stat` unchanged. `du` reports allocated bytes and drops. That is the same hole story as `truncate`, done through the fallocate system call. Filesystems differ. This host's ext4 accepted the punch. A filesystem that does not will return an error, and the script should notice.

`findmnt -n -o FSTYPE /` prints the root filesystem type. `df -T` from coreutils is the space view. They should agree on the type name. `lsblk` lists block devices. Names like `vda` are this machine's. The example prints only the unique `TYPE` values so a disk rename does not rewrite the lesson. Do not script against a device node you saw here.

`script` records a typescript of a command. The file contains a header with a timestamp and a carriage return after the payload. Strip `\r` before you grep for an exact line. `logger` writes to syslog. `--no-act` still opens `/dev/log` on this version, and this host has no such socket, so the status is failure. The example prints that status and the error. It does not claim a log line was stored. `setsid` starts a new session. Compare session ids of the parent and of a `setsid bash -c 'ps -o sid= -p $$'` child. They differ. `prlimit --nofile=64` runs a child whose `ulimit -n` is 64. `ulimit` is the shell builtin. `prlimit` is the program that can set the limit on a command without changing the rest of the script.

## Worked examples

### column and rev

```run
# title: Align fields, reverse a line
# companion: column
/usr/bin/printf 'a b\nc d\n' | /usr/bin/column -t
/usr/bin/printf 'abc\n' | /usr/bin/rev
```

### Lock, pin, and idle I/O

```run
# title: flock, taskset, ionice
# companion: flock
/usr/bin/flock lock -c '/usr/bin/sleep 1' &
/usr/bin/sleep 0.2
set +e
/usr/bin/flock -n lock -c '/usr/bin/printf got\n'
status=$?
set -e
/usr/bin/printf 'second:%s\n' "$status"
wait || true
/usr/bin/taskset -c 0 /usr/bin/bash --noprofile --norc -c 'taskset -c -p $$' | /usr/bin/sed 's/.*: //'
/usr/bin/ionice -c 3 /usr/bin/ionice
```

### Allocate, punch, and look at the mount

```run
# title: fallocate, findmnt, lsblk
# companion: fallocate
/usr/bin/fallocate -l 8192 blob
/usr/bin/du -B1 blob | /usr/bin/awk '{print "before:" $1}'
/usr/bin/fallocate --punch-hole --offset 0 --length 8192 blob
/usr/bin/du -B1 blob | /usr/bin/awk '{print "after:" $1}'
/usr/bin/stat -c 'apparent:%s' blob
/usr/bin/findmnt -n -o FSTYPE /
/usr/bin/lsblk -d -n -o TYPE | /usr/bin/sort -u
```

### script, logger, setsid, prlimit

```run
# title: Session tools and a missing syslog socket
# companion: setsid
/usr/bin/script -q -c '/usr/bin/printf "%s\n" payload-line' typescript >/dev/null
/usr/bin/tr -d '\r' < typescript | /usr/bin/grep -x payload-line
set +e
/usr/bin/logger --no-act -t cuwb 'hello-log' 2>logger.err
status=$?
set -e
/usr/bin/printf 'logger_status:%s\n' "$status"
/usr/bin/grep -F '/dev/log' logger.err
parent=$(/usr/bin/ps -o sid= -p $$ | /usr/bin/tr -d ' ')
child=$(/usr/bin/setsid /usr/bin/bash --noprofile --norc -c 'ps -o sid= -p $$' | /usr/bin/tr -d ' ')
if [ "$parent" != "$child" ]; then /usr/bin/printf 'new-session\n'; else /usr/bin/printf 'same-session\n'; fi
/usr/bin/prlimit --nofile=64 /usr/bin/bash --noprofile --norc -c 'ulimit -n'
```

## Performance

`taskset` changes which core runs the process. It does not change the instruction count. The `taskset-pin` bench is an 8 MiB `sha256sum`, five trials, warm cache, CPU 0 versus the default mask. Unpinned median elapsed time was 0.0062s and pinned was 0.0066s. The gap was 0.0004s and the widest trial spread was 0.0012s, so this run does not separate the variants. Pinning did not pay on this input. Quote that, not a hope about turbo. Pinning is how you make a benchmark less noisy when the machine is otherwise busy, and this machine's disclosure says nothing else was tuned.

`ionice -c 3` is the background-backup knob. It helps when something else needs the disk. A measurement taken on an idle disk will not show it. This course does not generate competing I/O and does not publish an ionice delta.

`fallocate` that reserves a large file is a metadata operation when the filesystem supports it, faster than writing zeros, and it consumes the space immediately. Punching a hole gives the space back. `dd` of zeros does not. The sparse-tar bench is the archive view of a hole created with `truncate`. fallocate's punch is the util-linux view. `du` is the coreutils view of allocation.

`flock` costs almost nothing next to the job it protects. The cost of forgetting it is two backups corrupting one output. That is not a median.

`script` copies the session through a pseudoterminal and is slower than running the command. Use it to record a reproduction, not to wrap a benchmark. The harness would time `script` and lie.

`logger` that cannot reach syslog fails fast here. In a real system a blocking syslog socket can stall a program. `--socket-errors` and a timeout belong in that design. This host simply has no socket.

## Tips and pitfalls

`flock` on NFS is only as good as the server's advisory locks. Do not assume it.

`taskset -p` changes an existing pid and needs permission. Changing your own child is allowed. Changing another user's pid is not, and this course does not try.

`prlimit` on pid 1 is a system change. These scripts only set a limit on a child they spawn.

`lsblk` and `findmnt` read kernel tables. They are not a license to format a disk. No example calls `mkfs`.

`column -t` widens with the data. A huge field makes a huge line. It is not a table serializer.

`rev` reverses bytes in the C locale and characters in a UTF-8 locale. A multibyte character reversed as bytes is corruption. `LC_ALL=C` if you mean bytes.

## Exercises

```exercise
expect-exit: 0
---title---
Reverse a line
---prompt---
Print `cba` by reversing `abc`.
---hint---
`rev` reads stdin.
---hint2---
The package is util-linux, not coreutils.
---solution---
`cba`.
---script---
/usr/bin/printf 'abc\n' | /usr/bin/rev
```

```exercise
expect-exit: 0
---title---
Show a failed non-blocking lock
---prompt---
Hold `lock` in a background flock for one second, then try `flock -n` and print the status.
---hint---
The second flock should fail. Capture `$?` with `set +e`.
---hint2---
`wait || true` collects the sleeper. Print `second:` and the status.
---solution---
`second:1`.
---script---
/usr/bin/flock lock -c '/usr/bin/sleep 1' &
/usr/bin/sleep 0.2
set +e
/usr/bin/flock -n lock -c '/usr/bin/printf got\n'
status=$?
set -e
/usr/bin/printf 'second:%s\n' "$status"
wait || true
```

```exercise
expect-exit: 0
---title---
Limit a child to 64 files
---prompt---
Run a bash whose open-file soft limit is 64 and print `ulimit -n`.
---hint---
`prlimit --nofile=64` wraps the child.
---hint2---
`--noprofile --norc` keeps bash from changing the limit in a startup file.
---solution---
`64`.
---script---
/usr/bin/prlimit --nofile=64 /usr/bin/bash --noprofile --norc -c 'ulimit -n'
```
