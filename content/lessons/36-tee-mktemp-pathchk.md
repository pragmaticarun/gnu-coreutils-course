---
number: 36
slug: tee-mktemp-pathchk
title: tee, mktemp, pathchk, and mkfifo
module: Space, time, and processes
level: intermediate
minutes: 28
summary: tee splits a stream without rereading it. mktemp makes an unguessable scratch name. pathchk rejects names that will not travel. mkfifo is a pipe with a filesystem entry.
objectives:
  - Write one stream to two files with tee
  - Create a scratch file and a scratch directory with mktemp
  - Reject a newline in a portable name with pathchk -p
  - See timeout report 124 when cat waits on an empty fifo
manual: tee invocation | https://www.gnu.org/software/coreutils/manual/html_node/tee-invocation.html
manual: mktemp invocation | https://www.gnu.org/software/coreutils/manual/html_node/mktemp-invocation.html
manual: pathchk invocation | https://www.gnu.org/software/coreutils/manual/html_node/pathchk-invocation.html
manual: mkfifo invocation | https://www.gnu.org/software/coreutils/manual/html_node/mkfifo-invocation.html
gnu_vs_bsd: |
  POSIX specifies `tee`, `mktemp`, `pathchk`, and `mkfifo`. GNU `mktemp` template rules match the usual `XXXXXX` spelling. BSD `mktemp` exists and the flag letters for dry-run and suffixes differ. GNU `pathchk -p` checks the POSIX portable character set and a 255-byte name limit. `tee -p` (operate on pipes, ignore write errors to a pipe) is a GNU behavior to read in `--help` before you rely on it. This lesson did not run BSD tee.
---

`tee` reads stdin once and writes the same bytes to stdout and to every file you name. That is how you keep a log of a pipeline without running the producer twice. `printf 'ab\n' | tee a.txt b.txt` creates two files of three bytes and also writes those three bytes to stdout. `-a` appends. Without `-a`, tee truncates each file at the start, the same way a shell redirect does. The order of writes to the files and to stdout is not a transaction: a full disk on the second file can leave the first file complete and the pipeline failing. Check the status.

The manual notes that `tee` is one of the programs that resets its own buffering. Putting `stdbuf` in front of `tee` does not give you a free line-buffered split. If you need a line to appear in a log before a later stage finishes, look at the producer, not at a second stdbuf wrapped around tee.

`mktemp` creates a file or, with `-d`, a directory, using a template that ends in at least six `X` characters. It replaces the `X`s with random characters and creates the object with `O_EXCL`, so two racing scripts do not share the name. The course runner already gives every example a private directory. You still want `mktemp` inside a script that a person will run on their own machine, because `/tmp/out` is a shared name and a symlink attack. Print the name mktemp prints. Do not invent a parallel "random" name with `date` alone. The clock is a poor unique id when two jobs start in the same second.

`pathchk` answers a different question: would this name be legal and portable? `-p` checks the POSIX portable filename character set. A newline fails. `pathchk` does not create the file and does not look at whether you have permission. It is the check you run on a name you are about to embed in a release tarball, not a substitute for `mkdir`.

`mkfifo` creates a named pipe. Opening it for reading blocks until a writer opens it, and the reverse. `timeout 1 cat fifo` with no writer exits 124. That is the same timeout status as the process-wrapper lesson, applied to a pipe that nobody is writing. Named pipes are useful in a demo of "this command waits" and a poor place to store data. A fifo has a name and no contents you can `ls` the size of in a useful way. The size stays zero. The bytes exist only while a reader and a writer are both connected.

## Worked examples

### One stream, two files

```run
# title: tee duplicates stdin
/usr/bin/printf 'ab\n' | /usr/bin/tee a.txt b.txt >/dev/null
/usr/bin/wc -c a.txt b.txt
```

### Append

```run
# title: tee -a
/usr/bin/printf 'one\n' > log.txt
/usr/bin/printf 'two\n' | /usr/bin/tee -a log.txt >/dev/null
/usr/bin/cat log.txt
```

### Scratch names

```run
# title: mktemp file and directory
file=$(/usr/bin/mktemp ./item.XXXXXX)
dir=$(/usr/bin/mktemp -d ./dir.XXXXXX)
/usr/bin/printf 'z\n' > "$file"
/usr/bin/printf 'file=%s\n' "$(/usr/bin/basename "$file")"
/usr/bin/printf 'dir_is_dir:'
/usr/bin/test -d "$dir" && /usr/bin/printf 'yes\n'
```

### Portable names and a fifo that nobody writes

```run
# title: pathchk and a waiting fifo
/usr/bin/pathchk -p 'ok_name'
set +e
/usr/bin/pathchk -p "$(/usr/bin/printf 'bad\nname')"
/usr/bin/printf 'path_status:%s\n' $?
set -e
/usr/bin/mkfifo fifo
set +e
/usr/bin/timeout 1 /usr/bin/cat fifo
/usr/bin/printf 'fifo_status:%s\n' $?
set -e
```

## Recipes

Record a long build log and still watch it with `command 2>&1 | tee build.log`. The shell redirect applies to the whole pipeline's display. tee is what copies the bytes into the file. Add `-a` only when you mean to continue yesterday's log.

Create a work directory with `work=$(mktemp -d)` and remove it in an `EXIT` trap. Put intermediates there. A fixed path in `$HOME` collides with the previous run and survives a crash in a way that hides bugs.

Run `pathchk -p` on every filename a code generator emits before you write the file. A C++ header named with a space will build on your laptop and fail in a tool that splits on whitespace. Fail the generator.

## Tips and pitfalls

`mktemp` with a template that does not end in `XXXXXX` fails. Six `X` characters is the minimum. A template in a directory you cannot write also fails. The status is non-zero and no name is printed.

`tee` of a file you are also reading is a classic truncation bug. `tee file < file` empties the file. Write to a new name and `mv` it.

`pathchk` accepting a name does not mean the filesystem will accept it. A too-long UTF-8 name can pass a character-set check and still fail in `open`. `pathchk` without `-p` also checks length against the filesystem. Use both checks when the name is destined for this machine and for a tarball.

A fifo left in a directory looks like a file. `rm` removes the name. Do not `cp` a fifo and expect bytes. There are no stored bytes.

## Exercises

```exercise
expect-exit: 0
---title---
Duplicate a line
---prompt---
Write `hi` plus a newline through tee into `one.txt` and show the file.
---hint---
Redirect tee's stdout to /dev/null if you only want the file.
---solution---
`one.txt` contains `hi` and a newline. tee also wrote that to stdout if you did not redirect it.
---script---
/usr/bin/printf 'hi\n' | /usr/bin/tee one.txt >/dev/null
/usr/bin/cat one.txt
```

```exercise
expect-exit: 0
---title---
Accept a portable name
---prompt---
Run `pathchk -p` on `ok_name` and print `ok` if it accepts the name.
---hint---
Status 0 means the check passed.
---solution---
`ok` is printed. The name uses letters and an underscore.
---script---
/usr/bin/pathchk -p 'ok_name' && /usr/bin/printf 'ok\n'
```

```exercise
expect-exit: 0
---title---
Make a scratch directory
---prompt---
Create a directory with `mktemp -d` using a template in the current directory, and write `note` into `note.txt` inside it.
---hint---
Capture the directory name. It is not a fixed string.
---solution---
The file exists under the generated directory. The directory name ends with the characters mktemp substituted.
---script---
dir=$(/usr/bin/mktemp -d ./work.XXXXXX)
/usr/bin/printf 'note\n' > "$dir/note.txt"
/usr/bin/cat "$dir/note.txt"
```

## Performance

`tee` doubles the writes and does not double the reads. That is the point. A pipeline that runs the producer twice to "save a copy" pays the producer's CPU and the input reads twice. tee pays the output writes twice and the input once. On a large stream the extra write is the cost. If one destination is a slow disk and the other is a terminal, the slow destination back-pressures the whole pipeline, including the terminal. tee does not have a side buffer that hides that.

`mktemp` is one create. Calling it per line of a million-line file is the wrong shape. Create one directory and write the million files inside it with names you control, or, better, do not create a million files. `pathchk` is also a once-per-name check. Run it on the generator's pattern, not on every file of a tree you already wrote, unless you are auditing.

A fifo has no throughput advantage over an anonymous pipe. It exists so two unrelated processes can meet at a path. The timeout example spends about a second waiting, and that second is the deadline, not work. Do not benchmark `cat` on an idle fifo.
