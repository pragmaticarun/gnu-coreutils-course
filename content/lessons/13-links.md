---
number: 13
slug: links
title: Hard links, symlinks, ln, link, unlink
module: Changing the tree
level: intermediate
minutes: 30
summary: A hard link is another name for the same inode. A symlink is a path stored as data. ln -r rewrites that path to be relative.
objectives:
  - Create a hard link and watch the link count with stat
  - Create a symlink, retarget it with ln -sfn, and print it with readlink
  - Use GNU ln --relative and explain why absolute link text breaks when a tree moves
  - Show that link and unlink refuse directories for an unprivileged caller
manual: ln invocation | https://www.gnu.org/software/coreutils/manual/html_node/ln-invocation.html
manual: link invocation | https://www.gnu.org/software/coreutils/manual/html_node/link-invocation.html
manual: unlink invocation | https://www.gnu.org/software/coreutils/manual/html_node/unlink-invocation.html
gnu_vs_bsd: |
  `ln -s` is POSIX. GNU `ln -r` / `--relative` is not on BSD ln. `link` and `unlink` exist widely as thin wrappers around the syscalls; diagnostics differ. macOS `cp -c` is unrelated. GNU `cp -a` preserving a symlink was captured in the copy lesson, not here. No BSD ln was executed.
---

A hard link is a directory entry that points at an inode. Two names, one inode, one set of bytes, one link count. `stat -c '%h'` prints that count. When you `rm` one name, the count drops and the bytes remain while any name or open file descriptor remains. Hard links cannot span filesystems, because the inode number is local to the device. `ln` across devices fails. Hard links to directories are rejected for an unprivileged user; the kernel returns EPERM. `link` is the bare syscall wrapper and produces that error on a directory. `ln` is the tool with the useful flags.

A symbolic link is a file whose content is a path. The path is not checked when the link is created. It is interpreted when someone opens the link. `readlink` prints the stored path and does not follow further. `readlink -f` resolves it. If you store an absolute target, moving the tree to another prefix breaks the link. GNU `ln -s -r` / `ln -sr` stores a relative target computed from the link's location. That is what you want inside a project tree you will relocate. `cp -a` copies the symlink as a symlink. `cp -L` follows it. Those were captured in the copy lesson; the distinction belongs next to this one.

`ln -sfn new target-name` replaces a symlink even when the name already exists. Without `-f`, ln refuses. Without `-n`, some cases treat an existing symlink-to-directory as a directory to link inside. `-n` / `--no-dereference` is the "do not treat the destination as a directory" flag. The combination `-sfn` is the usual retarget.

`unlink` removes one name via `unlink(2)`. It does not take `-r` and it does not remove a directory. `rm` is the tool with those behaviors and with prompts. Use `unlink` when you mean exactly one non-directory name and you want a failure if that is not what you have.

`du` counts a hard-linked file once unless you pass `-l`. Two names are not two copies of the bytes. The disk-usage lesson measures that. Installing a binary with hard links to save space is a real packaging trick and a real surprise when you edit one name and the other changes.

## Worked examples

### Link count

```run
# title: Two names, one inode
/usr/bin/printf 'same\n' > a
/usr/bin/ln a b
/usr/bin/stat -c '%h %i %n' a b
/usr/bin/unlink b
/usr/bin/stat -c '%h %n' a
```

### A relative symlink

```run
# title: ln -sr stores a relative target
/usr/bin/mkdir -p sub
/usr/bin/printf 'x\n' > sub/target
/usr/bin/ln -sr sub/target the-link
/usr/bin/readlink the-link
```

### Retarget

```run
# title: ln -sfn replaces the stored path
/usr/bin/ln -s old name
/usr/bin/ln -sfn new name
/usr/bin/readlink name
```

### Directories are refused

```run
# title: link and unlink do not remove or alias a directory
/usr/bin/mkdir box
set +e
/usr/bin/link box box2
/usr/bin/printf 'link:%s\n' $?
/usr/bin/unlink box
/usr/bin/printf 'unlink:%s\n' $?
set -e
```

## Recipes

Inside a repository, create tool symlinks with `ln -sr` so a checkout moved to another directory still resolves. For a system prefix, an absolute link under `/usr` can be correct because the target is supposed to stay at that absolute path. Decide which world the link lives in before you let `ln -s` store whatever string you were holding.

When a Rust `target` directory hard-links identical artifacts, `du -s` without `-l` is the honest disk usage and `du -l` is the sum of the names. Publish the one your capacity planning means.

## Tips and pitfalls

`ln -s target link` does not read `target`. A typo creates a dangling link and exits 0. `readlink -e` is the check that every component exists.

Replacing a symlink with `ln -sf` while a running program has already resolved the old target does not change what that process has open. Symlinks are resolved at open time.

`unlink` on a directory prints "Is a directory". `link` on a directory printed "Operation not permitted" in this sandbox. Those are different errno values. Do not collapse them into one handler if you are wrapping the tools.

## Exercises

```exercise
expect-exit: 0
---title---
Raise the link count
---prompt---
Create `data` and a hard link `alias`. Print the link count of `data`.
---hint---
`stat -c %h`.
---solution---
The count is 2. Removing one name would drop it to 1 and keep the bytes.
---script---
/usr/bin/printf 'z\n' > data
/usr/bin/ln data alias
/usr/bin/stat -c '%h' data
```

```exercise
expect-exit: 0
---title---
Store a relative target
---prompt---
Create `dir/file` and a symlink `dir/link` whose stored path is relative, using `ln -sr`, and print the stored path.
---hint---
`ln -sr dir/file dir/link` then `readlink`.
---solution---
The stored text is relative. `readlink` does not print an absolute path unless that is what was stored.
---script---
/usr/bin/mkdir dir
/usr/bin/printf 'z\n' > dir/file
/usr/bin/ln -sr dir/file dir/link
/usr/bin/readlink dir/link
```

```exercise
expect-exit: 1
---title---
Refuse to unlink a directory
---prompt---
Create `dir` and `unlink` it. Leave the non-zero status.
---hint---
unlink has no `-r`.
---solution---
The message says the name is a directory. `rmdir` is the empty-directory tool.
---script---
/usr/bin/mkdir dir
/usr/bin/unlink dir
```

## Performance

Creating a hard link or a symlink is a small metadata write. It does not scale with the size of the target file. That is the performance reason to link identical multi-megabyte artifacts instead of copying them, and it is only available for hard links when both names are on the same filesystem. Symlinks are cheap everywhere and cost a resolution on every open: a chain of symlinks is extra `stat` traffic on process start, which shows up when a dynamic linker walks a long path. `ln -sr` does the resolution work once, at creation, and stores a short relative path. Prefer that to a deep absolute path that every later open must parse. There is no measured "ln is faster than cp" number in this lesson because the comparison is only interesting for large files on a filesystem that cannot reflink, and the copy lesson already showed this ext4 host cannot clone.
