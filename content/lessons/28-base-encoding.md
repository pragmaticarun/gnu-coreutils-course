---
number: 28
slug: base-encoding
title: base64, base32, and basenc
module: Integrity and encoding
level: intermediate
minutes: 26
summary: These tools transform bytes into ASCII and back. They do not encrypt. GNU base64 wraps columns unless -w 0. basenc 9.4 has no base58.
objectives:
  - Encode and decode base64, including whitespace with -i
  - Turn wrapping off with -w 0
  - Use basenc --base64url and a valid z85 length
  - Show that --base58 is rejected by this version
manual: base64 invocation | https://www.gnu.org/software/coreutils/manual/html_node/base64-invocation.html
manual: basenc invocation | https://www.gnu.org/software/coreutils/manual/html_node/basenc-invocation.html
gnu_vs_bsd: |
  GNU `base64 -d` decodes and `-w` sets the wrap. macOS `base64` uses `-D` to decode and does not take `-w`. `base32` and `basenc` are GNU. coreutils 9.4 `basenc` supports base64, base64url, base32, base32hex, base16, base2msbf, base2lsbf, and z85. It does not support base58. That absence was checked with `--help` and with a rejected flag in the example. No BSD base64 was run.
---

Encoding is a reversible spelling of bytes. Encryption is a different operation that needs a key. `base64` of a token is still the token, readable to anyone who decodes it. Use it so a binary blob can sit in a text file or a header. Do not use it as a secrecy mechanism.

GNU `base64` wraps at 76 columns by default. `-w 0` emits one line, which is what you want in a JSON string or a shell variable. `-d` decodes. `-i` ignores garbage characters such as whitespace inside the input. Without `-i`, a wrapped or spaced payload can fail the decoder depending on where the extra characters sit. The example decodes `aGVs bG8=` with `-i` back to `hello`.

`base32` is the RFC 4648 alphabet, used where the result must be case-insensitive. `-w 0` matters there too. `basenc` is the multi-alphabet tool. `--base64url` uses the URL-safe alphabet. `--z85` is the ZeroMQ alphabet and requires an input length that is a multiple of 4 for encoding. `printf 'hell'` works. `printf 'hello'` is five bytes and `basenc --z85` rejects it. That constraint is in the tool, not in the shell.

`--base58` is not in this 9.4 `basenc`. Passing it exits non-zero and names an invalid option. Bitcoin-style base58 lives elsewhere. If a blog shows `basenc --base58` and your `--help` does not list it, you do not have that feature. Do not install a random package to follow the blog in the middle of a coreutils lesson.

Decoding a truncated payload fails. Check the status. A script that ignores a decode error will feed an empty or partial file to the next stage and then checksum the wrong bytes.

## Worked examples

### One line, then decode

```run
# title: base64 -w 0 and -d
/usr/bin/printf 'hello world' | /usr/bin/base64 -w 0
/usr/bin/printf '\n'
/usr/bin/printf 'aGVsbG8gd29ybGQ=' | /usr/bin/base64 -d
/usr/bin/printf '\n'
```

### Ignore whitespace

```run
# title: base64 -d -i
/usr/bin/printf 'aGVs bG8=\n' | /usr/bin/base64 -d -i
/usr/bin/printf '\n'
```

### URL-safe and z85

```run
# title: basenc alphabets that exist here
/usr/bin/printf 'hi?' | /usr/bin/basenc --base64url -w 0
/usr/bin/printf '\n'
/usr/bin/printf 'hell' | /usr/bin/basenc --z85
/usr/bin/printf '\n'
```

### base58 is absent

```run
# title: This basenc rejects --base58
# expect-exit: 1
/usr/bin/basenc --base58
```

## Recipes

Embed a small binary fixture in a test by storing the `base64 -w 0` line next to the test and decoding it in the setup. Checksum the decoded bytes so a truncated paste fails the test.

When an HTTP API wants base64url, use `basenc --base64url` rather than `tr` of `+/` to `-_`, which is easy to get wrong on the padding. If you do transform padding, test a length that needs padding.

## Tips and pitfalls

`base64 file > file.b64` is fine. `base64 file > file` destroys the input because the shell truncates the destination first. Same rule as `cat`.

z85's length rule is on the raw bytes for encoding. A failed z85 of `hello` is not a broken install.

`base32` output uses a different alphabet. Feeding it to `base64 -d` fails. Name the decoder that matches the encoder.

## Exercises

```exercise
expect-exit: 0
---title---
Encode hi
---prompt---
base64-encode `hi` as a single line.
---hint---
`-w 0`.
---solution---
The alphabet is the standard base64 spelling of those two bytes.
---script---
/usr/bin/printf 'hi' | /usr/bin/base64 -w 0
/usr/bin/printf '\n'
```

```exercise
expect-exit: 0
---title---
Decode hello
---prompt---
Decode `aGVsbG8=` and print a newline after it so the capture is a clean line.
---hint---
`base64 -d`.
---solution---
The bytes are `hello`.
---script---
/usr/bin/printf 'aGVsbG8=' | /usr/bin/base64 -d
/usr/bin/printf '\n'
```

```exercise
expect-exit: 1
---title---
Reject a missing alphabet
---prompt---
Run `basenc --base58` and let it fail.
---hint---
9.4 does not list base58 in --help.
---solution---
Invalid option, non-zero status. The feature is not hiding behind another flag name in this version.
---script---
/usr/bin/basenc --base58
```

## Performance

Encoding expands data by a constant factor and is limited by memory bandwidth on large files. It is not the slow part of a build next to compression or a hash you also compute. Decoding a huge blob into a temporary file costs the write. Doing it in a shell loop per line of a multi-megabyte manifest costs a process per line, which dominates. One `base64 -d` of a concatenated payload is the coreutils-shaped solution. A language library is the right solution when you already hold the bytes in a Rust buffer and do not want to spawn a process. There is no secret faster alphabet. base64url is not quicker than base64 in any way that matters. It exists so the text survives a URL.
