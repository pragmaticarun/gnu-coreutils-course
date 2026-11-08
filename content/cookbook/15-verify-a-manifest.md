---
number: 15
slug: verify-a-manifest
title: Verify a manifest before you trust the file
module: Cookbook
level: intermediate
minutes: 15
summary: sha256sum -c is the gate. A matching file prints OK. A rewritten file fails the check and the script stops.
manual: sha256sum invocation | https://www.gnu.org/software/coreutils/manual/html_node/sha256sum-invocation.html
gnu_vs_bsd: |
  GNU `sha256sum -c` understands the two-space text-mode line this recipe writes. BSD check tools want their own label. A mismatch exits non-zero and prints FAILED. This recipe ran GNU sha256sum. It does not download anything.
---

The point of a manifest is the check you run before the next step, not the file you printed and forgot. `sha256sum blob > MANIFEST` records the digest and the name. `sha256sum -c MANIFEST` recomputes it. With `set -e`, a failed check stops the script, which is what you want in a build that is about to unpack an NDK archive or flash an image. The recipe does both the good check and a deliberate mismatch so the statuses are visible.

The mismatch is local. The script writes `payload`, records the digest, overwrites the file with `other`, and checks. The failed check prints `FAILED` and a warning about the computed digest. The status is non-zero. The example uses `set +e` only so it can print that status and continue. A real script leaves `set -e` on and does not continue.

Paths in the manifest are relative to the directory you run `-c` from. Generate and check in the same directory, or write the paths you will actually use. A check that fails because you changed directories is still a failed check. Fix the path. Do not pass `--ignore-missing` to paper over a file you thought you had.

`md5sum` has the same shape and a weaker hash. Use it when you are matching an old vendor file. Use SHA-256 when you are choosing. The checksum lesson lists the algorithms this `cksum` supports. `cksum` without `-a` is the traditional CRC, not SHA-256. Read the label before you compare it to a web page.

## Steps

```run
# title: A matching file
/usr/bin/printf 'payload\n' > blob
/usr/bin/sha256sum blob > MANIFEST
/usr/bin/sha256sum -c MANIFEST
```

```run
# title: A rewritten file fails
/usr/bin/printf 'payload\n' > blob
/usr/bin/sha256sum blob > MANIFEST
/usr/bin/printf 'other\n' > blob
set +e
/usr/bin/sha256sum -c MANIFEST
/usr/bin/printf 'status:%s\n' $?
set -e
```

## Check yourself

```exercise
expect-exit: 0
---title---
Check a fresh manifest
---prompt---
Write `payload` plus a newline, record sha256sum, and check it.
---hint---
Do not modify the file between the two commands.
---solution---
The line says `blob: OK`.
---script---
/usr/bin/printf 'payload\n' > blob
/usr/bin/sha256sum blob > MANIFEST
/usr/bin/sha256sum -c MANIFEST
```

## Performance

Checking a digest reads the whole file once. That read is the lower bound on "are these the bytes I hashed". Skipping it saves the read and accepts corruption. For a small artifact the read is cheaper than the outage. For a huge disk image the read is minutes, and those minutes are still cheaper than flashing the wrong image. The algorithm benchmark compares hash functions on 8 MiB so you can see CPU differences without pretending the ranking survives a different file size and a cold disk. Run one check, not two, unless the two files are different. `sha256sum -c` already recomputes.
