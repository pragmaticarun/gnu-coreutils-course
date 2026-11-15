---
number: 24
slug: weird-filenames
title: Safely process weird file names
module: Cookbook
level: advanced
minutes: 20
summary: A space and a newline in a name survive find -print0 and xargs -0. A line-oriented find does not. sha256sum then hashes the bytes. find and xargs are not coreutils.
manual: GNU findutils | https://www.gnu.org/software/findutils/manual/html_node/index.html
manual: sha256sum invocation | https://www.gnu.org/software/coreutils/manual/html_node/sha256sum-invocation.html
gnu_vs_bsd: |
  BSD find's NUL flag is not spelled -print0 on every version. BSD xargs -0 exists in many builds and is still a different findutils. This recipe ran GNU find and GNU xargs only.
---

File names are bytes. A space splits `xargs` arguments. A newline splits `find`'s default output into extra lines. `find -print0` and `xargs -0` are findutils, not coreutils, and they keep both names intact. `sha256sum` is coreutils and hashes the contents once the name arrives as one argument. `sort -z` is the coreutils sort that orders NUL records if you need order before xargs. This recipe sorts after the hash, on the text sha256sum printed, which is safe only because the names in the checksum output are the second field and our demo names do not contain a newline in the hashed listing we sort as text. The newline name is counted with NULs instead of being pushed through a line-oriented sort.

The broken form is shown by counting lines versus NULs, not by letting `xargs` without `-0` roam.

## Steps

```run
# title: Space in the name, hash intact
# companion: find
/usr/bin/mkdir box
/usr/bin/printf 'abc\n' > "box/my file"
/usr/bin/find box -type f -print0 | /usr/bin/xargs -0 /usr/bin/sha256sum
```

```run
# title: Newline in the name
# companion: find
/usr/bin/mkdir odd
/usr/bin/printf 'z\n' > "odd/a
name"
lines=$(/usr/bin/find odd -type f | /usr/bin/wc -l | /usr/bin/tr -d ' ')
nuls=$(/usr/bin/find odd -type f -print0 | /usr/bin/tr -cd '\0' | /usr/bin/wc -c | /usr/bin/tr -d ' ')
/usr/bin/printf 'lines:%s\nnuls:%s\n' "$lines" "$nuls"
bytes=$(/usr/bin/find odd -type f -print0 | /usr/bin/xargs -0 /usr/bin/wc -c | /usr/bin/awk '{s+=$1} END {print s}')
/usr/bin/printf 'bytes:%s\n' "$bytes"
```

## Check yourself

```exercise
expect-exit: 0
---title---
Hash a name that contains a space
---prompt---
Create `box/my file` and sha256sum it through find -print0 and xargs -0.
---hint---
Quote the path when you create it. Pass -0.
---hint2---
The checksum line contains `box/my file` as one path.
---solution---
One sha256sum line for that path.
---script---
/usr/bin/mkdir box
/usr/bin/printf 'abc\n' > "box/my file"
/usr/bin/find box -type f -print0 | /usr/bin/xargs -0 /usr/bin/sha256sum
```

## Performance

NUL safety is not slower in any way that matters next to reading the file. The failure mode of the unsafe form is wrong names, not a few microseconds. `xargs` batches arguments, which is the performance feature, and `-0` does not disable batching. `-n 1` does. The benchmark id `xargs-parallel` shows the cost of one process per tiny file. Use the batching and the NUL flags together. `sort -z` costs the same sort as a line sort and handles the records a line sort would corrupt. plocate will not see these scratch names. The index is the wrong tool for a tree you just created.
