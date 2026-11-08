---
number: 16
slug: cat-and-tac
title: cat and tac
module: Reading and shaping text
level: beginner
minutes: 26
summary: cat streams bytes forward. tac reverses records. Neither one parses the file, and tac's separator stays glued to the record.
objectives:
  - Show cat -A for tabs, line ends, and NULs
  - Squeeze blank lines with cat -s and number lines with cat -n
  - Reverse lines with tac
  - Explain tac -s using a hex dump of the separator
manual: cat invocation | https://www.gnu.org/software/coreutils/manual/html_node/cat-invocation.html
manual: tac invocation | https://www.gnu.org/software/coreutils/manual/html_node/tac-invocation.html
gnu_vs_bsd: |
  BSD `cat -v -e -t` covers much of what GNU `cat -A` combines (`-A` is `-vET`). `tac` is GNU-only. The usual BSD substitute is `tail -r`, which is not the same program and was not run here. GNU cat is unaffected by stdbuf because it does not use FILE streams; that limit is in the stdbuf node and the buffering lesson.
---

`cat` concatenates files to stdout. With no file, or with `-`, it reads stdin. It does not transform the bytes unless you ask. `-n` numbers lines. `-s` squeezes repeated blank lines into one. `-A` is the "show me the hidden bytes" mode: tabs as `^I`, ends of lines as `$`, and other nonprinting bytes in caret notation, including NUL as `^@`. The output of `-A` is not the original file. Do not checksum it and think you checksummed the input.

`tac` prints records in reverse. The default record is a line. It has to see the end of the input before it can print the last record first, so it is not a streaming tool in the way `cat` is. A multi-gigabyte file reversed with `tac` is a memory and temporary-space question. The manual does not give you a sort-style `-S` for it. If you need the last lines of a log, `tail` is the tool that seeks. `tac` is the tool that flips a small stream.

`-s` on `tac` sets the separator. The separator stays attached to the record. For the input `a,b,c` with separator `,`, the records are `a,`, `b,`, and `c`, and the reverse is `c` then `b,` then `a,`, which prints as `cb,a,` with no extra newline. That looks like corruption until you dump it. `od -An -tx1c` shows the commas are still there, attached to the following record in the reversed output. This is the behavior to teach, not a bug to "fix" by adding a newline and hoping.

A missing final newline is still data. `printf 'abc' | cat` writes three bytes and no newline. `wc -l` on that stream reports 0. `cat` did not eat a line. There was no newline to count. The wc lesson is the full version of that trap.

`cat` of a binary file to a terminal can scramble the terminal by writing control sequences. This course dumps binary with `od` or `cat -A` into a pipe, not onto a claimed tty. The capture environment's stdout is a pipe anyway.

## Worked examples

### Show the hidden bytes

```run
# title: cat -A
/usr/bin/printf 'a\tb \n' | /usr/bin/cat -A
```

### NUL is ^@

```run
# title: cat -A on a NUL
/usr/bin/printf 'a\0b\n' | /usr/bin/cat -A
```

### Squeeze blank lines

```run
# title: cat -s
/usr/bin/printf 'a\n\n\nb\n' | /usr/bin/cat -s
```

### tac and a separator that stays attached

```run
# title: Reverse comma-separated records
/usr/bin/printf 'a,b,c' | /usr/bin/tac -s,
/usr/bin/printf '\n---\n'
/usr/bin/printf 'a,b,c' | /usr/bin/tac -s, | /usr/bin/od -An -tx1c
```

## Recipes

Number a snippet for a code review paste with `nl -ba` rather than `cat -n` when you also need the blank lines numbered in the style the nl lesson controls. `cat -n` is the quick version.

Reverse a short list of records you produced yourself, after you have decided the separator. Do not `tac` a log to "see the end". `tail` seeks. `tac` reads.

## Tips and pitfalls

`tac` on a file that does not end with the separator still prints the last partial record. The comma example has no trailing comma and no trailing newline. The dump is the authority.

`cat file1 file2 > file1` truncates `file1` before reading it. The shell opens the redirection first. Do not concatenate a file onto itself that way. Write to a new name and `mv` it on the same filesystem.

`stdbuf -oL cat` does not switch cat to line buffering. The buffering lesson says why. Repeating it here because people put stdbuf in front of cat in log pipelines and then argue about the flag.

## Exercises

```exercise
expect-exit: 0
---title---
Mark the end of a line
---prompt---
Show `hi` followed by a newline using `cat -A`.
---hint---
You want to see the dollar sign that -A adds in the visualization.
---solution---
The output is the visualization `hi$`, not the two characters h and i alone.
---script---
/usr/bin/printf 'hi\n' | /usr/bin/cat -A
```

```exercise
expect-exit: 0
---title---
Reverse three lines
---prompt---
Print `a`, `b`, and `c` on separate lines and reverse them with tac.
---hint---
Default separator is newline.
---solution---
The order is c, b, a, each with its newline.
---script---
/usr/bin/printf 'a\nb\nc\n' | /usr/bin/tac
```

```exercise
expect-exit: 0
---title---
Squeeze three blank lines
---prompt---
Feed cat -s a stream that contains `a`, three blank lines, and `b`.
---hint---
`printf 'a\n\n\n\nb\n'`.
---solution---
Repeated blanks collapse. One blank line remains between a and b.
---script---
/usr/bin/printf 'a\n\n\n\nb\n' | /usr/bin/cat -s
```

## Performance

`cat` is a sequential read and write. For a warm cache and a destination that is another file, `cp` is the tool that can ask the filesystem for a reflink or a sparse layout. `cat` will read and write the bytes. Using `cat` in a pipeline (`cat file | tool`) adds a process and a pipe for no transformation. The tool can open the file. That extra process is small and measurable only when the work itself is small; the benchmark page does not pretend otherwise. `tac` is the one that becomes expensive for large inputs because reversal needs the records available from the end. `tail` is the constant-time-ish choice for "show me the end" on a regular file, subject to the kernel's ability to seek.
