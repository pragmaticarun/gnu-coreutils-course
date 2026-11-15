#!/usr/bin/env python3
"""Measure companion-tool benchmarks and write their own disclosure.

These rows are not merged into sample-run.json or supplements.json.
Do not edit the numbers by hand.
"""

from __future__ import annotations

import json
import os
import platform
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from libbench import disclosure

ROOT = Path(__file__).resolve().parent


def first_line(cmd: list[str]) -> str:
    proc = subprocess.run(cmd, capture_output=True, text=True)
    text = (proc.stdout or proc.stderr or "").strip()
    return text.splitlines()[0] if text else "unavailable"


def cpu_model() -> str:
    cpuinfo = Path("/proc/cpuinfo")
    if not cpuinfo.is_file():
        return "unavailable"
    for line in cpuinfo.read_text(errors="replace").splitlines():
        if line.lower().startswith("model name"):
            return line.split(":", 1)[1].strip()
    return "unavailable"


def mem_total() -> str:
    meminfo = Path("/proc/meminfo")
    if not meminfo.is_file():
        return "unavailable"
    for line in meminfo.read_text(errors="replace").splitlines():
        if line.startswith("MemTotal:"):
            return line.split(":", 1)[1].strip()
    return "unavailable"


def package_version(name: str) -> str:
    proc = subprocess.run(
        ["dpkg-query", "-W", "-f", "${Version}", name],
        capture_output=True,
        text=True,
    )
    return proc.stdout.strip() if proc.returncode == 0 else "not-installed"


def run_script(script: str, work: Path, extra: list[str]) -> dict:
    proc = subprocess.run(
        [sys.executable, str(ROOT / script), str(work), *extra],
        capture_output=True,
        text=True,
        timeout=600,
    )
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr)
        raise SystemExit(f"{script} {' '.join(extra)} failed")
    return json.loads(proc.stdout)


def main() -> None:
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "public" / "benchmarks" / "companions.json"
    benches = []
    with tempfile.TemporaryDirectory(prefix="cuwb-companion-") as tmp:
        work = Path(tmp)
        benches.append(run_script("bench_grep_mode.py", work, []))
        benches.append(run_script("bench_awk_vs_sort.py", work, []))
        benches.append(run_script("bench_compress.py", work, ["compressible"]))
        benches.append(run_script("bench_compress.py", work, ["random"]))
        benches.append(run_script("bench_xargs_p.py", work, []))
        benches.append(run_script("bench_sed_rewrite.py", work, []))
        benches.append(run_script("bench_sparse_tar.py", work, []))
        benches.append(run_script("bench_taskset.py", work, []))
        info = disclosure(work)
    info["separateFromSampleRun"] = True
    info["separateFromSupplements"] = True
    info["noSystemTuning"] = True
    info["cpuModel"] = cpu_model()
    info["cpuCount"] = os.cpu_count() or 0
    info["memTotal"] = mem_total()
    info["python"] = platform.python_version()
    info["tools"] = {
        "grep": first_line(["grep", "--version"]),
        "grepPackage": package_version("grep"),
        "sed": first_line(["sed", "--version"]),
        "sedPackage": package_version("sed"),
        "awk": first_line(["/usr/bin/awk", "-W", "version"]),
        "awkPackage": package_version("mawk"),
        "gawk": first_line(["gawk", "--version"]),
        "gawkPackage": package_version("gawk"),
        "gzip": first_line(["gzip", "--version"]),
        "gzipPackage": package_version("gzip"),
        "pigz": first_line(["pigz", "--version"]),
        "pigzPackage": package_version("pigz"),
        "zstd": first_line(["zstd", "--version"]),
        "zstdPackage": package_version("zstd"),
        "xz": first_line(["xz", "--version"]),
        "xzPackage": package_version("xz-utils"),
        "bzip2": first_line(["bzip2", "--version"]),
        "bzip2Package": package_version("bzip2"),
        "tar": first_line(["tar", "--version"]),
        "tarPackage": package_version("tar"),
        "parallel": first_line(["parallel", "--version"]),
        "parallelPackage": package_version("parallel"),
        "time": package_version("time"),
        "hyperfine": first_line(["hyperfine", "--version"]),
        "strace": first_line(["strace", "-V"]),
        "perf": "not-installed",
    }
    info["disclaimer"] = (
        "Warm-cache timings from this machine only. Each trial includes a short "
        "Python process that starts the command. Caches were not dropped. No root, "
        "no sysctl, no drop_caches, no frequency scaling. These numbers do not predict "
        "another computer, a cold cache, a larger file, or a different package build. "
        "Do not compare a median here with sample-run.json or supplements.json as if "
        "they were one experiment. Companion tools are not GNU coreutils. perf was "
        "not installed, so this file has no perf counters."
    )
    payload = {"disclosure": info, "benches": benches}
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, indent=2) + "\n")
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
