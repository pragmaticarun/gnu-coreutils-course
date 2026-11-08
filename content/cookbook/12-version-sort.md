---
number: 12
slug: version-sort
title: Sort version-like names with sort -V
module: Cookbook
level: intermediate
minutes: 14
summary: Lexical sort puts a10 before a2. sort -V treats the digit runs as version numbers and prints a1, a2, a10.
manual: Version sort | https://www.gnu.org/software/coreutils/manual/html_node/Version-sort-overview.html
manual: sort invocation | https://www.gnu.org/software/coreutils/manual/html_node/sort-invocation.html
gnu_vs_bsd: |
  GNU `sort -V` is a GNU version-sort. BSD sort does not use `-V` for the same algorithm. The order is not the same as numeric `-n`, and it is not locale dictionary order. This recipe shows GNU sort 9.4 on three names. It is not a claim about every version scheme a package manager accepts.
---

Lexical sort compares characters. The name `a10` and the name `a2` share the prefix `a`, and then `1` is before `2`, so `a10` sorts first. That is the correct byte order and the wrong version order. `sort -V` recognizes runs of digits and compares those runs as version numbers, so the same three names come out `a1`, `a2`, `a10`. Package filenames, kernel tags, and `ls` of `app-1.2` versus `app-1.10` are why the flag exists.

Version sort is not a general semver parser. It does not apply every rule of a particular ecosystem's pre-release tags. Debian and RPM disagree with each other and with `-V` on some suffixes. Use `-V` for the "digits should compare as integers" problem. Use the package manager's own comparison when you are ordering real package versions for an upgrade decision.

`ls -v` is the listing form of a similar idea. `sort -V` is the filter you can put in a pipeline. Set the locale deliberately. Version sort still has text parts, and those parts follow rules the version-sort node describes. If the names are pure integers, `sort -n` is the simpler tool and the one readers expect.

## Steps

```run
# title: Lexical order
/usr/bin/printf 'a1\na10\na2\n' | /usr/bin/sort
```

```run
# title: Version order
/usr/bin/printf 'a1\na10\na2\n' | /usr/bin/sort -V
```

## Check yourself

```exercise
expect-exit: 0
---title---
Put a10 after a2
---prompt---
Version-sort the three lines `a1`, `a10`, and `a2`.
---hint---
`-V`, not the default comparison.
---solution---
`a1`, then `a2`, then `a10`.
---script---
/usr/bin/printf 'a1\na10\na2\n' | /usr/bin/sort -V
```

## Performance

`-V` is a more expensive comparison than an unsigned byte compare. On a short list of release names you will not measure it. On a multi-million-line file, a heavier comparator shows up in CPU, and `--parallel` does not remove that cost. If you only needed integer order on one field, `-n` or `-k` with `-n` is cheaper and clearer. The sort benchmarks on this site use a fixed key and a byte or locale collation. They do not time `-V`. Do not cite them as the cost of version sort. For a directory of a few hundred build artifacts, either flag finishes before you can read the help text.
