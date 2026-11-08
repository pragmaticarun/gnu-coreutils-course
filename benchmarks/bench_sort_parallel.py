#!/usr/bin/env python3
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import SEED, TRIALS, interpret, run_command, write_variant


def main() -> None:
    work = Path(sys.argv[1])
    rng = random.Random(SEED)
    path = work / "parallel.txt"
    path.write_text("".join(f"{rng.randrange(1_000_000):07d}\n" for _ in range(120000)))
    variants = []
    for workers in (1, 2):
        trials = [
            run_command(
                ["sort", "-n", f"--parallel={workers}", str(path)],
                env={"LC_ALL": "C"},
                cwd=work,
            )
            for _ in range(TRIALS)
        ]
        variants.append(write_variant(f"--parallel={workers}", trials))
    note = interpret(variants)
    note += (
        " The manual says --parallel defaults to the number of available processors, "
        "capped at 8, and that more threads raise memory use by a factor of log N. "
        "These trials stop at 2 threads on purpose. They are not a tuning recommendation."
    )
    print(
        __import__("json").dumps(
            {
                "id": "sort-parallel",
                "title": "sort --parallel=1 and --parallel=2",
                "question": "On this numeric file, do one and two concurrent sorts separate on elapsed time?",
                "input": f"120000 seven-digit lines, seed {SEED}, LC_ALL=C, numeric sort, {TRIALS} trials.",
                "variants": variants,
                "note": note,
            }
        )
    )


if __name__ == "__main__":
    main()
