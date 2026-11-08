---
number: 7
slug: stat-touch-timestamps
title: stat, touch, and timestamps
module: Seeing files
level: intermediate
minutes: 30
summary: stat prints kernel metadata with a format string. touch sets timestamps. GNU and BSD spell those jobs with different flags, and ext4's type code confuses stat -f.
objectives:
  - Print size, mode, owner, and mtime with stat -c
  - Set an explicit timestamp with touch -d and copy one with touch -r
  - Distinguish stat on a file from stat -f on a filesystem
  - Explain why stat -f can say ext2/ext3 on an ext4 volume
manual: stat invocation | https://www.gnu.org/software/coreutils/manual/html_node/stat-invocation.html
manual: touch invocation | https://www.gnu.org/software/coreutils/manual/html_node/touch-invocation.html
manual: File timestamps | https://www.gnu.org/software/coreutils/manual/html_node/File-timestamps.html
gnu_vs_bsd: |
  This is the sharpest everyday split. GNU `stat -c '%s'` is BSD `stat -f %z` (the format letters differ too). GNU `stat -f` means filesystem, not format. BSD `touch` does not accept GNU `-d`; it uses `-t` with a different timestamp grammar. Scripts that try `stat -c` on macOS fail immediately. Nothing here was run on BSD. The captured `stat -f` line is this host's GNU coreutils reading this filesystem.
---

`stat` reads the inode (and, with `-f`, the filesystem) and prints what you ask. The default multi-line layout is for a person. `stat -c` is for a script. Format sequences include `%s` size in bytes, `%a` mode in octal, `%A` mode in symbolic form, `%U` and `%G` owner names, `%u` and `%g` ids, `%F` file type, `%y` human mtime, `%Y` mtime as seconds since the epoch, `%n` the name, `%h` the link count, `%b` the number of allocated blocks, and `%B` the block size those blocks are counted in. `%b` times `%B` is the allocated space, which is not `%s` for a sparse file. The du lesson uses that pair.

`touch` creates an empty file or updates timestamps. `touch -d '2020-01-02 03:04:05 UTC'` sets both times to that instant on GNU touch. `touch -r other file` copies timestamps from `other`. `touch -c` will not create a missing file. None of this writes your data. A reproducible build that needs `SOURCE_DATE_EPOCH` still has to pass that into the compiler; `touch` only fixes the inode clock after the fact.

Filesystem identity is where this host is a good teacher. `df -T` on the capture disk reports `ext4`. `stat -f -c '%T'` reports `ext2/ext3`. GNU stat is not confused about the mount in a vague way: the kernel's statfs type code for ext2, ext3, and ext4 is the same historic magic, and the format sequence prints that shared name. Use `df -T` or `findmnt` (findmnt is util-linux, not coreutils) when you need the type string a person means. Use `stat -f -c '%s'` when you need the filesystem block size.

Timestamps you copy from another machine are not a security log. They are metadata the owner can set, which is exactly why `touch -d` works without being root. Do not authenticate a file by its mtime. Checksum the bytes.

## Worked examples

### One field, not a paragraph

```run
# title: Format strings for size, mode, and type
/usr/bin/printf 'hello\n' > notes.txt
/usr/bin/stat -c 'size=%s mode=%a type=%F name=%n' notes.txt
```

### An explicit timestamp

```run
# title: touch -d then read it back
/usr/bin/touch -d '2020-01-02 03:04:05 UTC' stamped
/usr/bin/stat -c '%y' stamped
```

### Copy a timestamp

```run
# title: touch -r copies mtime
/usr/bin/touch -d '2020-01-02 03:04:05 UTC' source
/usr/bin/touch -r source copy
/usr/bin/stat -c '%y %n' source copy
```

### The filesystem type string disagrees with df

```run
# title: stat -f versus df -T on this disk
/usr/bin/stat -f -c 'statfs_type=%T block_size=%s' .
/usr/bin/df --output=source,fstype,target .
```

## Recipes

In a C++ or Rust release job, after you `install` a binary, record `stat -c '%s %a' ` on the installed path if the package format cares about mode and size. Record `sha256sum` if the package format cares about bytes. Do not record the default `stat` paragraph into a machine-readable bill of materials; the column widths are not a contract.

To see whether two builds produced the same bytes, ignore mtime. `cmp` is diffutils, not coreutils. `sha256sum` is the coreutils answer, and `install -C` is the coreutils way to avoid bumping mtime when the bytes already match.

## Tips and pitfalls

`stat file >` redirection is a different file from `stat`'s operand. People overwrite the file they meant to inspect by pointing a redirect at it. Put redirects on a log name.

`%Y` is seconds. `%y` contains a space and a timezone. If you sort on `%y` as text you are not sorting by time once the format varies. Print `%Y` and `sort -n`.

`touch` on a symlink updates the target unless you pass `-h`. The link-count and symlink lessons cover the distinction. If you only remember one rule: metadata operations follow symlinks unless a flag says `-h` or `--no-dereference`.

## Exercises

```exercise
expect-exit: 0
---title---
Print just the byte size
---prompt---
Create `payload` containing `abcd` with no newline. Print only the size using stat.
---hint---
`%s` and printf of four bytes.
---solution---
The size is 4. wc -c agrees. A newline would have made it 5.
---script---
/usr/bin/printf 'abcd' > payload
/usr/bin/stat -c '%s' payload
```

```exercise
expect-exit: 0
---title---
Stamp a file at the epoch plus a known second
---prompt---
Set `when` to 2020-01-02 00:00:00 UTC and print `%Y`, the epoch seconds.
---hint---
`touch -d` accepts that phrase. `stat -c %Y` prints seconds.
---solution---
You get a stable integer, not "now". That integer is what you can sort and compare across machines that agree on UTC.
---script---
/usr/bin/touch -d '2020-01-02 00:00:00 UTC' when
/usr/bin/stat -c '%Y' when
```

```exercise
expect-exit: 0
---title---
Show the block size of the filesystem
---prompt---
Print `stat -f -c '%S'` for the current directory. `%S` is the fundamental block size in the filesystem format sequences.
---hint---
`-f` selects filesystem mode. `%S` is documented in the stat node for file systems.
---solution---
The number is a property of the filesystem, not of the empty directory's apparent size. du uses related block accounting.
---script---
/usr/bin/stat -f -c '%S' .
```

## Performance

`stat` is one syscall per call for a file, plus formatting. It does not read the file. Calling it in a shell loop over tens of thousands of names is slower than a language that calls `stat` in-process, because you pay for a process per file. That overhead is real and it is still not a reason to parse `ls -l`. If you need many metadata records, use a program that can do the loop internally (`find -printf`, which is findutils, not coreutils) or call `stat` from Rust. `touch` is not a performance tool. Setting timestamps on an entire tree with a shell loop is dominated by process startup, the same way.
