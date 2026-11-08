---
number: 20
slug: wrap-and-number
title: fmt, fold, expand, nl, and pr
module: Reading and shaping text
level: intermediate
minutes: 28
summary: These tools reflow, wrap, expand tabs, number lines, and paginate. They are byte and column tools, and fold can split a UTF-8 character.
objectives:
  - Reflow a paragraph with fmt and keep a prefix with -p
  - Show fold splitting the bytes of é
  - Expand and unexpand tabs at a chosen stop
  - Number every line with nl -ba and columnate with pr -t
manual: fmt invocation | https://www.gnu.org/software/coreutils/manual/html_node/fmt-invocation.html
manual: fold invocation | https://www.gnu.org/software/coreutils/manual/html_node/fold-invocation.html
manual: expand invocation | https://www.gnu.org/software/coreutils/manual/html_node/expand-invocation.html
manual: nl invocation | https://www.gnu.org/software/coreutils/manual/html_node/nl-invocation.html
gnu_vs_bsd: |
  `fmt` and `fold` exist on BSD with different extra flags. GNU `fmt -p` is the prefix-preserving mode used below. `expand` and `unexpand` are POSIX-ish and the tabstop flags vary. `nl` and `pr` are in both worlds and their option letters are a portability hazard. `pr -t` to drop headers is what you want for a pipe; the default header includes a date and will not match across runs. Captured behavior is GNU 9.4.
---

`fmt` joins and breaks lines so a paragraph fits a width. It is for prose. It will join short lines that look like one paragraph, which is the wrong thing to do to a table, a poem, or a source file. `-w` sets the width. `-p` keeps a leader such as `>` on mail quotes and reflows the text after it. The leader is not a comment syntax for every language. `fmt` does not know Markdown.

`fold` breaks lines that are already too long. `-w` is the width. `-s` prefers to break at spaces. `-b` counts bytes. On this UTF-8 locale, `fold -w 1` of the character `é` (bytes C3 A9) split the character across lines. The dump is in the example. Do not assume a "column" option keeps a multibyte character together. If you need a character-aware wrap, this is the wrong tool, and the observation belongs in the lesson so you do not discover it in a log file of names.

`expand` turns tabs into spaces. `-t 4` sets the stop. `-i` only converts leading tabs. `unexpand` does the reverse and will change a run of spaces into a tab only when it lands on a stop. Round-tripping is not identity unless the stops and the `-a` flag agree. A Makefile has meaningful tabs. Do not `expand` a Makefile and check it in.

`nl` numbers lines. The default body style skips blank lines. `-ba` is `-b a`, "number all lines", and it numbers the blanks too. `-w` sets the width of the number and `-s` the separator. It is a formatter for a listing you will read. It is not an index you should parse to edit the file.

`pr` paginates. The default page header includes the date and the filename, which makes output unstable. `-t` omits the header and trailer so the bytes can go to another filter. `-2` makes two columns. `-s,` sets the separator between columns. `pr` is not `paste` and not `join`. It fills columns down the page from one stream.

## Worked examples

### Reflow and a quoted prefix

```run
# title: fmt -w and fmt -p
/usr/bin/printf 'one two three four\n' | /usr/bin/fmt -w 10
/usr/bin/printf '> a b c d e\n' | /usr/bin/fmt -p '>' -w 8
```

### fold splits é

```run
# title: fold -w 1 on U+00E9
/usr/bin/printf 'éé\n' | /usr/bin/fold -w 1 | /usr/bin/od -An -tx1
```

### Tabs

```run
# title: expand and unexpand
/usr/bin/printf 'a\tb\n' | /usr/bin/expand -t 4 | /usr/bin/cat -A
/usr/bin/printf 'a   b\n' | /usr/bin/unexpand -t 4 | /usr/bin/cat -A
```

### Number every line and make two columns

```run
# title: nl -ba and pr -t
/usr/bin/printf 'a\n\nb\n' | /usr/bin/nl -ba -w2 -s' '
/usr/bin/printf 'a\nb\nc\nd\n' | /usr/bin/pr -t -2 -s,
```

## Recipes

Prepare a commit message paragraph with `fmt -w 72` if your project asks for that width. Do not run it on the diff.

Show a tab that a test failed to preserve with `cat -A` after `expand`, so the failure is visible in a log that does not show a tab as whitespace.

Number a log excerpt you are pasting into a bug report with `nl -ba` so the other person can say "line 40".

## Tips and pitfalls

`pr` without `-t` puts the run date in the header. Two captures will differ. The example uses `-t`.

`fmt` treats a blank line as a paragraph break. A file of single-line records with no blanks may become one paragraph. Check.

`unexpand` can look like it did nothing when the spaces do not fill a tab stop. Dump with `cat -A` before you conclude the input had a tab.

## Exercises

```exercise
expect-exit: 0
---title---
Wrap at width 10
---prompt---
Reformat `alpha beta gamma` to width 10 with fmt.
---hint---
`-w 10`.
---solution---
The words break across lines. The exact breaks are fmt's, captured in the output.
---script---
/usr/bin/printf 'alpha beta gamma\n' | /usr/bin/fmt -w 10
```

```exercise
expect-exit: 0
---title---
Expand a leading tab
---prompt---
Turn a leading tab before `a` into spaces at tab stop 4 and show the result with cat -A.
---hint---
`expand -t 4`.
---solution---
cat -A shows spaces and a dollar at the end of the line. The tab is gone.
---script---
/usr/bin/printf '\ta\n' | /usr/bin/expand -t 4 | /usr/bin/cat -A
```

```exercise
expect-exit: 0
---title---
Number blanks too
---prompt---
Number `a`, a blank line, and `b` with nl so the blank line gets a number.
---hint---
`-ba`.
---solution---
Three numbers. The default nl style would have skipped the blank.
---script---
/usr/bin/printf 'a\n\nb\n' | /usr/bin/nl -ba
```

## Performance

These tools are linear in the input and cheap next to a compiler. The performance issue is using them on data they will damage: `fmt` on a minified JSON line builds a "paragraph" and spends CPU to produce a file the parser rejects. `fold` on a multi-gigabyte minified line holds a long line. GNU tools do not impose a tiny line-length limit, so the memory cost is the line, not a fixed buffer you can ignore. `pr` with many columns buffers a page. For a huge file, cut the piece you need with `head` first. None of these is a parallel formatter. If you need a fast code formatter, it is not in coreutils.
