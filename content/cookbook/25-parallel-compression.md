---
number: 25
slug: parallel-compression
title: Parallel compression
module: Cookbook
level: advanced
minutes: 20
summary: pigz threads inside one gzip stream. zstd -T threads inside one frame. xargs -P compresses independent files. All three are not coreutils. The bench says when the threads fail to pay.
manual: pigz | https://zlib.net/pigz/
manual: Zstandard | https://facebook.github.io/zstd/zstd.1.html
manual: sha256sum invocation | https://www.gnu.org/software/coreutils/manual/html_node/sha256sum-invocation.html
gnu_vs_bsd: |
  pigz and zstd are the same upstream projects on BSD ports, with the same warning that -T0 means "this machine's cores". This recipe ran Ubuntu pigz 2.8 and zstd 1.5.5. GNU parallel is a different scheduler and is not required for one file.
---

Three different "parallel" knobs get mixed up. `pigz -p` threads a single gzip-format stream. `zstd -T` threads a single zstd frame. `xargs -P` runs several processes, one file each. None of those programs are coreutils. `cmp` after decompress proves the bytes. Independent files can use a pool. One big file should use the compressor's own threads, not a pool of one.

`-T0` and `-p` default follow the core count. This recipe writes `-T1` and `-p1` for the round trip so the result does not depend on `nproc`. The benchmark varies the thread count on 1 MiB and records whether the medians separated.

## Steps

```run
# title: pigz and zstd round-trip
# companion: pigz
/usr/bin/printf 'payload\n' > blob
/usr/bin/pigz -n -p1 -c blob > blob.gz
/usr/bin/gzip -dc blob.gz | /usr/bin/cmp - blob && /usr/bin/printf 'pigz-ok\n'
/usr/bin/zstd -q -T1 -c blob > blob.zst
/usr/bin/zstd -q -dc blob.zst | /usr/bin/cmp - blob && /usr/bin/printf 'zstd-ok\n'
```

```run
# title: Two files, xargs -P, separate outputs
# companion: xargs
/usr/bin/mkdir in out
/usr/bin/printf 'a\n' > in/a.txt
/usr/bin/printf 'b\n' > in/b.txt
/usr/bin/find in -type f -print0 | /usr/bin/xargs -0 -P 2 -I {} /bin/bash -c '/usr/bin/gzip -n -c "$1" > "out/$(/usr/bin/basename "$1").gz"' _ {}
/usr/bin/find out -type f -print | LC_ALL=C /usr/bin/sort
/usr/bin/gzip -dc out/a.txt.gz | /usr/bin/cmp - in/a.txt && /usr/bin/printf 'a-ok\n'
```

## Check yourself

```exercise
expect-exit: 0
---title---
Compress one file with an explicit thread
---prompt---
zstd-compress `blob` with `-T1`, decompress, and cmp.
---hint---
`-q` silences the banner. `-c` writes stdout. `-dc` decompresses.
---hint2---
Do not use `-T0`. The exercise asks for one thread.
---solution---
`zstd-ok`.
---script---
/usr/bin/printf 'payload\n' > blob
/usr/bin/zstd -q -T1 -c blob > blob.zst
/usr/bin/zstd -q -dc blob.zst | /usr/bin/cmp - blob && /usr/bin/printf 'zstd-ok\n'
```

## Performance

On 1 MiB, extra threads often lose to startup. That is what `compress-compressible` and `compress-random` are for. Read the note before you add `-T` to a script whose files are small. On a large artifact the same flags can separate. This course did not time a multi-gigabyte input. `xargs -P` around `zstd -T` stacks two pools. Use one. GNU parallel adds a Perl startup that the `xargs-parallel` bench includes for tiny checksums. It is the wrong scheduler for one pigz of one file. gzip without pigz is single-threaded and remains the compatible reader.
