---
number: 33
slug: printf-echo-yes
title: printf, echo, and yes
module: Space, time, and processes
level: beginner
minutes: 26
summary: printf is the coreutils formatter you can trust. echo is a bash builtin first and a coreutils binary second. yes repeats a line until the pipe closes.
objectives:
  - Format a number and a string with /usr/bin/printf
  - Show that bash echo --help prints the text --help
  - Use /usr/bin/echo --help when you want the manual summary
  - Bound yes with head and explain SIGPIPE 141
manual: printf invocation | https://www.gnu.org/software/coreutils/manual/html_node/printf-invocation.html
manual: echo invocation | https://www.gnu.org/software/coreutils/manual/html_node/echo-invocation.html
manual: yes invocation | https://www.gnu.org/software/coreutils/manual/html_node/yes-invocation.html
gnu_vs_bsd: |
  `printf` exists in both userlands and as a shell builtin. Escape sequences and `%b` differ in edge cases. `echo` flags are famously non-portable: bash, dash, GNU echo, and BSD echo disagree about `-n` and `-e`. Write `/usr/bin/printf` when the bytes matter. `yes` is GNU and BSD. SIGPIPE status 141 is Linux's 128+13. macOS reports the same signal with a different shell spelling. This lesson ran the Ubuntu bash and GNU binaries.
---

`/usr/bin/printf` formats arguments and writes bytes. `printf '%s\n' 'a b'` prints the string and a newline. `printf '%04d\n' 7` prints `0007`. The format is data, not a command. A user-supplied format string is an injection bug in any language, including this one. Keep the format literal.

Bash also has a `printf` builtin. For the format strings in this course the two agree. The lesson still writes the absolute path so the captured command is the coreutils binary and not "whatever the shell provides". `type printf` and `type /usr/bin/printf` make the distinction visible.

`echo` is the tool people reach for and the tool that then surprises them. In this bash, `echo` is a builtin. `echo --help` prints the four characters `--help` and a newline. It does not open the manual. `/usr/bin/echo --help` prints the GNU help text. `/usr/bin/echo -e 'a\tb'` interprets escapes when you pass `-e`. The default is not to interpret them (`-E`). BSD echo often interprets escapes by default. A script that depends on either behavior is already a portability bug. Use printf.

`yes` prints a line forever. `yes | head -n 2` prints `y` twice and then `yes` receives SIGPIPE because `head` closed the pipe. With `set -o pipefail`, that pipeline's status is 141 (128 + SIGPIPE). Without pipefail, the status is the status of `head`, which is 0, and the SIGPIPE is hidden. The quoting lesson introduced pipefail. This is the command that makes it visible. Do not use `yes` to fill a disk. Bound it with `head` or `timeout`.

## Worked examples

### printf

```run
# title: Width and a literal string
/usr/bin/printf '%04d\n' 7
/usr/bin/printf '%s\n' 'a b'
```

### Which echo

```run
# title: Builtin echo versus /usr/bin/echo
type echo
echo --help
/usr/bin/echo --help | /usr/bin/head -n 1
```

### Escape interpretation is opt-in

```run
# title: echo -e
/usr/bin/printf 'default:'
/usr/bin/echo 'a\tb'
/usr/bin/printf 'dash-e:'
/usr/bin/echo -e 'a\tb'
```

### yes and SIGPIPE

```run
# title: yes bounded by head
set +e
bash -c 'set -o pipefail; yes | /usr/bin/head -n 2'
/usr/bin/printf 'pipefail:%s\n' $?
set -e
```

## Recipes

Write generated source headers with `/usr/bin/printf`. A version banner, a `#include` guard, a Rust `const` array of bytes: the format is the contract. `echo` in that job will eventually interpret a backslash in a path.

Answer a prompt that only accepts `y` with `yes | command` only when you also bound the time. A command that stops reading still leaves `yes` writing until it dies of SIGPIPE, which is fine. A command that keeps reading fills a log. Prefer a flag on the command (`rm -f`, `apt-get -y`) over `yes`.

## Tips and pitfalls

`printf '%d' "$n"` without `\n` leaves the cursor mid-line and concatenates with the next prompt. The examples include `\n` unless the point is the missing newline.

`yes` with an argument repeats that argument. `yes n` is how you feed "no" to a prompt. It is still unbounded.

`echo -n` to suppress the newline is the non-portable form. `printf '%s' "$text"` is the portable one.

## Exercises

```exercise
expect-exit: 0
---title---
Zero-pad a number
---prompt---
Print 7 as four digits with printf.
---hint---
`%04d`.
---solution---
`0007`.
---script---
/usr/bin/printf '%04d\n' 7
```

```exercise
expect-exit: 0
---title---
Show the builtin echo
---prompt---
Run `echo --help` and then the first line of `/usr/bin/echo --help`.
---hint---
The builtin prints the operand. The binary prints a usage summary.
---solution---
The first line is `--help`. The GNU help line starts with `Usage:`.
---script---
echo --help
/usr/bin/echo --help | /usr/bin/head -n 1
```

```exercise
expect-exit: 0
---title---
Print two y lines
---prompt---
Run `yes | head -n 2` inside a shell without treating SIGPIPE as a script failure.
---hint---
`set +e` around the pipeline, or expect the pipefail status.
---solution---
Two lines of `y`. The pipeline status is 141 when pipefail is on, and 0 when it is off and head succeeds.
---script---
set +e
yes | /usr/bin/head -n 2
/usr/bin/printf 'status:%s\n' $?
set -e
```

## Performance

`printf` once per record in a shell loop is process overhead if you call `/usr/bin/printf` each time, and builtin overhead if you do not. A million iterations of either is slower than formatting in the program that owns the data. `yes` is a tight write loop. It will saturate a pipe and then block. It is a useful producer in a buffering demo and a poor way to generate a test file: `dd` or `head -c` from `/dev/zero` states the size. `yes | head` measures nothing about disk. The SIGPIPE is the interesting cost: the writer is killed, the reader stops, and a pipeline that forgot pipefail reports success.
