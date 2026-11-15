#!/usr/bin/env python3
"""Compare xargs -P1, xargs -P N, and GNU parallel on many tiny checksums."""

import os
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import SEED, TRIALS, interpret, run_command, write_variant


def main() -> None:
    work = Path(sys.argv[1])
    folder = work / "files"
    folder.mkdir()
    names = []
    for index in range(120):
        path = folder / f"f{index:03d}.txt"
        path.write_text(f"payload-{index}\n")
        names.append(str(path))
    listing = work / "names.txt"
    listing.write_text("\n".join(names) + "\n")
    threads = min(4, os.cpu_count() or 1)
    jobs = [
        ("xargs -P1", f"xargs -P 1 -n 1 sha256sum < {listing}"),
        (f"xargs -P{threads}", f"xargs -P {threads} -n 1 sha256sum < {listing}"),
        (
            f"parallel -j{threads}",
            f"parallel --will-cite -j {threads} sha256sum :::: {listing}",
        ),
    ]
    variants = []
    env = {"LC_ALL": "C", "HOME": str(work)}
    for name, script in jobs:
        cmd = ["bash", "-c", script]
        trials = [run_command(cmd, env=env, cwd=work) for _ in range(TRIALS)]
        variants.append(write_variant(name, trials))
    note = interpret(variants)
    note += (
        f" {len(names)} files of one short line each. Seed constant {SEED} is not used to vary bytes. "
        f"Each file is a separate sha256sum process. Parallelism is {threads}, capped at 4 and at nproc "
        f"({os.cpu_count()}). GNU parallel is invoked with --will-cite so the citation notice is not "
        "part of the work. The checksums are discarded. This measures process overhead on tiny inputs. "
        "A multi-megabyte compression per file is a different experiment."
    )
    print(
        json.dumps(
            {
                "id": "xargs-parallel",
                "title": "xargs -P versus GNU parallel on tiny processes",
                "question": "When each job is a checksum of a few bytes, does a process pool separate from one-at-a-time xargs?",
                "input": f"{len(names)} files, {TRIALS} trials, up to {threads} workers.",
                "variants": variants,
                "note": note,
            }
        )
    )


if __name__ == "__main__":
    main()
