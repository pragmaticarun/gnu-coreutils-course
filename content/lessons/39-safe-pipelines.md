---
number: 39
slug: safe-pipelines
title: Pipelines that fail closed
module: How the toolbox thinks
level: advanced
minutes: 30
summary: Spaces, newlines, empty variables, and SIGPIPE are how a short script deletes the wrong tree or reports success after a writer died. The fixes are quoting, explicit targets, and pipefail.
objectives:
  - Create and name a file that contains a space without letting the shell split it
  - Show a newline inside a name with ls --quoting-style=shell-escape
  - Delete a relative build directory you just created, and refuse an empty target
  - Read status 141 from yes | head when pipefail is on
manual: Quoting | https://www.gnu.org/software/coreutils/manual/html_node/Quoting.html
manual: rm invocation | https://www.gnu.org/software/coreutils/manual/html_node/rm-invocation.html
manual: ls invocation | https://www.gnu.org/software/coreutils/manual/html_node/ls-invocation.html
manual: Special file names | https://www.gnu.org/software/coreutils/manual/html_node/Special-file-names.html
gnu_vs_bsd: |
  POSIX quoting rules are shared. GNU `ls --quoting-style=shell-escape` is the GNU spelling. BSD `ls` uses different flags to reveal a newline in a name. GNU `rm --preserve-root` is the default, and `--no-preserve-root` exists. This lesson never runs `rm` against `/`. `set -o pipefail` is a bash/ksh feature, not a coreutils flag, and it is how the SIGPIPE from `yes` becomes visible. Status 141 is 128+SIGPIPE on Linux. A macOS shell reports the signal with its own spelling. No destructive BSD command was run.
---

A pipeline is safe when every name is one word, every deletion has a target you computed, and a dead writer is allowed to fail the script. Coreutils will do exactly what the shell asks after the shell has already split the words. Most "rm disasters" are word-splitting and empty variables, not a bug in `rm`.

Quoting comes first. `printf 'hello world\n' > "my file"` creates one file. The same redirect without quotes creates `my` and then tries to write `world` as a command, or worse, passes two operands to a later `rm`. The quoting lesson covers globs. This lesson is the part where you apply it to destruction. Double quotes allow expansions and prevent splitting. Single quotes prevent expansions. A name you got from a variable is always quoted: `"$path"`.

Newlines in names are legal on Linux. `ls` with the default quoting can hide them or render them as a question mark depending on version and options. `--quoting-style=shell-escape` prints a form you can tell is one name. `ls --zero` emits NUL separators so a reader does not have to parse the escape. `find -print0` and `xargs -0` are the findutils pair, not coreutils, and they are the right producer when the walk is recursive. Coreutils tools that support `-z` (`sort -z`, `uniq -z`, `comm` has related options you should read in `--help` before you assume them) keep the NUL boundary. The filename lesson is the longer treatment. The rule to remember here is: if you pipe `ls` to anything, you have already given up, unless you used `--zero` and a reader that understands it.

Deletion comes second. `rm -rf -- "$dir"` is safe only when `$dir` is the directory you created. The double dash stops a name that begins with `-` from becoming a flag. `--preserve-root` is the default, which blocks `rm -rf /` specifically. It does not block `rm -rf /tmp` or `rm -rf "$dir"` when `dir` is empty. An empty expansion of an unquoted variable vanishes. An empty expansion of a quoted variable is an empty argument, and `rm` will complain. Test the string before you call `rm`. Refuse empty. Refuse `/`. Prefer to `cd` into a parent you created and delete a relative name. The example creates `build/obj`, removes `build`, and checks that the name is gone. It does not touch the real root.

`rm -I` asks once when you pass more than three files, and with an empty stdin it removes nothing and exits 0. That status is easy to misread as "I deleted them". The remove lesson captures it. If you need a prompt, also check that the files are gone. Do not use `-I` as your only safety check.

SIGPIPE is the third failure. `yes | head -n 2` prints two lines and then `yes` is killed because `head` closed the pipe. With `set -o pipefail` the pipeline status is 141. Without it, the status is `head`'s status, which is 0, and a script reports success for a writer that died. The printf lesson shows the same pipeline. Turn pipefail on in any script whose middle stage is not allowed to fail quietly. `set -e` does not by itself give you pipefail.

A final habit: run the script once in a scratch directory. The course runner does that for every example. Your laptop should do it too, with `mktemp -d`, before you point a command at a source tree.

## Worked examples

### A space is part of the name

```run
# title: Quoted filename
/usr/bin/printf 'hello world\n' > "my file"
/usr/bin/ls --quoting-style=shell-escape
/usr/bin/wc -c "my file"
```

### A newline inside a name

```run
# title: shell-escape quoting
/usr/bin/mkdir nest
/usr/bin/printf 'x\n' > "$(/usr/bin/printf 'nest/a\nb')"
/usr/bin/ls --quoting-style=shell-escape nest
```

### Delete a tree you just made

```run
# title: Relative rm of a scratch build
/usr/bin/mkdir -p build/obj
/usr/bin/printf 'o\n' > build/obj/a.o
/usr/bin/rm -rf -- build
/usr/bin/test ! -e build && /usr/bin/printf 'gone\n'
```

### pipefail sees SIGPIPE

```run
# title: yes and head
set +e
bash -c 'set -o pipefail; yes | /usr/bin/head -n 2'
/usr/bin/printf 'pipefail:%s\n' $?
set -e
```

## Recipes

Generate a path, then guard it.

```bash
dir=${1:-}
if test -z "$dir" || test "$dir" = / || test "$dir" = .; then
  printf 'refuse %s\n' "$dir" >&2
  exit 1
fi
```

That fragment is the shape. The exercise runs the empty case and prints `refuse` without calling `rm`. Add the `rm` only after the guard, and only on a relative directory you created in the same script.

Log a pipeline with `tee` and keep pipefail so a failing producer is not hidden by tee's success. `set -o pipefail` applies to the shell running the pipeline. A shell that execs another shell needs the option in the inner shell, which is why the example uses `bash -c`.

Walk names with `find -print0` when you must recurse. The companion lesson shows the command. Do not convert the NUL stream back to lines with `tr '\0' '\n'` and then split again. You have reintroduced the bug.

## Tips and pitfalls

`rm -rf -- "$dir/"` with a trailing slash still deletes the directory's contents when the variable is set. The slash is not a safety feature. The guard is the safety feature.

`ls` output is not a file list API. `--quoting-style=shell-escape` is for human eyes and for reproducing a name in a shell snippet. `--zero` is for programs. Mixing them up produces a list that still contains escapes a later tool will treat as literal characters.

`yes` exists to feed a prompt. Bound it. An unbounded `yes` into a command that never closes stdin fills a disk. `head` or `timeout` is the bound. The status under pipefail will be non-zero. Decide whether that non-zero is acceptable and handle it, rather than turning pipefail off for the whole script.

GNU `rm` refuses to operate on `.` and `..` as the final path component in the cases the manual describes. Do not rely on that as permission to build paths by string concatenation without checking the parent.

## Exercises

```exercise
expect-exit: 0
---title---
Write a two-word filename
---prompt---
Create `my file` containing `hello world` and a newline, and print its byte count.
---hint---
Quote the name in the redirect and in wc.
---solution---
The count includes the newline. `ls` without care would show two words. The file is one name.
---script---
/usr/bin/printf 'hello world\n' > "my file"
/usr/bin/wc -c "my file"
```

```exercise
expect-exit: 0
---title---
Refuse an empty target
---prompt---
Set `target` to empty and print `refuse` when it is empty or `/`. Do not call rm.
---hint---
`test -z` and `test "$target" = /`.
---solution---
The script prints `refuse` and never deletes anything.
---script---
target=""
if test -z "$target" || test "$target" = /; then
  /usr/bin/printf 'refuse\n'
else
  /usr/bin/printf 'would-delete\n'
fi
```

```exercise
expect-exit: 0
---title---
Remove a relative directory
---prompt---
Create `scratch/file`, remove `scratch` with `rm -rf --`, and print `gone` if the name is absent.
---hint---
`test ! -e`.
---solution---
`gone` is printed. The double dash is what you keep when the name might start with a dash.
---script---
/usr/bin/mkdir -p scratch
/usr/bin/printf 'x\n' > scratch/file
/usr/bin/rm -rf -- scratch
/usr/bin/test ! -e scratch && /usr/bin/printf 'gone\n'
```

## Performance

Quoting and `pipefail` do not slow a pipeline down in any way that matters next to the work. The unsafe version is the one that gets rerun after it splits names wrong, and a rerun of `sort` on a large file is the expensive part. NUL-safe tools pass the same bytes with a different delimiter. `sort -z` is not a faster sort. It is the sort that does not break the key in half at a newline.

`rm -rf` of a tree of small files is a metadata storm: one unlink per file, plus directory updates. It is slow on a cold cache and it is not made faster by `-f`. `-f` only changes the prompt. If you need to delete millions of files often, the design problem is the millions of files, not the flags. A new directory and an atomic `mv` of the parent, followed by a background delete, keeps the publisher fast. The delete itself still costs the unlinks.

`yes | head` is a terrible benchmark. The 141 status is a signal, and the elapsed time is dominated by process startup. Use the benchmark scripts when you want a median.
