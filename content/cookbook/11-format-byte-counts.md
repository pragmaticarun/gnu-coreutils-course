---
number: 11
slug: format-byte-counts
title: Label IEC units with numfmt
module: Cookbook
level: beginner
minutes: 14
summary: 2048 bytes is 2.0K in IEC and 2.1K in SI. numfmt --field formats one column and leaves the rest of the line alone.
manual: numfmt invocation | https://www.gnu.org/software/coreutils/manual/html_node/numfmt-invocation.html
gnu_vs_bsd: |
  `numfmt` is GNU. BSD has no matching binary. `--to=iec` uses powers of 1024. `--to=si` uses powers of 1000. The one-decimal rounding of 2048 to `2.1K` in SI is the trap. This recipe ran GNU numfmt 9.4.
---

Human-readable sizes are where capacity graphs go wrong. `numfmt --to=iec` scales by 1024. `numfmt --to=si` scales by 1000. The integer 2048 is exactly 2 × 1024, so IEC prints `2.0K`. The same integer divided by 1000 is 2.048, and one-decimal SI rounding prints `2.1K`. A dashboard that mixes the flags will show a file growing when nobody wrote to it. Pick one unit system, label the column, and pass the matching flag.

`--field=2` formats the second whitespace-separated field and copies the others. That is how you pretty-print a `du -B1` report without turning the path into a number. `--from=si` parses a suffixed value back to a count when you must sort numerically. Sorting the suffixed text with `sort` is wrong. `sort -h` knows human suffixes and is the other honest option. The sort manual describes `-h`. Prefer raw bytes in the file you sort, and format only the display copy.

`--invalid=ignore` leaves a bad token in place and exits 0. The default is to fail. A header line such as `BYTES name` fails a conversion. Strip headers with `tail -n +2` before you format, or the first bad field aborts the pipeline under `set -e`.

## Steps

```run
# title: IEC and SI disagree on 2048
/usr/bin/printf '2048\n' | /usr/bin/numfmt --to=iec
/usr/bin/printf '2048\n' | /usr/bin/numfmt --to=si
```

```run
# title: Format one field
/usr/bin/printf '2048 payload\n' | /usr/bin/numfmt --field=1 --to=iec
```

## Check yourself

```exercise
expect-exit: 0
---title---
Format 4096 as IEC
---prompt---
Pipe `4096` through `numfmt --to=iec`.
---hint---
4096 is 4 × 1024.
---solution---
`4.0K`.
---script---
/usr/bin/printf '4096\n' | /usr/bin/numfmt --to=iec
```

## Performance

`numfmt` is a formatting pass over text. It does not stat files and it does not change how full the disk is. The expensive mistake is human: an operator deletes the wrong tree because SI and IEC were mixed. Format once at the edge of a report. Keep the bytes integer in the log you will grep later. There is no parallel mode worth invoking. If you are formatting the output of `du` on a million-file tree, the walk inside `du` is the cost and numfmt is a rounding error on top of it.
