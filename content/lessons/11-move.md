---
number: 11
slug: move
title: mv on one filesystem and across two
module: Changing the tree
level: intermediate
minutes: 28
summary: mv is a rename when the destination is the same filesystem. Across devices it copies and then unlinks. -n refuses to replace and exits 1.
objectives:
  - Rename a file and move it into a directory with -t
  - Show that -n exits 1 and leaves the destination bytes alone
  - Demonstrate a cross-device move from the ext4 disk onto tmpfs
  - Use -T when the destination must not be treated as a container
manual: mv invocation | https://www.gnu.org/software/coreutils/manual/html_node/mv-invocation.html
manual: Target directory | https://www.gnu.org/software/coreutils/manual/html_node/Target-directory.html
gnu_vs_bsd: |
  POSIX `mv` across filesystems is copy-plus-unlink because `rename` returns EXDEV. GNU `mv -t` and `-T` are not portable to BSD mv. GNU `mv -n` on this version exits 1 when it refuses; do not assume BSD `-n` prints the same diagnostic. The cross-device example uses `/dev/shm` (tmpfs) and was captured here. No BSD host was involved.
---

`rename(2)` changes a directory entry. It is atomic on one filesystem and it does not copy bytes. `mv` uses it when source and destination are on the same device. When they are not, the kernel returns EXDEV and `mv` copies, then unlinks the source. That second form is not atomic. A crash in the middle can leave both copies, or the new copy without the mode bits you expected. Scripts that move a finished artifact into place on the same filesystem get the atomic publish. Scripts that move from the build disk onto a tmpfs ramdisk, or onto another mount, do not.

You can see the device identity with `stat -c '%d'`. Two paths with the same device number can still be different mount points in exotic setups, but a different device number is enough to prove the move cannot be a pure rename. This sandbox lives on the ext4 root. `/dev/shm` is tmpfs. The example moves a small file between them and prints both device numbers, then deletes the tmpfs file. Do not leave scratch files in `/dev/shm`.

`-t DIR` means "every operand is a source, and DIR is the container". That is the form that works with `xargs` (findutils, not coreutils), because you can put `-t` before the names `xargs` appends. `-T` means "the destination is not a directory to move into, even if it is a directory". Without `-T`, `mv file existing-dir` puts `file` inside `existing-dir`. With `-T`, that shape is an error unless you are replacing a non-directory. Pick one explicitly in a script.

`-n` refuses to replace an existing destination. On this GNU mv it prints "not replacing" and exits 1. The source remains. `--update=none` is the related cp spelling; mv's `-n` did not print the cp portability warning in the probe for this course. Still prefer the long option you can explain. `--backup` makes a backup according to the version-control rules in the common-options chapter. It is easy to fill a directory with `~` files if you turn it on in a loop.

Trailing slashes matter. `mv file dir/` insists that `dir` is a directory. The trailing-slashes node in the manual is the reference. A script that adds the slash fails closed when `dir` was accidentally a file.

## Worked examples

### A same-filesystem rename

```run
# title: mv changes the directory entry
/usr/bin/printf 'body\n' > old
/usr/bin/mv old new
/usr/bin/ls -1
/usr/bin/cat new
```

### Refusing to clobber

```run
# title: mv -n exits 1
# expect-exit: 1
/usr/bin/printf 'aaa\n' > a
/usr/bin/printf 'bbb\n' > b
/usr/bin/mv -n a b
```

### Into a directory, using -t

```run
# title: -t collects sources
/usr/bin/mkdir dest
/usr/bin/printf '1\n' > one
/usr/bin/printf '2\n' > two
/usr/bin/mv -t dest one two
/usr/bin/ls -1 dest
```

### Across a device boundary

```run
# title: ext4 to tmpfs is not a pure rename
/usr/bin/printf 'cross\n' > local
dest="/dev/shm/cuwb-mv-$$"
trap 'rm -f "$dest"' EXIT
/usr/bin/stat -c 'src_dev=%d' .
/usr/bin/stat -c 'shm_dev=%d' /dev/shm
/usr/bin/mv local "$dest"
/usr/bin/cat "$dest"
```

## Recipes

Publish a finished archive by writing it to a temporary name on the same filesystem and then `mv -T` it onto the public name. Readers see the old file or the new file, not a partial write. If the public name is on another mount, you cannot have that atomicity. Copy to a temporary name on the destination filesystem and `mv` there.

`mv -n` in a loop is a reasonable "do not smash an existing artifact" check because the status is non-zero. Test the status. A script with `set -e` will stop, which is what you want if replacement is a bug.

## Tips and pitfalls

`mv` of a directory onto another directory moves it inside, the same way as a file. `mv a b` when both are directories yields `b/a` if `b` exists. That surprise has eaten release directories. `-T` makes the intent visible.

Cross-device `mv` of a symlink copies the symlink or the content depending on flags, and it may not preserve every attribute an ordinary user cannot set. Read stderr.

The trap in the cross-device example removes the shm file even when a later command fails. Copy that pattern. The course runner also deletes its sandbox, but `/dev/shm` is outside the sandbox.

## Exercises

```exercise
expect-exit: 0
---title---
Rename
---prompt---
Create `draft` containing `ok` and rename it to `final`. Print `final`.
---hint---
`mv draft final` on the same directory is a rename.
---solution---
The body is unchanged. Only the directory entry moved.
---script---
/usr/bin/printf 'ok\n' > draft
/usr/bin/mv draft final
/usr/bin/cat final
```

```exercise
expect-exit: 1
---title---
Keep the existing destination
---prompt---
Create `src` and `dst` with different bodies. `mv -n src dst` must fail and `dst` must still be readable afterward. Because the status is 1, print `dst` before the mv if you need to show it, or accept that a failing script stops.
---hint---
Put `cat dst` before `mv -n` if you want the body in the output. The mv is the last command.
---solution---
The refusal is the result. Status 1 is GNU mv telling you it did not replace the file.
---script---
/usr/bin/printf 'new\n' > src
/usr/bin/printf 'old\n' > dst
/usr/bin/cat dst
/usr/bin/mv -n src dst
```

```exercise
expect-exit: 0
---title---
Move two files into a new directory
---prompt---
Create `d`, `a`, and `b`, and move both files into `d` with a single mv that uses `-t`.
---hint---
`-t d a b`.
---solution---
`-t` is what you want when the destination must stay in one place and the source list can grow.
---script---
/usr/bin/mkdir d
/usr/bin/printf 'a\n' > a
/usr/bin/printf 'b\n' > b
/usr/bin/mv -t d a b
/usr/bin/ls -1 d
```

## Performance

A same-filesystem `mv` is a directory update, constant in the size of the file. A cross-device `mv` costs as much as `cp` plus `unlink`, including page-cache traffic. People "speed up" a script by switching to `mv` and then point it at another mount, where it is suddenly a full copy. Check `stat -c '%d'` when a move of a large Android image is mysteriously slow. There is no flag that makes EXDEV cheap. Reflink copies, where the filesystem supports them, are a `cp` feature, not an `mv` feature. On this ext4 host you already saw that the clone is unavailable.
