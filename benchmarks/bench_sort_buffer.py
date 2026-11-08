#!/usr/bin/env python3
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import SEED, TRIALS, interpret, run_command, write_variant


def main() -> None:
    work = Path(sys.argv[1])
    rng = random.Random(SEED)
    path = work / "buffer.txt"
    # About 4 MiB of text. -S sets the initial main-memory buffer.
    path.write_text("".join(f"key-{rng.randrange(1_000_000):07d} payload\n" for _ in range(160000)))
    variants = []
    for size in ("1M", "32M"):
        trials = [
            run_command(
                ["sort", "-S", size, "-T", str(work), str(path)],
                env={"LC_ALL": "C"},
                cwd=work,
            )
            for _ in range(TRIALS)
        ]
        variants.append(write_variant(f"-S {size}", trials))
    note = interpret(variants)
    note += (
        " The manual says -S sets the initial main-memory buffer. A bare number is in "
        "1024-byte units; M multiplies by 1,048,576. The buffer can still grow to hold "
        "a longer line. Temporary files, when needed, go to -T. This run does not count "
        "those files after the fact because sort removes them."
    )
    print(
        __import__("json").dumps(
            {
                "id": "sort-buffer",
                "title": "sort -S 1M and -S 32M",
                "question": "Does a larger initial buffer change the median on a roughly 4 MiB text file?",
                "input": f"160000 short lines, seed {SEED}, LC_ALL=C, -T set to the work directory, {TRIALS} trials.",
                "variants": variants,
                "note": note,
            }
        )
    )


if __name__ == "__main__":
    main()
