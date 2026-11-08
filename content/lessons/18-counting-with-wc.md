---
number: 18
slug: counting-with-wc
title: Counting with wc
module: Reading and shaping text
level: beginner
minutes: 26
summary: wc counts newlines, words, characters, bytes, and the longest line. A missing final newline makes -l and your eyes disagree.
objectives:
  - Separate wc -l, -w, -m, -c, and -L
  - Predict -l on a file that does not end in a newline
  - Count characters and bytes in a two-byte UTF-8 character
  - Pass names with --files0-from
manual: wc invocation | https://www.gnu.org/software/coreutils/manual/html_node/wc-invocation.html
gnu_vs_bsd: |
  POSIX `wc` counts lines, words, and bytes. GNU adds `--files0-from`, `--total`, and a few output controls. `-m` is characters and depends on the locale. BSD wc exists and its extra flags differ. The missing-newline behavior of `-l` is POSIX: a line is a sequence ending in a newline. This capture is GNU wc 9.4 under en_US.UTF-8 unless a command overrides it.
---

`wc` counts. It does not define a "line" as "what a text editor shows". `-l` counts newline bytes. A file that contains `hello` with no newline has a last line in an editor and a line count of 0 from `wc -l`. A file that contains `hello\n` has a line count of 1. This is the most common off-by-one in shell scripts that check "did the program print a line". Print the bytes with `od` when the count surprises you.

`-c` counts bytes. `-m` counts characters under the current locale. For the two bytes of UTF-8 `é` (U+00E9), `-m` reports 1 and `-c` reports 2 when the locale is UTF-8. The help text says the order of selected counts is newline, word, character, byte, maximum line length. So `wc -m -c` prints the character count and then the byte count. Under `LC_ALL=C`, the character classification collapses toward bytes and `-m` will not save you as a Unicode counter. Set the locale on purpose.

`-w` counts words: non-empty sequences of characters delimited by whitespace, with the locale deciding what is whitespace and what is printable. `-L` is the maximum display width of a line, not the byte length. A tab's display width is greater than one. Do not use `-L` as a buffer-size calculator.

With more than one file, `wc` prints a total unless you change `--total`. `--total=never` suppresses it. `--total=only` prints only the total. `--files0-from=F` reads NUL-separated names from F, or from stdin if F is `-`. That is how you count lines in files whose names contain spaces without the shell splitting them. Empty files contribute zeros and still appear as names.

`wc` reads the whole input. There is no "stop at the first match" flag. If you needed the first match, you wanted `grep` (not coreutils) or `head`.

## Worked examples

### The missing newline

```run
# title: wc -l counts newlines
/usr/bin/printf 'hello' | /usr/bin/wc -l
/usr/bin/printf 'hello\n' | /usr/bin/wc -l
```

### Bytes and characters

```run
# title: é is one character and two bytes
/usr/bin/printf 'é' | /usr/bin/wc -m -c
```

### Words and the longest line

```run
# title: -w and -L
/usr/bin/printf 'a  b\nc\n' | /usr/bin/wc -w
/usr/bin/printf 'a\nabc\n' | /usr/bin/wc -L
```

### NUL-separated names

```run
# title: --files0-from accepts a space in a name
/usr/bin/printf 'a\n' > 'a b'
/usr/bin/printf 'bb\n' > c
/usr/bin/printf 'a b\0c\0' | /usr/bin/wc -l --files0-from=-
```

## Recipes

Assert a generator produced a trailing newline by checking `wc -l` only after you have decided the format includes one. For "is the file empty", `test -s` is the predicate. `wc -c` is the measurement when you need the number.

Count lines in a selection of files with weird names by writing a NUL list. `ls --zero` is not a full recursive inventory. `find -print0` is the companion that walks. Either way, the consumer is `--files0-from=-`.

## Tips and pitfalls

`wc` with no flags prints lines, words, and bytes. Scripts that parse the default three columns break when someone adds `-l` and the columns shift. Pass the flag.

The total line says `total`. If you add `--total=only`, you lose the per-file lines. Pick the one the next parser expects.

`wc -l` on a directory fails. It is not `du`.

## Exercises

```exercise
expect-exit: 0
---title---
Count newlines only
---prompt---
Count the newlines in a file that contains `one\ntwo\n`.
---hint---
`wc -l`.
---solution---
The count is 2.
---script---
/usr/bin/printf 'one\ntwo\n' > t
/usr/bin/wc -l t
```

```exercise
expect-exit: 0
---title---
Show an empty file
---prompt---
Create an empty file and print `wc -l -c` for it.
---hint---
`: > empty` or `truncate -s 0`.
---solution---
Both counts are 0. An empty file is not a missing file.
---script---
: > empty
/usr/bin/wc -l -c empty
```

```exercise
expect-exit: 0
---title---
Count bytes of a digest-sized string
---prompt---
Print the byte count of `abc` with no newline, as a bare number. Use a redirect or a pipe so the filename does not appear... `wc -c` on stdin still may pad. Print the number in a stable way by taking the first field.
---hint---
`printf 'abc' | wc -c` prints a padded number and no name when reading stdin.
---solution---
The count is 3. There is no filename column when wc reads stdin.
---script---
/usr/bin/printf 'abc' | /usr/bin/wc -c
```

## Performance

`wc -c` can use the file size from metadata for a regular file in some cases, but you should not depend on a shortcut for a benchmark story. `wc -m` has to look at the encoding. `wc -l` has to look at every byte for newline. The wc benchmark runs `-c`, `-l`, and `-m` on a warm ASCII file of 200000 lines and reports whether the medians separate. On ASCII, `-m` and `-c` count the same quantity and `-m` may still do more work. If the run cannot separate them, that is the result. A file of multi-byte characters is a different experiment; do not reuse the ASCII medians for it.
