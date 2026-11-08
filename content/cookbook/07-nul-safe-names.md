---
number: 7
slug: nul-safe-names
title: Count a file whose name contains a space
module: Cookbook
level: intermediate
minutes: 15
summary: find -print0 and xargs -0 keep a space inside one filename. find and xargs are findutils, not coreutils. wc is coreutils.
manual: wc invocation | https://www.gnu.org/software/coreutils/manual/html_node/wc-invocation.html
manual: Special file names | https://www.gnu.org/software/coreutils/manual/html_node/Special-file-names.html
gnu_vs_bsd: |
  GNU find `-print0` and GNU xargs `-0` are the NUL pair. BSD find and xargs also support them. A POSIX-only `xargs` without `-0` splits on blanks. `wc` is in both userlands. This recipe marks find as a companion and ran it on Ubuntu.
---

A space in a filename is ordinary on a desktop and fatal in a shell pipeline that splits words. `my file` is one directory entry. An unquoted expansion or a newline-oriented `xargs` treats it as two arguments, and `wc` then reports that `my` does not exist. The durable fix is to end each name with a NUL byte, which cannot appear inside a path, and to read names the same way.

`find` is findutils. `xargs` is findutils. `wc` is coreutils. The pipeline `find box -type f -print0 | xargs -0 wc -c` is a collaboration, and the example badge says so. Dropping either `-print0` or `-0` reintroduces the split. `ls` piped to `xargs` is the version that fails the space test even before newlines. GNU `ls --zero` exists when you already have a non-recursive listing and you refuse to switch to find. Recursive walks belong to find or to your build system.

Coreutils filters that accept `-z` (`sort -z`, `uniq -z`) keep the same boundary once find has produced it. Converting NUL to newline with `tr` so you can use a tool that lacks `-z` brings the original bug back the moment a name contains a newline. Prefer a tool that understands NUL, or do the walk in the language that will process the files.

## Steps

```run
# title: A space survives NUL framing
# companion: find
/usr/bin/mkdir box
/usr/bin/printf 'hello\n' > "box/my file"
/usr/bin/find box -type f -print0 | /usr/bin/xargs -0 /usr/bin/wc -c
```

```run
# title: The quoting style a human can see
/usr/bin/mkdir box
/usr/bin/printf 'hello\n' > "box/my file"
/usr/bin/ls --quoting-style=shell-escape box
```

## Check yourself

```exercise
expect-exit: 0
---title---
Byte-count a two-word name
---prompt---
Create `box/my file` containing `hello` and a newline, and count it with find -print0 and xargs -0 wc -c.
---hint---
Both the producer and the consumer need the NUL flag.
---solution---
wc prints 6 and the path. The space stayed inside one argument.
---script---
/usr/bin/mkdir box
/usr/bin/printf 'hello\n' > "box/my file"
/usr/bin/find box -type f -print0 | /usr/bin/xargs -0 /usr/bin/wc -c
```

## Performance

NUL framing adds one byte per name and no measurable CPU next to reading the file. The win is that you do not rerun the job after `wc` skipped half the tree. `xargs` batches names so `wc` starts once per batch instead of once per file. That exec saving matters when the files are tiny and disappears when each file is hundreds of megabytes, because the read dominates. `find` itself is a metadata walk. It is slow on a cold directory cache and fast on a warm one. This recipe does not drop caches, and it does not claim a timing. The safe pipeline is the one you can finish.
