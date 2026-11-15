---
number: 46
slug: diffutils-and-patch
title: diffutils and patch
module: Companion Tools
level: intermediate
minutes: 35
summary: diff, cmp, sdiff, and diff3 are GNU diffutils. patch is GNU patch. None of them are coreutils. Exit status 1 means the inputs differ.
objectives:
  - Attribute diff, cmp, sdiff, and diff3 to diffutils and patch to GNU patch
  - Read a unified hunk without treating the timestamp header as content
  - Use cmp for a byte offset and diff3 for a three-way conflict
  - Apply a patch and check the result with cmp
manual: GNU diffutils | https://www.gnu.org/software/diffutils/manual/html_node/index.html
manual: GNU patch | https://www.gnu.org/software/patch/manual/html_node/index.html
manual: Coreutils cmp is not this cmp | https://www.gnu.org/software/coreutils/manual/html_node/Introduction.html
gnu_vs_bsd: |
  BSD diff and patch differ in default unified context, in -u labels, and in backup suffixes. macOS diff is not GNU diffutils 3.10. This lesson ran the Ubuntu binaries only. Exit status 1 for a difference is shared with POSIX and is still easy to mishandle under set -e.
---

`diff`, `cmp`, `sdiff`, and `diff3` ship in GNU diffutils. They are not coreutils. On this host the Ubuntu package is `diffutils` 3.10. `patch` is a different Ubuntu package, `patch`, upstream GNU patch 2.7.6. diff computes a difference. patch applies one. `cmp` from diffutils compares bytes and reports the first offset that disagrees. There is no coreutils `cmp`.

`diff` exits 0 when the files match, 1 when they differ, and 2 when it cannot read an input. Under `set -e` a useful diff aborts the script unless you record the status. `diff -q` prints `Files old and new differ` and still exits 1. A unified diff (`-u`) is the form patch expects. The header lines carry timestamps, so two runs on the same bytes do not produce identical headers. The hunk, from the `@@` line down, is the content. Strip the headers when you need a stable capture. Do not check a whole unified diff into a test that embeds the clock.

`sdiff` prints a side-by-side view. `-s` suppresses identical lines. It exits 1 when the files differ, same rule as diff. It is for a human reading two configs. It is a poor input to another program.

`diff3` compares three files: mine, the base, and theirs. That is the shape of a conflicted config or a generated file that two branches edited. The output marks which side changed which range. It is not a git merge, and it does not touch the working tree. You still decide what to write. Exit status is non-zero when there is a conflict to report. Handle it, or `set -e` will treat a successful report as a failure.

`patch` reads a diff and edits a file. `patch work p.diff` applies `p.diff` to `work`. On success it prints `patching file work`. Apply the patch to a copy if you still need the original. Then `cmp` the result against the file you meant to reach. `cmp` exits 1 at the first different byte and names the offset. That offset is the fastest answer to "did the object files diverge", and it does not try to align lines. Use `diff` for text you want to read. Use `cmp` for firmware blobs and `.o` files.

None of these tools understand a build. A unified diff of two 200 MB binaries is the wrong artifact. `cmp -s` is silent and returns status, which is what a script wants. Checksums from coreutils answer "did the bytes change at all" without an offset. `cmp` answers "where".

## Worked examples

### Status, then the hunk

```run
# title: Differing files and a stable hunk
# companion: diff
/usr/bin/printf 'a\nb\n' > old
/usr/bin/printf 'a\nB\n' > new
/usr/bin/diff -q old new >brief.txt || test $? -eq 1
/usr/bin/cat brief.txt
/usr/bin/diff -u old new >raw.diff || test $? -eq 1
/usr/bin/sed -n '/^@@/,$p' raw.diff
```

### The first byte that disagrees

```run
# title: cmp names the offset
# companion: cmp
/usr/bin/printf 'a\nb\n' > old
/usr/bin/printf 'a\nB\n' > new
/usr/bin/cmp old new >cmp.txt || test $? -eq 1
/usr/bin/cat cmp.txt
```

### Side by side and three way

```run
# title: sdiff and diff3
# companion: diff3
/usr/bin/printf 'a\nb\nc\n' > base
/usr/bin/printf 'a\nB\nc\n' > mine
/usr/bin/printf 'a\nb\nC\n' > theirs
/usr/bin/sdiff -s mine theirs >side.txt || test $? -eq 1
/usr/bin/cat side.txt
/usr/bin/diff3 mine base theirs >three.txt || test $? -eq 1
/usr/bin/grep -c . three.txt
```

### patch, then cmp

```run
# title: Apply the hunk
# companion: patch
/usr/bin/printf 'a\nb\n' > old
/usr/bin/printf 'a\nB\n' > new
/usr/bin/diff -u old new >p.diff || test $? -eq 1
/usr/bin/cp old work
/usr/bin/patch work p.diff
/usr/bin/cmp work new && /usr/bin/printf 'matches-new\n'
```

## Performance

diff on two large text files is CPU and memory proportional to the file size and to how different they are. A binary that changed in the first byte is a job for `cmp`, which stops. Running `diff -u` on two APKs builds a huge hunk and writes it. That is I/O you asked for by choosing the wrong tool.

`diff -r` walks two trees. It stats every name. It is not `find`, and it is slower than a checksum manifest when you only needed "which paths differ" and you already have hashes. Coreutils `sha256sum` plus `join` or `comm` is the manifest recipe already in this course. diffutils is the tool when you need the text of the change.

`sdiff` and `diff3` are not batch tools. They format for a person. Do not put `sdiff` in a tight loop over thousands of files. `cmp -s` in a loop is still one process per file. Batch the decision with checksums when the set is large, then `cmp` the few that disagree if you need offsets.

This lesson does not publish timings. A diff of two tiny fixtures is dominated by process startup. The startup supplement in the coreutils benchmarks is the measurement of that overhead. Quoting it as a diffutils result would mix two experiments.

## Tips and pitfalls

Status 1 is success-with-difference. Status 2 is the failure. `diff a b || test $? -eq 1` keeps 2 as a real error.

Timestamps in `---` and `+++` lines change every run. Tests should match the hunk or use `diff -q`.

`patch` without `--dry-run` edits the file. On a source tree, know which file the header names. A diff recorded from another directory can apply to the wrong relative path.

`diff3` argument order is mine, base, theirs in the example. Swapping base and mine changes the report. Read the headings in the output before you script against them.

GNU diff's `-Z` ignores trailing white space. That can hide a change you needed in a generated file. Use it only when trailing space is noise.

## Exercises

```exercise
expect-exit: 0
---title---
Report that two files differ
---prompt---
Write `a` and `b` as one-line files and run `diff -q`. Keep the script alive when diff exits 1.
---hint---
`diff -q left right >out || test $? -eq 1`, then print the file.
---hint2---
The message names both files. Status 1 is the difference, not a usage error.
---solution---
`Files left and right differ`.
---script---
/usr/bin/printf 'a\n' > left
/usr/bin/printf 'b\n' > right
/usr/bin/diff -q left right >out || test $? -eq 1
/usr/bin/cat out
```

```exercise
expect-exit: 0
---title---
Point at the byte
---prompt---
Compare `ax` and `ay` with cmp and show the offset line.
---hint---
cmp exits 1. Catch that status.
---hint2---
The first byte matches. The report should mention byte 2.
---solution---
The captured line says the files differ at byte 2.
---script---
/usr/bin/printf 'ax' > left
/usr/bin/printf 'ay' > right
/usr/bin/cmp left right >out || test $? -eq 1
/usr/bin/cat out
```

```exercise
expect-exit: 0
---title---
Apply a one-line patch
---prompt---
Build a unified diff from `a`/`b` to `a`/`B`, apply it to a copy, and cmp the copy with the new file.
---hint---
`diff -u` exits 1. `patch` then edits the copy. `cmp` should exit 0.
---hint2---
Print `matches-new` only if cmp succeeds.
---solution---
patch's own line, then `matches-new`.
---script---
/usr/bin/printf 'a\nb\n' > old
/usr/bin/printf 'a\nB\n' > new
/usr/bin/diff -u old new >p.diff || test $? -eq 1
/usr/bin/cp old work
/usr/bin/patch work p.diff
/usr/bin/cmp work new && /usr/bin/printf 'matches-new\n'
```
