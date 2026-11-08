---
number: 13
slug: reproducible-shuf
title: Repeat a shuffle with --random-source
module: Cookbook
level: advanced
minutes: 15
summary: shuf has no --seed flag. The same --random-source file produces the same permutation. /dev/zero is deterministic and is not entropy.
manual: shuf invocation | https://www.gnu.org/software/coreutils/manual/html_node/shuf-invocation.html
gnu_vs_bsd: |
  GNU `shuf` takes randomness from `--random-source`, a file it reads as a byte stream. There is no `--seed` in coreutils 9.4. BSD `jot -r` and other shufflers use different flags. `/dev/zero` makes the run repeatable and is a terrible secret. This recipe ran GNU shuf.
---

`shuf` prints a permutation of its input. Two runs without a fixed random source differ, which is what you want for a real sample and what you do not want for a test. There is no `--seed` option in this version. Reproducibility is `--random-source=FILE`. The file is read as raw bytes. The same file and the same input produce the same permutation, which the recipe checks with `sha256sum` of the two outputs. `/dev/zero` is a convenient infinite file of zero bytes. It is deterministic. It is not a secret and it is not a high-quality random stream. Use it for tests. Use `/dev/urandom`, or a file you generated once and checked in, when you understand which of those you need.

`sort -R` is the other GNU tool that shuffles, and it also accepts `--random-source`. Its order is not required to match `shuf` even with the same source. Pick one tool and keep it. Do not mix them in a golden test.

`shuf -n 2` prints a sample of two lines rather than a full permutation. The sample is still a function of the random source. A test that only checks the count, not the identity, can use `-n`. A test that checks the identity must fix the source.

An empty input produces empty output and exits 0. A missing random source fails. Quote the path if it contains spaces. The source is a filename, not a seed integer, so do not pass `20261108` and expect it to be parsed as a number. That string would be opened as a file and fail.

## Steps

```run
# title: Two shuffles from /dev/zero match
/usr/bin/printf 'a\nb\nc\nd\n' > names
/usr/bin/shuf --random-source=/dev/zero names > one
/usr/bin/shuf --random-source=/dev/zero names > two
/usr/bin/sha256sum one two
```

```run
# title: A short sample still uses the source
/usr/bin/printf 'a\nb\nc\nd\n' > names
/usr/bin/shuf -n 2 --random-source=/dev/zero names
```

## Check yourself

```exercise
expect-exit: 0
---title---
Repeat a four-line shuffle
---prompt---
Shuffle `a` through `d` twice with `--random-source=/dev/zero` and hash both outputs.
---hint---
The digests match because the source bytes match.
---solution---
`sha256sum` prints one digest twice. `/dev/zero` is not entropy.
---script---
/usr/bin/printf 'a\nb\nc\nd\n' > names
/usr/bin/shuf --random-source=/dev/zero names > one
/usr/bin/shuf --random-source=/dev/zero names > two
/usr/bin/sha256sum one two
```

## Performance

Shuffling a few lines is instant. Shuffling a file larger than memory is a disk problem, because `shuf` has to hold the permutation. `-n` with a reservoir is the mode that avoids storing every line when you only want a sample, and the manual describes the limits. Do not read `/dev/zero` as a performance trick. It is an infinite file of zeros, and shuf only reads as many bytes as its algorithm needs. Pointing a cryptographic generator at a unit test slows the test and does not make the assertion stronger once the source is fixed. The benchmark seed on this site (`20261108`) belongs to the benchmark scripts, which do not call `shuf`.
