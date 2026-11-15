---
number: 57
slug: helper-tools
title: bc, jq, ripgrep, fd, moreutils, and entr
module: Companion Tools
level: intermediate
minutes: 40
summary: Small tools that show up in real scripts and are still not coreutils. bc does arithmetic, jq reads JSON, rg and fdfind search, moreutils patches shell gaps, and entr reruns a command.
objectives:
  - Name the Ubuntu package and upstream for each helper
  - Evaluate a scale expression in bc and a field in jq without using the network
  - Show ripgrep honoring a gitignore and fdfind finding a file by name
  - Use sponge, ts, ifne, chronic, and entr where a plain redirection is the wrong shape
manual: GNU bc | https://www.gnu.org/software/bc/manual/html_mono/bc.html
manual: jq | https://jqlang.org/manual/
manual: ripgrep | https://github.com/BurntSushi/ripgrep
manual: fd | https://github.com/sharkdp/fd
manual: moreutils | https://joeyh.name/code/moreutils/
manual: entr | https://eradman.com/entrproject/
manual: Coreutils printf | https://www.gnu.org/software/coreutils/manual/html_node/printf-invocation.html
gnu_vs_bsd: |
  BSD ships its own bc and not these Ubuntu package names. ripgrep, fd, jq, moreutils, and entr are ports. macOS Homebrew names the fd binary fd, while Ubuntu's package fd-find installs fdfind. This lesson ran the Ubuntu binaries only.
---

These helpers sit next to shell scripts. None of them are GNU coreutils.

`bc` is GNU bc, Ubuntu package `bc` 1.07.1. It is arbitrary-precision arithmetic. `scale=2; 1/3` prints `.33` with no leading zero. That missing zero breaks a later tool that expects `0.33`. `printf` from coreutils can format a number bc already computed, or you can ask bc to print a leading zero yourself. The shell's `$((1/3))` is integer arithmetic and is the wrong tool when the fraction matters. bc is the right tool, and it is still a program you start, so do not call it once per line of a million-line file. One awk process adds a column faster. bc is for the expression you do not want to get wrong.

`jq` is jq, Ubuntu package `jq`, upstream jqlang. It filters JSON. It is not a streaming editor for random logs. A saved API response is a file. This course's sandboxes have no network and must not grow one, so the example writes the JSON in the script and treats it as a fixture you might have saved from an API. `jq -r '.items[].name'` prints raw strings. Pipe them to `sort` when you need order. jq's own `sort` exists and is a different language. Use it when you are already in jq. Use coreutils `sort` when the next step is a coreutils pipeline.

ripgrep is `/usr/bin/rg`, Ubuntu package `ripgrep`, upstream BurntSushi ripgrep. It is not GNU grep. Inside a git work tree it skips files ignored by `.gitignore`. The example builds a tiny tree with a `.git` directory and a `.gitignore` that hides `skip.log`, then shows that `rg` prints `keep me` and hides `secret` until `--no-ignore`. That default is why people love it in a Rust or Android tree full of build output, and it is why a script that must see the ignored file has to say `--no-ignore` or call `/usr/bin/grep`. A binary named `rg` earlier on `PATH` may be a different build. The examples call `/usr/bin/rg`.

`fd` is the upstream name. Ubuntu's package `fd-find` installs `/usr/bin/fdfind`, which is a symlink to the fd binary. There is no `/usr/bin/fd` on this image. `fdfind -t f` lists files. It is not findutils. It respects ignore rules in a project and it is faster to type. A script that must be POSIX and complete should still call `find -print0`. Use fdfind for interactive search and for project trees where the ignore rules are the point.

moreutils is Ubuntu package `moreutils`, upstream Joey Hess's moreutils. `sponge` reads all of stdin, then writes the file. `sort file | sponge file` is the way to sort a file onto itself. A redirection `sort file > file` truncates the file before sort reads it. `ts` prefixes a timestamp. The clock changes, so the example checks the shape and prints `ts-prefixed` instead of the time. `ifne` runs a command only when stdin is non-empty, which keeps a watcher from firing on an empty grep. `chronic` hides the output of a successful command and shows it when the command fails, which is what you want from a cron job that is quiet until it breaks. moreutils also had a `parallel`. GNU parallel diverted it to `parallel.moreutils`. Do not confuse the two.

`entr` watches files and runs a command. Ubuntu package `entr`, upstream eradman entr. `-n` avoids touching the terminal. `-z` exits after the utility finishes. The example feeds one file name and prints `ran-once`. A long-running watch is a development loop, not a capture. The manual on the project site describes the file list on stdin.

## Worked examples

### bc scale

```run
# title: bc prints scale without a leading zero
# companion: bc
/usr/bin/printf 'scale=2; 1/3\n' | /usr/bin/bc
/usr/bin/printf '2+2\n' | /usr/bin/bc
```

### jq on a saved document

```run
# title: Names from a JSON fixture
# companion: jq
/usr/bin/printf '%s\n' '{"items":[{"name":"libfoo","arch":"arm64"},{"name":"libbar","arch":"amd64"}]}' > api.json
/usr/bin/jq -r '.items[].name' api.json | LC_ALL=C /usr/bin/sort
```

### ripgrep, then fdfind

```run
# title: gitignore and a file find
# companion: rg
/usr/bin/mkdir proj
/usr/bin/printf 'secret\n' > proj/skip.log
/usr/bin/printf 'keep me\n' > proj/main.txt
/usr/bin/printf '*.log\n' > proj/.gitignore
/usr/bin/mkdir proj/.git
/usr/bin/rg -n . proj
/usr/bin/printf 'ignored-too:\n'
/usr/bin/rg -n --no-ignore secret proj
/usr/bin/mkdir tree
/usr/bin/printf x > tree/widget.rs
/usr/bin/fdfind -t f . tree
```

### sponge, ts, ifne, chronic, entr

```run
# title: moreutils and one entr run
# companion: sponge
/usr/bin/printf 'b\na\nb\n' > names.txt
LC_ALL=C /usr/bin/sort -u names.txt | /usr/bin/sponge names.txt
/usr/bin/cat names.txt
/usr/bin/printf 'line\n' | /usr/bin/ts | /usr/bin/grep -q 'line$' && /usr/bin/printf 'ts-prefixed\n'
/usr/bin/printf 'x\n' | /usr/bin/ifne /usr/bin/printf 'had-input\n'
/usr/bin/printf '' | /usr/bin/ifne /usr/bin/printf 'should-not\n'
/usr/bin/printf 'after-ifne\n'
/usr/bin/chronic /usr/bin/printf 'hidden\n'
/usr/bin/printf 'chronic-ok\n'
/usr/bin/printf 'x\n' > watched
/usr/bin/printf 'watched\n' | /usr/bin/entr -nz /usr/bin/printf 'ran-once\n'
```

## Performance

jq loads the document it needs. A multi-gigabyte JSON array is a memory spike. A line-delimited JSON log can be one object per line, and jq `--stream` or one object at a time is the way through it. This lesson's fixture is two objects. Do not conclude that jq is free on an API dump of a whole registry.

ripgrep is fast on source trees because it skips ignored paths and directories you did not mean to read, and because its search is specialized. GNU grep is the tool when you need POSIX or the system grep exactly. The grep benchmark times GNU grep, not rg. Do not quote it as a ripgrep number. If you need that comparison, measure it on your tree and record the versions. This course does not invent the gap.

fdfind's speed advantage over find is irrelevant when you then run a slow `-exec` on every file. The walk was never the cost. `find -print0 | xargs -0` remains the batching lesson.

`sponge` buffers the whole stream in memory or a temp file. Sorting a file onto itself with sponge uses sort's memory plus sponge's copy. For a huge file, `sort -o file file` is coreutils and does not need sponge. sponge is the general case for programs that cannot write `-o`.

`entr` plus a test suite is only as fast as the suite. `-z` in the example exits. A watch loop you forget about is a process. `ps` will show it.

bc once per line of a file is process overhead. The xargs benchmark shows how small processes add up. Do the arithmetic in one process when the file is long.

## Tips and pitfalls

Ubuntu's fd binary is `fdfind`. A script that calls `fd` works on some machines and not on this one.

`rg` respects gitignore only when it believes it is in a git work tree, which is why the example creates `.git`. Without that directory, the ignore file may not apply the way you expect. Test the actual tree.

`chronic` returns the command's status. Under `set -e`, a failing chronic aborts. The example only runs a successful printf.

`ifne` with an empty stdin does not run the command. A newline is not empty. `printf ''` is empty. `printf '\n'` is one line.

`jq` exits non-zero on invalid JSON. That is what you want in a pipeline that must not sort an error message.

moreutils `ts` is not the `ts` from moreutils's cousins on other systems with different format strings. Check `--help` on the host.

## Exercises

```exercise
expect-exit: 0
---title---
Divide with a scale
---prompt---
Print bc's value of `1/3` at scale 2.
---hint---
The program is `scale=2; 1/3`.
---hint2---
GNU bc omits the leading zero. The line is `.33`.
---solution---
`.33`. bc is not coreutils.
---script---
/usr/bin/printf 'scale=2; 1/3\n' | /usr/bin/bc
```

```exercise
expect-exit: 0
---title---
Sort names from JSON
---prompt---
Given a fixture with items `libfoo` and `libbar`, print the names in C locale order.
---hint---
`jq -r '.items[].name'` and `sort`.
---hint2---
No network. The JSON is a file you write in the script.
---solution---
`libbar` then `libfoo`.
---script---
/usr/bin/printf '%s\n' '{"items":[{"name":"libfoo"},{"name":"libbar"}]}' > api.json
/usr/bin/jq -r '.items[].name' api.json | LC_ALL=C /usr/bin/sort
```

```exercise
expect-exit: 0
---title---
Sort a file onto itself
---prompt---
Write `b`, `a`, `b` and replace the file with the unique sorted lines using sponge.
---hint---
`sort -u file | sponge file`. A redirection onto the same file would truncate it first.
---hint2---
Then cat the file. Expect `a` and `b`.
---solution---
Two lines, `a` and `b`. sponge is moreutils, not coreutils.
---script---
/usr/bin/printf 'b\na\nb\n' > names.txt
LC_ALL=C /usr/bin/sort -u names.txt | /usr/bin/sponge names.txt
/usr/bin/cat names.txt
```
