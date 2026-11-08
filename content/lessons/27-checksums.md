---
number: 27
slug: checksums
title: Checksums and manifests
module: Integrity and encoding
level: intermediate
minutes: 32
summary: sha256sum is the usual manifest tool. md5sum is a legacy check. cksum's default is still a CRC and a byte count. A faster digest is not a better one.
objectives:
  - Compute SHA-256 of the bytes abc and match the known test vector
  - Verify a manifest and show a FAILED line with status 1
  - Read cksum's historical CRC line versus cksum -a sha256 --tag
  - Distinguish sum, md5sum, and b2sum by job, not by speed
manual: sha2 utilities | https://www.gnu.org/software/coreutils/manual/html_node/sha2-utilities.html
manual: cksum invocation | https://www.gnu.org/software/coreutils/manual/html_node/cksum-invocation.html
manual: md5sum invocation | https://www.gnu.org/software/coreutils/manual/html_node/md5sum-invocation.html
gnu_vs_bsd: |
  GNU `sha256sum` prints `DIGEST  NAME` with two spaces for text mode. BSD tools such as `sha256 -r` or `shasum` use different line layouts. A GNU `--check` will not accept a foreign line unless it matches the format the manual describes. macOS has no `sha256sum` in the base system. `cksum -a` is GNU. The digests below are GNU coreutils 9.4. Algorithm test vectors are properties of the hash, not of the vendor.
---

A checksum tool reads bytes and writes a digest. `sha256sum` is the coreutils program to put in a download page or a firmware manifest. The digest of the three bytes `abc` (no newline) is `ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad`. The example prints that line. If you include a newline in the file, you are hashing different bytes and the digest must change. `printf 'abc'` and `printf 'abc\n'` are not the same input.

`--check` reads a manifest and recomputes. A match prints `OK` unless `--status` or `--quiet` suppresses it. A mismatch prints `FAILED`, a warning, and status 1. `--status` is what a script wants, because the exit status is the result and stdout stays empty. The manifest format is part of the contract. A line that is not a digest line at all produces "no properly formatted checksum lines found" rather than FAILED. Two spaces versus a space-star (text versus binary marker) matters. When you generate and check with the same tool, you stay inside the format.

`md5sum` has the same interface and a broken collision story. Use it to verify an old file that was published with an MD5. Do not choose it for a new artifact. `sha1sum` is in the same category for new designs: SHA-1 collisions are practical. `sha224sum`, `sha384sum`, and `sha512sum` are the other SHA-2 lengths. Pick the one the protocol names.

`b2sum` is BLAKE2b. `cksum` without `-a` prints the historical POSIX CRC and the byte count, not a cryptographic digest. `cksum -a sha256 --tag` prints a BSD-style tagged line. `cksum -a` also selects md5, sha1, the SHA-2 family, blake2b, sm3, and the old `sum` algorithms. `sum -r` and `sum -s` are the legacy BSD and System V checksums. They are not interchangeable with each other or with SHA-256. `md5sum.textutils` on this system is a symlink to `md5sum`, not a second algorithm.

The checksum benchmark times md5sum, sha256sum, and b2sum on one 8 MiB warm file. A lower median does not promote that algorithm. The note on the benchmark page says this explicitly.

## Worked examples

### The abc test vector

```run
# title: SHA-256 of abc
/usr/bin/printf 'abc' | /usr/bin/sha256sum
```

### A good check and a bad hash

```run
# title: --check success and failure
/usr/bin/printf 'abc' > payload
/usr/bin/sha256sum payload > good
/usr/bin/sha256sum -c good
set +e
/usr/bin/printf 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  payload\n' | /usr/bin/sha256sum -c -
/usr/bin/printf 'bad:%s\n' $?
set -e
```

### CRC versus a tagged SHA-256

```run
# title: cksum default and cksum -a sha256 --tag
/usr/bin/printf 'abc' | /usr/bin/cksum
/usr/bin/printf 'abc' | /usr/bin/cksum -a sha256 --tag
```

### Legacy sum is a different number

```run
# title: sum -r and sum -s
/usr/bin/printf 'abc' | /usr/bin/sum -r
/usr/bin/printf 'abc' | /usr/bin/sum -s
/usr/bin/printf 'abc' | /usr/bin/b2sum
```

## Recipes

In a release job, hash the bytes you ship: `sha256sum --binary` or the default text mode, consistently, and store the manifest next to the artifact. Verify in CI with `sha256sum --status -c manifest`. For names that contain newlines, generate with `--zero` and check with the matching flag. Do not `cut` a zero-terminated manifest as if it were lines.

Android APK and Rust crate files are just bytes. The hash does not know they are zip archives. If you need a hash of the uncompressed contents, unpack first with a tool that understands the format (`tar` or an unzip, neither of which is coreutils) and then hash.

## Tips and pitfalls

Hashing `abc\n` because you used `echo abc` is the usual test-vector miss. The shell lesson and the printf lesson exist so the bytes are the bytes you named.

`--tag` output and the default two-space output are both checkable by the same family when the line is well formed. Mixing a macOS `shasum` line into `sha256sum -c` fails the format check. Translate deliberately, do not "fix" it by ignoring status.

`cksum` of a file and `wc -c` answer different questions. The CRC line includes a size. It is not SHA-256 shortened.

## Exercises

```exercise
expect-exit: 0
---title---
Hash three bytes
---prompt---
Print the sha256sum of `abc` with no newline.
---hint---
printf, not echo.
---solution---
The digest matches the known test vector. A trailing newline would not.
---script---
/usr/bin/printf 'abc' | /usr/bin/sha256sum
```

```exercise
expect-exit: 0
---title---
Verify a file you just hashed
---prompt---
Write `abc` to `payload`, hash it to `manifest`, and `--check` the manifest.
---hint---
`sha256sum payload > manifest` then `sha256sum -c manifest`.
---solution---
The OK line is the success text. `--status` would have stayed quiet.
---script---
/usr/bin/printf 'abc' > payload
/usr/bin/sha256sum payload > manifest
/usr/bin/sha256sum -c manifest
```

```exercise
expect-exit: 1
---title---
Detect a wrong digest
---prompt---
Create `payload` with `abc` and check a manifest whose digest is 64 `a` characters and the name `payload`.
---hint---
Two spaces between the digest and the name. The status must be non-zero.
---solution---
FAILED, plus a warning, status 1.
---script---
/usr/bin/printf 'abc' > payload
/usr/bin/printf 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  payload\n' | /usr/bin/sha256sum -c -
```

## Performance

Hash throughput is CPU and how the bytes get to the CPU. A warm page cache, which is what the benchmark uses, measures the hash and the read from RAM. A cold disk measures the disk. Reporting one number as "sha256sum's speed" without saying which is a category error. md5sum doing less cryptographic work can finish sooner and still be the wrong choice. b2sum can be faster than sha256sum on some CPUs and slower on others. The sample run on the benchmark page is one machine. Use it to learn the method, then rerun the script on the machine that will do the work if the number matters. Parallel hashing of independent files is multiple processes, which you can schedule yourself. A single `sha256sum` of one file is one stream.
