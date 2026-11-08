---
number: 14
slug: permissions-and-install
title: chmod, chown, and install
module: Changing the tree
level: intermediate
minutes: 32
summary: chmod changes mode bits. chown changes ownership and fails here without privilege. install copies a binary into place and can skip the write when the bytes already match.
objectives:
  - Set an octal mode and a symbolic mode with chmod
  - Copy a mode with chmod --reference
  - Explain a failed chown to root on this sandbox
  - Place a file with install -D and skip a rewrite with install -C
manual: chmod invocation | https://www.gnu.org/software/coreutils/manual/html_node/chmod-invocation.html
manual: chown invocation | https://www.gnu.org/software/coreutils/manual/html_node/chown-invocation.html
manual: install invocation | https://www.gnu.org/software/coreutils/manual/html_node/install-invocation.html
gnu_vs_bsd: |
  Symbolic and octal chmod are POSIX. GNU `chmod --reference` and `chown --reference` are not BSD flags. GNU `install -D` creates leading directories and `-C` compares content before writing. BSD `install` uses a different set (`-S` for backups on some systems). `chown` to another user needs privilege on both. The failed chown below was captured as an unprivileged user. No BSD install was run.
---

The mode is a set of bits stored on the inode: read, write, execute, for owner, group, and other, plus setuid, setgid, and sticky. `chmod 640 file` sets owner read-write, group read, other nothing. `chmod u=rw,go= file` is the same request in the symbolic grammar, which is what you want when you are editing rather than replacing the mode. `chmod --reference=other file` copies the mode. It does not copy the owner. The reference file is dereferenced if it is a symlink, so you copy the target's mode.

`chown user:group file` changes ownership. Only a privileged process can give a file to another user. In this sandbox `chown 0:0` fails with "Operation not permitted" and exits 1. That is the correct outcome, not a broken chown. `chgrp` can change the group to another group you belong to. `--from` on GNU chown avoids a race where you only want to change the owner if it is still the owner you think. `--reference` copies both user and group. None of these change the bytes.

`install` is `cp` plus the modes you want for a published binary, with a few extra contracts. `install -D -m 755 src dest/bin/tool` creates the parent directories of the destination and sets the mode. `install -C` compares the content and does not rewrite the destination if it already matches, which leaves the mtime alone. Build systems use that so a later step does not rebuild the world because a timestamp moved. `-s` strips symbols and needs a `strip` program; this lesson does not strip, because stripping is binutils, not coreutils, and it changes the bytes.

SELinux context is a third channel. `chcon` and `runcon` are coreutils, and they need a kernel with SELinux. `id -Z` on this host fails because the kernel is not SELinux-enabled. A mode of 644 is not a substitute for a context, and a context is not a substitute for a mode. On this machine you only have the mode.

Directories need the execute bit to be traversed. A directory mode of 600 lets the owner read the directory's names and not traverse it usefully in the way people expect from files. `chmod` on a tree with `-R` will happily clear execute on directories if you apply a file-shaped mode. Do not `chmod -R 644` a source tree.

## Worked examples

### Octal and symbolic

```run
# title: 640 and u=rw,go= are the same end state
/usr/bin/printf 'x\n' > a
/usr/bin/printf 'y\n' > b
/usr/bin/chmod 640 a
/usr/bin/chmod u=rw,go= b
/usr/bin/stat -c '%a %A %n' a b
```

### Copy a mode

```run
# title: --reference copies mode only
/usr/bin/printf 'x\n' > src
/usr/bin/printf 'y\n' > dst
/usr/bin/chmod 600 src
/usr/bin/chmod --reference=src dst
/usr/bin/stat -c '%a %n' dst
```

### chown to root fails closed

```run
# title: Unprivileged chown
# expect-exit: 1
/usr/bin/printf 'x\n' > mine
/usr/bin/chown 0:0 mine
```

### install -D and install -C

```run
# title: Place a tool and do not rewrite identical bytes
/usr/bin/printf '#!/bin/sh\nprintf ok\n' > tool
/usr/bin/install -D -m 755 tool prefix/bin/tool
/usr/bin/stat -c '%a %n' prefix/bin/tool
before=$(/usr/bin/stat -c '%Y' prefix/bin/tool)
/usr/bin/install -C -m 755 tool prefix/bin/tool
after=$(/usr/bin/stat -c '%Y' prefix/bin/tool)
/usr/bin/printf 'mtime %s %s\n' "$before" "$after"
```

## Recipes

A Rust or C++ release script should `install -D -m 755` the binary into the prefix rather than `cp` plus a separate `chmod`. The mode is part of the publish. Use `install -C` when the same script may run twice and you do not want to bump mtimes that a package diff will treat as a change.

Do not chown build outputs to another user in CI. If the package format needs root ownership, that is a packaging step with privilege, outside this sandbox, and it should be explicit. A failed chown in the log is better than a script that ignores the status and ships a root-owned path it did not create.

## Tips and pitfalls

`chmod` follows symlinks to change the target's mode. `chmod -h` is not portable. GNU chmod's `--help` documents how symlinks are handled; do not assume a mode change on the link itself.

`install -d` creates directories. `install -D` on a file creates leading components of the file destination. Mixing them up produces a directory where you wanted a file, or the reverse.

The mtime comparison in the example prints two integers. If they match, `-C` did not rewrite the inode's mtime. If a filesystem's timestamp granularity ever made them match by accident, the content comparison is still what `-C` did; the printed integers are the observation on this run.

## Exercises

```exercise
expect-exit: 0
---title---
Make a file owner-readable only
---prompt---
Create `secret` and set mode 600. Print the symbolic mode.
---hint---
`stat -c %A`.
---solution---
`-rw-------` is the symbolic form of 600.
---script---
/usr/bin/printf 'hide\n' > secret
/usr/bin/chmod 600 secret
/usr/bin/stat -c '%A' secret
```

```exercise
expect-exit: 1
---title---
Show the privilege boundary
---prompt---
Create `mine` and `chown` it to `0:0`. Do not hide the status.
---hint---
The sandbox user is not root.
---solution---
Operation not permitted, status 1. The file is still yours.
---script---
/usr/bin/printf 'x\n' > mine
/usr/bin/chown 0:0 mine
```

```exercise
expect-exit: 0
---title---
Install into a prefix
---prompt---
Write a one-line file `tool` and `install -D -m 755` it to `opt/bin/tool`. Print the mode.
---hint---
`-D` creates `opt/bin`.
---solution---
The mode is 755 and the parent directories exist. That is the publish step a build should use.
---script---
/usr/bin/printf 'echo hi\n' > tool
/usr/bin/install -D -m 755 tool opt/bin/tool
/usr/bin/stat -c '%a' opt/bin/tool
```

## Performance

`chmod` and `chown` are metadata updates. They do not rewrite file contents. `install` without `-C` does rewrite the destination, which changes mtime and can cascade into rebuilds that dwarf the copy. `-C` exists so a repeated install of identical bytes stays cheap and quiet. The comparison itself reads both files, so `-C` is not free; it is cheaper than a false rebuild of a C++ target that depends on the installed header's timestamp. `install -s` runs `strip`, which is another process and another write. Do not strip in the hot loop of a debug build. None of these tools are the bottleneck of a link that reads gigabytes of objects. They are the bottleneck of a script that installs one file at a time in a shell loop over thousands of headers. Copy the tree with a tool that can do many files per process, or accept the process-startup cost knowingly.
