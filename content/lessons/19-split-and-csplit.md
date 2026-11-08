---
number: 19
slug: split-and-csplit
title: split and csplit
module: Reading and shaping text
level: intermediate
minutes: 28
summary: split cuts by size or into chunks. csplit cuts at a pattern. Round-robin mode distributes lines, so one line stays in one piece.
objectives:
  - Split a file by line count with numeric suffixes
  - Distinguish split -n N from split -n r/N
  - Cut a file at a regex with csplit
  - Suppress empty pieces with csplit -z
manual: split invocation | https://www.gnu.org/software/coreutils/manual/html_node/split-invocation.html
manual: csplit invocation | https://www.gnu.org/software/coreutils/manual/html_node/csplit-invocation.html
gnu_vs_bsd: |
  GNU `split` adds `-d`, `-a`, `--additional-suffix`, `--filter`, and `-n` with `l/` and `r/` forms. BSD split is a smaller tool. `csplit` is GNU and is not in the macOS base system. Chunk behavior below was captured with GNU split 9.4. Do not copy `-n r/3` into a script and assume byte-wise round robin.
---

`split` writes pieces of a file. `-l 2` means two lines per piece. `-b` means bytes per piece. `-d` uses numeric suffixes instead of letters. `-a` sets the suffix width. The default prefix is `x`. Pieces land in the current directory unless you pass a prefix path. A script should `cd` to a scratch directory or pass an absolute prefix so it does not scatter `x00` files through a source tree.

`-n N` splits into N byte chunks as evenly as it can. `-n l/N` splits into N chunks without breaking lines. `-n r/N` round-robins lines across N files. The input `abcdef` with no newline is one line. `split -n 3` produces three pieces of two bytes. `split -n r/3` puts that single line into the first piece and leaves the other two empty, because there is only one record to hand out. People use `r/N` expecting byte striping and then checksum the empty files. The mode is about lines. Name the mode in a comment next to the command.

`--filter` runs a command for each piece, with `$FILE` set to the piece name. It is a way to compress pieces without a second pass you schedule yourself. The filter is a shell command. Quote it. This lesson does not need a filter to show the cuts; the sort lesson uses an external program for a different reason.

`csplit` cuts where a pattern matches. `csplit -f p - '/^FOOT/'` on a file that contains a header and a `FOOT` line writes the pieces and prints their byte counts to stdout. Those counts are the tool's report, not a `wc` you have to add. `-z` suppresses empty pieces, which matters when the pattern matches the start of the file or matches twice with nothing between. Patterns are basic regular expressions. They are not PCRE, and they are not a JSON splitter. A JSON line file splits cleanly with `split -l` only because each record is already one line. The moment a record contains a raw newline, line split is wrong.

## Worked examples

### Two lines per piece, numeric names

```run
# title: split -d -l 2
/usr/bin/printf 'a\nb\nc\nd\n' | /usr/bin/split -d -a 1 -l 2 - p-
/usr/bin/ls -1
/usr/bin/printf 'p-0:\n'
/usr/bin/cat p-0
```

### Byte chunks versus line round-robin

```run
# title: -n 3 is not -n r/3
/usr/bin/printf 'abcdef' | /usr/bin/split -d -a 1 -n 3 - bytes-
/usr/bin/printf 'abcdef' | /usr/bin/split -d -a 1 -n r/3 - lines-
/usr/bin/wc -c bytes-* lines-*
```

### csplit on a marker

```run
# title: Cut before FOOT
/usr/bin/printf 'HEAD\n1\n2\nFOOT\n' > doc
/usr/bin/csplit -q -f part doc '/^FOOT/'
/usr/bin/printf 'part00:\n'
/usr/bin/cat part00
/usr/bin/printf 'part01:\n'
/usr/bin/cat part01
```

### Drop empty pieces

```run
# title: csplit -z
/usr/bin/printf 'a\n\nb\n' > blanks
/usr/bin/csplit -z -q -f z blanks '/^$/' '{*}'
/usr/bin/wc -c z*
```

## Recipes

Shard a line-oriented log for parallel workers with `split -d -l 10000 -a 4 --additional-suffix=.log`. Workers must tolerate a boundary that is not a transaction boundary. If the transaction is multiple lines, `split` does not know. `csplit` can cut on a start marker you control.

`--filter='gzip > $FILE.gz'` compresses each piece. Test the filter on one small file before you point it at a disk you care about. A bad filter with `-` reading stdin can look like a hang.

## Tips and pitfalls

`split` of a file that is smaller than the chunk size still creates the pieces `-n` asked for, some of them empty in the round-robin case. Check sizes with `wc -c` before you launch a worker per file.

`csplit` without `-k` removes the output files if an error occurs mid-way. `-k` keeps them. The quiet flag `-q` suppresses the byte counts. Use it when the counts would pollute a log, and omit it when the counts are the verification.

Brace repetition `'{*}'` must be quoted so the shell does not expand it.

## Exercises

```exercise
expect-exit: 0
---title---
Split four lines into pairs
---prompt---
Split `a b c d` each on its own line into pieces of two lines with numeric suffixes of width 1 and prefix `o`. List the piece names.
---hint---
`split -d -a 1 -l 2`.
---solution---
You get `o0` and `o1`.
---script---
/usr/bin/printf 'a\nb\nc\nd\n' | /usr/bin/split -d -a 1 -l 2 - o
/usr/bin/ls -1 o*
```

```exercise
expect-exit: 0
---title---
See a one-line round-robin
---prompt---
Round-robin the six bytes `abcdef` with no newline into 3 pieces using `-n r/3`, prefix `r`, and show `wc -c`.
---hint---
One record goes to the first piece.
---solution---
The first piece holds the six bytes. The other pieces are empty. That is line round-robin, not byte striping.
---script---
/usr/bin/printf 'abcdef' | /usr/bin/split -d -a 1 -n r/3 - r
/usr/bin/wc -c r*
```

```exercise
expect-exit: 0
---title---
Split on a line that says END
---prompt---
Put `one\nEND\n` in `doc` and csplit it on `/^END/`. Print both pieces.
---hint---
`-f p` and quote the pattern.
---solution---
The first piece is the line before the match. The second begins with END.
---script---
/usr/bin/printf 'one\nEND\n' > doc
/usr/bin/csplit -q -f p doc '/^END/'
/usr/bin/printf '0:\n'
/usr/bin/cat p00
/usr/bin/printf '1:\n'
/usr/bin/cat p01
```

## Performance

`split` reads the input once and writes the pieces. The cost is the bytes, plus a directory update per piece. A million tiny pieces is a metadata storm, the same shape as the rm lesson's many unlinks. Choose a piece size that matches the consumer, not a piece size of one line for a multi-gigabyte log, unless you have a reason to pay for millions of inodes. `--filter` starts a process per piece. That startup dominates when the pieces are tiny and disappears when each piece is large. `csplit` scans for the pattern. It is not a search index. If you only need "bytes 0 to N", `dd` or `head -c` avoids the regex. There is no parallel flag on split in the sense of `--parallel` on sort. Parallelism comes from processing the pieces afterward, and only if the pieces are independent.
