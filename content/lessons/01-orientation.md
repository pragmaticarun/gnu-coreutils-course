---
number: 1
slug: orientation
title: What you are actually running
module: How the toolbox thinks
level: beginner
minutes: 25
summary: GNU coreutils 9.4 on Ubuntu, the info manual, and the shell builtins that pretend to be the same tools.
objectives:
  - Identify the installed coreutils package and the manual that matches it
  - Tell a shell builtin from the coreutils binary on PATH
  - Read an exit status as data, including the commands the manual calls out as special
  - Name the Ubuntu binaries that the GNU manual documents but this package does not own
manual: Introduction | https://www.gnu.org/software/coreutils/manual/html_node/Introduction.html
manual: Exit status | https://www.gnu.org/software/coreutils/manual/html_node/Exit-status.html
gnu_vs_bsd: |
  macOS and the BSDs ship a different userland. `ls --version` is a GNU question and fails on BSD ls. Homebrew and similar systems often install the GNU tools under a `g` prefix (`gls`, `gdate`, `gstat`) so they do not replace the BSD ones. This course ran only the Ubuntu GNU binaries. BSD notes later in the course are documented differences, not captured output.
---

GNU coreutils is one package that absorbed the old textutils, fileutils, and shellutils collections. On this machine it is the set of programs that copy, list, sort, checksum, and format ordinary files. It is not the kernel, not the compiler, and not the shell. A C++, Rust, or Android build uses it constantly anyway: `install` places a binary, `nproc` suggests a job count, `sha256sum` checks an NDK archive, and `timeout` stops a hung test. Those are coreutils jobs. `grep`, `find`, `make`, and `adb` are not.

The introduction in the installed info file says the utilities are mostly compatible with POSIX, and that the info manual is the documentation the project maintains. It also says the man pages are no longer maintained. When a man page and the info node disagree, follow the info node for coreutils 9.4, then confirm the flag still exists in `--help` on the binary you will run. The HTML manual on gnu.org tracks newer releases. A flag you saw on the web and cannot find in `--help` is not a flag you have.

The shell sits in front of every command line. Bash provides its own `echo`, `printf`, `test`, `[`, `true`, `false`, and `pwd`. Those builtins do not have to match `/usr/bin` of the same name. The manual says this explicitly for `echo`: an unadorned `echo` may not be the program the chapter describes, and `env echo` is one way to skip the shell's version. This course uses absolute paths when the difference matters, and it shows `type` so you can see the shadowing on your own prompt.

Exit status is how these short programs talk back. The manual's rule for almost every command is that zero means success and non-zero means failure. It then lists exceptions whose statuses mean something narrower: `chroot`, `env`, `expr`, `ls`, `nice`, `nohup`, `numfmt`, `printenv`, `runcon`, `sort`, `stdbuf`, `test`, `timeout`, and `tty`. `sort -c` uses 1 to mean "not in order" and 2 to mean "I could not run the check". `timeout` uses 124 when it kills the child. `test` uses 1 as the answer "false". Reading a bare non-zero as "the tool is broken" will make you mis-handle all three.

Ubuntu does not install every name the GNU manual has a chapter for. On this image, `hostname` belongs to the hostname package, `kill` and `uptime` belong to procps, and `find` belongs to findutils. Teaching those binaries as if they were this coreutils 9.4 build would be a lie about the system you develop on. The reference marks them as companions. The lessons that need them say so in the example badge.

Performance shows up later as a property of a bottleneck: locale collation, a sort that spills, a pipe that block-buffers, a copy that cannot reflink. Nothing in this orientation lesson is a speed ranking. The useful habit is to ask which resource is scarce before you add a flag.

## Worked examples

### Package and version

```run
# title: The coreutils package you have
dpkg-query -W -f 'coreutils ${Version}\n' coreutils
/usr/bin/ls --version | /usr/bin/head -n 1
```

### Builtin versus binary

```run
# title: echo is usually the shell
type -a echo
echo --help
/usr/bin/echo --version | /usr/bin/head -n 1
```

### Exit status is the value

```run
# title: true and false from the package
set +e
/usr/bin/true
/usr/bin/printf 'true:%s\n' $?
/usr/bin/false
/usr/bin/printf 'false:%s\n' $?
set -e
```

### Names the manual mentions that this package does not own

```run
# title: Who owns hostname, kill, and uptime
dpkg -S /usr/bin/hostname
dpkg -S /usr/bin/kill
dpkg -S /usr/bin/uptime
```

## Recipes

Before a script depends on a GNU flag, print the version and the `type` of the command. In a Rust `build.rs` or a CMake custom command the `PATH` may not be your interactive shell, and a builtin is not involved there at all: the exec'd binary is coreutils. In an interactive bash function, the builtin is involved. Check both places if the script is sometimes pasted into a prompt.

When you file a bug, the introduction asks for the version, the architecture, the input, what you expected, and what you got. `sort --debug` and `date --debug` are the two places the manual tells you to look before you write that report.

## Tips and pitfalls

`echo --help` from the builtin prints the two words `--help`. That is not a documentation viewer failing. It is the builtin treating every operand as text. `/usr/bin/echo --help` is the manual page for the binary.

`ls --version` on macOS is not a quiet no-op. It is an error from BSD ls, which reads `--version` as an illegal option. A script that starts by asserting GNU should check the version line, not merely the exit status of an unrelated command.

Do not parse `ls` to decide what a build tree contains. The next lessons show why. This lesson's only listing is the version line, which is a single predictable stream.

## Exercises

```exercise
expect-exit: 0
---title---
Read the sort version
---prompt---
Print only the first line of `sort --version`, using the binary on `PATH`.
---hint---
`head -n 1` keeps the banner and drops the copyright lines.
---solution---
The first line names GNU coreutils and the version. Later lessons assume that version's flags.
---script---
sort --version | /usr/bin/head -n 1
```

```exercise
expect-exit: 0
---title---
See whether test is a builtin
---prompt---
Show how bash resolves `test` and `[`.
---hint---
`type` is a shell builtin. It is not part of coreutils, and that is the point.
---solution---
Both names are builtins in this bash. The coreutils programs are still at `/usr/bin/test` and `/usr/bin/[`.
---script---
type test
type [
```

```exercise
expect-exit: 0
---title---
Record a failure status without stopping
---prompt---
Run `/usr/bin/ls` on a path that does not exist and print the status. The script as a whole should still exit 0.
---hint---
A failing command under `set -e` would stop the script. Put the `ls` in a conditional or append `||` and then echo the status you saved.
---solution---
GNU ls uses status 2 when it cannot access the path. That is one of the special cases the exit-status node is pointing at: non-zero is not always 1.
---script---
set +e
/usr/bin/ls /no/such/coreutils-orientation-path
status=$?
set -e
/usr/bin/printf 'status:%s\n' "$status"
```

## Performance

Starting a coreutils process is cheap next to reading a multi-gigabyte artifact, and expensive next to a Rust function that already has the bytes in memory. The orientation question is not "which command is fastest". It is "is this work a process, a pipe, or a library call?" Checksums of a firmware blob belong in `sha256sum`. Splitting a string you already hold in a Rust `&str` does not belong in `cut`. The benchmark page measures a few cases where the process is the right tool and the cost is visible. It does not claim a winner for every machine.
