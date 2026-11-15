#!/usr/bin/env python3
"""Compare sha256sum pinned to CPU 0 with the same command unpinned."""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import SEED, TRIALS, interpret, run_command, write_variant


def main() -> None:
    work = Path(sys.argv[1])
    blob = work / "blob.bin"
    blob.write_bytes(b"a" * (8 * 1024 * 1024))
    plain = ["sha256sum", str(blob)]
    pinned = ["taskset", "-c", "0", "sha256sum", str(blob)]
    variants = [
        write_variant(
            "sha256sum",
            [run_command(plain, cwd=work) for _ in range(TRIALS)],
        ),
        write_variant(
            "taskset -c 0 sha256sum",
            [run_command(pinned, cwd=work) for _ in range(TRIALS)],
        ),
    ]
    note = interpret(variants)
    note += (
        f" Input is {blob.stat().st_size} identical bytes, seed constant {SEED} unused. "
        "taskset is util-linux, sha256sum is coreutils. The pin is CPU 0 only. "
        "No frequency scaling was changed. A single-threaded checksum often does not "
        "move when pinned; if this run does not separate the variants, that is the result."
    )
    print(
        json.dumps(
            {
                "id": "taskset-pin",
                "title": "sha256sum pinned to one CPU",
                "question": "On one warm 8 MiB buffer, does taskset -c 0 separate from an unpinned sha256sum?",
                "input": f"{blob.stat().st_size} bytes of 0x61, {TRIALS} trials.",
                "variants": variants,
                "note": note,
            }
        )
    )


if __name__ == "__main__":
    main()
