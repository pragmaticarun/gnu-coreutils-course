---
number: 47
slug: findutils-and-nul
title: find, xargs, locate, and NUL
module: Companion Tools
level: intermediate
minutes: 40
summary: GNU find and xargs are findutils. plocate searches a database and is not find. -print0, xargs -0, and sort -z keep names that contain spaces or newlines.
objectives:
  - Attribute find and xargs to findutils and locate to plocate
  - Pass a name that contains a space or a newline without splitting it
  - Explain why a private updatedb fails here with fchown
  - Choose find for a tree you just wrote and plocate for the indexed system
manual: GNU findutils | https://www.gnu.org/software/findutils/manual/html_node/index.html
manual: plocate | https://plocate.sesse.net/
manual: Coreutils sort | https://www.gnu.org/software/coreutils/manual/html_node/sort-invocation.html
gnu_vs_bsd: |
  BSD find uses different predicates for maximum depth and for printing NULs. BSD locate is a different database format from plocate. macOS find is not GNU findutils 4.9. This lesson ran Ubuntu's find, xargs, and plocate only.
---

`find` and `xargs` are GNU findutils. They are not GNU coreutils. Ubuntu package `findutils` 4.9.0 owns `/usr/bin/find` and `/usr/bin/xargs`. `find` walks a tree and tests names, types, and timestamps. `xargs` reads names and builds argument lists so you do not start one process per file and do not blow past `ARG_MAX`.

The failure mode is the shell's splitting. `find` without `-print0` writes a newline after each path. `xargs` without `-0` splits on blanks. A file named `my file` becomes two arguments. A file named with an embedded newline becomes two lines of `find` output and one extra "file" that does not exist. `-print0` ends each path with a NUL. `xargs -0` reads those records. Coreutils `sort -z` orders them. GNU grep's `-z` is the same idea for data records, and it is taught in the grep lesson. The three flags are a set: `-print0`, `-0`, `-z`. Drop them together or not at all.

`find -exec command {} +` batches paths into as few commands as the argument limit allows. `{} \;` runs once per file. The plus form is the one that matches why `xargs` exists. `-exec` does not invoke a shell unless you ask for `sh -c`. That is a feature. A pipeline needs `xargs` or an explicit shell, and the shell must not split the name again.

`locate` on this host is not findutils. `/usr/bin/locate` is an alternative for `plocate`, Ubuntu package `plocate`, upstream plocate. It searches a database built by `updatedb`, not the live tree. A file you just created is invisible until the database is rebuilt. The system database was initialized when the package was installed and can answer `plocate --literal /usr/bin/mawk`. A private database for a scratch directory would be the right demo, and `updatedb -o` fails here with `fchown: Operation not permitted`. plocate's updatedb chowns the database to its group. This sandbox is not root and has no `CAP_CHOWN`. The failure is the lesson. Do not pretend a private index exists. For a tree you just wrote, use `find`.

`xargs` exits 255 from the child can stop the whole run. GNU `xargs -r` does not run the command on empty input. Without `-r`, some xargs implementations still run the command once with no input. Know which one you have. This host is GNU xargs. `-P` runs several commands at once. It is a pool, not GNU parallel. Order of completion is not order of input. The parallel lesson compares them. If you use `-P`, write each worker to its own output file and sort the names afterward.

## Worked examples

### A space survives

```run
# title: find -print0 and xargs -0
# companion: find
/usr/bin/mkdir box
/usr/bin/printf 'x\n' > "box/my file"
/usr/bin/find box -type f -print0 | /usr/bin/xargs -0 /usr/bin/wc -c
```

### A newline does not survive a line count

```run
# title: Newline in the name
# companion: find
/usr/bin/mkdir box
/usr/bin/printf 'y\n' > "box/a
name"
lines=$(/usr/bin/find box -type f | /usr/bin/wc -l | /usr/bin/tr -d ' ')
nuls=$(/usr/bin/find box -type f -print0 | /usr/bin/tr -cd '\0' | /usr/bin/wc -c | /usr/bin/tr -d ' ')
/usr/bin/printf 'lines:%s\nnuls:%s\n' "$lines" "$nuls"
```

### The system index knows mawk

```run
# title: plocate literal path
# companion: plocate
/usr/bin/plocate --literal /usr/bin/mawk
```

### A private updatedb cannot chown

```run
# title: updatedb fails closed without CAP_CHOWN
# companion: plocate
/usr/bin/mkdir tree
/usr/bin/printf 'hi\n' > tree/needle.txt
set +e
updatedb -U "$PWD/tree" -o "$PWD/locatedb" --prunepaths '' 2>upd.err
status=$?
set -e
/usr/bin/printf 'updatedb_status:%s\n' "$status"
/usr/bin/grep -F 'fchown' upd.err
```

## Performance

`find` is a metadata walk. It does not read file bodies unless the predicate asks it to, for example `-size` after the name is already known still may stat, and a later `grep` or `sha256sum` reads bytes. Put the cheap tests first. `-name '*.o'` before an `-exec` that checksums. `locate` is a binary search of an index and it is the wrong speed story for a tree that changed during the build. The index is stale by design.

`xargs` batches to save process startup. One `sha256sum` with a hundred names is cheaper than a hundred `sha256sum` processes. `-n 1` forces one name per process and brings the startup back. `-P` overlaps those processes. On tiny files the overlap loses to scheduling. The benchmark id `xargs-parallel` times `-P 1`, `-P` at the host's capped width, and GNU parallel on 120 tiny checksums. Read it before you add `-P` to a script whose jobs are smaller than the fork.

`sort -z` is coreutils and it is the sort that can order NUL records. A newline sort of `find` output is already wrong if any name contains a newline. Sorting after `xargs` has expanded the names does not repair the split.

plocate's database build is I/O over the whole root. The package's timer does that as root. This course does not run it, does not drop caches, and does not time a walk of `/`. A user-level `find` of a project tree is the measurement you can reproduce without privileges.

## Tips and pitfalls

`find . -name '*.rs' -print0` is the walk. The build system knows the file list better than find does when the build generated it. Prefer the build system's list for Rust and Android sources. Use find when you are cleaning or auditing a tree the build system does not own.

`xargs` without `-0` and `find` without `-print0` fail together. Quoting the file in the shell does not help, because xargs does the splitting after the shell.

`plocate` patterns are not always literal. `--literal` in the example asks for the path as bytes. A regex search of the whole index is slower and it is a different question.

`updatedb` writing `/var/lib/plocate/plocate.db` is a system job. Do not point a lesson script at that path.

## Exercises

```exercise
expect-exit: 0
---title---
Count a name that contains a space
---prompt---
Create `box/my file` with two bytes and a newline, and run `wc -c` through `find -print0` and `xargs -0`.
---hint---
Quote the redirection target. Pass `-0` to xargs.
---hint2---
`wc -c` prints the byte count and the path. The path must still contain the space.
---solution---
One wc line for `box/my file`. The count is 2.
---script---
/usr/bin/mkdir box
/usr/bin/printf 'x\n' > "box/my file"
/usr/bin/find box -type f -print0 | /usr/bin/xargs -0 /usr/bin/wc -c
```

```exercise
expect-exit: 0
---title---
Count NULs, not lines
---prompt---
Create one file whose name contains a newline. Print the line count of plain find and the NUL count of find -print0.
---hint---
Plain find splits the name into two lines. `-print0` emits one NUL.
---hint2---
Strip spaces from `wc` output so the labels are stable.
---solution---
`lines:2` and `nuls:1`.
---script---
/usr/bin/mkdir box
/usr/bin/printf 'y\n' > "box/a
name"
lines=$(/usr/bin/find box -type f | /usr/bin/wc -l | /usr/bin/tr -d ' ')
nuls=$(/usr/bin/find box -type f -print0 | /usr/bin/tr -cd '\0' | /usr/bin/wc -c | /usr/bin/tr -d ' ')
/usr/bin/printf 'lines:%s\nnuls:%s\n' "$lines" "$nuls"
```

```exercise
expect-exit: 0
---title---
Look up a path in plocate
---prompt---
Print the plocate hit for the literal path `/usr/bin/mawk`.
---hint---
`--literal` disables pattern metacharacters.
---hint2---
This uses the system database built at package install. It is not a search of the scratch directory.
---solution---
The line is `/usr/bin/mawk`. plocate is not coreutils and not findutils.
---script---
/usr/bin/plocate --literal /usr/bin/mawk
```
