---
number: 44
slug: gnu-sed
title: GNU sed
module: Companion Tools
level: intermediate
minutes: 30
summary: GNU sed is a stream editor, Ubuntu package sed, not coreutils. sed -i replaces the inode. A redirect writes a new file and leaves hard links alone.
objectives:
  - Identify sed as GNU sed and not coreutils
  - Edit a stream with an address and a substitution
  - Show that sed -i breaks a hard link by writing a new inode
  - Prefer a redirect when the file is large or linked
manual: GNU sed manual | https://www.gnu.org/software/sed/manual/html_node/index.html
manual: sed invocation | https://www.gnu.org/software/sed/manual/html_node/Invoking-sed.html
manual: Coreutils ln | https://www.gnu.org/software/coreutils/manual/html_node/ln-invocation.html
gnu_vs_bsd: |
  BSD sed -i requires an argument for the backup suffix, so sed -i 's/a/b/' is a GNU form. BSD sed also lacks some GNU escapes. This lesson ran GNU sed 4.9 only. No BSD sed was executed.
---

GNU sed edits a stream. It is not GNU coreutils. The binary is `/usr/bin/sed`, Ubuntu package `sed`, upstream GNU sed 4.9. `head` and `tail` can drop lines by count. They cannot apply `s/old/new/`. When the edit is a substitution, sed is the tool, and the script should say so.

A sed program is a list of commands with optional addresses. `sed -n '2p'` prints the second line and nothing else, because `-n` suppresses the default print. `s/b/B/` replaces the first `b` on each line. A trailing `g` replaces all of them. Addresses can be numbers or patterns. The language is small and it is not awk. If you need fields, arithmetic, or an associative array, you have left sed.

`sed -i` looks like an in-place edit. GNU sed writes a temporary file in the same directory and renames it over the original. The directory needs space for a second copy. The inode number changes. A hard link still points at the old inode and keeps the old bytes. A process that already opened the path keeps the old file too, the same way a deleted log stays open. Symbolic links are followed to the target, and the rewrite lands on the target. Permissions on the new inode come from sed's creation, not from a promise to preserve every attribute. `--follow-symlinks` is a GNU switch worth reading before you point `-i` at a link.

That rewrite is the performance pitfall. On a small config file it does not matter. On a multi-gigabyte log it needs a second multi-gigabyte write, then a rename, and it still changes the inode. A streaming `sed 's/a/A/g' log > log.next` also writes the bytes once, to a name you chose, and you can `mv -f` it into place if you accept the new inode. You do not pay a hidden temp plus the original until the rename. The companion benchmark `sed-rewrite` times both shapes on a 2 MiB file, and both shapes include one `cp`, so the comparison is the edit rather than "one of them also copied". Read the note before you declare a winner. The gap on 2 MiB of warm cache can sit inside the noise. The disk cost shows up when the file is larger than the cache and the directory is nearly full.

`sed` reads line by line. A line that is gigabytes long, because nobody wrote a newline, becomes a gigabyte buffer. That is the same class of surprise as `wc -l` on a file with one line. Coreutils `fold` and `split` are the tools when the record is not a line.

Hold space and the `N`, `P`, `D` cycle are real sed, and they are how people join pairs of lines. They are also how scripts become unreadable. For a join of two fields across a whole file, awk is the clearer program. This lesson stays with addresses, substitutions, and the inode.

## Worked examples

### Address and substitution

```run
# title: Second line, then a substitution
# companion: sed
/usr/bin/printf 'a\nb\nc\n' | /usr/bin/sed -n '2p'
/usr/bin/printf 'a\nb\nc\n' | /usr/bin/sed 's/b/B/'
```

### sed -i changes the inode

```run
# title: Hard link keeps the old bytes
# companion: sed
/usr/bin/printf 'a\n' > seen
/usr/bin/ln seen hard
/usr/bin/stat -c %i seen > before
/usr/bin/sed -i 's/a/A/' seen
/usr/bin/stat -c %i seen > after
if /usr/bin/cmp -s before after; then /usr/bin/printf 'same-inode\n'; else /usr/bin/printf 'new-inode\n'; fi
/usr/bin/printf 'sed:%s\n' "$(cat seen)"
/usr/bin/printf 'hard:%s\n' "$(cat hard)"
```

### A redirect leaves the source

```run
# title: Stream to a new file
# companion: sed
/usr/bin/printf 'a\nb\n' > source
/usr/bin/sed 's/b/B/' source > next
/usr/bin/printf 'source:%s' "$(/usr/bin/cat source)"
/usr/bin/printf 'next:%s' "$(/usr/bin/cat next)"
```

### Delete one address

```run
# title: Drop a matching line
# companion: sed
/usr/bin/printf 'keep\ndrop\nkeep\n' | /usr/bin/sed '/^drop$/d'
```

## Performance

sed's CPU cost on a simple substitution is a linear scan. The I/O cost of `-i` is a full rewrite in the same directory. If the filesystem is full enough that the temp file cannot be allocated, `-i` fails and, if you are lucky, leaves the original. Do not use `-i` on the only copy of a log without a backup suffix you can see: `sed -i.bak 's/a/b/' file` keeps `file.bak`. That backup is another full copy. On a large file, decide whether you wanted the backup before you pay for it.

Streaming into a new file on the same filesystem, then `mv`, is one write plus a rename. Streaming onto another filesystem is a real copy at `mv` time. The move lesson in the coreutils track is the one that explains that. sed does not change it.

The benchmark id `sed-rewrite` used a base file of 2097140 bytes. Median elapsed time was 0.0547s for `cp` then `sed -i` and 0.0546s for `cp` then a redirect. The gap was 0.0001s and the widest trial spread was 0.0059s, so this run does not separate the variants. Elapsed time includes the Python starter. Nothing was tuned. The honest summary is that this input did not show an `-i` penalty you can quote. The inode change is still true. It was demonstrated by `stat`, not by the clock.

Do not pipe `grep` into `sed` into `awk` into `cut` when one awk program can do the field edit. Each extra process is a read and a write of the whole stream. The profile recipe in the cookbook makes that concrete without inventing a millisecond.

## Tips and pitfalls

GNU `sed -i` without a suffix is not portable to BSD sed, which takes the next argument as the suffix and then treats your program as a file name. If a script must run on macOS, pass `-i ''` there, or skip `-i` and write a new file. This course did not run BSD sed.

`-i` and a failing substitution still rewrite the file when the program is valid and simply matches nothing. The bytes may look identical and the inode may still change. Check the inode if a hard link matters.

`sed` does not understand CSV quotes. A comma inside quotes is just bytes. The cut lesson already said this for `cut`. sed does not fix it.

A slash in the replacement needs a different delimiter: `s#/old/#/new/#`. The delimiter is the character after `s`.

## Exercises

```exercise
expect-exit: 0
---title---
Print only line 2
---prompt---
From `a`, `b`, `c` on three lines, print only `b`.
---hint---
`sed -n` and the address `2p`.
---hint2---
Without `-n`, sed would print every line and also the addressed line a second time.
---solution---
The only output line is `b`.
---script---
/usr/bin/printf 'a\nb\nc\n' | /usr/bin/sed -n '2p'
```

```exercise
expect-exit: 0
---title---
Show the hard link after sed -i
---prompt---
Put `a` in `seen`, hard-link it to `hard`, run `sed -i` to turn `a` into `A`, and print both files.
---hint---
`ln seen hard` before the edit. Then print `seen` and `hard` with labels.
---hint2---
The new file should read `A`. The hard link should still read `a`.
---solution---
`sed:A` and `hard:a`. The inode changed. sed is not coreutils.
---script---
/usr/bin/printf 'a\n' > seen
/usr/bin/ln seen hard
/usr/bin/sed -i 's/a/A/' seen
/usr/bin/printf 'sed:%s\n' "$(cat seen)"
/usr/bin/printf 'hard:%s\n' "$(cat hard)"
```

```exercise
expect-exit: 0
---title---
Delete a marker line
---prompt---
Remove the line that is exactly `drop` and keep the other two.
---hint---
The command is `/^drop$/d`.
---hint2---
Anchor both ends or a line that merely contains the letters will also go.
---solution---
Two lines, `keep` and `keep`.
---script---
/usr/bin/printf 'keep\ndrop\nkeep\n' | /usr/bin/sed '/^drop$/d'
```
