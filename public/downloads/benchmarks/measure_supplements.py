#!/usr/bin/env python3
"""Measure the supplement benchmarks and write their own disclosure.

These rows are not merged into public/benchmarks/sample-run.json. That file is
an earlier run. Do not edit the numbers by hand.
"""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import disclosure

ROOT = Path(__file__).resolve().parent
SCRIPTS = [
    "bench_pipeline.py",
    "bench_startup.py",
    "bench_sparse.py",
]


def main() -> None:
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "public" / "benchmarks" / "supplements.json"
    benches = []
    with tempfile.TemporaryDirectory(prefix="cuwb-supplement-") as tmp:
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
        info = disclosure(work)
    info["separateFromSampleRun"] = True
    info["disclaimer"] = (
        "Warm-cache timings from this machine only. Each trial includes a short "
        "Python process that starts the command. Caches were not dropped. No root, "
        "no sysctl, no drop_caches. These numbers do not predict another computer, "
        "a cold cache, or a different coreutils build. Do not compare a median "
        "here with a median in sample-run.json as if they were one experiment; "
        "that file is an earlier run of a different script list."
    )
    payload = {"disclosure": info, "benches": benches}
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, indent=2) + "\n")
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
