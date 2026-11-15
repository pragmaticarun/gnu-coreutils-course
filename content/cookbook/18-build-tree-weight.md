---
number: 18
slug: build-tree-weight
title: What weighs on a build tree
module: Cookbook
level: intermediate
minutes: 18
summary: du -d 1 shows which child directory dominates. du -b plus sort names the heavy file. numfmt runs after the sort, not before it.
manual: du invocation | https://www.gnu.org/software/coreutils/manual/html_node/du-invocation.html
manual: numfmt invocation | https://www.gnu.org/software/coreutils/manual/html_node/numfmt-invocation.html
gnu_vs_bsd: |
  GNU `du -d` is `--max-depth`. BSD du spells the depth limit differently. GNU `du -b` is apparent size in bytes. macOS `du` uses another flag for logical size. `numfmt` is GNU. This recipe uses holes from `truncate`, so the apparent sizes are the sizes a zip would see. Allocated blocks on a sparse file are a different question, and this recipe does not claim them.
---

`du -h` of a Rust `target/` or an Android `out/` prints a number a person can read and a column `sort -n` will mis-order once the units change. Keep the byte count until the order is settled. `du -d 1 -b` is one level of apparent size. The parent line is the total. The child lines are the question "debug or release?". `du -b` on the files inside the heavy directory is the question "which file?".

`numfmt --to=iec` turns 1048576 into `1.0M`. That string does not sort as a number next to `512K`. Format last, with `--field=1`, so the path stays text. `--padding=1` avoids a run of spaces that looks like a second column.

The tree below is two holes, not two compiled libraries. `truncate -s 5M` and `truncate -s 1M` set apparent size without writing those bytes. On this capture, `du -d 1 -b` reports exactly 5242880 for `target/debug`, 1048576 for `target/release`, and 6291456 for `target`. A directory that is not a hole can add its own apparent size on top of the files. Compare the child lines with `sort -n` rather than assuming the directory inode is free. Apparent size is what you are about to zip. Allocated size is why the disk is full when holes are involved. The du lesson keeps those apart. The assertion script is [sandbox/build-tree-weight.sh](/sandbox/build-tree-weight.sh).

## Steps

```run
# title: One level, then the files
mkdir -p target/debug target/release
truncate -s 5M target/debug/deps.rlib
truncate -s 1M target/release/demo
echo '--- depth ---'
du -d 1 -b target | LC_ALL=C sort -n
echo '--- files ---'
du -b target/release/demo target/debug/deps.rlib | LC_ALL=C sort -n | numfmt --field=1 --to=iec --padding=1
```

```run
# title: The parent total is the largest line
mkdir -p target/debug target/release
truncate -s 5M target/debug/deps.rlib
truncate -s 1M target/release/demo
du -d 1 -b target | LC_ALL=C sort -n | tail -n 1
```

## Check yourself

```exercise
expect-exit: 0
---title---
Which child directory is heavier?
---prompt---
Build the two-hole tree and show `du -d 1 -b target` sorted numerically.
---hint---
`du -d 1` prints the parent and the children. The parent total is the largest line.
---hint2---
`sort -n` orders by the byte field. The child path with the larger number is the heavier directory. Do not sort the `numfmt` text.
---solution---
`target/release` is 1048576 apparent bytes. `target/debug` is 5242880. `target` is 6291456, the sum, and it sorts last. Debug is the heavier child.
---script---
mkdir -p target/debug target/release
truncate -s 5M target/debug/deps.rlib
truncate -s 1M target/release/demo
du -d 1 -b target | LC_ALL=C sort -n
```

```exercise
expect-exit: 0
---title---
Format after the sort
---prompt---
Sort `du -b` of the two files numerically, then format field 1 as IEC with one column of padding. The demo line should contain `1.0M`.
---hint---
1048576 bytes is `1.0M` in IEC units. SI units would not print the same text.
---hint2---
`--field=1` is the size. `--padding=1` keeps a single space before the path. The path is not a number.
---solution---
The demo line is `1.0M target/release/demo`. The library line is `5.0M`. Formatting before `sort -n` would ask sort to compare those strings as text.
---script---
mkdir -p target/debug target/release
truncate -s 5M target/debug/deps.rlib
truncate -s 1M target/release/demo
du -b target/release/demo target/debug/deps.rlib | LC_ALL=C sort -n | numfmt --field=1 --to=iec --padding=1
```

## Performance

`du -d 1` still stats every file under the children. The depth limit only hides their names. On a real `target/` directory the cost is the metadata walk, the same cost the du lesson describes, and a second run is the page cache. These two holes are a metadata update each. Do not time them and call the result the cost of a Rust build. `du -b` does not read the five mebibytes, because they were never written. A tool that opens the file and reads to EOF will generate the zeros and then the time is real. Say which `du` you ran before you compare two trees.
