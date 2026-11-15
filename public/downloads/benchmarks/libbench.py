#!/usr/bin/env python3
"""Measurement helpers for the coreutils workbench.

Trials are bounded. The page cache is not dropped. No root is required.
ru_maxrss is reported in kibibytes on Linux.
"""

from __future__ import annotations

import json
import os
import platform
import resource
import statistics
import subprocess
import sys
import textwrap
import time
from pathlib import Path

SEED = 20261108
TRIALS = 5


def disclosure(workdir: Path) -> dict:
    version = subprocess.check_output(["ls", "--version"], text=True).splitlines()[0]
    package = subprocess.check_output(
        ["dpkg-query", "-W", "-f", "${Version}", "coreutils"], text=True
    ).strip()
    df = subprocess.check_output(["df", "-T", str(workdir)], text=True).splitlines()[-1].split()
    statfs = subprocess.check_output(
        ["stat", "-f", "-c", "%T", str(workdir)], text=True
    ).strip()
    return {
        "coreutils": version,
        "package": package,
        "uname": subprocess.check_output(["uname", "-srm"], text=True).strip(),
        "python": platform.python_version(),
        "locale": os.environ.get("LC_ALL") or os.environ.get("LANG") or "",
        "filesystemDf": df[1] if len(df) > 1 else "",
        "filesystemStat": statfs,
        "seed": SEED,
        "trials": TRIALS,
        "maxRss": "Linux ru_maxrss of waited-for children, kibibytes",
        "warmCache": (
            "Inputs are created in this process and reread immediately. "
            "Caches are not dropped. This is not a cold-disk measurement and "
            "not a ranking that transfers to another machine."
        ),
        "noRoot": True,
        "noDropCaches": True,
        "helper": (
            "Most elapsed times include a short Python process that starts the "
            "command and waits. Compare variants with each other. Do not treat "
            "the absolute seconds as a shell-only measurement."
        ),
    }


HARNESS = textwrap.dedent(
    """\
    import resource, subprocess, sys, time
    cmd = sys.argv[1:]
    start = time.perf_counter()
    proc = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    elapsed = time.perf_counter() - start
    usage = resource.getrusage(resource.RUSAGE_CHILDREN)
    print(f"{elapsed:.6f} {usage.ru_utime:.6f} {usage.ru_stime:.6f} {usage.ru_maxrss} {proc.returncode}")
    """
)


def run_command(cmd: list[str], env: dict | None = None, cwd: Path | None = None) -> dict:
    merged = os.environ.copy()
    if env:
        merged.update(env)
    proc = subprocess.run(
        [sys.executable, "-c", HARNESS, *cmd],
        cwd=cwd,
        env=merged,
        capture_output=True,
        text=True,
        timeout=60,
    )
    if proc.returncode != 0:
        raise SystemExit(f"harness failed for {cmd}: {proc.stderr}")
    elapsed, user, system, rss, status = proc.stdout.strip().split()
    return {
        "elapsed": float(elapsed),
        "user": float(user),
        "system": float(system),
        "maxRssKb": int(rss),
        "exitCode": int(status),
    }


def median_of(trials: list[dict]) -> dict:
    def med(key: str) -> float:
        return float(statistics.median(trial[key] for trial in trials))

    return {
        "elapsed": med("elapsed"),
        "user": med("user"),
        "system": med("system"),
        "maxRssKb": int(statistics.median(trial["maxRssKb"] for trial in trials)),
    }


def interpret(variants: list[dict]) -> str:
    if len(variants) < 2:
        return (
            "One variant was measured. Read the median next to the trial spread. "
            "This is not a comparison and not a general speed claim."
        )
    spreads = []
    for variant in variants:
        elapsed = [trial["elapsed"] for trial in variant["trials"]]
        spreads.append(max(elapsed) - min(elapsed))
    widest = max(spreads)
    ordered = sorted(variants, key=lambda item: item["median"]["elapsed"])
    gap = ordered[-1]["median"]["elapsed"] - ordered[0]["median"]["elapsed"]
    names = ", ".join(
        f"{item['name']} median {item['median']['elapsed']:.4f}s" for item in ordered
    )
    if gap <= widest:
        return (
            f"Medians on this run: {names}. The gap between the fastest and slowest "
            f"median is {gap:.4f}s, which is within the widest trial spread "
            f"({widest:.4f}s). This run does not separate the variants. "
            "It is not evidence that one form is generally faster."
        )
    return (
        f"Medians on this run: {names}. The gap is {gap:.4f}s and the widest "
        f"trial spread is {widest:.4f}s, so the medians are farther apart than the "
        "scatter of this sample. That is evidence about this input, this warm cache, "
        "and this machine. It is not a universal ranking and it says nothing about "
        "cold disk or a different filesystem."
    )


def write_variant(name: str, trials: list[dict]) -> dict:
    return {"name": name, "trials": trials, "median": median_of(trials)}


def emit(payload: dict, path: Path | None) -> None:
    text = json.dumps(payload, indent=2)
    if path:
        path.write_text(text + "\n")
    else:
        print(text)
