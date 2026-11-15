#!/usr/bin/env python3
"""Static checks for lesson shape, sandbox safety, and the supplement disclosure.

Does not re-run lesson captures. scripts/assemble.py does that.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LESSONS = ROOT / "content" / "lessons"
COOKBOOK = ROOT / "content" / "cookbook"
SANDBOX = ROOT / "public" / "sandbox"
NOTES = ROOT / "scripts" / "reference_notes.json"
SUPPLEMENTS = ROOT / "public" / "benchmarks" / "supplements.json"

TWO_HINT_FILES = {
    COOKBOOK / "17-atomic-publish.md",
    COOKBOOK / "18-build-tree-weight.md",
    COOKBOOK / "19-nul-safe-sort.md",
}
TWO_HINT_TITLES = {
    "Name the package that owns chroot",
    "Show the copy that fills the hole",
    "Prove the bytes outlived the name",
    "Separate a missing PATH from an empty PATH",
    "Ask nproc inside a one-CPU mask",
}

DANGEROUS = [
    (re.compile(r"\bsudo\b"), "sudo"),
    (re.compile(r"\bmkfs\b"), "mkfs"),
    (re.compile(r"\bsysctl\b"), "sysctl"),
    (re.compile(r"drop_caches"), "drop_caches"),
    (re.compile(r"of=/dev/(?!null\b|zero\b)"), "dd onto a device"),
    (re.compile(r"rm\s+-rf\s+/(?![\w])"), "rm -rf /"),
    (re.compile(r"chmod\s+-R\s+777"), "chmod -R 777"),
]


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def frontmatter(text: str) -> str:
    if not text.startswith("---\n"):
        fail("missing frontmatter")
    end = text.find("\n---\n", 4)
    if end < 0:
        fail("unterminated frontmatter")
    return text[4:end]


def scripts_of(text: str) -> list[str]:
    return re.findall(r"```(?:run|exercise)\n(.*?)```", text, flags=re.S)


def exercise_blocks(text: str) -> list[str]:
    return re.findall(r"```exercise\n(.*?)```", text, flags=re.S)


def check_dangerous(label: str, text: str) -> None:
    for pattern, name in DANGEROUS:
        if pattern.search(text):
            fail(f"{label} contains {name}")


def main() -> None:
    notes = json.loads(NOTES.read_text())
    if "chroot" not in notes:
        fail("reference notes are missing chroot")
    if "/usr/sbin/chroot" not in notes["chroot"]["note"]:
        fail("chroot note does not mention /usr/sbin/chroot")

    lesson_count = 0
    cookbook_count = 0
    exercises = 0
    two_hints = 0
    for path in sorted(LESSONS.glob("*.md")):
        lesson_count += 1
        text = path.read_text()
        front = frontmatter(text)
        if "https://www.gnu.org/software/coreutils/manual/html_node/" not in front:
            fail(f"{path.name} has no GNU manual URL")
        if "cannot find `printf` by name" in text:
            fail("process-wrappers still claims env -i cannot find printf")
        for block in scripts_of(text):
            check_dangerous(path.name, block)
        for block in exercise_blocks(text):
            exercises += 1
            title = ""
            match = re.search(r"(?m)^---title---\n(.+)", block)
            if match:
                title = match.group(1).strip()
            if title in TWO_HINT_TITLES:
                if "---hint2---" not in block or not re.search(r"(?m)^---hint2---\n\s*\S", block):
                    fail(f"{path.name} exercise {title!r} needs a second hint")
                two_hints += 1
    for path in sorted(COOKBOOK.glob("*.md")):
        cookbook_count += 1
        text = path.read_text()
        front = frontmatter(text)
        if "https://www.gnu.org/software/coreutils/manual/html_node/" not in front:
            fail(f"{path.name} has no GNU manual URL")
        for block in scripts_of(text):
            check_dangerous(path.name, block)
        blocks = exercise_blocks(text)
        if path in TWO_HINT_FILES and len(blocks) < 2:
            fail(f"{path.name} should have two exercises")
        for block in blocks:
            exercises += 1
            if path in TWO_HINT_FILES:
                if block.count("---hint2---") != 1:
                    fail(f"{path.name} exercise missing hint2")
                if "---solution---" not in block or "---script---" not in block:
                    fail(f"{path.name} exercise missing solution or script")
                two_hints += 1

    sandbox_scripts = sorted(SANDBOX.glob("*.sh"))
    if len(sandbox_scripts) < 8:
        fail(f"expected at least 8 sandbox scripts, found {len(sandbox_scripts)}")
    for path in sandbox_scripts:
        text = path.read_text()
        if "Refusing to run as root" not in text:
            fail(f"{path.name} does not refuse root")
        if "mktemp" not in text:
            fail(f"{path.name} does not use mktemp")
        check_dangerous(path.name, text)
        proc = subprocess.run(["bash", str(path)], capture_output=True, text=True, timeout=30)
        if proc.returncode != 0:
            fail(f"{path.name} failed\n{proc.stdout}\n{proc.stderr}")
        if not proc.stdout.startswith("ok "):
            fail(f"{path.name} did not print ok: {proc.stdout!r}")

    companion_slugs = {
        "companion-boundary",
        "gnu-grep",
        "gnu-sed",
        "awk-family",
        "diffutils-and-patch",
        "findutils-and-nul",
        "gnu-parallel",
        "gnu-tar",
        "compression",
        "timing-tools",
        "tracing-processes",
        "throughput-stats",
        "procps-processes",
        "open-files",
        "util-linux-toolbox",
        "helper-tools",
    }
    cookbook_slugs = {
        "log-triage",
        "large-duplicate-files",
        "fast-backup-tarball",
        "profile-slow-pipeline",
        "weird-filenames",
        "parallel-compression",
        "cpu-pinned-benchmark",
        "json-api-fixture",
    }
    seen_lessons = set()
    seen_books = set()
    companion_text = []
    for path in sorted(LESSONS.glob("*.md")):
        text = path.read_text()
        front = frontmatter(text)
        slug = ""
        match = re.search(r"(?m)^slug:\s*(\S+)\s*$", front)
        if match:
            slug = match.group(1)
            seen_lessons.add(slug)
        if "module: Companion Tools" in front:
            if slug not in companion_slugs:
                fail(f"{path.name} is Companion Tools but slug {slug} is not registered")
            if "not coreutils" not in text.lower():
                fail(f"{path.name} must say the tools are not coreutils")
            if "Ubuntu package" not in text and "package `" not in text:
                fail(f"{path.name} must name the Ubuntu package")
            urls = re.findall(r"https://[^\s|]+", front)
            official = [url for url in urls if "/coreutils/manual/" not in url]
            if not official:
                fail(f"{path.name} needs an official non-coreutils manual URL")
            for block in re.findall(r"```run\n(.*?)```", text, flags=re.S):
                if "# companion:" not in block:
                    fail(f"{path.name} run block is missing # companion:")
            for block in exercise_blocks(text):
                if not re.search(r"(?m)^---hint2---\n\s*\S", block):
                    fail(f"{path.name} companion exercise needs hint2")
            companion_text.append(text)
    for slug in sorted(companion_slugs - seen_lessons):
        fail(f"missing companion lesson {slug}")
    for path in sorted(COOKBOOK.glob("*.md")):
        text = path.read_text()
        front = frontmatter(text)
        match = re.search(r"(?m)^slug:\s*(\S+)\s*$", front)
        slug = match.group(1) if match else ""
        seen_books.add(slug)
        if slug in cookbook_slugs:
            if "not coreutils" not in text.lower():
                fail(f"{path.name} must say the companion is not coreutils")
            urls = re.findall(r"https://[^\s|]+", front)
            if not any("/coreutils/manual/" not in url for url in urls):
                fail(f"{path.name} needs the companion project's docs")
            for block in exercise_blocks(text):
                if not re.search(r"(?m)^---hint2---\n\s*\S", block):
                    fail(f"{path.name} exercise needs hint2")
    for slug in sorted(cookbook_slugs - seen_books):
        fail(f"missing companion cookbook {slug}")
    blob = "\n".join(companion_text)
    for needle in (
        "mawk",
        "gawk",
        "shell keyword",
        "util-linux",
        "procps",
        "sysstat",
        "/usr/bin/time",
        "plocate",
        "pigz",
        "zstd",
        "-print0",
        "xargs",
        "-T0",
        "perf-absent",
        "fdfind",
        "sponge",
        "chronic",
        "entr",
    ):
        if needle not in blob:
            fail(f"companion lessons do not mention {needle}")

    required_sandboxes = [
        "companion-log-triage.sh",
        "companion-large-dupes.sh",
        "companion-backup-tar.sh",
        "companion-profile-pipeline.sh",
        "companion-weird-names.sh",
        "companion-parallel-compress.sh",
        "companion-cpu-pin.sh",
        "companion-json.sh",
    ]
    for name in required_sandboxes:
        if not (SANDBOX / name).is_file():
            fail(f"missing sandbox {name}")

    course_path = ROOT / "content" / "generated" / "course.json"
    if course_path.is_file():
        course = json.loads(course_path.read_text())
        rows = course.get("companions", [])
        names = {row["name"] for row in rows}
        for required in ("grep", "sed", "awk", "gawk", "mawk", "perf", "pigz", "zstd", "fdfind", "jq"):
            if required not in names:
                fail(f"companion catalog missing {required}")
        perf = next(row for row in rows if row["name"] == "perf")
        if perf.get("installed"):
            fail("perf is installed; update the tracing lesson before claiming it is absent")
        for row in rows:
            if "not coreutils" not in row.get("note", "").lower():
                fail(f"companion note for {row['name']} must say not coreutils")
            if row.get("installed") and not row.get("package"):
                fail(f"installed companion {row['name']} has no package")
            if not row.get("project"):
                fail(f"companion {row['name']} has no upstream project")
        modules = {lesson["module"] for lesson in course["lessons"]}
        if "Companion Tools" not in modules:
            fail("course.json has no Companion Tools module")

    search_path = ROOT / "public" / "search-index.json"
    if search_path.is_file():
        index = json.loads(search_path.read_text())
        if not any(row.get("kind") == "companion" for row in index):
            fail("search index has no companion entries")

    companions_bench = ROOT / "public" / "benchmarks" / "companions.json"
    if not companions_bench.is_file():
        fail("public/benchmarks/companions.json is missing")
    companion_run = json.loads(companions_bench.read_text())
    disclosure = companion_run["disclosure"]
    if "do not predict" not in disclosure.get("disclaimer", "").lower():
        fail("companion disclaimer must say the numbers do not predict other machines")
    if disclosure.get("separateFromSampleRun") is not True:
        fail("companion disclosure must be marked separate from the sample run")
    if disclosure.get("noRoot") is not True or disclosure.get("noDropCaches") is not True:
        fail("companion disclosure must record noRoot and noDropCaches")
    if not disclosure.get("cpuModel") or not disclosure.get("tools"):
        fail("companion disclosure must name the CPU and the tool versions")
    bench_ids = [item["id"] for item in companion_run["benches"]]
    for required in (
        "grep-fixed-locale",
        "awk-vs-sort",
        "compress-compressible",
        "compress-random",
        "xargs-parallel",
        "sed-rewrite",
        "sparse-tar",
        "taskset-pin",
    ):
        if required not in bench_ids:
            fail(f"companion benchmarks missing {required}")

    if not SUPPLEMENTS.is_file():
        fail("public/benchmarks/supplements.json is missing")
    supplement = json.loads(SUPPLEMENTS.read_text())
    disclaimer = supplement["disclosure"].get("disclaimer", "")
    if "do not predict" not in disclaimer.lower():
        fail("supplement disclaimer must say the numbers do not predict other machines")
    if not supplement["disclosure"].get("separateFromSampleRun"):
        fail("supplement disclosure must be marked separate from the sample run")
    if supplement["disclosure"].get("noRoot") is not True:
        fail("supplement disclosure must record noRoot")
    ids = [item["id"] for item in supplement["benches"]]
    for required in ("pipeline-overhead", "process-startup", "sparse-copy"):
        if required not in ids:
            fail(f"supplement missing {required}")

    print(
        f"ok lessons={lesson_count} cookbook={cookbook_count} "
        f"exercise_blocks={exercises} two_hint_exercises={two_hints} "
        f"sandboxes={len(sandbox_scripts)} supplements={len(ids)}"
    )


if __name__ == "__main__":
    main()
