#!/usr/bin/env python3
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import SEED, TRIALS, interpret, run_command, write_variant


def build(work: Path) -> Path:
    rng = random.Random(SEED)
    words = ["alpha", "Beta", "gamma", "Delta", "epsilon", "Zed"]
    path = work / "words.txt"
    lines = [rng.choice(words) + f" {rng.randrange(10000)}\n" for _ in range(100000)]
    path.write_text("".join(lines))
    return path


def main() -> None:
    work = Path(sys.argv[1])
    path = build(work)
    variants = []
    for name, locale in (("LC_ALL=C", "C"), ("LC_ALL=en_US.UTF-8", "en_US.UTF-8")):
        trials = [
            run_command(["sort", str(path)], env={"LC_ALL": locale}, cwd=work)
            for _ in range(TRIALS)
        ]
        variants.append(write_variant(name, trials))
    note = interpret(variants)
    note += (
        " LC_ALL=C selects a simple byte collation. en_US.UTF-8 uses the locale's "
        "multi-level rules. A difference here is about this 100000-line input in a "
        "warm page cache, not a promise that C is always the right order or always faster."
    )
    print(
        __import__("json").dumps(
            {
                "id": "sort-locale",
                "title": "sort under C versus en_US.UTF-8",
                "question": "On a fixed 100000-line file, how do the two collations compare on this host?",
                "input": f"100000 lines, seed {SEED}, vocabulary of 6 words plus an integer. {TRIALS} trials each. Output discarded by the harness.",
                "variants": variants,
                "note": note,
            }
        )
    )


if __name__ == "__main__":
    main()
