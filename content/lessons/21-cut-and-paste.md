---
number: 21
slug: cut-and-paste
title: cut, paste, and the CSV myth
module: Reading and shaping text
level: intermediate
minutes: 30
summary: cut selects bytes, characters, or delimiter fields. It does not parse quotes. paste merges lines. Neither tool is a CSV library.
objectives:
  - Select fields and a complement of fields with cut
  - Show a quoted comma breaking -d,
  - Compare cut -c and cut -b on a multibyte character
  - Merge files and join lines of one file with paste
manual: cut invocation | https://www.gnu.org/software/coreutils/manual/html_node/cut-invocation.html
manual: paste invocation | https://www.gnu.org/software/coreutils/manual/html_node/paste-invocation.html
gnu_vs_bsd: |
  POSIX cut selects fields. GNU `--complement`, `--output-delimiter`, and `-z` are extensions. BSD cut will not accept the GNU long options. `paste -z` is GNU. The CSV failure is not GNU-specific: any delimiter cut that does not implement quotes will split `"a,b",c` the same way. This capture is GNU 9.4. A real CSV parser is not in coreutils.
---

`cut -f2 -d,` prints the second comma-separated field. Fields are numbered from 1. `-d` is a single character. `--output-delimiter` changes what is printed between fields you kept, which is how you turn a comma file into a tab file without `tr` eating commas you meant to keep inside a field. `--complement` prints the fields you did not name. `-c` selects characters. `-b` selects bytes. On `é`, which is two bytes, `-c1` can yield the character and `-b1` yields the first byte, which is not a character. The od dump in the tr lesson is the same class of bug. Know which flag you passed.

The CSV myth is the sentence "I will just cut on commas". The input `"a,b",c` has a comma inside quotes. `cut -d, -f1` returns `"a` and `-f2` returns `b"`. The quotes are ordinary bytes. There is no escape syntax. A field that contains the delimiter cannot be represented in the format cut understands. If your Android manifest or your benchmark table is actually CSV with quotes, parse it in a language that has a CSV reader. If your file is a delimiter-separated file with a contract that the delimiter never appears inside a field, cut is appropriate and fast.

`paste` reads lines from each file and writes them side by side, separated by a tab by default. `-d,` uses a comma. `-s` serializes one file: it joins the lines of that file with the delimiter. `paste -s -d,` of three lines is one line. `paste` does not match keys. If the files are not in corresponding order, you silently zip the wrong rows. `join` is the tool that matches keys, and it requires sorted input. Use paste when the alignment is "line N with line N" and you created both files.

`-z` on cut and paste uses NUL as the line delimiter. That is the filename-safe mode. It does not make cut understand CSV quotes either.

## Worked examples

### Fields and the complement

```run
# title: Second field, and everything but the second
/usr/bin/printf 'a,b,c\n' | /usr/bin/cut -d, -f2
/usr/bin/printf 'a,b,c\n' | /usr/bin/cut -d, -f2 --complement
```

### Quotes do not protect a comma

```run
# title: cut is not a CSV parser
/usr/bin/printf '"a,b",c\n' | /usr/bin/cut -d, -f1
/usr/bin/printf '"a,b",c\n' | /usr/bin/cut -d, -f2
```

### Character versus byte

```run
# title: cut -c and cut -b on é
/usr/bin/printf 'éx' | /usr/bin/cut -c1 | /usr/bin/od -An -tx1
/usr/bin/printf 'éx' | /usr/bin/cut -b1 | /usr/bin/od -An -tx1
```

### paste side by side and in series

```run
# title: paste columns and paste -s
/usr/bin/printf 'a\nb\n' > left
/usr/bin/printf '1\n2\n' > right
/usr/bin/paste left right
/usr/bin/printf 'a\nb\nc\n' | /usr/bin/paste -s -d,
```

## Recipes

Extract a column from a GNU `sha256sum` manifest with `cut -d' ' -f1` only after you know the format uses two spaces and the names do not contain newlines. The checksum lesson shows the actual line. For names with spaces, cut on the first field is the hash and the rest is not one simple field. Prefer `--zero` manifests when names are hostile.

Build a two-column report with `paste` from two lists you generated in the same order, for example a list of object files and a list of their sizes from a loop that printed one then the other. If the lists can diverge, stop and use `join`.

## Tips and pitfalls

`cut -f` without `-d` uses tab. A comma file stays one field. The output looks like cut "did nothing".

`-f1-3` is a range. `-f1,3` is a set. The comma in the flag is not the delimiter.

`paste` of files with different line counts pads the shorter side. You do not get an error. Count lines with `wc -l` if alignment matters. Remember the missing-newline trap when you count.

## Exercises

```exercise
expect-exit: 0
---title---
Keep column 1 and 3
---prompt---
From `a,b,c` print `a,c` using complement or an explicit field list and an output delimiter.
---hint---
`--output-delimiter=,` and `-f1,3`.
---solution---
The middle field is gone and the comma between the kept fields is the output delimiter, not a leftover from the input.
---script---
/usr/bin/printf 'a,b,c\n' | /usr/bin/cut -d, -f1,3 --output-delimiter=,
```

```exercise
expect-exit: 0
---title---
Break a quoted comma on purpose
---prompt---
Show the first field of `"a,b",c` under cut -d,.
---hint---
The first comma is inside the quotes and cut does not care.
---solution---
The first field is `"a`. That is the demonstration to keep next to any script that claims to parse CSV with cut.
---script---
/usr/bin/printf '"a,b",c\n' | /usr/bin/cut -d, -f1
```

```exercise
expect-exit: 0
---title---
Zip two one-column files
---prompt---
Write `x` and `y` as single-line files and paste them.
---hint---
Default delimiter is a tab.
---solution---
One line, two fields, tab between. cat -A would show the tab as ^I.
---script---
/usr/bin/printf 'x\n' > x
/usr/bin/printf 'y\n' > y
/usr/bin/paste x y
```

## Performance

`cut` and `paste` are single-pass and memory-light. They are faster than a spreadsheet and slower than a purpose-built parser only when the parser does more work, such as honoring quotes. Do not "speed up" CSV handling by switching to cut if the result is wrong. The cost of a wrong field is a bad Android versionName in a release note, not a saved millisecond. For a huge delimiter file that really is delimiter-safe, cut is appropriate and the bottleneck is reading the bytes, which a warm cache hides. The benchmark method on the benchmarks page is how you would time it. This lesson does not invent a cycles-per-byte figure.
