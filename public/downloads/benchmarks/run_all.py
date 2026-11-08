#!/usr/bin/env python3
"""Run every bounded benchmark and write one JSON document."""

import json
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import disclosure

ROOT = Path(__file__).resolve().parent
SCRIPTS = [
    "bench_sort_locale.py",
    "bench_sort_parallel.py",
    "bench_sort_buffer.py",
    "bench_checksums.py",
    "bench_wc.py",
    "bench_copy.py",
    "bench_buffering.py",
]


def main() -> None:
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    benches = []
    with tempfile.TemporaryDirectory(prefix="cuwb-bench-") as tmp:
        work = Path(tmp)
        for script in SCRIPTS:
            proc = subprocess.run(
                [sys.executable, str(ROOT / script), str(work)],
                capture_output=True,
                text=True,
                timeout=180,
            )
            if proc.returncode != 0:
                sys.stderr.write(proc.stderr)
                raise SystemExit(f"{script} failed")
            benches.append(json.loads(proc.stdout))
        payload = {"disclosure": disclosure(work), "benches": benches}
    text = json.dumps(payload, indent=2) + "\n"
    if out:
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text)
    else:
        sys.stdout.write(text)


if __name__ == "__main__":
    main()
