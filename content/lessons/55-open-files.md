---
number: 55
slug: open-files
title: lsof and fuser
module: Companion Tools
level: intermediate
minutes: 25
summary: lsof lists open descriptors. fuser names the processes that hold a path. lsof is the lsof package. fuser is psmisc. Neither is coreutils. A deleted path can stay open.
objectives:
  - Attribute lsof and fuser to their packages
  - Show the basename of a descriptor this shell holds
  - Show that fuser sees the shell and that a closed file is a non-match
  - Recognize the deleted marker after unlinking an open file
manual: lsof | https://man7.org/linux/man-pages/man8/lsof.8.html
manual: fuser | https://man7.org/linux/man-pages/man1/fuser.1.html
manual: Coreutils rm | https://www.gnu.org/software/coreutils/manual/html_node/rm-invocation.html
gnu_vs_bsd: |
  BSD fstat and fuser are different programs. macOS lsof exists and is not this Ubuntu build. This lesson ran lsof 4.95.0 and psmisc fuser 23.7. No BSD fstat was executed.
---

`lsof` lists open files. It is not GNU coreutils. Ubuntu package `lsof`, upstream lsof. A "file" here is a descriptor: a regular file, a directory, a socket, a pipe. `fuser` answers a narrower question: which processes have this path open. Ubuntu package `psmisc`, upstream psmisc. It is not procps and not coreutils. Exit status 1 from `fuser` means no process held the path. Exit status 0 means at least one did. The table goes to stderr. Pids go to stdout. Both move, so the examples search for a stable word instead of printing the pid.

The Android and server case you actually hit is a log that was rotated or removed while a process still has it open. `rm` unlinks the directory entry. The inode remains until the last descriptor closes. `df` still shows the blocks. `ls` does not show the name. `lsof` shows the descriptor and marks it `(deleted)`. The example opens `hold.txt` on descriptor 3, removes the name, and looks for that marker. The path in the raw lsof line includes the scratch directory, which changes every capture, so the check is the marker and the basename, not the absolute path.

`lsof -a -p $$ -d 3` combines filters with AND. Without `-a`, extra selectors sometimes widen the search. `-Fn` is a parseable field mode. The `n` field is the name. Stripping directories leaves `hold.txt`, which is stable. This shell is the process. You do not need to lsof the whole machine to learn the tool, and a whole-machine lsof is slow and full of other users' sockets you should not publish.

`fuser -v hold.txt` while descriptor 3 is open reports this bash. Without `-v`, fuser prints a pid and not the command name. The example greps stderr for `bash` and prints `fuser-sees-bash`. A file nobody has open is the opposite case. `fuser` returns 1. The example records `fuser_closed:1`. Do not use `fuser -k`. That flag sends a signal, which is `pkill`'s job with a name you chose, not a sweep of whoever has a directory open. Killing every process that has a build tree open will kill your editor.

Permissions apply. lsof shows what you are allowed to see. Another user's descriptors may be hidden. A failure to see a pid is not proof the pid is gone.

Coreutils `ls` and `stat` look at directory entries. They do not list descriptors. That is why a deleted open file confuses `du` and `df`: `du` walks names, `df` sees blocks. lsof is the missing list.

## Worked examples

### The basename of descriptor 3

```run
# title: lsof on one descriptor
# companion: lsof
exec 3>hold.txt
/usr/bin/lsof -a -p $$ -d 3 -Fn | /usr/bin/sed -n 's|.*/||p'
```

### Unlinked and still open

```run
# title: deleted marker
# companion: lsof
exec 3>hold.txt
/usr/bin/rm hold.txt
/usr/bin/lsof -a -p $$ -d 3 | /usr/bin/grep -o '(deleted)'
```

### fuser sees the shell

```run
# title: fuser on an open path
# companion: fuser
exec 3>hold.txt
/usr/bin/fuser -v hold.txt >/dev/null 2>fuser.err
/usr/bin/grep -q bash fuser.err && /usr/bin/printf 'fuser-sees-bash\n'
```

### Nothing holds this file

```run
# title: fuser misses a closed file
# companion: fuser
/usr/bin/printf 'x\n' > closed.txt
set +e
/usr/bin/fuser closed.txt >/dev/null 2>/dev/null
status=$?
set -e
/usr/bin/printf 'fuser_closed:%s\n' "$status"
```

## Performance

`lsof` without a pid walks every descriptor it can open in `/proc`. On a busy host that is a lot of reads of small files, and it is slow. Always pass `-p` when you know the process. `-d` limits the descriptor. The examples do both. A cron job that runs unrestricted `lsof` every second will show up in its own `pidstat` as a CPU and metadata cost.

`fuser` on a single path is a smaller walk. `fuser` on a directory can match every process using any file under it, depending on flags, and that list is large. Ask for the file.

Neither tool changes I/O throughput. They explain a `du`/`df` disagreement after a delete. The fix for the space is to close the descriptor or restart the holder, not to run lsof again. Restarting is process startup, which the coreutils startup supplement measured for a trivial binary. A fat JVM is more.

These examples do not print byte rates. There is no companion-benchmark row for lsof, because a correct lsof of one descriptor is noise next to the harness.

## Tips and pitfalls

`exec 3>file` keeps the descriptor for the rest of the script. Close it with `exec 3>&-` when you want the "closed" case in the same script. The closed example uses a different file that was never opened.

lsof's field output and its human table disagree in column order. Scripts should use `-F`. Humans can read the table. The deleted example uses the table because `(deleted)` is visible there.

`fuser` writes the pid to stdout with no newline sometimes, so a later `printf` can sit on the same line. Send stdout to `/dev/null` if you only wanted the status or the stderr table.

Do not parse `lsof` of a network socket and treat the result as an authorization boundary. It is a debug view.

## Exercises

```exercise
expect-exit: 0
---title---
Name the open file
---prompt---
Open `hold.txt` on descriptor 3 and print the basename lsof reports.
---hint---
`-a -p $$ -d 3 -Fn`, then strip directories.
---hint2---
The `n` field is the name. The basename is `hold.txt`.
---solution---
`hold.txt`.
---script---
exec 3>hold.txt
/usr/bin/lsof -a -p $$ -d 3 -Fn | /usr/bin/sed -n 's|.*/||p'
```

```exercise
expect-exit: 0
---title---
See the deleted marker
---prompt---
Open `hold.txt`, remove it, and print the deleted marker from lsof.
---hint---
`rm` unlinks the name. The descriptor stays.
---hint2---
`grep -o '(deleted)'` prints only the marker.
---solution---
`(deleted)`.
---script---
exec 3>hold.txt
/usr/bin/rm hold.txt
/usr/bin/lsof -a -p $$ -d 3 | /usr/bin/grep -o '(deleted)'
```

```exercise
expect-exit: 0
---title---
Status when nobody has the file
---prompt---
Write `closed.txt` and print `fuser`'s status when no descriptor holds it.
---hint---
fuser exits 1. Capture `$?` under `set +e`.
---hint2---
Redirect both stdout and stderr so the pid format cannot leak into the capture.
---solution---
`fuser_closed:1`.
---script---
/usr/bin/printf 'x\n' > closed.txt
set +e
/usr/bin/fuser closed.txt >/dev/null 2>/dev/null
status=$?
set -e
/usr/bin/printf 'fuser_closed:%s\n' "$status"
```
