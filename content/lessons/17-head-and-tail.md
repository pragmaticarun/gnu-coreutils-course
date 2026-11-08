---
number: 17
slug: head-and-tail
title: head and tail
module: Reading and shaping text
level: beginner
minutes: 28
summary: head prints a prefix, including GNU negative counts. tail prints a suffix or follows a file. Follow mode needs a bound.
objectives:
  - Take the first lines or bytes, and all but the last lines, with GNU head
  - Start at line K with tail -n +K
  - Use NUL as a record separator with head -z
  - Bound tail -f with timeout so a capture cannot hang
manual: head invocation | https://www.gnu.org/software/coreutils/manual/html_node/head-invocation.html
manual: tail invocation | https://www.gnu.org/software/coreutils/manual/html_node/tail-invocation.html
gnu_vs_bsd: |
  GNU `head -n -1` means "all but the last line". BSD head rejects a negative count. `tail -n +K` is the widely available "start at line K" form. GNU `tail -F` follows by name and retries when the file is replaced; BSD tails vary. `timeout` around `tail -f` is GNU coreutils. Negative head counts in this lesson are a GNU capture, not a portable script.
---

`head` and `tail` cut a sequence of records. The default record is a line. `-n` selects lines and `-c` selects bytes. `head -n 2` keeps the first two lines. `head -n -1` keeps everything except the last line. That negative form is the GNU extension that deletes a trailer without a second pass you write yourself. `head -c -2` keeps all but the last two bytes. BSD head will not run these negative counts. If the script must be portable, do the trim another way and do not copy the GNU flag blindly.

`tail -n 1` is the last line. `tail -n +2` starts at line 2 and continues to the end, which is the usual "drop the header" operation. `tail -c 3` is the last three bytes. These are streaming from the point they start, except that finding the last N lines of a pipe requires buffering those lines because a pipe cannot be seeked. On a regular file, `tail` can seek near the end. That is why `tail` of a huge log is cheap and `tac` of the same log is not.

`-f` follows a file descriptor as it grows. `-F` follows by name: if the file is rotated and a new file appears under the same name, `-F` retries and switches. A capture that uses `-f` must stop. `timeout 1 tail -n +1 -f log` runs until the timer sends SIGTERM and then exits 124. The lines that were already in the file are printed first. Nothing in this course follows a log forever.

`-z` makes the record separator NUL. `head -z -n 1` keeps the first NUL-terminated record, including the NUL. That pairs with `sort -z` and `ls --zero` when names are the records. Mixing `-z` tools with newline tools splits the wrong places.

`head` closes the pipe early when it has enough input. The writer receives SIGPIPE. Under `pipefail`, a pipeline such as `yes | head` can exit 141. Without `pipefail`, you see head's status 0. The shell lesson introduced the rule. `yes` is where the 141 is captured on purpose.

## Worked examples

### All but the last line

```run
# title: GNU head -n -1
/usr/bin/printf 'a\nb\nc\n' | /usr/bin/head -n -1
```

### Drop a header with tail

```run
# title: tail -n +2
/usr/bin/printf 'header\na\nb\n' | /usr/bin/tail -n +2
```

### NUL records

```run
# title: head -z keeps one record and its NUL
/usr/bin/printf 'a\0b\0' | /usr/bin/head -z -n 1 | /usr/bin/od -An -tx1
```

### Follow, but only for a second

```run
# title: timeout bounds tail -f
# expect-exit: 124
/usr/bin/printf 'boot\n' > log
/usr/bin/timeout 1 /usr/bin/tail -n +1 -f log
```

## Recipes

Drop a CSV header with `tail -n +2` only when you have already accepted that the file is not quoted-CSV-safe. The cut lesson shows why a comma inside quotes breaks field tools. Dropping the first line is still valid for a log whose first line is a banner.

Watch a build log interactively with `tail -F` so a rotation does not freeze the view. In CI, copy the finished log. Do not leave `tail -f` as the last step of a job without `timeout`.

## Tips and pitfalls

`head -n -0` is not "give me nothing" in the way a casual reading suggests. Read the help text before you invent a negative zero. Prefer an explicit positive count when you can.

`tail -f` on a file that is not growing still holds the process. The timeout is not optional in a sandbox.

Combining `tail -f` and a pipe to `grep` (grep is not coreutils) reintroduces block buffering in grep. The lines exist and you do not see them. That is the buffering lesson, not a tail bug.

## Exercises

```exercise
expect-exit: 0
---title---
Keep the first two lines
---prompt---
From `a`, `b`, `c` each on their own line, print the first two.
---hint---
`head -n 2`.
---solution---
c is dropped. The newline after b remains.
---script---
/usr/bin/printf 'a\nb\nc\n' | /usr/bin/head -n 2
```

```exercise
expect-exit: 0
---title---
Last three bytes
---prompt---
Print the last three bytes of `abcdef`.
---hint---
`tail -c 3`.
---solution---
The bytes are d, e, f. This is a byte count, not a character count.
---script---
/usr/bin/printf 'abcdef' | /usr/bin/tail -c 3
/usr/bin/printf '\n'
```

```exercise
expect-exit: 124
---title---
Stop a follower
---prompt---
Write `hi` into `log` and run `timeout 1 tail -n 1 -f log`.
---hint---
The expected status is 124.
---solution---
You see `hi` and the status is timeout's 124, not tail's own success. The follower was stopped.
---script---
/usr/bin/printf 'hi\n' > log
/usr/bin/timeout 1 /usr/bin/tail -n 1 -f log
```

## Performance

`head` stops reading when it has enough. On a pipe, that saves the producer from generating the rest only if the producer honors SIGPIPE or a short write. A producer that ignores SIGPIPE and keeps computing wastes the work `head` tried to avoid. On a regular file, `tail -n 10` of a large log is a seek plus a small read. `cat | tail` throws the seek away and reads the whole file. Do not insert `cat`. Following a file is idle most of the time; the cost is the open file and the poll, which is fine for a person and wasteful as a permanent CI step. There is no timing number in this lesson because "how fast is head" on three lines is process startup, and the interesting case is the seek `tail` can do. Measure that on a file large enough to matter, on the filesystem you care about, with the benchmark method: repeated trials, warm or cold stated out loud.
