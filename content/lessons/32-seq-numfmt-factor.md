---
number: 32
slug: seq-numfmt-factor
title: seq, numfmt, and factor
module: Space, time, and processes
level: intermediate
minutes: 28
summary: seq prints numbers, numfmt rescales them, and factor splits integers. Floating-point steps and SI versus IEC rounding are the traps.
objectives:
  - Print an integer sequence with a separator and a padded width
  - Show seq 0 0.1 1 as this version actually prints it
  - Contrast numfmt --to=iec and --to=si on 2048
  - Factor a small integer and read the empty factor lists of 0 and 1
manual: seq invocation | https://www.gnu.org/software/coreutils/manual/html_node/seq-invocation.html
manual: numfmt invocation | https://www.gnu.org/software/coreutils/manual/html_node/numfmt-invocation.html
manual: factor invocation | https://www.gnu.org/software/coreutils/manual/html_node/factor-invocation.html
manual: Floating point | https://www.gnu.org/software/coreutils/manual/html_node/Floating-point.html
gnu_vs_bsd: |
  `seq` is GNU. macOS historically used `jot` instead. `numfmt` is GNU-only. `factor` exists on BSD with a different output layout. The floating-point chapter of the GNU manual applies to seq's non-integer steps. The exact `seq 0 0.1 1` lines below are what GNU seq 9.4 printed in this locale. They are not a theorem about every step size.
---

`seq FIRST INCREMENT LAST` prints numbers. `seq 1 3` is 1, 2, 3. `-s,` puts commas between them instead of newlines. `-w` equalizes width with leading zeros, so `seq -w 8 10` prints `08`, `09`, `10`. `-f` is a printf format. Integer sequences are the ones to trust in a loop bound. A shell `for i in $(seq 1 100)` is still a process and a word list; a C++ or Rust loop does not need seq.

Non-integer steps use floating point. The manual's floating-point node says these conversions inherit the usual rounding, overflow, and locale decimal-point rules. The example runs `seq 0 0.1 1` and counts the lines with `wc -l`. On this GNU seq 9.4 the capture is eleven lines, ending at `1.0`. That is a measured result for this binary and this step, not a theorem about every increment. Another step can miss the endpoint. If the endpoint matters, use integers (`seq 0 100` and divide in a language with a decimal type) or check the output of the exact command you ship.

`numfmt` converts numbers to and from human units. `--to=iec` uses powers of 1024. `--to=si` uses powers of 1000. `2048` is exactly `2.0K` in IEC and rounds to `2.1K` in SI because 2048/1000 = 2.048, which rounds to one decimal as 2.1. That single digit is why a dashboard that mixes the flags lies. `--from=si` parses a suffixed number back. `--field` selects a column so you can format a byte column without touching the name column. `--invalid=ignore` leaves a bad token alone and exits 0. The default is to fail. Pick the one the pipeline needs, and do not use ignore to hide corruption.

`factor 8051` prints `8051: 83 97`. `factor 17` prints `17: 17`. `factor 1` and `factor 0` print the number and no factors. It is an arbitrary-precision factorizer for a puzzle and a teaching example, not a library you link into a service, and not a timing oracle you should build.

## Worked examples

### Integers, width, separator

```run
# title: seq -w and seq -s
/usr/bin/seq -w 8 10
/usr/bin/seq -s, 1 3
```

### A decimal step, captured rather than assumed

```run
# title: seq 0 0.1 1
/usr/bin/seq 0 0.1 1
/usr/bin/printf 'lines:'
/usr/bin/seq 0 0.1 1 | /usr/bin/wc -l
```

### IEC versus SI

```run
# title: 2048 in both unit systems
/usr/bin/printf '2048\n' | /usr/bin/numfmt --to=iec
/usr/bin/printf '2048\n' | /usr/bin/numfmt --to=si
/usr/bin/printf 'x 2048 y\n' | /usr/bin/numfmt --field=2 --to=iec
```

### Factors

```run
# title: factor of a composite, a prime, and 1
/usr/bin/factor 8051
/usr/bin/factor 17
/usr/bin/factor 1
```

## Recipes

Number build shards with `seq -w 1 32` so the names sort lexically and numerically the same way. Avoid `seq 0 0.1 1` as a progress marker in a shell loop. The shell is the wrong place for a float grid.

Format a `du -B1` column for a report with `numfmt --field=1 --to=iec` after you have decided the reader wants IEC. Label the column `KiB-style` or just leave the suffix numfmt prints, and do not call it MB.

## Tips and pitfalls

`seq` writes a newline after the last number unless you change the separator and forget the final newline. `seq -s, 1 3` prints `1,2,3` and a newline. Check with `od` if a consumer is strict.

`numfmt` of a blank field fails unless `--invalid` says otherwise. A header line in the file is a blank-or-text field. Strip the header with `tail -n +2` first.

`factor` of a huge integer is CPU. Do not point it at untrusted gigabyte strings in a public service. The examples use tiny inputs.

## Exercises

```exercise
expect-exit: 0
---title---
Pad a sequence
---prompt---
Print seq from 8 to 10 with equal width.
---hint---
`-w`.
---solution---
`08`, `09`, `10`.
---script---
/usr/bin/seq -w 8 10
```

```exercise
expect-exit: 0
---title---
Format 4096 as IEC
---prompt---
Pipe `4096` through `numfmt --to=iec`.
---hint---
4096 is 4 * 1024.
---solution---
`4.0K` in IEC. SI would not be the same spelling.
---script---
/usr/bin/printf '4096\n' | /usr/bin/numfmt --to=iec
```

```exercise
expect-exit: 0
---title---
Factor 8051
---prompt---
Print the factors of 8051.
---hint---
The output names the number, then the factors.
---solution---
83 and 97. The product is 8051.
---script---
/usr/bin/factor 8051
```

## Performance

`seq` of a million numbers is a lot of text and a lot of pipe traffic if a shell reads it line by line. Generate the numbers in-process when the consumer is C++ or Rust. `numfmt` is linear and cheap; the cost of a wrong unit is a human misreading a capacity graph, which is more expensive than the process. `factor` is exponential in the size of the integer in the worst cases that matter. A small example finishes immediately and says nothing about factoring a 2048-bit number. Do not time `factor 17` and conclude anything about cryptographic sizes. This course does not include a factoring benchmark because the interesting inputs are the ones you should not casually run, and the small ones are noise.
