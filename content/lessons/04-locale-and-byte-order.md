---
number: 4
slug: locale-and-byte-order
title: Locale, collation, and LC_ALL=C
module: How the toolbox thinks
level: intermediate
minutes: 28
summary: LC_COLLATE decides what "sorted" means. LC_ALL=C is byte order, not a universal speedup, and it changes joins and checksums of nothing but the order of text.
objectives:
  - Show that en_US.UTF-8 and C order the same bytes differently
  - Explain which tools consult LC_COLLATE, LC_CTYPE, and LC_NUMERIC
  - Use LC_ALL=C when the contract is bytes, and say so in the script
  - Refuse a speed claim that was not measured on a fixed input
manual: sort invocation | https://www.gnu.org/software/coreutils/manual/html_node/sort-invocation.html
manual: Floating point | https://www.gnu.org/software/coreutils/manual/html_node/Floating-point.html
gnu_vs_bsd: |
  Both GNU and BSD userlands honor POSIX locales, but the collation tables are not the same data. `LC_ALL=C` is the portable way to ask for byte order on either side. GNU `sort` adds `-V`, `--parallel`, and `-S`, which BSD sort does not match flag for flag. macOS `sort` is not GNU sort. This lesson's captured order is the GNU 9.4 order on this Ubuntu locale set.
---

A locale is a bundle of rules for characters, collation, numbers, dates, and messages. Coreutils does not invent a private alphabet. The sort node says that unless you ask otherwise, comparisons use `LC_COLLATE`, and a line's trailing newline is not part of the comparison. Under `en_US.UTF-8` the letters `a` and `A` are primary-equal and the case difference is a later pass, so they group together. Under `LC_ALL=C` the order is the unsigned byte order: `A` (0x41) before `a` (0x61), and `B` before `a` as well.

`LC_ALL` overrides the individual `LC_*` variables. Setting only `LC_COLLATE=C` while leaving `LC_CTYPE` as UTF-8 is a sharper knife, and it is easy to get half-wrong. For a byte-oriented contract, set `LC_ALL=C` on that one command. Exporting it for an entire desktop session also switches messages and number formats, which is more than a sort script needs.

Tools that look at locale in ways people forget: `sort` and therefore anything that requires sorted input (`uniq` after a locale sort, `join`, `comm`); `tr` character classes such as `[:upper:]`, because `LC_CTYPE` defines which bytes are letters; `sort -n` and `seq`, because `LC_NUMERIC` can make the decimal point a comma; `date`, because `LC_TIME` names months; `wc -m`, because a character is not a byte once the encoding is UTF-8. Checksums do not consult collation. `sha256sum` of a file is the same in C and in en_US. If a checksum changed when you exported `LC_ALL`, you changed the bytes, not the hash.

`LC_ALL=C` is often faster for `sort` of large text because the collation is a simple comparison instead of a multi-level Unicode weight. The manual does not promise a ratio. The benchmark page runs a fixed 100000-line file under both locales and reports medians. If they separate, the note says they separated on that file in a warm cache. If they do not, the note says the run cannot rank them. Either result is allowed. Do not paste a blog's "C is always 10x" into a build script.

Byte order is also the wrong order for humans reading a dictionary, and the wrong order for version numbers (`sort -V` is its own lesson). Pick the order that matches the consumer. A `join` requires both files to be sorted by the same rule. Sorting one file in C and the other in en_US produces a disorder diagnostic, not a merged table.

## Worked examples

### The same four lines, two orders

```run
# title: UTF-8 collation groups case together
# env: LC_ALL=en_US.UTF-8
/usr/bin/printf 'A\na\nB\nb\n' | /usr/bin/sort
```

```run
# title: C locale is unsigned byte order
# env: LC_ALL=C
/usr/bin/printf 'A\na\nB\nb\n' | /usr/bin/sort
```

### Character count is not the byte count

```run
# title: wc -m and wc -c on U+00E9
/usr/bin/printf 'é' | /usr/bin/wc -m -c
```

### A checksum ignores collation

```run
# title: sha256sum of abc in two locales
# env: LC_ALL=C
/usr/bin/printf 'abc' | /usr/bin/sha256sum
```

## Recipes

Put `LC_ALL=C sort -u` in front of a manifest of file names when the manifest is a byte contract, for example a list of object files a linker will consume. Put the locale sort only when a person will read the list as a dictionary.

If a `join` fails with "not sorted", do not reach for `--nocheck-order` first. Re-sort both inputs with the same `LC_ALL`. The join lesson shows what the nocheck flag hides.

For numbers that must use a dot, run `LC_ALL=C sort -n` or `LC_ALL=C numfmt`. A teammate whose `LC_NUMERIC` uses a comma will otherwise see a different parse. This sandbox's locale uses a dot; the flag is still worth writing down so the script does not depend on that accident.

## Tips and pitfalls

`sort --debug` prints which locale rules it used, on stderr. That line is part of diagnosing a "wrong" order. It is not corruption.

`uniq` compares adjacent lines in the locale's equality, unless you set C. Case-folding with `uniq -i` is a further fold. Sort and uniq have to agree or the adjacency is meaningless.

Setting `LC_ALL=C` does not make UTF-8 data ASCII. It makes comparisons and some classifications byte-wise. `wc -m` under `LC_ALL=C` counts bytes rather than decoded characters. That is useful when you mean bytes, and surprising when you meant letters.

## Exercises

```exercise
expect-exit: 0
---title---
Force byte order
---prompt---
Sort the lines b, A, a under `LC_ALL=C` and print them.
---hint---
Pass the environment only to sort. printf can stay as it is.
---solution---
C order is A, a, b because 0x41, 0x61, 0x62.
---script---
/usr/bin/printf 'b\nA\na\n' | LC_ALL=C /usr/bin/sort
```

```exercise
expect-exit: 0
---title---
Ask sort what it used
---prompt---
Run `sort --debug` on the single line `a` and keep both streams. The status is 0.
---hint---
The locale note is on stderr. The sorted line is on stdout.
---solution---
The diagnostic names the collation. That is the manual's suggested first step when order looks wrong.
---script---
/usr/bin/printf 'a\n' | /usr/bin/sort --debug
```

```exercise
expect-exit: 0
---title---
Hash both locales
---prompt---
Print `sha256sum` of the bytes `abc` with `LC_ALL=C` and with `LC_ALL=en_US.UTF-8`.
---hint---
Two pipelines. The digest is a property of the bytes.
---solution---
The two digests match the known SHA-256 of abc. Locale did not enter the hash.
---script---
/usr/bin/printf 'abc' | LC_ALL=C /usr/bin/sha256sum
/usr/bin/printf 'abc' | LC_ALL=en_US.UTF-8 /usr/bin/sha256sum
```

## Performance

Collation cost grows with the number of comparisons, which for a comparison sort grows like N log N times the cost of one comparison. A heavier comparison therefore shows up on large N, not on a ten-line example. The locale benchmark uses 100000 lines so the comparison work is at least visible next to process startup. Read the median gap against the trial spread before you keep `LC_ALL=C` as a speed hack. Keep it as a correctness hack whenever the next program assumes byte order, even if the medians tie.
