#!/usr/bin/env python3
"""Compare grep -F and a small regex, in C and UTF-8 locales."""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import SEED, TRIALS, interpret, run_command, write_variant


def main() -> None:
    work = Path(sys.argv[1])
    path = work / "log.txt"
    needle = "NEEDLE-TOKEN"
    plain = "info build step alpha beta gamma delta epsilon\n"
    parts = []
    # About 4 MiB of ASCII, with a needle every 40 lines. Seed is recorded, not mixed in.
    target = 4 * 1024 * 1024
    while sum(len(part) for part in parts) < target:
        parts.append(plain * 40)
        parts.append(f"error {needle} at unit\n")
    path.write_text("".join(parts))
    variants = []
    jobs = [
        ("LC_ALL=C grep -F", ["grep", "-F", "-c", needle, str(path)], "C"),
        ("UTF-8 grep -F", ["grep", "-F", "-c", needle, str(path)], "en_US.UTF-8"),
        ("UTF-8 grep -E", ["grep", "-E", "-c", "NEE?DLE-TOKEN", str(path)], "en_US.UTF-8"),
    ]
    for name, cmd, locale in jobs:
        trials = [
            run_command(cmd, env={"LC_ALL": locale}, cwd=work) for _ in range(TRIALS)
        ]
        variants.append(write_variant(name, trials))
    note = interpret(variants)
    note += (
        f" Input is {path.stat().st_size} ASCII bytes with the fixed string {needle}. "
        f"Seed constant {SEED} is not used to vary bytes. grep -c exits 0 when the count "
        "is non-zero. The regex is one optional character, not a pathological pattern. "
        "This is a warm-cache CPU comparison on this build of GNU grep. It is not a "
        "ranking for binary files, -P, or a cold page cache."
    )
    print(
        json.dumps(
            {
                "id": "grep-fixed-locale",
                "title": "grep -F, locale, and a small regex",
                "question": "On one warm ASCII log, do LC_ALL=C, grep -F, and a tiny extended regex separate?",
                "input": f"{path.stat().st_size} bytes, needle every 40 lines, {TRIALS} trials.",
                "variants": variants,
                "note": note,
            }
        )
    )


if __name__ == "__main__":
    main()
