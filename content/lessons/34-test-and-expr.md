---
number: 34
slug: test-and-expr
title: test and expr
module: Space, time, and processes
level: intermediate
minutes: 26
summary: test and [ are the same coreutils program. expr evaluates an expression and uses exit status as a boolean. The shell builtins shadow both.
objectives:
  - Compare /usr/bin/test, the [ binary, and the bash builtin
  - Check a file exists and a string is non-empty
  - Use expr for a small arithmetic comparison and read its status
  - Keep test out of a hot loop
manual: test invocation | https://www.gnu.org/software/coreutils/manual/html_node/test-invocation.html
manual: expr invocation | https://www.gnu.org/software/coreutils/manual/html_node/expr-invocation.html
gnu_vs_bsd: |
  POSIX specifies `test` and `[`. GNU `test` and `[` are the same program. Bash provides builtins of both, so a script that writes `test` may never exec coreutils. GNU `expr` has operators BSD also has, plus GNU-only extensions. `expr` matching uses basic regular expressions. Status conventions differ from C++: `expr` exits 1 when the result is 0 or null, and 2 on error. This lesson used `/usr/bin/test`, `/usr/bin/[`, and `/usr/bin/expr` so the binary is unambiguous.
---

`/usr/bin/test` evaluates an expression and exits 0 for true, 1 for false, and 2 when the expression itself is an error. It prints nothing on success. `/usr/bin/[` is the same program with a required closing `]`. The reference page for `[` uses the slug `bracket` because a directory named `[` breaks the static export. The manual node is still "test invocation".

In bash, `test` and `[` are builtins. `type test` says so. `type /usr/bin/test` names the file. The builtins are faster and they are not the bytes this course is teaching. Write the path in examples. In a script that must behave when `/bin/sh` is not bash, POSIX `test` is the contract, and the coreutils binary is a fine implementation of it.

Useful predicates: `-e` exists, `-f` regular file, `-d` directory, `-s` non-empty file, `-z` empty string, `-n` non-empty string, `=` string equal, `-eq` integer equal. Quote the operands. `test -n $name` is a syntax error when `name` is empty because the operand disappears. `test -n "$name"` is false and well-formed.

`expr` prints a result and uses status as a second channel. `expr 1 + 2` prints `3` and exits 0. `expr 1 = 2` prints `0` and exits 1. `expr 1 = 1` prints `1` and exits 0. A pipeline that checks only the printed text will treat a false comparison as the string `0`, which is easy to misread as success. Check `$?`. Shell arithmetic `$((1+2))` does not fork. Prefer it when you are in bash and the lesson is not "what does coreutils expr do".

The manual lists `expr` among the utilities whose exit status is not the plain 0-or-1 rule, because 2 means an error. `test` is on that list too.

## Worked examples

### The binary and the builtin

```run
# title: type test versus /usr/bin/test
type test
type /usr/bin/test
/usr/bin/test -d /usr && /usr/bin/printf 'usr-is-dir\n'
```

### A missing file

```run
# title: test -e
set +e
/usr/bin/test -e ./no-such-file
/usr/bin/printf 'exists:%s\n' $?
set -e
```

### Bracket form

```run
# title: [ is test
/usr/bin/[ -n 'hello' ] && /usr/bin/printf 'nonempty\n'
```

### expr status

```run
# title: expr equality
set +e
/usr/bin/expr 1 = 1
/usr/bin/printf 'eq:%s\n' $?
/usr/bin/expr 1 = 2
/usr/bin/printf 'ne:%s\n' $?
set -e
```

## Recipes

Guard a destructive command with `test` and an explicit path. `test -d "$build" && rm -rf -- "$build"` still requires `$build` to be a path you computed, not a path a user typed as `/`. The remove lesson's preserve-root default does not apply to `rm -rf -- "$build"` when the variable expands to something you did not intend. Test the prefix as well: a case statement that rejects empty, `/`, and paths without the expected parent.

Use `expr` when a strictly POSIX `sh` must do a match and you cannot assume bash `[[ ]]`. For everything else, the language you are already writing (C++, Rust) has the comparison.

## Tips and pitfalls

`[` without the space before `]` is a different command name. `/usr/bin/[` expects `]` as the last argument. Forgetting it is status 2.

`test` of too many arguments is an error, not a false result. Quote, and do not pass unquoted globs.

`expr` needs spaces around operators. `expr 1+2` is a string, not addition.

## Exercises

```exercise
expect-exit: 0
---title---
Confirm a directory
---prompt---
Use `/usr/bin/test -d /tmp` and print `yes` only if it is true.
---hint---
`&&` runs the next command when the status is 0.
---solution---
`yes` is printed. /tmp exists on this host.
---script---
/usr/bin/test -d /tmp && /usr/bin/printf 'yes\n'
```

```exercise
expect-exit: 0
---title---
Empty string is not -n
---prompt---
Show the status of `/usr/bin/test -n ""`.
---hint---
False is status 1. Use set +e so the script continues.
---solution---
Status 1. The quotes kept the empty operand.
---script---
set +e
/usr/bin/test -n ""
/usr/bin/printf 'status:%s\n' $?
set -e
```

```exercise
expect-exit: 0
---title---
Add with expr
---prompt---
Print `expr 20 + 22`.
---hint---
Spaces around `+`.
---solution---
`42`.
---script---
/usr/bin/expr 20 + 22
```

## Performance

Forking `/usr/bin/test` or `/usr/bin/expr` inside a per-file loop is the slow part. The predicate itself is a stat or a compare. The shell builtin `test` avoids the exec and is the right call when you are writing bash and you have already learned which binary you meant. A million stats is a million stats either way: the syscall remains. Batch the decision in one program when the loop is the product, not the lesson. `expr` on short strings is noise. `expr` with a pathological regular expression is a CPU sink. Do not pass untrusted patterns to it.
