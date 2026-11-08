---
number: 5
slug: checksum-a-blob
title: Record and check a SHA-256 digest
module: Cookbook
level: beginner
minutes: 14
summary: sha256sum writes a digest line and sha256sum -c reads it back. The three bytes abc are the usual test vector.
manual: sha256sum invocation | https://www.gnu.org/software/coreutils/manual/html_node/sha256sum-invocation.html
gnu_vs_bsd: |
  GNU `sha256sum` prints two spaces and then the name in text mode, or a space and an asterisk for binary mode. BSD `sha256` prints a different label. `cksum -a sha256 --tag` is the GNU way to get a BSD-style line. This recipe uses GNU sha256sum text mode. The digest of the bytes `abc` is a published test vector. The capture confirms this binary.
---

`sha256sum` reads bytes and writes a hex digest, two spaces, and the name. `sha256sum -c` reads that line back, rereads the file, and prints `OK` or `FAILED`. The status is 0 only when every line you asked it to check matches. A missing file and a wrong digest are both failures. The checksum lesson shows a bad line made of 64 `a` characters. This recipe keeps the good path, because a release script should prove the round trip before you depend on the failure path.

The three bytes `a`, `b`, and `c` with no newline are the SHA-256 test vector everyone publishes. Including a newline, which `echo` often adds and `printf 'abc'` does not, produces a different digest. The example uses `/usr/bin/printf 'abc'` so the newline is absent. If your check fails against a published vector, dump the file with `od -An -tx1` and count the bytes before you blame the hash.

Text mode and binary mode matter on platforms that translate newlines. On GNU/Linux they hash the same bytes and the marker in the output differs: two spaces versus a space and an asterisk. Check with the same mode you wrote. A manifest generated on Linux and checked with a tool that expects the BSD label will fail at parse time, before any byte is compared.

## Steps

```run
# title: Digest of abc
/usr/bin/printf 'abc' > blob
/usr/bin/sha256sum blob
```

```run
# title: Check the manifest
/usr/bin/printf 'abc' > blob
/usr/bin/sha256sum blob > MANIFEST
/usr/bin/sha256sum -c MANIFEST
```

## Check yourself

```exercise
expect-exit: 0
---title---
Round-trip a digest
---prompt---
Write `abc` with no newline, save sha256sum output, and check it.
---hint---
`printf`, not echo.
---solution---
The check prints `blob: OK`.
---script---
/usr/bin/printf 'abc' > blob
/usr/bin/sha256sum blob > MANIFEST
/usr/bin/sha256sum -c MANIFEST
```

## Performance

SHA-256 of a small file is startup noise. SHA-256 of a multi-gigabyte image is a streaming read and a CPU-bound compression of that read into 32 bytes. It does not benefit from locale settings. Running it twice to "be sure" doubles the read and does not change the mathematics. The checksum benchmark on the benchmark page compares algorithms on one 8 MiB input, warm cache, five trials, and tells you not to treat the absolute seconds as a disk measurement. Pick SHA-256 for a new manifest unless you are matching a vendor file that already published a different algorithm. Matching the vendor is more important than the microbenchmark.
