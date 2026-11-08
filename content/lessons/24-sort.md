---
number: 24
slug: sort
title: sort, keys, and external merge
module: Order and uniqueness
level: advanced
minutes: 40
summary: sort compares keys, then the whole line unless -s. It spills runs to -T when the initial buffer is not enough. --parallel is a cap, not a promise.
objectives:
  - Explain last-resort comparison and what -s disables
  - Sort numerically, by version, and on a single field
  - Use -c and read status 1 as "not in order"
  - Describe -S, -T, and --parallel from the manual without inventing a speedup
manual: sort invocation | https://www.gnu.org/software/coreutils/manual/html_node/sort-invocation.html
manual: Version sort ordering | https://www.gnu.org/software/coreutils/manual/html_node/Version-sort-overview.html
gnu_vs_bsd: |
  POSIX sort has `-k`, `-n`, `-r`, `-u`, and `-c` in some form. GNU adds `-V`, `-h`, `-s` as a stable sort that drops the last-resort compare, `--debug`, `--parallel`, `-S`, `-T`, `--compress-program`, `-z`, and `--files0-from`. The manual says `--parallel` defaults to the number of available processors and is limited to 8, and that more threads increase memory by a factor of log N. BSD sort does not take that flag set. All captures are GNU sort 9.4.
---

`sort` compares records. The default record ends at newline, and the newline is not part of the key. If the file does not end in a newline, GNU sort silently supplies one for the comparison. A key is a field range. Fields start at 1. The default field separator is the transition from non-blank to blank, and the blanks stay attached to the following field unless `-b` or `-t` says otherwise. `-k2,2` is "field 2 only". `-k2` is "from field 2 to the end of the line", which still includes the rest of the line in the key. Those are different sorts. `--debug` underlines the portion it used and warns about locale numeric punctuation. The underline goes to stdout with the line. The warnings go to stderr.

When all keys compare equal, sort compares the whole line as a last resort, ignoring the key options except `-r`. That last resort breaks stability: two lines with the same key can swap because the rest of the line differs. `-s` disables the last resort and keeps the input order of ties. `-u` also disables it, and it keeps one line from each equal-key group. `sort -u` and `sort | uniq` match only for the simple whole-line case. `sort -n -u` decides uniqueness on the numeric key. `sort -n | uniq` decides uniqueness on the whole line after the numeric sort. The manual states that difference. The uniq lesson shows an adjacent-line tool that cannot see a duplicate which is not adjacent.

External sort is the mechanism for inputs that do not fit in the initial buffer. Sort writes sorted runs to temporary files and merges them. `-T` selects the directory, overriding `TMPDIR`. `-S` sets the initial main-memory buffer. The manual says a bare number is in units of 1024 bytes, `%` means a percentage of physical memory, `K` multiplies by 1024, `M` by 1,048,576, and `b` means bytes. The buffer can still grow to hold a line longer than `-S`. `--compress-program` compresses the runs; the program must compress stdin to stdout and decompress with `-d`. `--parallel=N` is the number of concurrent sorts, defaulting as the manual describes, not "use every core you can find" beyond 8. None of these flags change the result if the comparison rules stay the same. They change resource use. The benchmarks measure a few of them and refuse to rank variants whose medians sit inside the noise.

`-c` checks order and exits 1 at the first disorder, with a diagnostic. `-C` is the quiet check. Status 2 is a real error, such as a missing file. `-m` merges files that are already individually sorted. Merging is faster when the premise holds, and wrong when it does not. `-z` uses NUL records so names can contain newlines.

Version sort `-V` treats digit runs as numbers, so `a2` precedes `a10`. It is not numeric sort of the whole line, and the manual has a whole chapter on where it disagrees with human "natural" expectations and with Debian version comparison. Use it for version-shaped tokens you have tested, not as a synonym for `-n`.

## Worked examples

### Stability

```run
# title: Last resort versus -s
/usr/bin/printf 'b 2\nb 1\na 2\n' | /usr/bin/sort -k1,1
/usr/bin/printf '---\n'
/usr/bin/printf 'b 2\nb 1\na 2\n' | /usr/bin/sort -k1,1 -s
```

### Numeric and version order

```run
# title: -n and -V
/usr/bin/printf '10\n2\n1\n' | /usr/bin/sort -n
/usr/bin/printf 'a10\na2\na1\n' | /usr/bin/sort -V
```

### A check that fails

```run
# title: sort -c status 1
# expect-exit: 1
/usr/bin/printf 'b\na\n' | /usr/bin/sort -c
```

### A spill that calls a helper

```run
# title: --compress-program runs when runs hit disk
# timeout: 90
cat > comp << 'EOF'
#!/bin/sh
if [ "${1:-}" = "-d" ]; then cat; else cat; fi
printf 'x\n' >> "$COMPLOG"
EOF
chmod +x comp
export COMPLOG="$PWD/comp.log"
/usr/bin/seq 4000 | /usr/bin/sort -S 1K -T "$PWD" --compress-program="$PWD/comp" > /dev/null
/usr/bin/wc -l comp.log
```

## Recipes

Sort a manifest of file names with `LC_ALL=C sort -z` when the names are NUL-delimited. Check it later with `sort -c -z` if you need a gate in CI.

For a table, write the key flags on the command, not in the environment. `sort -t, -k1,1 -k2,2n` is a comma key and a numeric second key. `--debug` once when the result looks wrong, then remove it so the underlines do not enter the artifact.

Point `-T` at a directory on a filesystem with room. A sort that spills to a small tmpfs fails late. The benchmark uses the work directory and says so.

## Tips and pitfalls

`-S 1` is not "one byte". Read the unit rules before you pick a number. The examples use `1K`, which is explicit.

`--parallel` on a tiny file spends more time starting threads than comparing keys. The parallel benchmark uses 120000 lines and only compares 1 versus 2. Read its note.

`sort -u` on version-sorted output is uniqueness under version comparison, which can collapse names a byte sort would keep. Test the keys.

## Exercises

```exercise
expect-exit: 0
---title---
Sort numbers
---prompt---
Numerically sort `10`, `2`, and `1`.
---hint---
`-n`. Lexical sort would put 10 first.
---solution---
The order is 1, 2, 10.
---script---
/usr/bin/printf '10\n2\n1\n' | /usr/bin/sort -n
```

```exercise
expect-exit: 0
---title---
Keep input order for equal keys
---prompt---
Sort `b 2` then `b 1` by field 1 only, stably.
---hint---
`-k1,1 -s`.
---solution---
`b 2` stays above `b 1`. Without `-s`, the last-resort compare orders `b 1` first.
---script---
/usr/bin/printf 'b 2\nb 1\n' | /usr/bin/sort -k1,1 -s
```

```exercise
expect-exit: 1
---title---
Reject disorder
---prompt---
Check `b` then `a` with `sort -c`.
---hint---
Status 1 is the check failing, not a crash.
---solution---
The diagnostic names the out-of-order line. Status 2 would mean sort could not run the check.
---script---
/usr/bin/printf 'b\na\n' | /usr/bin/sort -c
```

## Performance

External merge trades RAM for IO. A larger `-S` means fewer runs and less temporary traffic, until the machine starts paging, at which point a "bigger buffer" is slower. `--parallel` overlaps CPU-bound comparisons and raises memory. On a sort that is already IO-bound in `-T`, more threads do not create more disk. The buffer and parallel benchmarks in this course are warm-cache, small, and explicit about that. Use them as a method: fix the input, repeat, take the median, compare the gap to the spread. A spill you can prove is the compress-program log in the example: each invocation appends a line, so a non-zero count means sort did call the helper. The count is invocations, not seconds, and not a claim that compression made the sort faster. Compression can save IO and cost CPU. This lesson does not pick a winner.
