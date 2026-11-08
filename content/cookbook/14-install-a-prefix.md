---
number: 14
slug: install-a-prefix
title: Place a program in a prefix with install -D
module: Cookbook
level: intermediate
minutes: 14
summary: install -D -m 755 creates the destination directory and sets the mode in one step. An empty prefix is refused before any copy.
manual: install invocation | https://www.gnu.org/software/coreutils/manual/html_node/install-invocation.html
gnu_vs_bsd: |
  GNU `install -D` creates missing parents. BSD `install` uses a different set of flags and often requires the directory to exist. `-m 755` is the executable mode this recipe requests. The source here is `/usr/bin/true`, copied into a scratch prefix. This is GNU install from coreutils 9.4.
---

`install` is the tool a build uses to publish a binary into a prefix. `cp` copies bytes. `install -D -m 755` copies bytes, creates the parent directory, and sets the mode. `-D` is what saves you from a separate `mkdir -p` that a later edit forgets. The mode is the one you pass, not whatever umask did to a `cp` followed by a forgotten `chmod`.

The recipe copies `/usr/bin/true` into `prefix/bin/true` inside the scratch directory. That is a stand-in for the binary your compiler just linked. Running the installed path shows the mode is executable. `stat -c '%a'` prints `755`. Refuse an empty prefix and refuse `/` before you call install. The guard is ordinary `test`. `install` will not save you from a variable that expanded to the real root. `--preserve-root` is an `rm` feature, not an `install` feature.

`install -C` skips the write when the content is unchanged, which keeps the mtime stable and stops an incremental build from rebuilding the world. The permissions lesson measures that on a small file. Use `-C` when stamps matter. Use plain `-D` when you always want the mode reapplied and you have not read the `-C` comparison rules yet.

## Steps

```run
# title: Create bin and set the mode
/usr/bin/install -D -m 755 /usr/bin/true prefix/bin/true
/usr/bin/stat -c '%a %n' prefix/bin/true
prefix/bin/true
/usr/bin/printf 'ran:%s\n' $?
```

```run
# title: Refuse an empty prefix
prefix=""
if test -z "$prefix" || test "$prefix" = /; then
  /usr/bin/printf 'refuse\n'
else
  /usr/bin/printf 'would-install\n'
fi
```

## Check yourself

```exercise
expect-exit: 0
---title---
Install true into a prefix
---prompt---
Use `install -D -m 755` to copy `/usr/bin/true` to `prefix/bin/true` and print the mode.
---hint---
`-D` creates `prefix/bin`.
---solution---
The mode is `755`. The command runs and returns 0.
---script---
/usr/bin/install -D -m 755 /usr/bin/true prefix/bin/true
/usr/bin/stat -c '%a' prefix/bin/true
```

## Performance

Installing one binary is a copy. Installing thousands of headers is a metadata walk. `-C` avoids dirtying mtimes when the bytes did not change, and that saving shows up as fewer downstream rebuilds, not as a faster `install` process. The copy benchmark measures `cp` and `dd`, not `install`. Expect `install` of a large binary to cost about what a copy costs, plus a chmod. Do not put `install` on a network filesystem and then blame the flag for the latency. The network is the bottleneck. A local prefix on the same filesystem can at least be a rename of a finished file, which is the move lesson's publish pattern: write the temp name beside the final name, then `mv -T`.
