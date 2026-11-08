---
number: 15
slug: dd-truncate-sync
title: dd, truncate, and sync
module: Changing the tree
level: advanced
minutes: 30
summary: dd copies blocks and can leave holes. truncate sets a size. sync asks the kernel to flush caches and does not prove the drive finished.
objectives:
  - Copy a fixed number of blocks with dd and status=none
  - Create a sparse file with truncate and with dd conv=sparse
  - Read size and allocated blocks back with stat
  - Call sync -f on a file without claiming hardware durability
manual: dd invocation | https://www.gnu.org/software/coreutils/manual/html_node/dd-invocation.html
manual: truncate invocation | https://www.gnu.org/software/coreutils/manual/html_node/truncate-invocation.html
manual: sync invocation | https://www.gnu.org/software/coreutils/manual/html_node/sync-invocation.html
gnu_vs_bsd: |
  GNU `dd` adds `status=progress` and `status=none`. BSD `dd` often reports progress on SIGINFO instead. `conv=sparse` is not identical across implementations. `truncate` is GNU and is missing from older macOS base systems. `sync -f` is GNU. This lesson only writes files inside the sandbox and never opens a disk device. No BSD dd was run.
---

`dd` reads blocks and writes blocks. The historical interface is `if=`, `of=`, `bs=`, `count=`, and `conv=`. It is easy to destroy a device by pointing `of=` at the wrong node. Every example in this lesson uses a regular file in the scratch directory. There is no example with `/dev/sd` or `/dev/nvme`. If a real disk image job needs `dd`, the destination path should be a file you just created, and the script should print that path before it writes.

`status=none` keeps the statistics off stderr. `status=progress` prints them. GNU dd's `iflag=fullblock` accumulates a full input block when the reader returns short reads, which happens on pipes. Without it, `bs=1M count=1` on a pipe can stop after the first short read and produce a short file. Copying a regular file in this lesson does not hit that case. Know it before you `dd` from a pipe and think `count` means what it means for a disk.

`conv=sparse` tries to seek over NUL output blocks instead of writing them. A file of zeros produced that way has a large size and zero allocated blocks on a filesystem that supports holes. `truncate -s 1M file` creates the same shape without writing the zeros at all. `truncate -s 0 file` empties a file but leaves the directory entry, unlike `rm`. Shrinking discards the tail from the file's logical size. It does not shred it.

`sync` asks the kernel to write out cached data. With no arguments it applies broadly. `sync -f file` syncs the filesystem that contains `file`. `sync -d` limits itself to file data. None of these calls can promise that a drive's own cache has committed the bits to stable media. They are still the right call at the end of a snapshot script, followed by an honest sentence in the log: the kernel was asked to flush. Durability beyond that is a property of the hardware and the mount options, which this course does not tune and does not drop caches to measure.

`od` is how you look at a small `dd` result when you care about bytes. `stat -c '%s %b'` is how you look at sparseness. `du -b` versus `du -B1` is the same story from the disk-usage tools.

## Worked examples

### A counted copy

```run
# title: Four 1 KiB blocks from /dev/zero into a file
/usr/bin/dd if=/dev/zero of=block.bin bs=1024 count=4 status=none
/usr/bin/wc -c block.bin
```

### conv=sparse on zeros

```run
# title: A hole instead of written zeros
/usr/bin/dd if=/dev/zero of=sparse.bin bs=1024 count=8 conv=sparse status=none
/usr/bin/stat -c 'size=%s blocks=%b block_unit=%B' sparse.bin
```

### truncate extends without writing

```run
# title: truncate -s 1M
/usr/bin/truncate -s 1M hole
/usr/bin/stat -c 'size=%s blocks=%b' hole
/usr/bin/du -B1 hole
/usr/bin/du -b hole
```

### sync the filesystem that holds the file

```run
# title: sync -f returns success and proves only the call
/usr/bin/printf 'flushed-request\n' > note
/usr/bin/sync -f note
/usr/bin/printf 'sync-ok\n'
```

## Recipes

Build a sparse disk image for a test with `truncate -s 64M image` only when 64 MiB is a size you are willing to create, and prefer a few megabytes in a sandbox. Fill a region later with `dd conv=notrunc` if you must write at an offset. `seek=` skips output. `skip=` skips input. Write both names down in the script so a reader does not swap them.

At the end of a backup that must survive power loss at the kernel level, `sync -f` the destination directory. Then say in the operator log that device firmware caches are outside that call.

## Tips and pitfalls

`/dev/zero` is not a coreutils invention. It is an infinite source of NUL bytes. `count=` is what makes `dd` stop. Forgetting `count` while reading `/dev/zero` fills the disk. The examples always pass `count`.

`status=progress` writes to stderr and will dirty a captured byte stream if you merge the descriptors. Keep it on stderr.

`truncate` on a missing file creates it. `truncate` on a symlink follows the symlink. Check `readlink` first if the name might not be a regular file.

## Exercises

```exercise
expect-exit: 0
---title---
Write exactly 512 bytes
---prompt---
Use dd to put 512 zero bytes in `z` and print the size with wc -c.
---hint---
`bs=512 count=1 status=none`.
---solution---
The size is 512. status=none keeps the transfer stats off the output.
---script---
/usr/bin/dd if=/dev/zero of=z bs=512 count=1 status=none
/usr/bin/wc -c z
```

```exercise
expect-exit: 0
---title---
Extend a file to 4096 without copying zeros by hand
---prompt---
Create `h` with truncate at 4096 bytes and print size and allocated blocks.
---hint---
`stat -c '%s %b'`.
---solution---
Size is 4096. Allocated blocks on this filesystem are 0 for a fresh hole.
---script---
/usr/bin/truncate -s 4096 h
/usr/bin/stat -c '%s %b' h
```

```exercise
expect-exit: 0
---title---
Ask for a flush
---prompt---
Write `n` and run `sync -f n`. Print `done` afterward.
---hint---
sync's success means the request was accepted.
---solution---
The kernel accepted the sync. That is the whole claim.
---script---
/usr/bin/printf 'n\n' > n
/usr/bin/sync -f n
/usr/bin/printf 'done\n'
```

## Performance

`dd` with a tiny `bs` on a large file makes more syscalls than `bs` of 64 KiB or 1 MiB. The copy benchmark uses 64 KiB on an 8 MiB warm file and compares it with `cp`. Read the medians before you conclude anything. A larger block size can be slower if it causes a short-read bug on a pipe without `fullblock`, because you retry logic you did not write. Sparse conversion saves write I/O only when the output blocks are actually zero. A sparse `truncate` saves the writes entirely because nothing is copied. `sync` forces writeback, which makes a following read of "cold" data less cold and makes a benchmark that forgot about it lie. This course does not call `sync` inside the timing loops.
