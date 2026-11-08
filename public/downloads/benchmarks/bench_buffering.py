#!/usr/bin/env python3
"""Time-to-first-byte for a tiny stdio program with and without stdbuf -oL."""

import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import SEED, TRIALS, interpret, write_variant

ROOT = Path(__file__).resolve().parent


def compile_harness(work: Path) -> Path:
    binary = work / "stdio_lines"
    subprocess.check_call(
        ["gcc", "-O2", "-o", str(binary), str(ROOT / "stdio_lines.c")],
        timeout=30,
    )
    return binary


def ttfb(cmd: list[str]) -> dict:
    start = time.perf_counter()
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    assert proc.stdout is not None
    proc.stdout.read(1)
    elapsed = time.perf_counter() - start
    proc.wait(timeout=10)
    return {
        "elapsed": elapsed,
        "user": 0.0,
        "system": 0.0,
        "maxRssKb": 0,
        "exitCode": proc.returncode,
    }


def main() -> None:
    work = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/tmp")
    binary = compile_harness(work)
    plain = [ttfb([str(binary)]) for _ in range(TRIALS)]
    lined = [ttfb(["stdbuf", "-oL", str(binary)]) for _ in range(TRIALS)]
    variants = [write_variant("stdio default", plain), write_variant("stdbuf -oL", lined)]
    payload = {
        "id": "buffering",
        "title": "Line buffering changes time-to-first-byte",
        "question": (
            "When a small C program writes lines with printf and sleeps between them, "
            "how soon does the first byte reach a pipe?"
        ),
        "input": (
            f"stdio_lines.c, 4 lines, 100ms sleep, {TRIALS} trials. "
            "User/system/RSS are not collected for this latency probe (recorded as 0). "
            f"Seed field is unused ({SEED})."
        ),
        "variants": variants,
        "note": interpret(variants)
        + " The program is a harness, not cat or dd. The coreutils manual says those two do not use C FILE streams, so stdbuf does not apply to them. This measurement is about FILE buffering on a pipe.",
    }
    print(__import__("json").dumps(payload))


if __name__ == "__main__":
    main()
