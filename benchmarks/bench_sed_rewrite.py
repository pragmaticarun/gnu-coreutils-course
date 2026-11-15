#!/usr/bin/env python3
"""Compare sed -i with a streaming redirect. Both variants pay for one cp."""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import SEED, TRIALS, interpret, run_command, write_variant


def main() -> None:
    work = Path(sys.argv[1])
    base = work / "base.txt"
    line = b"alpha beta gamma delta\n"
    target = 2 * 1024 * 1024
    base.write_bytes(line * (target // len(line)))
    inplace = (
        f"cp {base} {work}/edit && sed -i 's/a/A/g' {work}/edit"
    )
    stream = (
        f"cp {base} {work}/copy && sed 's/a/A/g' {base} > {work}/stream"
    )
    variants = [
        write_variant(
            "cp then sed -i",
            [run_command(["bash", "-c", inplace], cwd=work) for _ in range(TRIALS)],
        ),
        write_variant(
            "cp then sed redirect",
            [run_command(["bash", "-c", stream], cwd=work) for _ in range(TRIALS)],
        ),
    ]
    note = interpret(variants)
    note += (
        f" Base file is {base.stat().st_size} bytes. Seed constant {SEED} is unused. "
        "Both variants copy the base file once, then edit. sed -i writes a temporary "
        "sibling and renames it over the copy. The redirect writes a new file from the "
        "original. This is a warm-cache rewrite of a small text file, not a claim about "
        "a multi-gigabyte log on a slow disk."
    )
    print(
        json.dumps(
            {
                "id": "sed-rewrite",
                "title": "sed -i versus a streaming redirect",
                "question": "With the same initial copy, does sed -i separate from sed writing a new file?",
                "input": f"{base.stat().st_size} bytes, {TRIALS} trials.",
                "variants": variants,
                "note": note,
            }
        )
    )


if __name__ == "__main__":
    main()
