---
number: 41
slug: developer-workflow
title: A small build, install, and checksum
module: How the toolbox thinks
level: advanced
minutes: 30
summary: The daily path for a C++, Rust, or Android tree is install, nproc, sha256sum, and timeout. This lesson runs that path on a one-file C program and a payload manifest.
objectives:
  - Compile a one-file program and place it with install -D -m 755
  - Record a sha256sum manifest and check it
  - Read nproc as a starting job count
  - Bound a command with timeout and keep a non-zero status visible
manual: install invocation | https://www.gnu.org/software/coreutils/manual/html_node/install-invocation.html
manual: sha256sum invocation | https://www.gnu.org/software/coreutils/manual/html_node/sha256sum-invocation.html
manual: nproc invocation | https://www.gnu.org/software/coreutils/manual/html_node/nproc-invocation.html
manual: timeout invocation | https://www.gnu.org/software/coreutils/manual/html_node/timeout-invocation.html
gnu_vs_bsd: |
  POSIX `install` is not the same program as GNU `install`. BSD install uses different flag letters for the mode and for creating parents. GNU `install -D` creates missing parent directories. `sha256sum` is GNU. BSD environments often spell the tool `shasum -a 256` or `sha256`. `nproc` and `timeout` are GNU. A macOS CI job needs the Homebrew equivalents or it needs to call different tools. This lesson ran gcc and GNU coreutils on Ubuntu. It did not run an Android SDK, and it did not claim an NDK zip was present.
---

A developer workstation uses coreutils in the gaps around the compiler. The compiler is not coreutils. `gcc` is not coreutils. `rustc` and `gradle` are not coreutils. The tools that place the binary, count the processors, hash the artifact, and stop a hung test are coreutils, and they are the ones a build script gets wrong when it uses `cp` and hopes.

`install -D -m 755 src/app dest/bin/app` copies the file, creates `dest/bin` if needed, and sets the mode. `-D` is the difference from `cp` followed by a separate `mkdir` and `chmod` that can race. `-m 755` is applied after the install umask handling the manual describes. The permissions lesson covers `install -C`, which preserves the mtime when the content matches, and the non-portable warning on `cp -n`. This lesson uses the plain install that a prefix expects. The mode in the capture is whatever `stat -c '%a'` prints. Read it. Do not assume a blog's `chmod` line ran.

A checksum is the artifact's identity. `sha256sum blob > MANIFEST` writes a line the same tool can check with `-c`. The check prints `OK` and exits 0 when the bytes match. A wrong digest exits non-zero. The checksum lesson shows a deliberately bad line. Here the manifest matches, because a release script that cannot round-trip a good file is not ready for a bad one. Hash the bytes you ship. Hashing a filename list without the contents does not catch a corrupt object file.

`nproc` is the starting point for `-j` in make, ninja, or cargo. `--ignore=1` leaves a processor for everything that is not the build. The number is local. The capture prints it. A linking C++ job can use more RAM than a processor count suggests, and an Android gradle build can saturate disk before it saturates CPUs. Raise the job count until RSS or the disk queue says stop. The performance lesson states that rule without a fake timing table.

`timeout` belongs around tests and around network fetches a build should not wait on forever. `timeout 2` of a program that returns immediately passes the program's status through. `timeout 1 sleep 3` returns 124. A CI script that treats every non-zero as "the compiler failed" will mis-file a hang. Branch on 124.

The shell around these tools still has the quoting rules from the previous lesson. A prefix in a variable is quoted. An empty prefix is refused. `install` will happily write to a relative `dest` you created in the scratch directory. That is the shape to copy. A script that `install`s into `/` because a variable was empty is the shape to reject before the command runs.

Rust and Android fit the same pattern even though this capture does not invoke them. `cargo build --release` writes a binary you then `install` into a prefix. An NDK archive you downloaded is a file you `sha256sum -c` against the digest the vendor published. `timeout` bounds the emulator test. None of those products are coreutils. The four commands around them are.

## Worked examples

### install into a prefix

```run
# title: Compile and install -D
/usr/bin/mkdir -p src
/usr/bin/printf '%s\n' 'int main(void) { return 0; }' > src/main.c
gcc -o src/app src/main.c
/usr/bin/install -D -m 755 src/app dest/bin/app
/usr/bin/stat -c '%a %n' dest/bin/app
dest/bin/app
/usr/bin/printf 'ran:%s\n' $?
```

### A manifest that checks

```run
# title: sha256sum -c
/usr/bin/printf 'payload\n' > blob
/usr/bin/sha256sum blob > MANIFEST
/usr/bin/sha256sum -c MANIFEST
```

### Job count

```run
# title: nproc as a starting point
/usr/bin/nproc
/usr/bin/nproc --ignore=1
```

### A hang is status 124

```run
# title: timeout distinguishes a quick program from a sleeper
/usr/bin/mkdir -p src
/usr/bin/printf '%s\n' 'int main(void) { return 0; }' > src/main.c
gcc -o src/app src/main.c
set +e
/usr/bin/timeout 2 src/app
/usr/bin/printf 'quick:%s\n' $?
/usr/bin/timeout 1 /usr/bin/sleep 3
/usr/bin/printf 'sleeper:%s\n' $?
set -e
```

## Recipes

A prefix script for a small C or C++ tool:

```bash
prefix=${1:-}
if test -z "$prefix" || test "$prefix" = /; then
  printf 'refuse prefix\n' >&2
  exit 1
fi
jobs=$(nproc --ignore=1)
make -j "$jobs"
install -D -m 755 app "$prefix/bin/app"
sha256sum "$prefix/bin/app" > "$prefix/bin/app.sha256"
```

The capture does not run `make`. It runs the same `install` and `sha256sum` on a scratch binary so you can see the bytes. Quote `$prefix`. Refuse `/`.

For a downloaded archive, verify before you unpack. `sha256sum -c` the vendor file. Then `tar` (a companion) extracts. A failed check should stop the script because `set -e` is on. Do not unpack and then check.

Put `timeout` on the test binary, not on the compiler, unless you have a reason to believe the compiler hangs. A killed compiler leaves a partial object that the next incremental build may trust. Delete the partial output in the failure branch when you do wrap the compiler.

## Tips and pitfalls

`install` without `-D` will not create `dest/bin`. The error is "no such file", and the binary you compiled is still in the build tree. The example uses `-D` because a prefix install that requires a manual mkdir is one more step to forget.

`sha256sum -c` reads the manifest's filenames relative to the current directory. Run it from the directory you will ship, or put paths in the manifest that match how you will check. A check from the wrong directory fails even when the bytes are fine.

`nproc` inside a container reports the container's limit when the runtime sets it. It can also report the host count when the runtime does not. Print it in the CI log so the job count you used is visible next to the failure.

`gcc` in the example is the system compiler, used only to produce a binary worth installing. The course is not a C tutorial. The interesting lines are `install`, `sha256sum`, `nproc`, and `timeout`.

## Exercises

```exercise
expect-exit: 0
---title---
Install a binary into bin
---prompt---
Create a tiny C program, compile it to `src/app`, and `install -D -m 755` it to `dest/bin/app`. Print the mode.
---hint---
`-D` creates the parent directory.
---solution---
`stat` prints `755` and the path. The parent `dest/bin` did not need a separate mkdir.
---script---
/usr/bin/mkdir -p src
/usr/bin/printf '%s\n' 'int main(void) { return 0; }' > src/main.c
gcc -o src/app src/main.c
/usr/bin/install -D -m 755 src/app dest/bin/app
/usr/bin/stat -c '%a' dest/bin/app
```

```exercise
expect-exit: 0
---title---
Check a matching manifest
---prompt---
Write `payload` and a newline to `blob`, save `sha256sum` output, and check it.
---hint---
`-c` reads the file you just wrote.
---solution---
The check prints `OK` and exits 0.
---script---
/usr/bin/printf 'payload\n' > blob
/usr/bin/sha256sum blob > MANIFEST
/usr/bin/sha256sum -c MANIFEST
```

```exercise
expect-exit: 124
---title---
Bound a sleep
---prompt---
Run `timeout 1 sleep 3`.
---hint---
124 is the wrapper.
---solution---
The status is 124 because the sleep outlasts the deadline.
---script---
/usr/bin/timeout 1 /usr/bin/sleep 3
```

## Performance

`install` of one binary is a copy plus metadata. It is noise next to a C++ link. `install` of a tree of thousands of headers is a metadata walk, and `-C` avoids rewriting a file whose contents did not change, which keeps dependent mtimes stable. The permissions lesson demonstrates `-C` on a small file. Use it when a stamp file would otherwise change every build and pull the whole incremental graph with it.

`sha256sum` of a large artifact is a streaming read and a CPU-bound hash. The checksum benchmark times `md5sum`, `sha256sum`, and `b2sum` on one 8 MiB input and reports medians. Use that page for a comparison. Do not infer the winner from a single release zip on a laptop with a warm cache. For an Android archive the hash cost is usually smaller than the download. Still hash it. A skipped check is not a performance optimization you can defend after a corrupt file spends an hour unpacking.

`nproc` costs nothing. The jobs it encourages cost RAM. If the build swaps, lower the job count before you change compilers. `timeout` adds a process. Around a multi-minute test it is invisible. Around a microbenchmark it is part of the measurement, so keep it outside the timed section. The benchmark scripts already separate the helper's overhead by comparing variants that share it.
