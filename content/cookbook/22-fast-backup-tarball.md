---
number: 22
slug: fast-backup-tarball
title: A fast backup tarball
module: Cookbook
level: advanced
minutes: 20
summary: GNU tar excludes a junk file, fixes metadata, and writes bytes you can cmp. zstd wraps the archive. tar and zstd are not coreutils.
manual: GNU tar | https://www.gnu.org/software/tar/manual/html_node/index.html
manual: Zstandard | https://facebook.github.io/zstd/zstd.1.html
manual: cksum invocation | https://www.gnu.org/software/coreutils/manual/html_node/cksum-invocation.html
gnu_vs_bsd: |
  bsdtar spells exclude and sort differently. macOS does not ship this zstd by default. This recipe ran GNU tar 1.35 and zstd 1.5.5 only.
---

A backup of a source drop should skip build junk, restore to the same bytes, and not embed your username. `tar` is GNU tar, not coreutils. `--exclude` drops `junk.o`. `--sort=name --owner=0 --group=0 --numeric-owner --mtime=@0` makes two creates match. `zstd` is Zstandard, not coreutils. `-T1` asks for one thread so the wrapper is explicit. `-q` keeps the banner off. `sha256sum` names the compressed bytes. Extract and `cmp` the member you kept.

This fixture is tiny, so it proves the bytes. Speed of zstd versus gzip is the `compress-compressible` and `compress-random` benches, on 1 MiB, not this file.

## Steps

```run
# title: Exclude, pin metadata, compress
# companion: tar
/usr/bin/mkdir src
/usr/bin/printf 'keep\n' > src/keep.txt
/usr/bin/printf 'nope\n' > src/junk.o
/usr/bin/tar --exclude='*.o' --sort=name --owner=0 --group=0 --numeric-owner --mtime=@0 -cf - -C src . | /usr/bin/zstd -q -T1 -o backup.tar.zst
/usr/bin/sha256sum backup.tar.zst
/usr/bin/mkdir restore
/usr/bin/zstd -q -dc backup.tar.zst | /usr/bin/tar -xf - -C restore
/usr/bin/cmp src/keep.txt restore/keep.txt && /usr/bin/printf 'member-matches\n'
/usr/bin/test ! -e restore/junk.o && /usr/bin/printf 'junk-excluded\n'
```

```run
# title: A second create matches
# companion: tar
/usr/bin/mkdir src
/usr/bin/printf 'keep\n' > src/keep.txt
/usr/bin/printf 'nope\n' > src/junk.o
/usr/bin/tar --exclude='*.o' --sort=name --owner=0 --group=0 --numeric-owner --mtime=@0 -cf - -C src . | /usr/bin/zstd -q -T1 -o backup.tar.zst
/usr/bin/tar --exclude='*.o' --sort=name --owner=0 --group=0 --numeric-owner --mtime=@0 -cf - -C src . | /usr/bin/zstd -q -T1 -o again.tar.zst
/usr/bin/cmp backup.tar.zst again.tar.zst && /usr/bin/printf 'archive-matches\n'
```

## Check yourself

```exercise
expect-exit: 0
---title---
Round-trip one file through tar and zstd
---prompt---
Archive `keep.txt` with epoch mtime and owner 0, compress with `zstd -q -T1`, extract, and cmp.
---hint---
tar writes to stdout with `-cf -`. zstd writes the file with `-o`.
---hint2---
`--mtime=@0 --owner=0 --group=0 --numeric-owner`. Then decompress into tar -x.
---solution---
`member-matches`. tar and zstd are not coreutils.
---script---
/usr/bin/printf 'keep\n' > keep.txt
/usr/bin/tar --owner=0 --group=0 --numeric-owner --mtime=@0 -cf - keep.txt | /usr/bin/zstd -q -T1 -o one.tar.zst
/usr/bin/mkdir out
/usr/bin/zstd -q -dc one.tar.zst | /usr/bin/tar -xf - -C out
/usr/bin/cmp keep.txt out/keep.txt && /usr/bin/printf 'member-matches\n'
```

## Performance

For a backup you will restore yourself, a fast zstd level and an explicit `-T` beat xz's high levels on CPU. The recorded sizes and medians are in `compress-compressible` for repetitive bytes and `compress-random` for bytes that will not shrink. Read both before you pick a format. `-T0` means "all cores here", which is a different number on the next machine. This recipe pins `-T1` so the bytes stay comparable. Sparse members belong under `tar --sparse`, measured as `sparse-tar`. Compression multiplies that choice. Do not drop caches to make the backup look slow. The disclosure already says the cache was warm.
