---
number: 9
slug: paths
title: basename, dirname, readlink, realpath, pwd
module: Seeing files
level: intermediate
minutes: 32
summary: These tools rewrite path strings. They do not all require the file to exist, and the shell's pwd is not always /usr/bin/pwd.
objectives:
  - Strip prefixes and suffixes with basename and dirname without reading stdin
  - Choose realpath -e, the default, and -m for missing components
  - Compare readlink -f with realpath
  - Call /usr/bin/pwd when you mean the coreutils program
manual: basename invocation | https://www.gnu.org/software/coreutils/manual/html_node/basename-invocation.html
manual: realpath invocation | https://www.gnu.org/software/coreutils/manual/html_node/realpath-invocation.html
manual: readlink invocation | https://www.gnu.org/software/coreutils/manual/html_node/readlink-invocation.html
gnu_vs_bsd: |
  GNU `basename` accepts multiple names, `-a`, and `-s`. BSD basename is usually one name and a suffix. GNU `readlink -f` canonicalizes and allows a missing final component; older BSD `readlink` only printed a symlink target. macOS has gained flags over time; do not assume the GNU set. `realpath` was missing on older macOS. `/usr/bin/pwd` versus the shell builtin is a bash issue on every system. This lesson ran GNU tools only.
---

Path tools are string and symlink resolvers. `basename /src/libfoo.a .a` prints `libfoo`. `dirname /src/libfoo.a` prints `/src`. Multiple arguments are allowed on GNU basename and dirname. `-z` changes the output separator to NUL. It does not switch the tools into a mode where they read NUL-separated stdin. If you have a NUL list, you still need something that splits it and passes arguments, or you stay in a language that has the bytes. People pipe `find -print0` into `dirname` and get "missing operand", which is what this package does.

`realpath` prints an absolute path. By default every component except the last must exist. `-e` requires the last component too. `-m` allows missing components in the middle, which is how you ask "what would this path be" before you create it. `--relative-to=DIR` prints the result relative to DIR. That is the form you want in a build log that should not embed the absolute sandbox path, when both paths share a root.

`readlink` without flags prints the immediate target of a symlink and fails on an ordinary file. `readlink -f` canonicalizes, following every symlink, and all but the last component must exist. On a missing final component it still prints a path and exits 0. `readlink -e` is the strict form. `readlink -m` allows missing components. If you only want "is this a symlink, and what does it store", do not pass `-f`. `-f` answers a different question: the canonical file name.

`pwd` is a builtin in bash. `/usr/bin/pwd` is coreutils. `-L` is logical and follows the shell's idea of `$PWD`. `-P` is physical and resolves symlinks. In a directory you entered through a symlink, they differ. Build scripts that compare paths should pick one and document it. `realpath -P` is the physical resolution if you already have a path in a variable.

None of these tools create or delete the file, except that your script might do that around them. `mkdir -p "$(dirname -- "$path")"` is the usual pairing, and the `--` matters when the path starts with a dash.

## Worked examples

### Suffix and directory

```run
# title: basename and dirname on a library path
/usr/bin/basename /opt/ndk/libfoo.a .a
/usr/bin/dirname /opt/ndk/libfoo.a
/usr/bin/basename -a /a/b /c/d.txt
```

### Missing paths

```run
# title: realpath -m versus -e
/usr/bin/realpath -m /tmp/does-not-exist-cu/child
set +e
/usr/bin/realpath -e /tmp/does-not-exist-cu
/usr/bin/printf 'strict:%s\n' $?
set -e
```

### readlink -f allows a missing tail

```run
# title: Canonical name of a missing final component
/usr/bin/readlink -f /tmp/missing-final-component
/usr/bin/printf 'exit:%s\n' $?
```

### A relative answer from the coreutils pwd

```run
# title: realpath --relative-to and /usr/bin/pwd
/usr/bin/mkdir -p proj/src
/usr/bin/realpath --relative-to=proj proj/src
/usr/bin/pwd -P
```

## Recipes

In a script that receives a path from a user, run `realpath -e -- "$path"` when the file must already exist, and fail the build if it does not. Use `realpath -m` only when you are about to create the path and you need the absolute form for a log line.

`basename -- "$0"` is a common way to get a program name. The `--` is load-bearing if the name can start with a dash. Pair `mkdir -p -- "$(dirname -- "$dest")"` with `install -D` when you would otherwise recreate the parent logic by hand. `install -D` creates leading components itself; the permissions lesson prefers it for placing a binary.

Build systems should store relative paths in committed files. `--relative-to` the repository root keeps a CI workspace prefix out of the artifact.

## Tips and pitfalls

`dirname` of a name with no slash prints `.`. Feeding that to `mkdir -p` creates a directory in the current working directory, which may be correct and may be a surprise.

Command substitution deletes trailing newlines. A path that legitimately ends in a newline, which is rare and legal, will be damaged by `path=$(realpath -- "$path")`. NUL-delimited APIs avoid that. Coreutils `realpath -z` ends the output with NUL.

The builtin `pwd` can be a shell function's view of the world. If a script's shebang is bash, `pwd` is the builtin even when `/usr/bin` is first on `PATH`. Type the absolute path when you are teaching or testing the coreutils behavior.

## Exercises

```exercise
expect-exit: 0
---title---
Strip a suffix
---prompt---
Print the basename of `/build/libfoo.a` without the `.a`.
---hint---
The suffix is a separate argument.
---solution---
`libfoo` is the result. The path is not read from disk.
---script---
/usr/bin/basename /build/libfoo.a .a
```

```exercise
expect-exit: 0
---title---
Allow a missing leaf
---prompt---
Print the absolute form of `./no-such-leaf` using realpath's default or `-m`, from the current directory. The file does not need to exist.
---hint---
`realpath ./no-such-leaf` is enough on GNU realpath because the final component may be missing. The current directory exists.
---solution---
You get an absolute path ending in `no-such-leaf`. `-e` would have failed.
---script---
/usr/bin/realpath ./no-such-leaf
```

```exercise
expect-exit: 0
---title---
Use the coreutils pwd
---prompt---
Print the physical working directory with `/usr/bin/pwd`.
---hint---
`-P` is physical.
---solution---
The absolute path is the sandbox the runner created. The builtin would usually match here because this directory was not entered through a symlink.
---script---
/usr/bin/pwd -P
```

## Performance

These tools are string and symlink operations. `realpath` may call `lstat` on each component. That is noise next to compiling a crate, and it is the whole cost if you call `realpath` once per file from a shell loop over a million paths. Resolve a root once, then join relative names in-process if you are in Rust or C++. Do not cache a `pwd` from a previous working directory across a `cd`. The slow bug is not realpath's algorithm. It is repeating it at process-per-file granularity, and following a symlink farm that an attacker or a broken install planted. `-e` failing closed is the performance win that matters: you find the bad path before a later tool walks the wrong tree.
