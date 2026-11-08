---
number: 5
slug: filenames-and-binary
title: Spaces, newlines, NULs, and binary bytes
module: How the toolbox thinks
level: intermediate
minutes: 30
summary: File names are byte strings. Newlines and leading dashes break line-oriented tools. NUL is the delimiter that cannot appear in a name.
objectives:
  - Show a name containing a space and a name containing a newline
  - Use --quoting-style=shell-escape and --zero on GNU ls
  - Explain why line-oriented pipes corrupt binary and hostile names
  - Pass -- when an operand begins with a dash
manual: ls invocation | https://www.gnu.org/software/coreutils/manual/html_node/ls-invocation.html
manual: Common options | https://www.gnu.org/software/coreutils/manual/html_node/Common-options.html
gnu_vs_bsd: |
  `ls --zero` and `--quoting-style` are GNU. BSD `ls` has no `--zero`. The portable NUL-safe producer outside coreutils is `find -print0` (findutils) together with `xargs -0`. BSD `ls -b` shows C-style escapes on some systems and is not the same flag set. This lesson captured GNU ls 9.4 only.
---

A Linux file name is a sequence of bytes, not a Unicode string and not a line. The only bytes that cannot appear are NUL and `/`. Space, newline, quote, leading dash, and invalid UTF-8 are all legal names. Tools that split input on whitespace or newline are assuming a subset of that space. The assumption holds for a tree you created with boring names and fails for a tree you downloaded, unpacked, or let a user name.

GNU `ls` can show the danger instead of hiding it. `--quoting-style=shell-escape` prints a name you could paste back into bash, including `$'...` for a newline. `--zero` ends each name with a NUL and does not escape the bytes inside the name, because NUL cannot occur there. Those two options answer different questions. The first is for a human. The second is for the next program.

`wc --files0-from=-` reads a NUL-delimited list of paths. `sort --files0-from` and the checksum tools have the same idea. The producer and the consumer must agree. `ls --zero | wc -l` is wrong: `wc -l` counts newlines, and the NUL list may contain none. The safe-pipelines lesson connects the pieces. Here the point is the delimiter.

Binary files are the same issue one level down. `cat -A` is a text visualization: tab becomes `^I`, a newline becomes `$`, a NUL becomes `^@`. It is not a reversible dump. `od -An -tx1` is the dump. `sort` will read binary input because the manual says GNU utilities do not restrict the bytes inside a line, but a "line" still ends at newline, and a missing final newline is silently supplied by `sort`. A file that is one huge line becomes one record. That is a memory question, not a character-set question.

Android build trees and Gradle caches do contain spaces (`Application Support` is a macOS problem; `My Documents` style names and NDK paths with spaces show up on Linux too). Rust `OUT_DIR` is usually safe. A test fixture that only uses `file1` never exercises the bug your user will hit.

## Worked examples

### A space is one name

```run
# title: shell-escape quoting
/usr/bin/mkdir box
/usr/bin/touch 'box/a b'
/usr/bin/ls -1 --quoting-style=shell-escape box
```

### A newline in the name

```run
# title: A newline is visible in shell-escape style
/usr/bin/mkdir -p nest
name="$(/usr/bin/printf 'nest/a\nb')"
/usr/bin/touch "$name"
/usr/bin/ls -1 --quoting-style=shell-escape nest
```

### NUL-delimited names

```run
# title: ls --zero keeps the space inside the field
/usr/bin/touch 'a b' c
/usr/bin/ls -1 --zero | /usr/bin/od -An -tx1
```

### NUL is data, not a line ending

```run
# title: cat -A marks a NUL
/usr/bin/printf 'a\0b\n' | /usr/bin/cat -A
```

## Recipes

When a shell loop must visit names, use `find -print0` (companion) and `read -d ''`, or stay inside coreutils with `ls --zero` only if you accept that `ls` is not a recursive inventory tool. `ls` without `-A` hides dotfiles. `ls` without a path argument lists `.`, which is a different set from the files you thought you passed.

For a checksum manifest of arbitrary names, GNU `sha256sum --zero` writes NUL-terminated records. Matching check mode can read them back. The checksum lesson shows the text format first, because that is what download pages publish. Switch to `--zero` when names are allowed to contain newlines.

## Tips and pitfalls

Creating the newline name with an unquoted command substitution is itself a quoting hazard. The example quotes the substitution. Copy the quotes.

`ls` output is not a stable API. Columns, color, and quoting depend on whether stdout is a terminal. In this capture, stdout is a pipe, so you get the non-terminal format. A screenshot of an interactive `ls` will not match.

Binary-safe does not mean "use cat". It means "do not treat the stream as newline-delimited text unless you have decided that is the format".

## Exercises

```exercise
expect-exit: 0
---title---
Quote a two-word name
---prompt---
Create a file called `notes draft.txt` and list it with shell-escape quoting.
---hint---
Quotes around the name passed to touch. `--quoting-style=shell-escape` on ls.
---solution---
The listing shows one name, with quotes, not two directory entries.
---script---
/usr/bin/touch 'notes draft.txt'
/usr/bin/ls -1 --quoting-style=shell-escape
```

```exercise
expect-exit: 0
---title---
Dump a newline byte
---prompt---
Show the hex of a file whose only bytes are `a`, newline, `b`, with no extra newline added by the dump's interpretation. Use od.
---hint---
`printf 'a\nb'` writes exactly those three bytes. `od -An -tx1` prints them.
---solution---
You should see 61, 0a, 62. The 0a is the newline that text tools would treat as a record boundary.
---script---
/usr/bin/printf 'a\nb' > bytes
/usr/bin/od -An -tx1 bytes
```

```exercise
expect-exit: 0
---title---
Count names, not newline-separated lines
---prompt---
Create `a b` and `c`. Feed `ls --zero` into `wc -l --files0-from=-` by way of a file of names, or directly. Print the wc output.
---hint---
`ls -1 --zero | wc -l --files0-from=-` asks wc to open each name. The total line is about the files' contents (empty files have 0 lines) plus a total. Read it as a name list that survived the space, not as a line count of the listing.
---solution---
wc opened both names. A space-splitting loop would have looked for a file named `a` and a file named `b`.
---script---
/usr/bin/touch 'a b' c
/usr/bin/ls -1 --zero | /usr/bin/wc -l --files0-from=-
```

## Performance

NUL-delimited streams are not slower in any way that matters next to `stat` calls. The costly bug is correctness that forces a retry: a script that splits names, misses a file, and reruns a link. `ls` itself is a poor recursive walker because it stats every name to decide how to print, which is a syscall per entry. If you only need names, a dedicated walker (`find`, which is not coreutils) can do less. If you need sizes, you were going to stat anyway, and `du` or `stat` is the honest tool. Do not "optimize" by parsing `ls -l`.
