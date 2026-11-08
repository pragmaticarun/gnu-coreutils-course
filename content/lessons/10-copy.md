---
number: 10
slug: copy
title: cp, sparse files, and reflinks
module: Changing the tree
level: intermediate
minutes: 34
summary: cp can share data, preserve holes, or read every byte. On this ext4 disk a reflink clone is refused and a sparse file is not.
objectives:
  - Copy a file, a symlink as a symlink, and a symlink's target
  - Show that --reflink=always fails here and --reflink=auto falls back
  - Compare apparent size and allocated blocks after a sparse copy
  - Prefer --update=none over -n on coreutils 9.4
manual: cp invocation | https://www.gnu.org/software/coreutils/manual/html_node/cp-invocation.html
gnu_vs_bsd: |
  GNU `cp --reflink` asks for a clone or copy-on-write when the filesystem supports it. macOS uses `cp -c` for a clonefile, which is a different flag. `--sparse` is GNU. `cp -a` is GNU's archive mode (`-dR --preserve=all`); BSD `cp -a` is not the same preserve set. GNU 9.4 warns that `-n` is non-portable and tells you to use `--update=none`. That warning was captured here. BSD was not executed.
---

`cp` reads a source and writes a destination, unless the filesystem can do better. "Better" has two independent meanings. A reflink or clone is a new directory entry that shares the source's data blocks until one side writes. A sparse copy is a destination whose holes are not written out as zero bytes. Neither is a guarantee. Both depend on the filesystem and on the flags.

On this machine `cp --reflink=always` fails with "Operation not supported". The capture disk is ext4, which does not do reflink clones. `--reflink=auto` is the default-ish polite request: try a clone, and if the kernel refuses, copy the bytes. `--reflink=never` forces the byte copy. A script that requires a clone, because it is about to mutate one side of a huge image, must pass `--reflink=always` and treat a non-zero status as "do not pretend these files are independent". A script that only wants a copy should pass `--reflink=never` when a silent clone would surprise a later checksum of allocated blocks, or leave the default if either result is acceptable. Say which one you mean.

Sparse files are a different axis. `truncate -s 1M` creates a hole. `stat` shows a large `%s` and a small `%b`. `cp --sparse=auto` uses a heuristic to keep holes. `--sparse=always` tries to make a sparse destination even when it has to detect zero runs. `--sparse=never` writes the zeros. `du -B1` without `--apparent-size` reports allocated space. `du -b` reports apparent size. If those numbers match, you do not have a hole.

`-a` is archive mode: recursive, preserve links as links, and preserve attributes. Copying a symlink with `-a` copies the symlink. `cp -L` follows it and writes a regular file. That choice matters for a toolchain sysroot, where a symlink to a shared library must stay a symlink.

`-n` / `--no-clobber` on this 9.4 prints that the behavior is non-portable and may change. The replacement the help text names is `--update=none`. `mv -n` does not print the same warning and exits 1 when it refuses. Do not assume the two `-n` flags are one feature.

`--parents` recreates the source path under the destination directory, but the source path is interpreted relative to the current directory. The example `cd`s first. Running it from the wrong place looks like a missing `src`.

## Worked examples

### Reflink request versus fallback

```run
# title: always fails here, auto copies
/usr/bin/printf 'abc\n' > src
set +e
/usr/bin/cp --reflink=always src dest-always
/usr/bin/printf 'always:%s\n' $?
set -e
/usr/bin/cp --reflink=auto src dest-auto
/usr/bin/sha256sum src dest-auto
```

### A symlink stays a symlink under -a

```run
# title: -a keeps the link, -L copies the target
/usr/bin/printf 'data\n' > target
/usr/bin/ln -s target link
/usr/bin/cp -a link copy-link
/usr/bin/cp -L link copy-file
/usr/bin/stat -c '%F %n' copy-link copy-file
```

### Sparse size versus allocated blocks

```run
# title: A hole survives an auto sparse copy
/usr/bin/truncate -s 1M hole
/usr/bin/cp --sparse=auto hole hole-copy
/usr/bin/stat -c 'src size=%s blocks=%b' hole
/usr/bin/stat -c 'dst size=%s blocks=%b' hole-copy
```

### Do not clobber, without -n

```run
# title: --update=none leaves the destination
/usr/bin/printf 'new\n' > incoming
/usr/bin/printf 'old\n' > kept
/usr/bin/cp --update=none incoming kept
/usr/bin/cat kept
```

## Recipes

For an Android `out/` tree or a Rust `target/` directory, `cp -a` is the blunt instrument that preserves symlinks and modes. It is not incremental. `rsync` is the incremental tool and it is not installed here and not coreutils. If you only needed a clone and the filesystem is btrfs or XFS with reflink, `--reflink=always` is the cheap copy. On this ext4 host it is not available, so the cheap copy does not exist and you pay the bytes.

`--parents` is how you lift `include/foo.h` into `dest/include/foo.h` without rewriting the path in the shell.

## Tips and pitfalls

`cp dir1 dir2` when `dir2` exists creates `dir2/dir1`. When `dir2` does not exist, it creates `dir2` as the copy. `-T` forces "destination is the directory itself, not a container". Use `-T` in scripts that must not nest by accident.

Preserving ownership requires privilege. `-a` asks to preserve it and, as an ordinary user, will keep the owner you already have and may warn about what it cannot copy. Read stderr. A zero status can still have skipped an xattr or a capability.

Confirm a copy with `sha256sum` of both names. Matching digests means the bytes match. They do not tell you whether the filesystem cloned the extents or wrote new ones; `stat` block counts are the clue for holes, and this ext4 host simply cannot reflink.

## Exercises

```exercise
expect-exit: 0
---title---
Force a normal copy
---prompt---
Copy `a` to `b` with `--reflink=never` and print both sha256 digests.
---hint---
One sha256sum command can take both names.
---solution---
The digests match because the bytes were copied. The flag only forbids a clone.
---script---
/usr/bin/printf 'xyz\n' > a
/usr/bin/cp --reflink=never a b
/usr/bin/sha256sum a b
```

```exercise
expect-exit: 1
---title---
Require a clone and accept the failure
---prompt---
Create `a` and run `cp --reflink=always a b` on this filesystem. Leave the non-zero status in place.
---hint---
ext4 on the capture host returns "Operation not supported".
---solution---
A required clone that the filesystem cannot do must fail the script. Falling back silently is `--reflink=auto`, which is a different request.
---script---
/usr/bin/printf 'xyz\n' > a
/usr/bin/cp --reflink=always a b
```

```exercise
expect-exit: 0
---title---
Keep an existing file
---prompt---
With `old` containing `keep` and `new` containing `replace`, copy `new` onto `old` using `--update=none`, then print `old`.
---hint---
The destination content should stay `keep`.
---solution---
`--update=none` is the GNU 9.4 spelling of "do not overwrite".
---script---
/usr/bin/printf 'keep\n' > old
/usr/bin/printf 'replace\n' > new
/usr/bin/cp --update=none new old
/usr/bin/cat old
```

## Performance

A reflink is a metadata operation. A byte copy moves every byte through the page cache and may write them back. On a filesystem that supports reflinks, the difference is enormous for a multi-gigabyte image and irrelevant for a 4-byte file. This host does not support the clone, so there is no reflink number to report, and inventing one would be false. The copy benchmark compares `cp --reflink=never` with `dd` on an 8 MiB warm file and tells you if the medians even separate. Sparse copies save write bandwidth when the source is mostly holes. They do not save it when the source is a compressed APK full of non-zero bytes. Look at `%b` before you celebrate.
