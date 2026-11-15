#!/usr/bin/env python3
"""Time gzip, pigz, zstd, xz, and bzip2. Record output sizes from one extra pass."""

import json
import os
import random
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import SEED, TRIALS, interpret, run_command, write_variant


def compress_size(cmd: list[str]) -> int:
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, check=True)
    return len(proc.stdout)


def payload_commands(src: Path, threads: int) -> list[tuple[str, list[str]]]:
    return [
        ("gzip -6", ["gzip", "-c", "-n", "-6", str(src)]),
        ("pigz -p1 -6", ["pigz", "-c", "-n", "-6", "-p", "1", str(src)]),
        (f"pigz -p{threads} -6", ["pigz", "-c", "-n", "-6", "-p", str(threads), str(src)]),
        ("zstd -1 -T1", ["zstd", "-c", "-q", "-1", "-T1", str(src)]),
        (f"zstd -1 -T{threads}", ["zstd", "-c", "-q", "-1", f"-T{threads}", str(src)]),
        ("zstd -6 -T1", ["zstd", "-c", "-q", "-6", "-T1", str(src)]),
        ("xz -1", ["xz", "-c", "-1", str(src)]),
        ("bzip2 -1", ["bzip2", "-c", "-1", str(src)]),
    ]


def run_case(work: Path, src: Path, threads: int, bench_id: str, title: str, question: str) -> dict:
    jobs = payload_commands(src, threads)
    variants = []
    sizes = []
    for name, cmd in jobs:
        trials = [run_command(cmd, env={"LC_ALL": "C"}, cwd=work) for _ in range(TRIALS)]
        variants.append(write_variant(name, trials))
        # Size uses stdin so the timed argv form and this pass compress the same bytes.
        sizes.append(f"{name} {compress_size(cmd)} bytes")
    note = interpret(variants)
    note += (
        f" Uncompressed size {src.stat().st_size} bytes. One extra compression, not a trial, "
        f"produced these sizes: {'; '.join(sizes)}. Threads requested where a flag exists: {threads}. "
        f"nproc on this host is {os.cpu_count()}. gzip -n omits name and timestamp. "
        "The harness discards compressed bytes during the timed trials. Levels are the flags "
        "in the variant name, not the tools' defaults. This is warm cache, one machine, "
        "and not a reason to pick a format for a different file."
    )
    return {
        "id": bench_id,
        "title": title,
        "question": question,
        "input": f"{src.stat().st_size} bytes, seed {SEED}, {TRIALS} trials, thread cap {threads}.",
        "variants": variants,
        "note": note,
    }


def main() -> None:
    if len(sys.argv) < 3:
        raise SystemExit("usage: bench_compress.py WORKDIR compressible|random")
    work = Path(sys.argv[1])
    kind = sys.argv[2]
    threads = min(4, os.cpu_count() or 1)
    src = work / f"{kind}.bin"
    size = 1024 * 1024
    if kind == "compressible":
        line = b"build-id 0123456789abcdef warning: unused variable in parser\n"
        src.write_bytes((line * ((size // len(line)) + 1))[:size])
        payload = run_case(
            work,
            src,
            threads,
            "compress-compressible",
            "Compression of a repetitive log",
            "On 1 MiB of repeated log lines, how do gzip, pigz, zstd, xz -1, and bzip2 -1 compare?",
        )
    elif kind == "random":
        rng = random.Random(SEED)
        src.write_bytes(rng.randbytes(size))
        payload = run_case(
            work,
            src,
            threads,
            "compress-random",
            "Compression of incompressible bytes",
            "On 1 MiB from a seeded PRNG, how do the same compressors compare when the ratio cannot collapse?",
        )
    else:
        raise SystemExit(f"unknown kind {kind}")
    print(json.dumps(payload))


if __name__ == "__main__":
    main()
