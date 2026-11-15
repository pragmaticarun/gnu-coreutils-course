---
number: 21
slug: large-duplicate-files
title: Find large files and duplicates
module: Cookbook
level: intermediate
minutes: 20
summary: find from findutils reports apparent size. du from coreutils reports allocated size. sha256sum groups duplicates. None of find is coreutils.
manual: GNU findutils | https://www.gnu.org/software/findutils/manual/html_node/index.html
manual: sha256sum invocation | https://www.gnu.org/software/coreutils/manual/html_node/sha256sum-invocation.html
gnu_vs_bsd: |
  BSD find prints sizes with a different predicate. BSD sha256 is not GNU sha256sum. This recipe ran GNU find and GNU sha256sum only.
---

A tree of build artifacts hides both a huge sparse file and two copies of the same blob. `find` is findutils, not coreutils. `-printf '%s'` is the apparent size. `du -B1` is the allocated size, and it is coreutils. A hole looks large to find and small to du. `sha256sum` is coreutils. Identical digests are duplicate contents even when the names differ. Sort the digests and let awk print the groups with more than one path. awk is mawk here and is not coreutils.

Keep the walk off the body of every file until you need the hash. Size filters first.

## Steps

```run
# title: Apparent size versus allocated size
# companion: find
/usr/bin/mkdir tree
/usr/bin/printf 'small\n' > tree/small.txt
/usr/bin/truncate -s 1M tree/hole
/usr/bin/find tree -type f -printf '%s %p\n' | LC_ALL=C /usr/bin/sort -n
/usr/bin/du -B1 tree/hole | /usr/bin/awk '{print "allocated:" $1}'
```

```run
# title: Identical bytes, two names
# companion: find
/usr/bin/mkdir tree
/usr/bin/printf 'same\n' > tree/a.bin
/usr/bin/printf 'same\n' > tree/b.bin
/usr/bin/find tree -type f -name '*.bin' -print0 | /usr/bin/xargs -0 /usr/bin/sha256sum | LC_ALL=C /usr/bin/sort | /usr/bin/awk '{c[$1]++; p[$1]=p[$1] " " $2} END {for (k in c) if (c[k]>1) print c[k], k}'
```

## Check yourself

```exercise
expect-exit: 0
---title---
Hash two copies
---prompt---
Create `a` and `b` with the same bytes and print one sha256sum line for each, sorted.
---hint---
sha256sum is coreutils. Sort so the names are stable.
---hint2---
The digests match. The paths differ.
---solution---
Two lines, same hash, paths `a` and `b` in order.
---script---
/usr/bin/printf 'same\n' > a
/usr/bin/printf 'same\n' > b
/usr/bin/sha256sum a b | LC_ALL=C /usr/bin/sort -k 2
```

## Performance

Hashing reads every byte. Finding sizes mostly stats. Do not sha256sum a tree to answer "what is large". `find -printf '%s'` or `du` answers size. Hash the candidates. Sparse files make `%s` and `du` disagree. The sparse-tar bench records archive sizes for a hole. It is a different question from duplicate content. `xargs -0` batches the checksums so you do not pay one process per file beyond the batches xargs builds. `-n 1` would throw that away. The `xargs-parallel` bench is the tiny-file extreme, where batching matters more than the hash.
