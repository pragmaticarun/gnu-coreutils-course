#!/usr/bin/env python3
"""Time GNU tar with and without --sparse on an 8 MiB hole, and record archive sizes."""

import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import SEED, TRIALS, interpret, run_command, write_variant


def main() -> None:
    work = Path(sys.argv[1])
    hole = work / "hole"
    subprocess.check_call(["truncate", "-s", "8M", str(hole)])
    apparent = hole.stat().st_size
    sparse_tar = work / "sparse.tar"
    plain_tar = work / "plain.tar"
    sparse_cmd = ["tar", "--sparse", "-cf", str(sparse_tar), "-C", str(work), "hole"]
    plain_cmd = ["tar", "--format=posix", "-cf", str(plain_tar), "-C", str(work), "hole"]
    variants = [
        write_variant(
            "tar --sparse",
            [run_command(sparse_cmd, cwd=work) for _ in range(TRIALS)],
        ),
        write_variant(
            "tar without --sparse",
            [run_command(plain_cmd, cwd=work) for _ in range(TRIALS)],
        ),
    ]
    note = interpret(variants)
    note += (
        f" Apparent size of the hole is {apparent} bytes. After the timed runs, "
        f"sparse.tar is {sparse_tar.stat().st_size} bytes and plain.tar is {plain_tar.stat().st_size} bytes. "
        f"Seed constant {SEED} is unused. truncate creates a hole; it does not write 8 MiB of zeros. "
        "The byte counts are archive sizes, not timings. This is one filesystem and one GNU tar."
    )
    print(
        json.dumps(
            {
                "id": "sparse-tar",
                "title": "GNU tar --sparse on an 8 MiB hole",
                "question": "Does storing the hole as a sparse archive separate from storing the zeros?",
                "input": f"apparent {apparent} bytes, {TRIALS} trials, no compression.",
                "variants": variants,
                "note": note,
            }
        )
    )


if __name__ == "__main__":
    main()
