#!/usr/bin/env python3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import SEED, TRIALS, interpret, run_command, write_variant


def main() -> None:
    work = Path(sys.argv[1])
    path = work / "blob.bin"
    # 8 MiB deterministic bytes. Not random from the kernel.
    blob = bytes((index * 17 + SEED) % 256 for index in range(8 * 1024 * 1024))
    path.write_bytes(blob)
    variants = []
    for tool in ("md5sum", "sha256sum", "b2sum"):
        trials = [run_command([tool, str(path)], cwd=work) for _ in range(TRIALS)]
        variants.append(write_variant(tool, trials))
    note = interpret(variants)
    note += (
        " These functions do different work. A lower median is not a reason to prefer "
        "that digest for integrity. md5sum is not a collision-resistant choice for new "
        "manifests. sha256sum is the usual download check. b2sum is BLAKE2b."
    )
    print(
        __import__("json").dumps(
            {
                "id": "checksums",
                "title": "md5sum, sha256sum, and b2sum on 8 MiB",
                "question": "What do the medians look like for three different digests of the same warm file?",
                "input": f"8388608 deterministic bytes, seed {SEED} mixed into the generator, {TRIALS} trials.",
                "variants": variants,
                "note": note,
            }
        )
    )


if __name__ == "__main__":
    main()
