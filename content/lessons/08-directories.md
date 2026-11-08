---
number: 8
slug: directories
title: mkdir, rmdir, and empty trees
module: Seeing files
level: beginner
minutes: 24
summary: mkdir -p builds parents under the umask. -m applies to the last component. rmdir only removes empty directories.
objectives:
  - Create a nested directory and predict parent modes under umask 0022
  - Remove an empty directory and explain the two rmdir failures
  - Choose rmdir over rm -r when emptiness is the safety check
  - Know that mknod of a device node is a privileged operation this course does not perform
manual: mkdir invocation | https://www.gnu.org/software/coreutils/manual/html_node/mkdir-invocation.html
manual: rmdir invocation | https://www.gnu.org/software/coreutils/manual/html_node/rmdir-invocation.html
gnu_vs_bsd: |
  `mkdir -p` and `mkdir -m` exist on BSD. GNU long options (`--parents`, `--mode`) do not. The parent-mode pitfall is shared: `-m` does not apply to parents created along the way. `rmdir` is POSIX. `mknod` exists on both and is the wrong tool for ordinary directories. Captured modes assume the sandbox umask printed in the example.
---

`mkdir` creates directories. `mkdir -p a/b/c` creates each missing component and succeeds if the final one already exists as a directory. The mode argument `-m 700` is applied to the directory that the invocation treats as the one being created at the end, not to every parent it had to materialize. Parents are created with the mode `0777` modified by the umask. This capture environment's umask is `0022`, so a parent lands at `0755` while the leaf you named with `-m 700` lands at `0700`. That is the bug behind a "private" cache directory whose parent is world-executable and world-readable. If the parent must be private too, `mkdir` it separately with `-m 700`, then create the child.

`rmdir` removes a directory only when it is empty. A regular file fails with "Not a directory". A directory that still has an entry fails with "Directory not empty". Those are different mistakes. `rmdir -p a/b/c` removes `c`, then `b`, then `a` if each becomes empty. It stops when one is not empty. It will not delete a file that happens to sit in the way. That is why it is safer than `rm -r` for tearing down a scratch tree you believe is empty. If `rmdir` fails, something is still there and you should look before you reach for `-r`.

`mkfifo` creates a named pipe and is covered with tee. `mknod` can create a fifo too, and it can create device nodes if you pass a major and minor number. Device nodes in `/dev` are not a coreutils exercise and they need privileges. The reference entry says so. This lesson does not call `mknod`.

Directories themselves have a size, but that size is the directory's own metadata storage, not the sum of the files inside. `du` is the tool that walks. `stat -c %s` on a directory is almost never the number you wanted in a disk-usage report.

## Worked examples

### Parent mode versus leaf mode

```run
# title: -m does not lock down parents
/usr/bin/printf 'umask:'
umask
/usr/bin/mkdir -p -m 700 deep/leaf
/usr/bin/stat -c '%a %n' deep deep/leaf
```

### rmdir refuses a file and a non-empty directory

```run
# title: Two different rmdir errors
set +e
/usr/bin/mkdir box
/usr/bin/printf 'x\n' > box/file
/usr/bin/rmdir box
/usr/bin/printf 'nonempty:%s\n' $?
/usr/bin/rmdir box/file
/usr/bin/printf 'nota_dir:%s\n' $?
set -e
```

### Remove a chain that is actually empty

```run
# title: rmdir -p removes emptied parents
/usr/bin/mkdir -p a/b/c
/usr/bin/rmdir -p a/b/c
/usr/bin/ls -A
```

### A directory's own byte size is not the tree

```run
# title: stat on a directory is not du
/usr/bin/mkdir -p tree/sub
/usr/bin/printf 'hello\n' > tree/sub/f
/usr/bin/stat -c 'dir_size=%s' tree
/usr/bin/du -b -s tree
```

## Recipes

Create a cache root once: `mkdir -m 700 "$HOME/.cache/mytool"` and then `mkdir -p` the subdirectories if the root already has the mode you want. Do not expect a single `mkdir -p -m 700` of a brand-new deep path to privatize the whole chain.

In a test harness, build the tree under `mktemp -d` and remove it with `rm -r` only at the end, when destruction is the point. During the test, `rmdir` is the assertion that a directory you meant to empty is empty.

## Tips and pitfalls

`mkdir -p` on a path whose middle component is a file fails. `-p` does not replace a file with a directory. That failure is useful.

`rmdir` on a symlink to a directory is not "remove the directory through the link" in the way people hope. Do not point recursive deletion at a symlink you have not inspected. The link lesson shows how to see the target with `readlink`.

The umask is a process property. A systemd unit, a CI runner, and your interactive shell can disagree. Print `umask` in the job if the modes matter.

## Exercises

```exercise
expect-exit: 0
---title---
Make a private directory in one level
---prompt---
Create `private` with mode 700 in a single mkdir, and print the mode.
---hint---
No `-p` is required. `-m 700`.
---solution---
With one component, `-m` is the mode you get, still masked only if the requested bits conflict with rules mkdir applies. 700 survives umask 0022 because the mode is explicit.
---script---
/usr/bin/mkdir -m 700 private
/usr/bin/stat -c '%a' private
```

```exercise
expect-exit: 0
---title---
Prove a directory is empty by removing it
---prompt---
Create `empty`, remove it with rmdir, and list the directory with `ls -A`. The listing should not contain `empty`.
---hint---
rmdir succeeds only if empty.
---solution---
Success plus absence is the check. A non-empty directory would have failed the rmdir.
---script---
/usr/bin/mkdir empty
/usr/bin/rmdir empty
/usr/bin/ls -A
```

```exercise
expect-exit: 1
---title---
Leave the non-empty directory alone
---prompt---
Create `full/item` as a file and run `rmdir full`. The status must stay non-zero.
---hint---
Do not delete the file first.
---solution---
rmdir is the safety check. The file is still there because the command failed.
---script---
/usr/bin/mkdir full
/usr/bin/printf 'z\n' > full/item
/usr/bin/rmdir full
```

## Performance

`mkdir` of a deep tree is metadata writes. It is slow on a filesystem that journals metadata when you do it one process per directory from a shell loop. `mkdir -p` in one process is the better coreutils form. It is still not a bulk extractor: `tar` (not coreutils) creates a tree from an archive with far less shell traffic. Creating thousands of directories as a cache partition is a filesystem-layout question. Keep directories from becoming huge in entry count; many filesystems slow down on a single directory with hundreds of thousands of names, and `ls` or shell globs then dominate. That limit is the filesystem's, not a mkdir flag.
