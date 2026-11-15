# GNU Coreutils Workbench

A static course in GNU coreutils for day-to-day work on Ubuntu: file trees, text, checksums, and the process wrappers around a C++, Rust, or Android build. Lessons, a scenario cookbook, and a utility reference. Command output on the pages was captured by running the scripts, not typed from memory.

Tested tools: `ls (GNU coreutils) 9.4`, Ubuntu package `9.4-3ubuntu6.3`. Local manual: `/usr/share/info/coreutils.info.gz` (coreutils 9.4). HTML links point at the GNU manual on gnu.org, which can describe newer flags than 9.4. Every flag in a captured script was present in `--help` on the capture host.

Capture host, as recorded by the generator: `Linux 6.12.113+ x86_64`, locale `en_US.UTF-8`, `df -T` type `ext4`, `stat -f -c %T` string `ext2/ext3` (shared statfs type code). The nodename is not recorded. BSD and macOS commands were not executed. Those notes are documented differences.

## What is in the course

| | |
| --- | ---: |
| Lessons | 41 |
| Captured lesson examples | 172 |
| Lesson exercises with solutions | 128 |
| Cookbook recipes | 19 |
| Cookbook examples | 38 |
| Cookbook exercises | 22 |
| Reference entries | 105 |
| Lesson prose | 31,201 words |
| Cookbook prose | 6,531 words |

Companions, checked as `/usr/bin/<name>` so a shell builtin cannot impersonate them:

| Command | On this host |
| --- | --- |
| find, xargs | findutils |
| grep | grep |
| sed | sed |
| awk | mawk (via alternatives) |
| tar | tar |
| hostname | hostname package, not coreutils |
| kill, uptime | procps, not coreutils |
| rsync, perf, `/usr/bin/time` | not installed |

`time` in bash is a keyword. The benchmark helper uses Python `resource.ru_maxrss`, not GNU time.

## Run it locally

Node 22 and npm. The captured JSON is already in the tree, so a local build does not need to re-execute the sandboxes.

```bash
npm ci
npm run dev
```

The dev server listens on `http://127.0.0.1:41827`.

```bash
npm run build
python3 scripts/check_export.py
```

`npm run build` writes a static site to `out/` with an empty base path, which is what you want for a local static server at `/`.

Refresh captures only on a machine with the same coreutils package if you want the prose and the stdout to stay in agreement. `nproc`, reflink support, and the kernel line are host-specific.

```bash
python3 scripts/assemble.py
```

That regenerates `content/generated/course.json`, `public/search-index.json`, `public/downloads/`, and `public/benchmarks/sample-run.json`. It runs every example in a temp directory and then the benchmark scripts. It refuses a few destructive patterns (`rm -rf /`, `mkfs`, writing to block devices, dropping caches). It does not need root.

## Benchmark sample

Seed `20261108`, 5 trials, median, warm page cache, no root, no `drop_caches`. Elapsed time includes a short Python helper that starts the command, except the buffering trial, which measures time to first byte of a small stdio harness and records user and RSS as 0. Inputs stay at or below 8 MiB plus sort's own buffer. If the gap between medians is within the widest trial spread, the script says the run does not separate the variants.

| Benchmark | What this run showed |
| --- | --- |
| Locale sort, 100,000 lines | `LC_ALL=C` median 0.0216s, `en_US.UTF-8` median 0.1221s. Gap 0.1005s, widest spread 0.0030s. |
| `sort --parallel`, 120,000 lines | `--parallel=1` 0.0430s, `--parallel=2` 0.0431s. Gap inside the spread. Not separated. |
| `sort -S`, 160,000 lines | `-S 32M` 0.0286s (max RSS 16408 KiB), `-S 1M` 0.0447s (11412 KiB). Gap larger than the spread on this input. |
| Checksums, 8 MiB | `sha256sum` 0.0067s, `b2sum` 0.0100s, `md5sum` 0.0138s elapsed. `md5sum` spent more system time. Not a general ranking. |
| `wc`, 200,000 ASCII lines | `-c` 0.0009s, `-l` 0.0017s, `-m` 0.0141s. |
| Copy, 8 MiB, reflink unavailable | `cp --reflink=never` 0.0125s, `dd bs=64k` 0.0140s. Gap inside the spread. Not separated. |
| stdio time-to-first-byte | default block buffering 0.4014s, `stdbuf -oL` 0.0012s, on the harness, not on `cat`. |

Scripts live in `benchmarks/` and are copied to `public/downloads/benchmarks/`.

### Supplement run, kept separate

`python3 benchmarks/measure_supplements.py` writes `public/benchmarks/supplements.json`. It does not rewrite `sample-run.json`. Same harness style: 5 trials, median, warm cache, no root, no `drop_caches`, elapsed time includes the Python starter. The disclosure in that file is the one that applies. These medians are not predictions, and they are not part of the table above.

| Question | What the supplement file recorded |
| --- | --- |
| `wc -c` versus `cat \| cat \| cat \| wc -c`, 8 MiB of zeros | `wc -c` median 0.0008s, pipeline median 0.0054s. Gap 0.0046s, widest spread 0.0014s. |
| One `/usr/bin/true` versus 400 sequential execs | one call median 0.0008s, 400 calls median 0.1740s. Gap 0.1731s, widest spread 0.0095s. |
| `cp --sparse=always` versus `--sparse=never` on an 8 MiB hole | always median 0.0010s, never median 0.0135s. Gap 0.0126s, widest spread 0.0115s. Untimed `du -B1` was 0 bytes and 8388608 bytes. |

Scenario checks that refuse to run as root live in `public/sandbox/`. `npm test` runs `scripts/validate_content.py`, which executes those scripts and checks the supplement disclaimer.

## GitHub Pages

The workflow is `.github/workflows/pages.yml`. It checks out the repo, installs Node 22, runs `npm ci` and `npm run build`, and deploys `out/` with the official Pages actions. It does **not** re-run the sandbox. Re-running the examples on a GitHub-hosted runner would replace captured stdout (processor count, filesystem, username) with that runner's output and could contradict the lesson text.

Base path, chosen at build time via `NEXT_PUBLIC_BASE_PATH`:

- Repository variable `BASE_PATH` set to `/` means the site root (custom domain or user site).
- Any other non-empty `BASE_PATH` is used after stripping a trailing slash. Example: `/course`.
- If `BASE_PATH` is unset and the repository name is `<owner>.github.io`, the base path is empty.
- Otherwise the base path is `/<repository-name>`.

`next.config.ts` sets `basePath` and `assetPrefix` from that value, and turns `/` into an empty path. A local check with `NEXT_PUBLIC_BASE_PATH=/coreutils-workbench` produced `href="/coreutils-workbench/lessons/orientation/"` and `/coreutils-workbench/_next/...` asset URLs. Next's `Link` and the `withBase()` helper both honor the prefix. The default build in this tree uses an empty base path.

The published site is [https://pragmaticarun.github.io/gnu-coreutils-course/](https://pragmaticarun.github.io/gnu-coreutils-course/). Pushes to `main` run the Pages workflow, which builds with base path `/gnu-coreutils-course`. A local build leaves `NEXT_PUBLIC_BASE_PATH` unset, so `out/` is served at `/`.

If the site should live at the root of a custom domain, set the repository variable `BASE_PATH` to `/` and configure the domain in Pages. Push again so the site rebuilds with the new prefix.

## Limits

- No example targeted `/`, a block device, or another user's files. `rm --preserve-root` was not disabled.
- Caches were not dropped. No sysctl. Benchmarks are warm-cache numbers.
- `cp --reflink=always` fails here with "Operation not supported". `--reflink=auto` copies.
- `chown` to another user, device `mknod`, and SELinux changes are not available. `/usr/sbin/chroot` is installed and is coreutils, but no example calls it to change the root directory. `id -Z` and `runcon` fail because SELinux is off. `stty` was not pointed at a terminal.
- `shred -u -n 1` removes a scratch name. It does not prove bytes are gone from an SSD, a journal, or a snapshot.
- `sort -u` and `sort | uniq` differ when the key is narrower than the line. `cut` does not parse CSV quotes.
- `stdbuf` does not change `cat` or `dd`, which do not use stdio for their data.
- SHA-256 of the bytes `abc` (no newline) is the usual test vector. A trailing newline is a different digest.
