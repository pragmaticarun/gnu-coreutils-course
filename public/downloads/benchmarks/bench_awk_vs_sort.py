#!/usr/bin/env python3
"""Compare a mawk frequency count with sort | uniq -c."""

import json
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import SEED, TRIALS, interpret, run_command, write_variant


def main() -> None:
    work = Path(sys.argv[1])
    path = work / "keys.txt"
    rng = random.Random(SEED)
    lines = [f"mod-{rng.randrange(40)}\n" for _ in range(200000)]
    path.write_text("".join(lines))
    awk = [
        "/usr/bin/awk",
        "{c[$0]++} END {for (k in c) print c[k], k}",
        str(path),
    ]
    via_sort = [
        "bash",
        "-c",
        f"LC_ALL=C sort {path} | uniq -c",
    ]
    env = {"LC_ALL": "C"}
    variants = [
        write_variant(
            "mawk one pass",
            [run_command(awk, env=env, cwd=work) for _ in range(TRIALS)],
        ),
        write_variant(
            "sort | uniq -c",
            [run_command(via_sort, env=env, cwd=work) for _ in range(TRIALS)],
        ),
    ]
    note = interpret(variants)
    note += (
        f" {len(lines)} lines, 40 distinct keys, seed {SEED}, file {path.stat().st_size} bytes. "
        "/usr/bin/awk is mawk on this host. Both runs use LC_ALL=C. The harness discards "
        "stdout, so this does not check that the counts match; the lesson scripts check "
        "that on a small file. sort must order the whole file before uniq can count. "
        "mawk holds the key set in memory. A key set that does not fit in RAM is a "
        "different experiment."
    )
    print(
        json.dumps(
            {
                "id": "awk-vs-sort",
                "title": "mawk frequency count versus sort | uniq -c",
                "question": "On 200,000 short keys, does one mawk process separate from sort | uniq -c?",
                "input": f"{path.stat().st_size} bytes, 40 keys, seed {SEED}, {TRIALS} trials, LC_ALL=C.",
                "variants": variants,
                "note": note,
            }
        )
    )


if __name__ == "__main__":
    main()
