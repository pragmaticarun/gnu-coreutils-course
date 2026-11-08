#!/usr/bin/env python3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import SEED, TRIALS, interpret, run_command, write_variant


def main() -> None:
    work = Path(sys.argv[1])
    path = work / "text.txt"
    line = "alpha beta gamma delta epsilon\n"
    path.write_text(line * 200000)
    variants = []
    for flag, name in (("-c", "wc -c"), ("-l", "wc -l"), ("-m", "wc -m")):
        trials = [
            run_command(["wc", flag, str(path)], env={"LC_ALL": "en_US.UTF-8"}, cwd=work)
            for _ in range(TRIALS)
        ]
        variants.append(write_variant(name, trials))
    note = interpret(variants)
    note += (
        " This file is ASCII, so character and byte counts are the same quantity, but "
        "-m still walks the multibyte rules. If the medians do not separate, that is "
        "the result: do not invent a winner. A file full of non-ASCII would be a "
        "different experiment."
    )
    print(
        __import__("json").dumps(
            {
                "id": "wc",
                "title": "wc -c, wc -l, and wc -m",
                "question": "On a warm ASCII file, do byte, line, and character counts separate?",
                "input": f"200000 identical ASCII lines, seed constant {SEED} is not used to vary bytes, {TRIALS} trials.",
                "variants": variants,
                "note": note,
            }
        )
    )


if __name__ == "__main__":
    main()
