#!/usr/bin/env python3
"""Time cp --sparse=always against cp --sparse=never for an 8 MiB hole."""

import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import SEED, TRIALS, interpret, run_command, write_variant


def allocated(path: Path) -> int:
    text = subprocess.check_output(["du", "-B1", str(path)], text=True)
    return int(text.split()[0])


def main() -> None:
    work = Path(sys.argv[1])
    hole = work / "hole.bin"
    subprocess.check_call(["truncate", "-s", "8M", str(hole)])
    always = work / "probe-always.bin"
    never = work / "probe-never.bin"
    subprocess.check_call(["cp", "--sparse=always", str(hole), str(always)])
    subprocess.check_call(["cp", "--sparse=never", str(hole), str(never)])
    always_bytes = allocated(always)
    never_bytes = allocated(never)
    variants = [
        write_variant(
            "cp --sparse=always",
            [
                run_command(["cp", "--sparse=always", str(hole), str(work / "timed-always.bin")], cwd=work)
                for _ in range(TRIALS)
            ],
        ),
        write_variant(
            "cp --sparse=never",
            [
                run_command(["cp", "--sparse=never", str(hole), str(work / "timed-never.bin")], cwd=work)
                for _ in range(TRIALS)
            ],
        ),
    ]
    note = interpret(variants)
    note += (
        f" An untimed probe on the same hole reported du -B1 of {always_bytes} bytes "
        f"after --sparse=always and {never_bytes} bytes after --sparse=never. "
        "Those are allocated sizes, not elapsed times. Apparent size is 8388608 "
        "either way. This is one ext4 host with a warm cache and an 8 MiB hole. "
        f"Seed {SEED} is unused. It does not predict another filesystem."
    )
    print(
        json.dumps(
            {
                "id": "sparse-copy",
                "title": "Copying an 8 MiB hole with and without the hole",
                "question": "On this filesystem, how do cp --sparse=always and cp --sparse=never compare for one hole?",
                "input": (
                    f"truncate -s 8M, {TRIALS} trials, destination overwritten in the work directory. "
                    f"Untimed du -B1: always={always_bytes}, never={never_bytes}."
                ),
                "variants": variants,
                "note": note,
            }
        )
    )


if __name__ == "__main__":
    main()
