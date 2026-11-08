---
number: 12
slug: remove-and-shred
title: rm, prompts, and shred's limits
module: Changing the tree
level: intermediate
minutes: 30
summary: rm unlinks directory entries. -I can exit 0 without deleting. shred overwrites only when the device actually stores the new bytes in place.
objectives:
  - Remove a normal file and a name that starts with a dash
  - Explain the captured behavior of rm -I when stdin hits EOF
  - State why --preserve-root exists without demonstrating a deletion of /
  - Describe the manual's limits on shred for journals, snapshots, and SSDs
manual: rm invocation | https://www.gnu.org/software/coreutils/manual/html_node/rm-invocation.html
manual: Treating / specially | https://www.gnu.org/software/coreutils/manual/html_node/Treating-_002f-specially.html
manual: shred invocation | https://www.gnu.org/software/coreutils/manual/html_node/shred-invocation.html
gnu_vs_bsd: |
  GNU rm defaults to `--preserve-root`. BSD rm historically did not have that guard; some current BSD rms added a similar check, and you must read the local man page rather than assume GNU's default. GNU `-I` prompts once in specific cases. `shred` is GNU. macOS has no coreutils shred in the base system. This lesson never ran `rm` against `/` and never ran a BSD rm.
---

`rm` removes a name. When the link count hits zero and no process has the file open, the filesystem may reuse the blocks. It does not promise to erase them. `rm` of a file you have open in another process removes the name and leaves the data alive until the last file descriptor closes. That is why deleting a log that a daemon still has open does not free the space. The space shows up in `du` of the directory as gone and in `df` of the filesystem as still used. The du and df lesson is the measurement. The mechanism is the inode reference count.

`--` ends options, so `rm -- -rf` removes a file named `-rf` and does not recurse. Build this habit before you interpolate a variable. `rm -r -- "$dir"` is the shape. `rm -r $dir` is the shape that word-splits and glob-expands.

GNU rm treats `/` specially. `--preserve-root` is the default. `--no-preserve-root` turns the guard off. This course does not run either form against the real root. The help text is enough to show that the guard exists, and a demonstration that "probably refuses" is not something to type against `/`. The manual's node on treating `/` specially is the citation. If you need to empty a scratch directory, point `rm -r` at a path you created with `mktemp -d` and checked with `realpath`.

`-i` prompts for each removal. `-I` is less chatty: it prompts when you ask it to remove more than three arguments, or when you descend recursively. In this sandbox, `rm -I` on four files, with empty stdin, printed a question, deleted nothing, and exited 0. A `set -e` script will not notice. If you automate `-I`, you have not built a safety check; you have built a prompt that an empty pipe answers by keeping the files and looking successful. Prefer a dry run that lists names, then an explicit `rm` without `-I`, over a prompt nobody is watching.

`shred` overwrites a file's bytes and, with `-u`, unlinks it. The manual's assumption is that the filesystem and the hardware replace those blocks in place. It then lists designs that break the assumption: journaled data modes, copy-on-write and log-structured filesystems, snapshots, RAID, compressed filesystems, and wear leveling on SSDs, which write the new data somewhere else and leave the old data until garbage collection. ext4 in the default `data=ordered` mode is one of the cases the manual says still overwrites file data as usual, and `data=journal` is not. If you do not know the mount options, the manual tells you to assume shred cannot reliably operate on regular files. The example uses `-n 1` on a scratch file so you can see the name disappear. It is not evidence that a secret is gone from the device.

## Worked examples

### Remove a dash-leading name

```run
# title: -- keeps -n as a file name
/usr/bin/printf 'x\n' > ./-n
/usr/bin/rm -- -n
/usr/bin/ls -A
```

### -I with nobody answering

```run
# title: Four files, empty stdin, nothing deleted
/usr/bin/touch f1 f2 f3 f4
set +e
/usr/bin/rm -I f1 f2 f3 f4
/usr/bin/printf 'status:%s\n' $?
set -e
/usr/bin/ls -1
```

### The guard is visible in --help, and that is as close as we get to /

```run
# title: preserve-root is a default, not a demo on the real root
# companion: grep
/usr/bin/rm --help | /usr/bin/grep -n preserve-root
```

### shred -u removes the name after one overwrite pass

```run
# title: One pass, then the directory entry is gone
/usr/bin/printf 'secret\n' > note
/usr/bin/shred -u -n 1 note
/usr/bin/ls -A
```

## Recipes

Delete a build scratch directory only after `realpath` shows it sits where you think. Compare the resolved path to the prefix you created. Then `rm -r -- "$scratch"`. The `mktemp` lesson gives you the directory.

For a secret on a laptop SSD, assume `shred` is not sufficient. The manual's own advice points at destroying media when the bytes must be unrecoverable, and at full-disk encryption so the deletion problem is "drop the key" rather than "overwrite the NAND". Encryption is not a coreutils feature. It is the reason not to oversell `shred`.

## Tips and pitfalls

`rm -I` exiting 0 with the files still present is the sharp edge. Test the listing, not only the status, if you ever script `-I`.

`grep` in the help example is the grep package, not coreutils. It is labeled. The same line is visible in `rm --help` without grep if you read it; the filter keeps the capture short.

`shred` of a symlink shreds the target if it follows the link. Know what the name points at before you pass `-u`.

## Exercises

```exercise
expect-exit: 0
---title---
Remove one file
---prompt---
Create `gone.txt` and remove it. `ls -A` should not show it.
---hint---
`rm -- gone.txt` is the safe spelling.
---solution---
The directory entry is gone. The blocks may still exist on the device until reused.
---script---
/usr/bin/printf 'x\n' > gone.txt
/usr/bin/rm -- gone.txt
/usr/bin/ls -A
```

```exercise
expect-exit: 0
---title---
Show the interactive-once prompt's status
---prompt---
Create four empty files and run `rm -I` on all four with the default stdin (empty in this runner). Print the status and then the remaining names.
---hint---
`set +e` around rm, because you need the listing afterward. Status may be 0 even when the files remain.
---solution---
The prompt received EOF. The files are still there. That is the captured GNU rm behavior you have to design around.
---script---
/usr/bin/touch a b c d
set +e
/usr/bin/rm -I a b c d
/usr/bin/printf 'status:%s\n' $?
set -e
/usr/bin/ls -1
```

```exercise
expect-exit: 0
---title---
Unlink after a single shred pass
---prompt---
Write `temp` and run `shred -u -n 1` on it. List the directory.
---hint---
`-n 1` is one pass, not a security proof. `-u` unlinks.
---solution---
The name is gone from the directory. The manual's caveats about SSDs and journals still apply to the blocks.
---script---
/usr/bin/printf 'temp\n' > temp
/usr/bin/shred -u -n 1 temp
/usr/bin/ls -A
```

## Performance

`rm` of a large tree is a metadata storm: one unlink per file, directory updates, journal traffic. It is often slower than people expect and almost never limited by "how fast rm the program is". `rm -r` of a tree of a million tiny files is seek and journal work. There is no parallel flag in GNU rm 9.4 that you should reach for to "speed it up" without understanding the filesystem. `shred -n` multiplies the write traffic by the pass count. Extra passes do not fix wear leveling. They make a false sense of security more expensive. One pass in the example is there to show the interface, not because one is a measured optimum.
