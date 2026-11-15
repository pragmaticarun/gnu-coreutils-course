#!/usr/bin/env python3
"""Time one /usr/bin/true against 400 sequential execs of the same binary."""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import SEED, TRIALS, interpret, run_command, write_variant


def main() -> None:
    work = Path(sys.argv[1])
    many = [
        "bash",
        "-c",
        "i=0; while [ \"$i\" -lt 400 ]; do /usr/bin/true; i=$((i+1)); done",
    ]
    variants = [
        write_variant(
            "one /usr/bin/true",
            [run_command(["/usr/bin/true"], cwd=work) for _ in range(TRIALS)],
        ),
        write_variant(
            "400 x /usr/bin/true",
            [run_command(many, cwd=work) for _ in range(TRIALS)],
        ),
    ]
    note = interpret(variants)
    note += (
        " true does no file IO. The 400-call sample is one bash -c loop of "
        "/usr/bin/true, not the shell builtin. Elapsed time includes this Python "
        "harness. The gap is process startup on this machine. It is not a "
        f"prediction, and the unused seed is {SEED}."
    )
    print(
        json.dumps(
            {
                "id": "process-startup",
                "title": "Process startup against /usr/bin/true",
                "question": "What does a loop of 400 trivial coreutils processes cost next to one exec, on this host?",
                "input": f"{TRIALS} trials. The loop is bash -c. No input file.",
                "variants": variants,
                "note": note,
            }
        )
    )


if __name__ == "__main__":
    main()
