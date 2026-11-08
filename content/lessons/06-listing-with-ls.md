---
number: 6
slug: listing-with-ls
title: Listing names with ls
module: Seeing files
level: beginner
minutes: 28
summary: ls prints names and, when asked, metadata. The format depends on the destination, the quoting style, and which names you asked to include.
objectives:
  - Choose -1, -A, -F, -l, and -S on purpose
  - Read --quoting-style and --zero as output contracts
  - Tell dir and vdir apart from ls
  - Keep color and columns out of scripts
manual: ls invocation | https://www.gnu.org/software/coreutils/manual/html_node/ls-invocation.html
manual: dir invocation | https://www.gnu.org/software/coreutils/manual/html_node/dir-invocation.html
gnu_vs_bsd: |
  GNU `ls --color` is BSD `ls -G` on macOS. GNU `ls -T` sets tab stops; BSD `ls -T` sets a time format. `--group-directories-first`, `--quoting-style`, and `--zero` are GNU. Human-readable `-h` exists on both, with different details. `dir` and `vdir` are GNU names. Captured output is GNU ls 9.4 writing to a pipe, so it uses the non-terminal format.
---

`ls` answers "what names are here, and optionally what metadata the kernel will tell me about them." It is a presentation program. The info node spends most of its length on which names are included, how they are sorted, and how they are printed. Those are three separate choices, and the defaults change when stdout is a terminal: columns and, depending on the build and aliases, color. In a pipe, this GNU ls writes one name per line if you pass `-1`, and a compact format otherwise. Scripts should pass the format they need and not inherit an alias. `command ls` or `/usr/bin/ls` skips an alias. It does not skip a shell function of the same name; `type ls` tells you.

`-a` includes names that start with `.`, including `.` and `..`. `-A` includes dot names and skips `.` and `..`. That is the useful inventory of a directory you intend to copy. `-F` appends a classifier: `/` for a directory, `@` for a symlink, nothing for a regular file. The classifier is a character on the end of the name. Do not feed `-F` output to another tool as a path.

`-l` is the long format: mode, link count, owner, group, size, time, name. `-h` prints powers-of-1024 sizes with a suffix. The sort lesson's `-h` can order that output; `numfmt` can turn a raw byte column into the same idea with an explicit unit. `-S` sorts by size. None of these are a substitute for `stat -c` when you need one field.

`dir` and `vdir` are the same package. `dir` is an ls with a different default presentation. `vdir` is closer to `ls -l`. Scripts that call `vdir` because it "looks like" a long listing will confuse a reader who has only learned `ls`. Call `ls -l`.

`dircolors` prints shell code that sets `LS_COLORS`. Evaluating it is what makes `--color=auto` look like your theme. The colors are not in the file. They are in the terminal. A log file that captured color codes is full of escapes; pass `--color=never` when the consumer is not a terminal.

## Worked examples

### Classifiers and dot names

```run
# title: -A -F shows the kind of name without hiding dots
/usr/bin/mkdir -p tree/sub
/usr/bin/printf 'x\n' > tree/file
/usr/bin/printf 'y\n' > tree/.hidden
/usr/bin/ln -s file tree/link
/usr/bin/ls -1 -A -F tree
```

### Size order

```run
# title: -S puts the larger file first
/usr/bin/printf 'aa' > smallish
/usr/bin/printf 'b' > tiny
/usr/bin/ls -1 -S
```

### Human size is a display choice

```run
# title: byte size versus -h
/usr/bin/printf 'hello\n' > notes.txt
/usr/bin/ls -l --block-size=1 notes.txt
/usr/bin/ls -l -h notes.txt
```

### dir and vdir are still ls

```run
# title: Version lines from the sibling entry points
/usr/bin/dir --version | /usr/bin/head -n 1
/usr/bin/vdir --version | /usr/bin/head -n 1
/usr/bin/dircolors -b | /usr/bin/head -n 2
```

## Recipes

For a build directory you want to eyeball, `ls -l -h -S --group-directories-first` puts directories first and large artifacts at the top of the file list. That is a human view. For a program, use `stat` or `find` (findutils) with an explicit format.

If you must log a listing in CI, pin `--time-style=long-iso`, `--quoting-style=shell-escape`, `-1`, and `--color=never`. The log is then diffable except for timestamps you expected to change.

## Tips and pitfalls

`ls` without arguments lists the current directory. A script that does `ls $maybe_empty` when the variable is empty becomes "list `.`", which looks like success and shows the wrong tree. Pass `--` and quote, and handle the empty case.

`-R` is recursive presentation, not an archive and not a walk you can resume. It is also easy to mix with `-l` into a blob no parser should read.

Aliases in `~/.bashrc` such as `alias ls='ls --color=auto'` do not apply to `sh -c` scripts or to exec from Rust. They apply to your interactive prompt. Do not debug a script by comparing it with what you see after an alias.

## Exercises

```exercise
expect-exit: 0
---title---
Include the dotfile
---prompt---
Create `.env` and `app` in an empty directory listing. Show both names with `ls`, one per line.
---hint---
`-A` or `-a`. `-a` will also show `.` and `..`.
---solution---
`-A` is the inventory that skips `.` and `..` and still shows `.env`.
---script---
/usr/bin/touch .env app
/usr/bin/ls -1 -A
```

```exercise
expect-exit: 0
---title---
Turn color off
---prompt---
List the current directory by name only, with color forced off, one name per line.
---hint---
`--color=never -1`.
---solution---
A pipe already suppresses the terminal layout, and `--color=never` is the explicit contract if someone later runs the script on a tty.
---script---
/usr/bin/touch a.o
/usr/bin/ls -1 --color=never
```

```exercise
expect-exit: 0
---title---
Do not classify paths you will reuse
---prompt---
Make a directory `sub` and a file `f`. Show `ls -1 -F`, and in the same script print the name `sub` with printf so you can see the classifier is not part of the name.
---hint---
The slash from `-F` is decoration.
---solution---
`sub/` in the listing is not the path. The path is `sub`.
---script---
/usr/bin/mkdir sub
/usr/bin/touch f
/usr/bin/ls -1 -F
/usr/bin/printf 'path:%s\n' sub
```

## Performance

`ls -l` stats every name it prints. On a directory of hundreds of thousands of build outputs that is a lot of `stat` syscalls, and it is still the wrong interface if the next step parses the columns. The cost is metadata, not the printing. `ls` of a single name is fine. Recursive `ls -lR` of a multi-gigabyte tree is an inventory you did not need if `du -s` or a build tool already knows the answer. No flag of `ls` changes the disk bandwidth of reading file contents, because `ls` does not read contents except when it must identify some special cases. Do not use it as a copy or a checksum.
