---
number: 3
slug: redirections-and-buffering
title: Redirections, streams, and stdbuf
module: How the toolbox thinks
level: intermediate
minutes: 30
summary: stdout and stderr are separate, FILE buffering is not the kernel pipe buffer, and stdbuf cannot change programs that never use FILE streams.
objectives:
  - Redirect stdout and stderr independently and explain which stream a diagnostic uses
  - Describe full buffering versus line buffering when stdout is a pipe
  - State why stdbuf does not affect cat or dd, and why it rejects line-buffered stdin
  - Point at libstdbuf.so as the mechanism on this ELF build
manual: stdbuf invocation | https://www.gnu.org/software/coreutils/manual/html_node/stdbuf-invocation.html
manual: cat invocation | https://www.gnu.org/software/coreutils/manual/html_node/cat-invocation.html
gnu_vs_bsd: |
  Redirection syntax is the shell. `stdbuf` is GNU coreutils and is absent on stock macOS and most BSDs. The manual says it exists only on ELF platforms that support a constructor attribute, so a portable script must not require it. The `gstdbuf` name from a GNU prefix package is the usual macOS install. Nothing in this lesson was executed on BSD.
---

A coreutils process has the three standard descriptors the C library expects. The shell wires them up before `exec`. `>` redirects file descriptor 1. `2>` redirects file descriptor 2. `>/tmp/out 2>&1` makes both descriptors share the destination, and the order of those redirections matters because `2>&1` copies the current meaning of descriptor 1. None of that logic lives in `cat`. `cat` writes bytes to whatever descriptor 1 already is.

Buffering is a second mechanism, inside the process, on top of the kernel pipe. The C standard library accumulates `printf` output in a user-space buffer. When stdout is a terminal it is typically line buffered. When stdout is a pipe it is typically fully buffered, often 4 KiB or 8 KiB, so a reader sees nothing until the buffer fills or the process exits. That delay is not the kernel holding the bytes. The bytes have not been written yet. Tools that call `write` directly never enter this path.

`stdbuf` exists to change the FILE buffering mode before the command's `main`. On this Ubuntu build the `stdbuf` binary contains the strings `LD_PRELOAD` and `libstdbuf.so`, and the library is installed at `/usr/libexec/coreutils/libstdbuf.so`. The preload constructor runs first and calls `setvbuf`. The manual then lists two reasons the setting may not stick. `dd` and `cat` do not use FILE streams for their I/O. `tee` sets up its own buffering and overwrites the stdbuf choice. Line buffering on stdin is rejected because it is meaningless; this 9.4 build exits 125 and says so.

A latency difference is real for programs that do use `printf` and then wait. The benchmark page times a four-line C harness, not `cat`. If that sample's medians separate, the note says they separated on that harness. It does not say `stdbuf -oL` makes coreutils filters faster. Throughput and time-to-first-byte are different questions. Full buffering can be the faster way to push a large file through a pipe, and the wrong way to watch a progress line.

## Worked examples

### Split the two output streams

```run
# title: stdout and stderr land in different files
set +e
/usr/bin/ls . missing-stream > out.txt 2> err.txt
status=$?
set -e
/usr/bin/printf 'status:%s\n' "$status"
/usr/bin/printf 'stdout-file:\n'
/usr/bin/cat out.txt
/usr/bin/printf 'stderr-file:\n'
/usr/bin/cat err.txt
```

### stdbuf refuses line-buffered input

```run
# title: -iL is rejected
# expect-exit: 125
/usr/bin/stdbuf -iL /usr/bin/true
```

### The helper library is on disk

```run
# title: libstdbuf.so shipped with this package
/usr/bin/ls -l /usr/libexec/coreutils/libstdbuf.so
```

### cat still runs under stdbuf, and that proves nothing about buffering

```run
# title: stdbuf does not stop cat, and does not document a new cat mode
/usr/bin/printf 'ab\n' | /usr/bin/stdbuf -o0 /usr/bin/cat | /usr/bin/od -An -tx1
```

## Recipes

When a long pipeline looks stuck, check whether the producer is fully buffering. A progress line from a C or C++ tool that uses `printf` and no `fflush` will sit in the FILE buffer until it fills. `stdbuf -oL` is the non-invasive experiment, and only if the program uses FILE streams and does not reset them. If the program is Rust and it wraps stdout in a `BufWriter`, stdbuf does nothing: Rust is not the C library.

For logs you want to keep, redirect in the shell rather than asking every tool for an output flag. `tool >run.log 2>run.err` keeps diagnostics out of the byte stream you will checksum.

## Tips and pitfalls

`stdbuf -oL` on `cat` is a no-op in the sense the manual describes. The pipeline still copies bytes. You cannot conclude from a successful exit that buffering changed.

Status 125 means stdbuf itself failed. Status 126 means the command was found but could not be executed. Status 127 means it was not found. Those numbers are in the stdbuf node. Do not treat them as the command's own status.

`LD_PRELOAD` is ignored for setuid binaries. stdbuf will not change a privileged program, which is what you want.

## Exercises

```exercise
expect-exit: 0
---title---
Keep stdout clean
---prompt---
Run `ls` on a missing file and on `.`, sending stdout to `ok.txt` and stderr to `bad.txt`. Then print both files with labels.
---hint---
`>ok.txt 2>bad.txt` applies to that one command.
---solution---
The directory listing is on stdout. The missing-name diagnostic is on stderr. Mixing them is what makes a later parser trip.
---script---
set +e
/usr/bin/ls . missing-ex > ok.txt 2> bad.txt
set -e
/usr/bin/printf 'OK\n'
/usr/bin/cat ok.txt
/usr/bin/printf 'BAD\n'
/usr/bin/cat bad.txt
```

```exercise
expect-exit: 125
---title---
Confirm the stdin restriction
---prompt---
Ask stdbuf for line-buffered standard input around `/usr/bin/true`. Let the non-zero status stand.
---hint---
The flag is `-iL`.
---solution---
The message says line buffering stdin is meaningless. The status is 125 because stdbuf failed before true ran.
---script---
/usr/bin/stdbuf -iL /usr/bin/true
```

```exercise
expect-exit: 0
---title---
Show a NUL on the byte stream
---prompt---
Write the two bytes `a` and NUL to stdout with printf, and dump them with `od -An -tx1`.
---hint---
`printf '\0'` in the coreutils printf emits a NUL. Quote the format.
---solution---
Redirects and pipes move bytes, including NUL. Text tools that split on newline are the things that stop, not the pipe.
---script---
/usr/bin/printf 'a\0' | /usr/bin/od -An -tx1
```

## Performance

The kernel pipe has a capacity. The FILE buffer is in the writer. Filling an 8 KiB stdio buffer and then one `write` system call is fewer transitions than one `write` per line. That is why fully buffered output can use less CPU for a bulk copy, and why it feels late when you are watching a build log. `stdbuf -o0` forces a write per FILE operation and can raise system time on a chatty producer. Measure that with the buffering benchmark, which reports time-to-first-byte for a harness that sleeps between `printf` calls. Do not copy its medians onto `cp` or `dd`. The manual already told you those two ignore stdbuf.
