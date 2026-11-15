---
number: 17
slug: atomic-publish
title: Publish by renaming beside the destination
module: Cookbook
level: intermediate
minutes: 18
summary: Write a temporary file in the destination directory, set the mode, and mv it onto the public name so readers never see a partial file.
manual: mv invocation | https://www.gnu.org/software/coreutils/manual/html_node/mv-invocation.html
manual: mktemp invocation | https://www.gnu.org/software/coreutils/manual/html_node/mktemp-invocation.html
gnu_vs_bsd: |
  POSIX rename is atomic on one filesystem. GNU `mv -T` refuses to treat an existing directory as a container. BSD mv does not take that long option. This recipe stays on one filesystem inside a temp directory. It does not demonstrate EXDEV, and it does not run a BSD mv.
---

A reader that opens a release artifact while the writer is still copying sees a short file. `rename(2)` replaces one directory entry with another on the same filesystem, and readers see the old name or the new name, not a mixture. `mv` uses that when the source and the destination are on the same device. The temporary file therefore has to be created in the destination directory, not in `/tmp` when the public name lives somewhere else. The move lesson states the rule. This recipe is the script.

`mktemp` with a template that ends in `XXXXXX` creates the temporary name and returns it. Write the finished bytes there, then `chmod` the mode you want readers to see, then `mv -f --` onto the public name. The mode is a property of the inode, so it survives the rename. An empty umask on the temporary file would otherwise publish a file nobody else can read, which is why the recipe sets `0644` after writing and checks `stat -c %a`.

`--` keeps a name that starts with a dash from being read as an option. `-f` replaces an existing public name. Do not `rm` the public name first: that opens a window where the name is missing. The assertion script is [sandbox/atomic-publish.sh](/sandbox/atomic-publish.sh). It refuses to run as root, works in a `mktemp` directory, and deletes that directory on exit.

If the public directory is a different mount, this `mv` copies and then unlinks. That is not atomic. The cross-device recipe is the one that shows two device ids. This one refuses to leave the destination directory.

## Steps

```run
# title: Rename onto the public name
mkdir -p out
umask 077
tmp=$(mktemp ./out/app-release.apk.XXXXXX)
printf 'finished-bytes\n' > "$tmp"
chmod 0644 "$tmp"
mv -f -- "$tmp" ./out/app-release.apk
if [ -e "$tmp" ]; then
  printf 'temp_remains\n'
  exit 1
fi
stat -c '%a %n' out/app-release.apk
cat out/app-release.apk
```

```run
# title: The temporary is in the destination directory
mkdir -p out
tmp=$(mktemp ./out/app-release.apk.XXXXXX)
dirname "$tmp"
basename "$tmp" | cut -c1-15
```

## Check yourself

```exercise
expect-exit: 0
---title---
The temporary sits next to the final name
---prompt---
Create `./out/app-release.apk.XXXXXX` with `mktemp` and print `dirname` of the path it returns.
---hint---
The template is a path. `mktemp` creates the file in that directory.
---hint2---
`dirname` is a string operation. It should print `./out`, which is the directory that will hold the public name.
---solution---
`dirname` prints `./out`. A temporary file under `/tmp` would be the wrong directory for an atomic publish onto `./out`.
---script---
mkdir -p out
tmp=$(mktemp ./out/app-release.apk.XXXXXX)
dirname "$tmp"
```

```exercise
expect-exit: 0
---title---
Mode after the rename
---prompt---
Write a temp file with umask 077, chmod it to 0644, mv it to `out/app-release.apk`, and print the mode with `stat -c %a`.
---hint---
`chmod` changes the inode. `mv` on the same filesystem keeps that inode.
---hint2---
`stat -c %a` prints the mode without the leading zero. 0644 is `644`.
---solution---
The mode is 644. The umask that applied at creation does not stick after `chmod`, and the rename does not reset it.
---script---
mkdir -p out
umask 077
tmp=$(mktemp ./out/app-release.apk.XXXXXX)
printf 'finished-bytes\n' > "$tmp"
chmod 0644 "$tmp"
mv -f -- "$tmp" ./out/app-release.apk
stat -c '%a' out/app-release.apk
```

## Performance

The rename itself is a directory update. The cost that matters is the write of the bytes into the temporary file, which is a normal copy into the destination filesystem. Putting the temporary file on a faster disk and then moving it across devices throws away the atomicity and pays for a second copy. `install` can place a file and set a mode in one step, and it is the right tool when you do not need readers to keep seeing the previous inode until the new one is complete. For a file that is replaced while something else might open it, write beside the final name and `mv`. Neither form is faster than the bytes you had to write. This recipe does not time them.
