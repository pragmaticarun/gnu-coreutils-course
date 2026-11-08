---
number: 2
slug: shell-quoting-globs-pipes
title: Quoting, globs, pipes, and status
module: How the toolbox thinks
level: beginner
minutes: 30
summary: The shell rewrites the command line before coreutils sees it. Quoting, globs, pipes, and exit status are the four rewrites that matter.
objectives:
  - Predict when the shell splits words, expands globs, and leaves quotes alone
  - Read a pipeline status with and without pipefail
  - Stop option parsing with -- when a file name starts with a dash
  - Notice ARG_MAX as a limit on globs, not as a property of ls
manual: Common options | https://www.gnu.org/software/coreutils/manual/html_node/Common-options.html
manual: Exit status | https://www.gnu.org/software/coreutils/manual/html_node/Exit-status.html
gnu_vs_bsd: |
  Quoting and pipelines are POSIX shell behavior, not a coreutils feature. `$'...'` ANSI-C quoting is bash and is not available in a strict POSIX `sh` such as dash. BSD shells differ the same way. `pipefail` is a bash/ksh option, not a coreutils flag. The coreutils programs themselves then run the same on GNU and, where they exist, on BSD; the shell in front of them does not.
---

Coreutils programs receive an argument vector and, if you connect them, a stream of bytes. They do not see the quotes you typed. Bash parses those quotes, expands globs against the directory, splits unquoted variables on `IFS`, and only then calls `exec`. If a lesson command "does the wrong thing", the first question is whether the shell already changed the request.

Single quotes are literal. Double quotes allow `$` and backslash escapes. Unquoted text splits on spaces and expands `*`, `?`, and `[]`. A file named `a b.txt` is one argument only when it is quoted or when a glob produces it as one match. The glob `box/*.txt` is safe for spaces in the matched names because each match becomes one argument. It is unsafe for a name that starts with `-`, and it never matches a leading dot.

A pipe connects stdout of one process to stdin of the next. The default status of a pipeline is the status of the last process. `set -o pipefail` changes that: the status is the rightmost non-zero status. GNU `false` in the middle of a pipeline is invisible unless pipefail is on. SIGPIPE is the other half of this. A writer whose reader exits early receives SIGPIPE and, under pipefail, the pipeline often ends at 141, which is 128 plus signal 13. `yes | head` is the small version of that story. The later `yes` lesson measures it directly; here you only need the rule.

`--` ends options. `cat -- -n` reads a file whose name is `-n`. Without `--`, many GNU tools treat `-n` as a flag. The common-options node describes this convention. It is not universal in the outside world (`echo` is the famous exception, covered with `printf`), but it is the habit to use in this package.

The shell also has a size limit on the argument vector. `getconf ARG_MAX` is not coreutils. It is still the number that explains why `printf '%s\n' *` dies in a directory of build products while `find` streaming names does not. Coreutils can read NUL-separated names with `--files0-from` on `sort`, `wc`, and several checksum tools. That is the escape hatch when the glob no longer fits.

## Worked examples

### Quotes and splitting

```run
# title: Three arguments or one
/usr/bin/printf '%s\n' 'a b' "a b" a b
```

### A glob keeps the space inside one match

```run
# title: Glob matches are single fields
/usr/bin/mkdir box
/usr/bin/printf 'x\n' > 'box/a b.txt'
/usr/bin/printf '%s\n' box/*.txt
```

### pipefail sees the middle failure

```run
# title: Pipeline status with and without pipefail
set +e
bash -c '/usr/bin/printf a | /usr/bin/false | /usr/bin/true'
/usr/bin/printf 'nopf:%s\n' $?
bash -c 'set -o pipefail; /usr/bin/printf a | /usr/bin/false | /usr/bin/true'
/usr/bin/printf 'pf:%s\n' $?
set -e
```

### A name that looks like an option

```run
# title: End option parsing with --
/usr/bin/printf 'secret\n' > ./-n
/usr/bin/cat -- -n
```

## Recipes

Pass file names from a Rust or C++ driver as separate `exec` arguments, not as one string you hope the shell will split. If you must go through `sh -c`, quote with `printf '%q'` from the coreutils `printf`, which the printf lesson demonstrates.

For a directory you do not control, prefer a NUL-safe producer. `ls --zero` is GNU coreutils. `find -print0` is findutils, and the safe-pipelines lesson shows both, labeled. Do not `ls | while read` a build tree. `read` splits on whitespace and the newline in a hostile name ends the record early.

## Tips and pitfalls

The runner for this course sets `pipefail` around every captured script. A script you paste into an interactive bash does not, until you set the option. When a captured pipeline exits 141 and your terminal exits 0, that is the option, not a different coreutils.

Unquoted `$var` is not a coreutils bug. If `var='a b'`, then `cat $var` asks cat for two files. Quote `"$var"`.

A failed glob in bash, with default settings, stays as the literal pattern if nothing matches. `nullglob` turns it into zero arguments, and `ls` with zero path arguments lists the current directory. That surprise is worse than an error. Leave `nullglob` off unless you have handled the empty case.

## Exercises

```exercise
expect-exit: 0
---title---
Print a star without expanding it
---prompt---
Create no files. Print the two characters `a*` as a single line.
---hint---
Single quotes suppress globbing.
---solution---
The shell never asks the directory about `*`, so printf receives the two characters.
---script---
/usr/bin/printf '%s\n' 'a*'
```

```exercise
expect-exit: 0
---title---
Count matches, not words
---prompt---
Create `my file.txt` in the current directory and print the number of names the glob `*.txt` produces. The number is 1.
---hint---
`printf` one name per line, then `wc -l`.
---solution---
The space stays inside the match, so wc sees one line.
---script---
/usr/bin/printf 'z\n' > 'my file.txt'
/usr/bin/printf '%s\n' *.txt | /usr/bin/wc -l
```

```exercise
expect-exit: 0
---title---
Save a failing status from ls
---prompt---
Run `/usr/bin/ls` on `./missing-name` and print `saw:` plus the status. Do not let `set -e` abort the script before the printf.
---hint---
Toggle `set +e` around the ls, or use an `if`.
---solution---
A missing operand path is status 2 for GNU ls. The script then returns to a strict shell.
---script---
set +e
/usr/bin/ls ./missing-name
status=$?
set -e
/usr/bin/printf 'saw:%s\n' "$status"
```

## Performance

Quoting costs nothing you can measure against file I/O. The performance failure mode is accidental work: a glob of a million object files builds a huge `argv`, the kernel rejects it with `E2BIG`, and the command never starts. Streaming names avoids that allocation. `getconf ARG_MAX` reports the limit on this machine; it is a kernel parameter, not a coreutils constant, and it is not a reason to claim one `ls` flag is faster than another.

```run
# title: The argument-size ceiling on this host
# companion: getconf
getconf ARG_MAX
```
