---
number: 40
slug: companion-tools
title: Tools that are not coreutils
module: How the toolbox thinks
level: intermediate
minutes: 30
summary: find, xargs, grep, sed, awk, and tar sit beside the toolbox and are easy to misfile as coreutils. hostname, kill, and uptime are in the GNU manual and still belong to other Ubuntu packages. rsync, perf, and GNU time are not installed here.
objectives:
  - Mark find, grep, sed, awk, and tar as other packages while using them for one real task
  - Walk a filename that contains a space with find -print0 and xargs -0
  - Show which package owns hostname, kill, and uptime on this image
  - Record that rsync, perf, and /usr/bin/time are absent
manual: Common options | https://www.gnu.org/software/coreutils/manual/html_node/Common-options.html
manual: Introduction | https://www.gnu.org/software/coreutils/manual/html_node/Introduction.html
gnu_vs_bsd: |
  BSD base systems ship their own find, grep, sed, awk, and tar, with different extended flags. GNU find is findutils. GNU grep is grep. On this Ubuntu image awk is mawk via alternatives, not gawk. The GNU coreutils manual documents hostname, kill, and uptime, but dpkg attributes those paths to other packages here. macOS `hostname` is not the hostname package this lesson queries. rsync and perf were not installed, so this lesson does not demonstrate their flags. No BSD companion was executed.
---

Coreutils is a bounded set. The introduction in the manual describes that set. Everything else you type in a shell is a guest. Guests are useful. Calling them coreutils leads to the wrong manual, the wrong bug tracker, and a script that assumes a flag the package never shipped. This lesson runs the guests and names the package.

`find` and `xargs` come from findutils. `find` walks a tree. `find -print0` ends each path with a NUL. `xargs -0` reads those paths and builds argument lists. Together they are the recursive form of the NUL-safe habit in the filename lesson. `xargs` has its own failure rules: by default a command that exits 255 can stop the whole run, and without `-0` it splits on blanks. A space in `my file` is the test. `wc -c` from coreutils can count the file once xargs has passed the name through intact.

`grep` searches. Coreutils does not. `grep -n` prints the line number. It is the right tool for "which line contains this token" and the wrong tool to cite as a coreutils one-liner. The remove lesson uses grep only as a companion to find a phrase in `rm --help`.

`sed` is a stream editor with its own language. `sed -n '2p'` prints the second line. `tail` and `head` can slice by count. They cannot apply an edit script. When you need the second line only, `sed -n '2p'` or `tail -n +2 | head -n 1` both work. The second form stays inside coreutils. Prefer it when the lesson is coreutils. Use sed when you are already in a sed script, and say so.

`awk` is a field language. On this host `/usr/bin/awk` is mawk, selected by the alternatives system, not GNU awk. A script that uses gawk-only features will fail here even though `awk` exists. The example prints the second field of one line and the version line mawk reports. `cut` is the coreutils field tool, and it splits on a single character. It does not evaluate an awk expression, and it does not understand CSV quotes. That limit has its own cookbook recipe.

`tar` writes a tape archive. `cp -a` copies a tree and is not an archive format. The example creates a one-file tar and lists it. Compression flags belong to tar and to gzip, not to coreutils. This course does not teach tar's format beyond "it is a different package".

`hostname`, `kill`, and `uptime` have nodes in the GNU coreutils manual because the upstream project documents them. Ubuntu packages them elsewhere. `dpkg -S` on the three paths shows the owning packages. The orientation lesson made the same point with the version of coreutils you do have. Read the manual node only after you have checked which binary answered.

`rsync` is not installed. `perf` is not installed. `/usr/bin/time` is not installed. The shell keyword `time` is bash, and it does not print maximum RSS. The benchmark helper uses Python's `resource` module for that counter and says so in the disclosure. Do not paste a GNU time format string into this environment and expect a binary to appear.

## Worked examples

### grep is its own package

```run
# title: A line number from grep
# companion: grep
/usr/bin/printf 'alpha\nbeta\n' | /usr/bin/grep -n beta
```

### A space survives -print0

```run
# title: find and xargs
# companion: find
/usr/bin/mkdir box
/usr/bin/printf 'x\n' > "box/my file"
/usr/bin/find box -type f -print0 | /usr/bin/xargs -0 /usr/bin/wc -c
```

### sed and mawk

```run
# title: Second line, second field
# companion: sed
/usr/bin/printf 'a\nb\n' | /usr/bin/sed -n '2p'
/usr/bin/printf 'field:'
/usr/bin/printf 'a b\n' | /usr/bin/awk '{print $2}'
/usr/bin/awk -W version > awk-version.txt
/usr/bin/head -n 1 awk-version.txt
```

### tar lists a member

```run
# title: tar is not cp
# companion: tar
/usr/bin/printf 'a\n' > file.txt
/usr/bin/tar -cf bundle.tar file.txt
/usr/bin/tar -tf bundle.tar
```

### Manual chapters this Ubuntu image attributes elsewhere

```run
# title: hostname, kill, uptime, and the absent tools
dpkg -S /usr/bin/hostname
dpkg -S /usr/bin/kill
dpkg -S /usr/bin/uptime
set +e
command -v rsync >/dev/null
/usr/bin/printf 'rsync_status:%s\n' $?
command -v perf >/dev/null
/usr/bin/printf 'perf_status:%s\n' $?
command -v /usr/bin/time >/dev/null
/usr/bin/printf 'gnu_time_status:%s\n' $?
set -e
```

## Recipes

In a C++ or Rust repository the usual walk is `find . -name '*.rs' -print0` or the build system's own file list. Prefer the build system. When you shell out, keep `-print0`. Count lines with `wc -l` only after each file is a separate argument or a separate redirection, so a filename cannot become an extra line of source.

Checksum an NDK zip with `sha256sum`, which is coreutils, and search the zip listing with tools that are not. Write the package name in the script comment. The next person will thank you when `awk` is mawk and their gawk function is missing.

When a blog shows `time -v`, check `command -v /usr/bin/time` before you port the flag. On this image the check fails. Use the benchmark helper or a language runtime counter.

## Tips and pitfalls

`command -v time` in bash finds the keyword and prints `time`, status 0. That is not GNU time. Test the path `/usr/bin/time`.

`xargs` without `-0` and without `-d` splits on spaces. The example's whole point disappears if you drop `-0` and also drop `-print0`. Drop them together or not at all.

`grep -r` is a walk plus a search. It is still not coreutils, and it has its own symlink and binary-file rules. Coreutils `grep` does not exist. There is nothing to fall back to inside `ls`.

`dpkg -S` can match several packages when the argument is a fragment. The example passes absolute paths. Keep that.

## Exercises

```exercise
expect-exit: 0
---title---
Find a numbered line
---prompt---
Print the grep line number of `beta` in a two-line stream.
---hint---
`grep -n`. This is not a coreutils binary.
---solution---
The line begins with `2:`.
---script---
/usr/bin/printf 'alpha\nbeta\n' | /usr/bin/grep -n beta
```

```exercise
expect-exit: 0
---title---
Print the second field with awk
---prompt---
Pipe `a b` through awk and print field 2.
---hint---
mawk is the awk on this host.
---solution---
`b`. The tool is a companion.
---script---
/usr/bin/printf 'a b\n' | /usr/bin/awk '{print $2}'
```

```exercise
expect-exit: 0
---title---
Show who owns hostname
---prompt---
Run `dpkg -S` on `/usr/bin/hostname`.
---hint---
The path is absolute so the match is the binary.
---solution---
The owning package is not coreutils. Read the captured line.
---script---
dpkg -S /usr/bin/hostname
```

## Performance

`find` is a directory walk, like `du`, and it does not read file bodies unless the predicate asks it to. `grep` reads bodies. Pointing `grep` at a tree of build artifacts reads those artifacts. Restrict the walk. `xargs` exists to batch arguments so you do not pay one exec per file, and also so you do not overflow `ARG_MAX`. A batch that is too large fails. A batch of one is a slow loop. The default batching is the feature. Do not replace it with a shell `while read` unless you need the loop, and if you do, read NUL with `read -d ''`.

`sed` and `awk` on a multi-gigabyte log are streaming and usually fine. They become the bottleneck when the script captures groups back into the shell once per line. Do the whole transform in one awk process. mawk and gawk differ in speed and in features. This course does not publish a winner, because the installed awk is mawk and gawk is not here to time.

`tar` of a tree of small files is metadata plus content. It is not a benchmark of `cp`. `rsync` would be a different algorithm and it is not installed, so any claim about its speed on this host would be fiction. The copy benchmark uses `cp` and `dd` only.
