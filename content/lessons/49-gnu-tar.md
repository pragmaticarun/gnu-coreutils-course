---
number: 49
slug: gnu-tar
title: GNU tar
module: Companion Tools
level: intermediate
minutes: 35
summary: GNU tar archives trees. It is not coreutils and not cp. Sparse files, --exclude, listings, and reproducible metadata are tar's own flags.
objectives:
  - Attribute tar to GNU tar and not to coreutils
  - Exclude a member, list the archive, and extract it
  - Show that --sparse stores a hole instead of the zero bytes
  - Build two archives with fixed owner, mtime, and sort order that cmp equal
manual: GNU tar manual | https://www.gnu.org/software/tar/manual/html_node/index.html
manual: tar sparse | https://www.gnu.org/software/tar/manual/html_node/sparse.html
manual: Coreutils truncate | https://www.gnu.org/software/coreutils/manual/html_node/truncate-invocation.html
gnu_vs_bsd: |
  BSD tar, often libarchive, spells some exclude and sparse flags differently and does not promise GNU tar's --sort. macOS bsdtar is not GNU tar 1.35. This lesson ran Ubuntu's GNU tar only. Archive hashes below depend on that implementation.
---

GNU tar reads and writes tape archives. It is not GNU coreutils. Ubuntu package `tar`, upstream GNU tar 1.35. `cp -a` copies a tree and keeps it as a tree. tar packs members into one file with its own headers. Checksums of a tree and checksums of a tarball answer different questions. Compression is a second program, gzip or zstd or the others in the next lesson, even when tar has a `-z` or `-I` switch that calls them. This lesson stays with the archive itself so the format is visible.

`tar -cf bundle.tar members` creates. `tar -tf bundle.tar` lists names. `tar -xf bundle.tar` extracts into the current directory. List before you extract. An archive can contain absolute paths or `..` members; GNU tar's defaults are safer than the oldest tar, and you should still look at `-t` before `-x` on an archive you did not write. Extract into a fresh directory when you are not sure.

`--exclude=drop.txt` skips a member while creating. Patterns are tar's, not the shell's, once they are quoted. Exclude build outputs, `.git`, and device files you do not want in a source drop. `--exclude` does not reach inside an archive you are only listing. It filters what gets added.

Sparse files are the disk feature `truncate` and `cp --sparse` already use in the coreutils lessons. A hole has a large apparent size and a small allocated size. `tar --sparse` records the hole. Without it, tar reads the zeros and stores them, and the archive grows to the apparent size plus headers. `wc -c` on the two archives is the proof. `du` and `stat` on the original file are the coreutils view of the same hole. The companion benchmark `sparse-tar` repeats that comparison on an 8 MiB hole and records both the medians and the archive sizes. Those sizes are measurements from that run. The example in this lesson prints `wc -c` for a 1 MiB hole so you can see the same mechanism on a fixture. Do not add the two experiments together.

Reproducible tarballs need fixed metadata. Default tar stores your user name, the file's mtime, and directory order that can follow readdir. Two creates of the same bytes then hash differently. `--sort=name` fixes the member order. `--owner=0 --group=0 --numeric-owner` stores numeric ids instead of the capture host's account. `--mtime=@0` stores the epoch. `cmp` of two archives built that way succeeds. `sha256sum` then names those bytes. GNU gzip's `-n` is the matching idea for the compressed wrapper, and it belongs to the compression lesson. This lesson's reproducible archive is uncompressed so the hash is tar's.

`--mtime` and `--owner` do not change the file on disk. They change the header in the archive. Extracting that archive as yourself creates files owned by you, unless you are root, which these scripts refuse to be.

## Worked examples

### Exclude, list, extract

```run
# title: One member in, one member out
# companion: tar
/usr/bin/printf 'keep\n' > keep.txt
/usr/bin/printf 'drop\n' > drop.txt
/usr/bin/tar --exclude=drop.txt -cf bundle.tar keep.txt drop.txt
/usr/bin/tar -tf bundle.tar
/usr/bin/mkdir out
/usr/bin/tar -xf bundle.tar -C out
/usr/bin/cat out/keep.txt
```

### A hole stays a hole in the archive

```run
# title: --sparse versus stored zeros
# companion: tar
/usr/bin/truncate -s 1M hole
/usr/bin/tar --sparse -cf sparse.tar hole
/usr/bin/tar --format=posix -cf plain.tar hole
/usr/bin/wc -c sparse.tar plain.tar
/usr/bin/stat -c %s hole
/usr/bin/du -B1 hole | /usr/bin/awk '{print $1}'
```

### Two creates, one byte string

```run
# title: Reproducible metadata
# companion: tar
/usr/bin/printf 'keep\n' > keep.txt
/usr/bin/tar --sort=name --owner=0 --group=0 --numeric-owner --mtime=@0 -cf a.tar keep.txt
/usr/bin/tar --sort=name --owner=0 --group=0 --numeric-owner --mtime=@0 -cf b.tar keep.txt
/usr/bin/cmp a.tar b.tar && /usr/bin/printf 'tar-bytes-match\n'
/usr/bin/sha256sum a.tar
```

### Listing shows the fixed header

```run
# title: Owner and mtime in the listing
# companion: tar
/usr/bin/printf 'keep\n' > keep.txt
/usr/bin/tar --owner=0 --group=0 --numeric-owner --mtime=@0 -cf bundle.tar keep.txt
/usr/bin/tar -tvf bundle.tar
```

## Performance

Creating a tarball of many small files is metadata and headers, not a sequential read of one blob. The cost is closer to `find` plus reads than to `dd` of one file. Compression on top multiplies CPU. For a backup you intend to restore once, a fast compressor with threads (pigz, `zstd -T`) is usually the right wrapper. For a release artifact you will download a million times, a slower higher ratio can win, and that choice is the next lesson's benchmark, not a property of tar.

`--sparse` saves archive bytes when the file is actually sparse. It costs a scan to find the holes. On a file that is dense, the scan is pure overhead. Use it when `du` and `stat` disagree, which is the sparse lesson in the coreutils track. The benchmark id `sparse-tar` is an 8 MiB hole, five trials, warm cache. Apparent size was 8388608 bytes. `tar --sparse` median elapsed time was 0.0012s and the archive was 10240 bytes. Without `--sparse` the median was 0.0136s and the archive was 8396800 bytes. The gap between medians was 0.0124s and the widest trial spread was 0.0091s, so the times separated on this hole, and the byte counts show why. A dense file is a different experiment.

Reproducible flags do not make creation slower in a way this course isolates. They make the hash stable, which is the point of a release tarball. Sorting member names is cheap next to reading the bodies, until the directory has an enormous number of names. This fixture has one member.

`tar -c` of a live build directory races the compiler. Snapshot the inputs, or accept a torn archive. tar does not lock the tree.

## Tips and pitfalls

`-f` takes the next argument as the archive. `tar -cf bundle.tar` is the archive. `tar -cf -` is stdout, for a pipe into a compressor. Forgetting `-f` makes tar wait for a tape device name you do not have.

`--exclude=drop.txt` matches the pattern against member names. A file in a subdirectory may need `*/drop.txt` or a path. Test with `-t`.

Extracting as root can create owners and device nodes. These scripts refuse root at download time. Do not "just sudo" a tarball from the internet.

GNU tar and libarchive tar both exist in the world. A flag you learned here may be spelled differently on macOS. The gnu-versus-BSD note is that warning. This capture did not run bsdtar.

## Exercises

```exercise
expect-exit: 0
---title---
List one member
---prompt---
Archive `keep.txt` and list the member names.
---hint---
`-cf` creates, `-tf` lists.
---hint2---
Do not extract yet. The list should be the one name.
---solution---
The line is `keep.txt`. tar is not coreutils.
---script---
/usr/bin/printf 'keep\n' > keep.txt
/usr/bin/tar -cf bundle.tar keep.txt
/usr/bin/tar -tf bundle.tar
```

```exercise
expect-exit: 0
---title---
Leave a file out
---prompt---
Create an archive of `keep.txt` and `drop.txt` that excludes `drop.txt`, then list it.
---hint---
`--exclude=drop.txt` on the create. Both names can still be on the command line.
---hint2---
`-tf` should print only `keep.txt`.
---solution---
One member, `keep.txt`.
---script---
/usr/bin/printf 'keep\n' > keep.txt
/usr/bin/printf 'drop\n' > drop.txt
/usr/bin/tar --exclude=drop.txt -cf bundle.tar keep.txt drop.txt
/usr/bin/tar -tf bundle.tar
```

```exercise
expect-exit: 0
---title---
Match two reproducible archives
---prompt---
Build two tar archives of `keep.txt` with owner 0, group 0, numeric ids, mtime at the epoch, and name sort. cmp them.
---hint---
The flags are `--sort=name --owner=0 --group=0 --numeric-owner --mtime=@0`.
---hint2---
`cmp` exits 0 when the bytes match. Print a word so the success is visible.
---solution---
`tar-bytes-match`. The hash can still be printed with sha256sum if you want a name for those bytes.
---script---
/usr/bin/printf 'keep\n' > keep.txt
/usr/bin/tar --sort=name --owner=0 --group=0 --numeric-owner --mtime=@0 -cf a.tar keep.txt
/usr/bin/tar --sort=name --owner=0 --group=0 --numeric-owner --mtime=@0 -cf b.tar keep.txt
/usr/bin/cmp a.tar b.tar && /usr/bin/printf 'tar-bytes-match\n'
```
