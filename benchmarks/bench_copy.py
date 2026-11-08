#!/usr/bin/env python3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import SEED, TRIALS, interpret, run_command, write_variant


def main() -> None:
    work = Path(sys.argv[1])
    src = work / "src.bin"
    src.write_bytes(bytes((index + SEED) % 256 for index in range(8 * 1024 * 1024)))
    variants = []
    commands = {
        "cp": ["cp", "--reflink=never", str(src), str(work / "via-cp")],
        "dd": [
            "dd",
            f"if={src}",
            f"of={work / 'via-dd'}",
            "bs=65536",
            "status=none",
        ],
    }
    for name, cmd in commands.items():
        trials = [run_command(cmd, cwd=work) for _ in range(TRIALS)]
        variants.append(write_variant(name, trials))
    # cat via a shell redirect would be a shell measurement. Keep this to two coreutils tools.
    note = interpret(variants)
    note += (
        " cp --reflink=never forces a normal copy on this host, where reflink clones "
        "are not supported. dd uses a 64 KiB block size and status=none. Both read a "
        "file that was just written, so the page cache is warm. A faster median is not "
        "a reason to replace one tool with the other."
    )
    print(
        __import__("json").dumps(
            {
                "id": "copy",
                "title": "cp and dd on an 8 MiB warm file",
                "question": "How do a normal cp and a fixed-block dd compare when the source is already cached?",
                "input": f"8388608 bytes, seed {SEED}, {TRIALS} trials, reflink disabled.",
                "variants": variants,
                "note": note,
            }
        )
    )


if __name__ == "__main__":
    main()
