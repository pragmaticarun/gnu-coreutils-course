#!/usr/bin/env python3
"""Time wc -c against the same file read through three extra cat processes."""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import SEED, TRIALS, interpret, run_command, write_variant


def main() -> None:
    work = Path(sys.argv[1])
    blob = work / "zeros.bin"
    blob.write_bytes(b"\0" * (8 * 1024 * 1024))
    direct = ["wc", "-c", str(blob)]
    pipeline = [
        "bash",
        "-c",
        f"cat {blob} | cat | cat | wc -c",
    ]
    variants = [
        write_variant("wc -c file", [run_command(direct, cwd=work) for _ in range(TRIALS)]),
        write_variant(
            "cat | cat | cat | wc -c",
            [run_command(pipeline, cwd=work) for _ in range(TRIALS)],
        ),
    ]
    note = interpret(variants)
    note += (
        " Both commands read the same 8388608 zero bytes that were just written, "
        "so the page cache is warm. The pipeline is a bash command and adds three "
        "cat processes. The harness discards stdout. This is process overhead on "
        "this input, not a reason to avoid a pipeline that filters, and not a "
        "prediction for another machine."
    )
    print(
        json.dumps(
            {
                "id": "pipeline-overhead",
                "title": "Extra cat processes in front of wc -c",
                "question": "On one warm 8 MiB file, how does wc -c compare with the same bytes through three cats?",
                "input": f"8388608 zero bytes, seed field unused ({SEED}), {TRIALS} trials. Pipeline runs under bash -c.",
                "variants": variants,
                "note": note,
            }
        )
    )


if __name__ == "__main__":
    main()
