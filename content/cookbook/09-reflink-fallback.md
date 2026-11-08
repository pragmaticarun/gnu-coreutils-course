---
number: 9
slug: reflink-fallback
title: Ask for a reflink and accept a real copy
module: Cookbook
level: intermediate
minutes: 14
summary: cp --reflink=always fails on this filesystem. --reflink=auto copies and exits 0. The fallback is the behavior a script can ship.
manual: cp invocation | https://www.gnu.org/software/coreutils/manual/html_node/cp-invocation.html
gnu_vs_bsd: |
  GNU `cp --reflink=always` and `--reflink=auto` are Linux clone requests. macOS `cp` uses a different clone flag and a different failure text. A script that requires `always` will exit 1 on this ext4. This recipe captured that failure and the auto fallback. It did not run BSD cp.
---

A reflink is a request that the filesystem share extents between two directory entries instead of reading and writing every byte. `cp --reflink=always` makes the request mandatory. On this capture host the kernel returns "Operation not supported" and cp exits 1. Nothing is left that you can treat as a successful clone. `cp --reflink=auto` makes the same request and, when the filesystem refuses, copies the bytes and exits 0. The destination then has the same contents and its own allocated blocks.

A build script that uses `always` on a developer laptop with btrfs and in CI on ext4 will be green on the laptop and red in CI, or the reverse. `auto` is the portable request inside GNU cp when a clone is a nice speedup and a copy is acceptable. `always` belongs in a test that is specifically asserting "this filesystem can clone", where a failure is the result you want to see.

Check the copy. `wc -c` or `sha256sum` of both files tells you the bytes arrived. A reflink and a plain copy look the same to `cat`. They do not look the same to `du -B1` once the file is large and the clone shares blocks. This recipe uses a five-byte file, so allocation differences are smaller than a block and are the wrong thing to assert. The status and the byte count are the assertion.

## Steps

```run
# title: A mandatory clone fails here
/usr/bin/printf 'data\n' > src
set +e
/usr/bin/cp --reflink=always src dst
/usr/bin/printf 'always:%s\n' $?
set -e
```

```run
# title: auto falls back to a copy
/usr/bin/printf 'data\n' > src
/usr/bin/cp --reflink=auto src dst
/usr/bin/wc -c dst
/usr/bin/sha256sum src dst
```

## Check yourself

```exercise
expect-exit: 0
---title---
Copy with an optional reflink
---prompt---
Write `data` and a newline and copy it with `--reflink=auto`. Print the destination size.
---hint---
`auto` exits 0 on this host.
---solution---
The size is 5. The digests of source and destination match.
---script---
/usr/bin/printf 'data\n' > src
/usr/bin/cp --reflink=auto src dst
/usr/bin/wc -c dst
```

## Performance

When a clone works, the elapsed time stays near the cost of a metadata update and does not grow with the file size. When it falls back, the elapsed time is a read and a write of every byte. This host takes the second path. The copy benchmark compares `cp --reflink=never` with `dd` on an 8 MiB dense file so the fallback is what is measured, and it says the cache is warm. Do not quote a btrfs clone benchmark as the speed of `cp` on this ext4. If you change filesystems, rerun the measurement. A script that logs whether the `always` probe failed is more honest than a script that hides the fallback inside `auto` and then claims the copy was free.
