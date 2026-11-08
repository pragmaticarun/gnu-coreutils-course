---
number: 30
slug: du-and-df
title: du and df
module: Space, time, and processes
level: intermediate
minutes: 30
summary: du walks a tree and sums allocation. df asks the filesystem how full it is. Sparse files and hard links make those numbers diverge on purpose.
objectives:
  - Compare du -b and du without --apparent-size on a small tree
  - Read a sparse file's apparent size against its allocated blocks
  - See du count a hard link once, and twice with -l
  - Read df --output and explain the ext2/ext3 statfs name on ext4
manual: du invocation | https://www.gnu.org/software/coreutils/manual/html_node/du-invocation.html
manual: df invocation | https://www.gnu.org/software/coreutils/manual/html_node/df-invocation.html
gnu_vs_bsd: |
  GNU `du --apparent-size` and `-b` report logical size. macOS `du` uses different flags for apparent size. GNU `df -T` prints the type. BSD `df -T` filters by type, so a GNU script that adds `-T` changes meaning when it is copied to BSD and may exclude every filesystem. `df --output` is GNU. The ext4-versus-ext2/ext3 observation is specific to this Linux host's statfs type code.
---

`du` walks directory entries, stats each file, and adds up space. By default it reports allocated space, in units that depend on the environment and the flags. This course passes `-B1` when it wants bytes of allocation, and `-b` when it wants apparent size. `-b` is defined as `--apparent-size --block-size=1`. Apparent size is the logical length, `%s` from stat. Allocated size counts blocks the filesystem has given the file, and it is smaller for a hole and larger when a short file still occupies a whole block.

A directory's own `stat` size is not the tree. The directories lesson showed a directory size that ignored `hello\n` inside. `du -s` is the sum. `-d 1` limits depth so you see children without the whole walk printed. `--exclude` skips a pattern. `-x` stays on one filesystem, which matters when a tree contains another mount. Hard links are counted once unless `-l` / `--count-links` is set. Two names for one inode are not two copies of the bytes. The links lesson created the inode; this lesson is where the accounting shows up.

`df` does not walk your tree. It calls the filesystem for free space and inode counts. A deleted file that is still open does not appear in `du` of the directory and still occupies space in `df` until the last descriptor closes. That is the resolution of "du says I freed it and df disagrees". `df -h` is human units. `df -i` is inodes. Running out of inodes looks like a full disk and is not fixed by deleting one large file.

`df --output=source,fstype,target` prints the type without `-T`. Combining `-T` and `--output` is an error on this GNU df. `stat -f -c '%T'` on the same directory can print `ext2/ext3` while df prints `ext4`, because the kernel statfs magic is shared. Trust df's fstype column for the name a person means. Trust statfs numbers for block size. The method page records both strings from the capture host.

## Worked examples

### Apparent versus allocated in a tiny tree

```run
# title: du -b versus du -B1
/usr/bin/mkdir -p tree/sub
/usr/bin/printf 'hello\n' > tree/sub/f
/usr/bin/du -B1 -d 1 tree
/usr/bin/du -b -s tree
```

### A sparse file

```run
# title: truncate then du
/usr/bin/truncate -s 1M hole
/usr/bin/stat -c 'size=%s blocks=%b unit=%B' hole
/usr/bin/du -B1 hole
/usr/bin/du -b hole
```

### Hard links

```run
# title: du counts one inode unless -l
/usr/bin/mkdir box
/usr/bin/printf 'hello\n' > box/a
/usr/bin/link box/a box/b
/usr/bin/du -B1 -s box
/usr/bin/du -B1 -s -l box
```

### df and the type-code quirk

```run
# title: df --output and stat -f
/usr/bin/df --output=source,fstype,target .
/usr/bin/stat -f -c '%T' .
```

## Recipes

Before you delete a build tree to free a laptop, `du -h -d 1` the parent and look at which child dominates. `du -h -d 1 target` in a Rust workspace is the usual discovery that `target` is the cost. Then delete the child, then `df -h` the filesystem if you need to know whether the space came back. If a process still has files open, `df` will not move until those descriptors close. Finding the process is `lsof` or `/proc`, which are not coreutils.

`du -x` on a backup source so a mounted remote filesystem is not walked. `df -x tmpfs` to skip memory filesystems when you are looking at disks. `-x` on df is exclude-by-type, which is the GNU meaning.

## Tips and pitfalls

`du` of a file you cannot stat prints a diagnostic and continues. The total is then incomplete. Check the status.

Human units from `du -h` are not a stable sort key as text. `sort -h` knows how to order them. The sort manual describes `-h`. Prefer `-B1` and `sort -n` when you can keep the raw number.

`df` percentages are the filesystem's, including reserved blocks. A non-root user can see "space left" in the number and still get ENOSPC because of root reserve. `df` is not a quota tool.

## Exercises

```exercise
expect-exit: 0
---title---
Sum apparent size
---prompt---
Create `tree/f` containing `hello\n` and print `du -b -s tree`.
---hint---
`-b` is apparent size in bytes.
---solution---
The number includes the six bytes of `hello\n` plus directory entries' apparent sizes. Read the captured integer. It is not "6" alone, because directories have size too.
---script---
/usr/bin/mkdir -p tree
/usr/bin/printf 'hello\n' > tree/f
/usr/bin/du -b -s tree
```

```exercise
expect-exit: 0
---title---
Show a hole
---prompt---
Create a 1 MiB hole with truncate and print `du -b` and `du -B1`.
---hint---
Apparent size and allocated size.
---solution---
`-b` reports 1048576. `-B1` reports 0 on this filesystem for a fresh hole.
---script---
/usr/bin/truncate -s 1M hole
/usr/bin/du -b hole
/usr/bin/du -B1 hole
```

```exercise
expect-exit: 0
---title---
Print the filesystem type from df
---prompt---
Show source, fstype, and target for `.` using df --output.
---hint---
Do not combine --output with -T.
---solution---
The fstype column is the name to quote when you describe the disk. stat -f may use a coarser type code.
---script---
/usr/bin/df --output=source,fstype,target .
```

## Performance

`du` is a walk: one stat per file, and directory reads. On a tree of a million small files the metadata reads dominate and the file contents are never touched. That is why `du` can be slow on a cold cache and cheap on a warm one, and why it does not tell you read bandwidth of the file bodies. `df` is a constant-time statfs and is the tool to ask "is the disk full" without walking. Neither tool drops caches. A benchmark that runs `du` twice and reports the second run as the speed of the disk is measuring the page cache. Say so. Apparent-size mode still stats every file; it does not skip the walk. The only saving is arithmetic, not IO.
