---
number: 4
slug: cut-is-not-csv
title: cut splits on a character, not on CSV quotes
module: Cookbook
level: intermediate
minutes: 16
summary: A comma inside quotes is still a comma to cut. Field two of a,"b,c",d is not the quoted cell.
manual: cut invocation | https://www.gnu.org/software/coreutils/manual/html_node/cut-invocation.html
gnu_vs_bsd: |
  POSIX `cut` selects bytes, characters, or fields. GNU cut adds `--complement` and `-z`. Neither GNU nor BSD cut implements RFC 4180 quotes. A CSV parser is a different program. This recipe shows the GNU split.
---

`cut -d, -f2` takes the second comma-separated field. It does not know that a double quote can protect a comma. The line `a,"b,c",d` has four comma-separated fields: `a`, `"b`, `c"`, and `d`. Field two is quote-b, not the cell b,c. Any script that extracts a column from an export "because it is a csv" with `cut` will silently shift columns the first time a description contains a comma. That is a correctness bug that looks like clean data.

`cut` is still the right tool for files that really are single-character-separated and contain no quoted separators: `/etc/passwd` with `-d:`, or a log you generated yourself with a delimiter you know cannot appear. `--complement` drops the fields you name and keeps the rest, which is useful for removing a column without renumbering. `-z` uses NUL as the line delimiter when the upstream tool produced NUL records. None of those flags add a quote parser.

If the file is real CSV, use a parser in the language you are shipping (Python's csv module, a Rust crate, a C++ library). `awk` with `FPAT` is a GNU awk feature, and this host's awk is mawk, so a blog snippet that depends on `FPAT` will not run here anyway. Do not "fix" cut by deleting quotes with `tr` first. Embedded quotes and escaped quotes will still break, and you will have destroyed data you needed.

## Steps

```run
# title: The comma inside quotes still splits
/usr/bin/printf 'a,"b,c",d\n' | /usr/bin/cut -d, -f1
/usr/bin/printf 'a,"b,c",d\n' | /usr/bin/cut -d, -f2
/usr/bin/printf 'a,"b,c",d\n' | /usr/bin/cut -d, -f3
/usr/bin/printf 'a,"b,c",d\n' | /usr/bin/cut -d, -f4
```

```run
# title: A delimiter that cannot appear is fine
/usr/bin/printf 'root:x:0:0:root:/root:/bin/bash\n' | /usr/bin/cut -d: -f1,7
```

## Check yourself

```exercise
expect-exit: 0
---title---
Show field two of a quoted comma
---prompt---
Print field 2 of `a,"b,c",d` split on commas.
---hint---
Do not expect `b,c`.
---solution---
The field is `"b` including the quote. The comma ended the field.
---script---
/usr/bin/printf 'a,"b,c",d\n' | /usr/bin/cut -d, -f2
```

## Performance

`cut` is a streaming scan. It is cheap compared with a CSV parser that counts quotes and allocations, and that cheapness is why people reach for it. The cost of a wrong column in a data export is not saved CPU. Use cut when the format matches the tool, and pay for a parser when it does not. `cut -c` on a multibyte locale counts characters. `cut -b` counts bytes and can split a UTF-8 sequence. For ASCII field files the difference is invisible. For logs in UTF-8, decide which one you meant. Neither mode makes CSV quotes work.
