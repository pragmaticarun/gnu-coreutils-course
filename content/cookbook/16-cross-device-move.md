---
number: 16
slug: cross-device-move
title: Move a file onto another filesystem
module: Cookbook
level: advanced
minutes: 16
summary: mv between the sandbox and /dev/shm cannot be a pure rename. stat -c %d shows two device ids. The scratch file is removed on exit.
manual: mv invocation | https://www.gnu.org/software/coreutils/manual/html_node/mv-invocation.html
gnu_vs_bsd: |
  When `rename` returns EXDEV, `mv` copies and then unlinks. That is POSIX behavior, not a GNU invention. GNU `mv -T` and `-t` are GNU spellings. Device numbers differ by host. This recipe uses `/dev/shm` on Linux and deletes the file in an EXIT trap. It does not run BSD mv and it does not leave the scratch file behind.
---

`mv` on one filesystem is a rename. The directory entry changes and the bytes stay where they are. `mv` across filesystems cannot do that. The kernel returns EXDEV, and `mv` copies, then unlinks the source. The copy is not atomic. A crash can leave both names, or the new name with a short file. Scripts that publish a finished artifact should `mv` within one filesystem: write a temporary name in the destination directory, then `mv -T` it onto the public name.

You can see the boundary with `stat -c '%d'`. The sandbox and `/dev/shm` have different device numbers on this host. The recipe prints both, moves a small file, prints the destination, and removes it with a trap. `/dev/shm` is outside the course runner's scratch directory. The trap is what deletes it. Copy the trap if you adapt the recipe. Do not point it at a directory you care about. The destination path includes the shell pid so two runs do not share a name.

Same-filesystem publish is still the pattern to prefer. Cross-device move is the pattern to recognize when a build directory and a deploy mount are different disks. If you need the copy to keep holes or modes, read the cp flags `mv` will use on the fallback, and test them. Do not assume every attribute survived because the exit status was 0.

## Steps

```run
# title: Two device ids and a move
/usr/bin/printf 'payload\n' > local
dest="/dev/shm/cuwb-cb-$$"
trap 'rm -f "$dest"' EXIT
/usr/bin/stat -c 'src_dev=%d' .
/usr/bin/stat -c 'shm_dev=%d' /dev/shm
/usr/bin/mv local "$dest"
/usr/bin/cat "$dest"
```

```run
# title: A same-directory rename
/usr/bin/printf 'payload\n' > local
/usr/bin/mv local published
/usr/bin/cat published
/usr/bin/test ! -e local && /usr/bin/printf 'source-gone\n'
```

## Check yourself

```exercise
expect-exit: 0
---title---
Rename inside the sandbox
---prompt---
Write `payload` and a newline to `local`, rename it to `published`, and print the file.
---hint---
Same directory means a rename, not a cross-device copy.
---solution---
The body is unchanged. `local` is gone.
---script---
/usr/bin/printf 'payload\n' > local
/usr/bin/mv local published
/usr/bin/cat published
```

## Performance

A rename is a directory update and does not move bytes. A cross-device `mv` is a full copy plus a delete, so it costs read bandwidth, write bandwidth, and then the unlink. Measuring `mv` without recording whether the device ids matched measures two different operations and calls them one name. Print the device ids in the log when a publish step is slow. If they differ, write the file on the destination filesystem in the first place, or copy with the cp flags you actually want and then rename into place on the destination. The copy benchmark's 8 MiB trial is the dense-copy cost on this host, warm cache, and it is the right order of magnitude for the fallback. It is not a rename.
