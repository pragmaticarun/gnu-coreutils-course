---
number: 43
slug: gnu-grep
title: GNU grep
module: Companion Tools
level: beginner
minutes: 35
summary: GNU grep searches lines. It is the grep package, not coreutils. Fixed strings and LC_ALL=C avoid work you did not mean to request. A binary file is a different mode.
objectives:
  - Say that grep is GNU grep and not coreutils
  - Choose -F when the needle is literal
  - Use -z for NUL-separated records and -a when you really want the bytes of a binary file
  - Point speed questions at the companion benchmark instead of a single stopwatch run
manual: GNU grep manual | https://www.gnu.org/software/grep/manual/html_node/index.html
manual: grep invocations | https://www.gnu.org/software/grep/manual/html_node/Invoking.html
manual: Coreutils wc | https://www.gnu.org/software/coreutils/manual/html_node/wc-invocation.html
gnu_vs_bsd: |
  BSD grep accepts -F and -E with different default engines and a different binary-file message. macOS grep is not GNU grep 3.11. This lesson ran Ubuntu's GNU grep only. ripgrep is a separate project, covered with the helpers, and it is not a GNU grep flag.
---

GNU grep searches. It is not GNU coreutils. On this host the binary is `/usr/bin/grep`, Ubuntu package `grep`, upstream GNU grep. `grep --version` reports GNU grep 3.11. Coreutils can count lines with `wc` and slice them with `cut`. It cannot say which line contains a token. Use grep for that, and say the package in the script comment.

The usual job in a C++, Rust, or Android tree is a fixed token: an error code, a log tag, a symbol. `-F` treats the needle as literal bytes. A dot in `a.c` is a dot. Without `-F`, a basic regular expression treats the dot as any character, and `-E` does the same for extended expressions. `-P` is Perl syntax, present in this build, and it is a different engine with its own cost. Do not reach for `-P` because a pattern looked hard. Most needles are fixed strings.

`-n` prints the line number. `-l` prints the file name once. `-w` asks for a word boundary, which is a locale-aware idea, not a byte idea. Recursive search is `grep -r`. It walks. It has its own rules for symlinks, binary files, and devices. It is still not coreutils. Prefer the build system's file list, or `find` with a name test, when you already know the suffixes.

GNU grep treats a file as binary when it sees a NUL in the first buffer. The default is then a one-line notice, `binary file matches`, and no line text. `-a` forces text. `-I` skips binary files. A log that embeds a NUL is binary to grep even when the rest is ASCII. `-z` changes the record separator to NUL, which is the match for `find -print0` and for `sort -z` when the data, not the file name, contains the NUL.

Locale is a speed knob and a correctness knob. In `en_US.UTF-8`, character classes and case folding walk multibyte rules. `LC_ALL=C` compares bytes. For an ASCII log and a fixed string, the C locale does less work. The companion benchmark `grep-fixed-locale` is the measured comparison on a warm 4 MiB ASCII file. Read that row. A single `time grep` in a shell is one sample and includes the shell.

`grep` exits 0 when it finds a match, 1 when it does not, and 2 on a real error. Under `set -o pipefail` a search that misses is a failed pipeline. That is often what you want in a script that must find the token, and it is a surprise in a script that was only asking.

## Worked examples

### A dot is a dot

```run
# title: Fixed string versus an extended dot
# companion: grep
/usr/bin/printf 'a.c\nabc\n' > names.txt
/usr/bin/printf 'fixed:\n'
/usr/bin/grep -F -n 'a.c' names.txt
/usr/bin/printf 'extended:\n'
/usr/bin/grep -E -n 'a.c' names.txt
```

### NUL records

```run
# title: grep -z splits on NUL
# companion: grep
/usr/bin/printf 'alpha\0beta gamma\0' | /usr/bin/grep -z -F 'beta' | /usr/bin/tr '\0' '\n'
```

### A NUL in the file changes the mode

```run
# title: Binary match, then -a
# companion: grep
/usr/bin/printf 'a\0b\nhello\n' > bin.txt
set +e
/usr/bin/grep -F hello bin.txt >text.out 2>text.err
status=$?
set -e
/usr/bin/printf 'status:%s\n' "$status"
cat text.err
/usr/bin/printf 'with-a:\n'
/usr/bin/grep -a -F hello bin.txt
```

### Count in the C locale

```run
# title: LC_ALL=C counts a fixed token
# companion: grep
/usr/bin/printf 'ok\nNEEDLE-TOKEN\nok\n' > log.txt
LC_ALL=C /usr/bin/grep -F -c 'NEEDLE-TOKEN' log.txt
```

## Performance

The expensive mistakes are a walk you did not need and an engine you did not need. `grep -r` on `target/`, `node_modules/`, or an Android `out/` directory reads build products. Restrict the path. If the needle is literal, `-F` skips the regex compiler's richer matcher. If the file is ASCII, `LC_ALL=C` skips multibyte decoding. Those are mechanisms. Whether they separate on a given file is a measurement.

On this host the harness timed `LC_ALL=C grep -F`, UTF-8 `grep -F`, and UTF-8 `grep -E` with one optional character, five trials, median, warm cache. The input recorded in `companions.json` under `grep-fixed-locale` is 4195400 ASCII bytes. The medians were 0.0009s, 0.0009s, and 0.0008s. The gap was 0.0000s and the widest trial spread was 0.0002s, so this run does not separate the variants. A 4 MiB ASCII file is too small for the locale and the engine to show up next to process startup. That is the result. It is not a reason to skip `-F` or `LC_ALL=C` on a multi-gigabyte log, and it is not a ranking you can carry to another machine.

`grep` on a pipe cannot seek. It reads until the writer closes. A slow producer looks like a slow grep. `pv` in the throughput lesson is how you see which side of the pipe is full. `strace -c -e read,write` shows the system calls and still is not a cycle counter. `perf` is not installed here.

Output volume matters. Printing every matching line from a multi-gigabyte log costs more than the match. `-c`, `-l`, or a tighter pattern reduces the write. `LC_ALL=C` does not make a huge output cheap.

## Tips and pitfalls

A pattern that starts with `-` looks like a flag. Use `grep -F -e -- -n` or `grep -e -- --marker` after `--`. The double dash ends options.

`grep -v` inverts. Combined with exit status 1 for "no match", an inverted search that finds nothing exits 1. Test the status you meant.

Word boundaries and `[[:space:]]` follow the locale. A fixed ASCII token does not need them.

GNU grep's `--null` (`-Z`) writes a NUL after a file name. That is the file-name form. `-z` is the data-record form. They solve different problems. The find lesson uses `-print0` and `xargs -0` for names.

ripgrep is faster on many source trees because it skips ignored and binary paths. It is not GNU grep, and a script that must match the system grep should call `/usr/bin/grep`.

## Exercises

```exercise
expect-exit: 0
---title---
Find a literal dot
---prompt---
Print only the line `a.c` from a two-line file that also contains `abc`. Use a fixed string.
---hint---
`-F` and `-n` together. The dot must not match the other line.
---hint2---
`grep -F -n 'a.c'`. Extended mode would also print `abc`.
---solution---
One line, number 1, text `a.c`.
---script---
/usr/bin/printf 'a.c\nabc\n' > names.txt
/usr/bin/grep -F -n 'a.c' names.txt
```

```exercise
expect-exit: 0
---title---
Count in the C locale
---prompt---
Count lines containing the fixed token `ERR` under `LC_ALL=C`.
---hint---
`grep -F -c` prints a number and exits 0 when the count is positive.
---hint2---
Put the assignment in front of the command. The token is literal.
---solution---
The output is `2`.
---script---
/usr/bin/printf 'ERR a\nok\nERR b\n' > log.txt
LC_ALL=C /usr/bin/grep -F -c ERR log.txt
```

```exercise
expect-exit: 0
---title---
Read a NUL-separated record
---prompt---
From the bytes `one\0two\0`, print the record that contains `two`, as a normal line.
---hint---
`grep -z -F` keeps NULs between records. Translate the NUL to a newline to display it.
---hint2---
`tr '\0' '\n'` after grep. This is data, not a file name.
---solution---
The line is `two`.
---script---
/usr/bin/printf 'one\0two\0' | /usr/bin/grep -z -F two | /usr/bin/tr '\0' '\n'
```
