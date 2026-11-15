#!/usr/bin/env python3
"""Execute lesson scripts in sandboxes and write the course JSON."""

from __future__ import annotations

import datetime as dt
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import textwrap
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LESSONS = ROOT / "content" / "lessons"
COOKBOOK = ROOT / "content" / "cookbook"
GENERATED = ROOT / "content" / "generated"
PUBLIC = ROOT / "public"
NOTES = ROOT / "scripts" / "reference_notes.json"
MAX_OUTPUT = 20000

MANUAL = "https://www.gnu.org/software/coreutils/manual/html_node"


def fail(message: str) -> None:
    raise SystemExit(message)


def parse_frontmatter(text: str) -> tuple[dict, str]:
    if not text.startswith("---\n"):
        fail("missing frontmatter")
    end = text.find("\n---\n", 4)
    if end < 0:
        fail("unterminated frontmatter")
    raw = text[4:end]
    body = text[end + 5 :]
    data: dict = {"objectives": [], "manual": []}
    mode = None
    bsd: list[str] = []
    for line in raw.splitlines():
        if mode == "bsd":
            if line.startswith("  "):
                bsd.append(line[2:])
                continue
            if line.strip() == "":
                bsd.append("")
                continue
            data["gnu_vs_bsd"] = "\n".join(bsd).strip()
            mode = None
        if line.startswith("objectives:"):
            mode = "obj"
            continue
        if mode == "obj" and line.startswith("  - "):
            data["objectives"].append(line[4:].strip())
            continue
        if line.startswith("manual:"):
            rest = line.split(":", 1)[1].strip()
            title, url = [part.strip() for part in rest.split("|", 1)]
            data["manual"].append({"title": title, "url": url})
            mode = None
            continue
        if line.startswith("gnu_vs_bsd: |"):
            mode = "bsd"
            bsd = []
            continue
        if ":" in line and not line.startswith(" "):
            key, value = line.split(":", 1)
            data[key.strip()] = value.strip()
            mode = None
    if mode == "bsd":
        data["gnu_vs_bsd"] = "\n".join(bsd).strip()
    return data, body


def parse_run(text: str) -> tuple[dict, str]:
    meta = {"expect": 0, "env": {}, "title": "", "companion": "", "timeout": 20}
    script: list[str] = []
    header = True
    for line in text.splitlines():
        if header and line.startswith("# expect-exit:"):
            meta["expect"] = int(line.split(":", 1)[1].strip())
        elif header and line.startswith("# title:"):
            meta["title"] = line.split(":", 1)[1].strip()
        elif header and line.startswith("# companion:"):
            meta["companion"] = line.split(":", 1)[1].strip()
        elif header and line.startswith("# timeout:"):
            meta["timeout"] = int(line.split(":", 1)[1].strip())
        elif header and line.startswith("# env:"):
            item = line.split(":", 1)[1].strip()
            key, value = item.split("=", 1)
            meta["env"][key.strip()] = value
        elif header and line.strip() == "":
            continue
        else:
            header = False
            script.append(line)
    return meta, "\n".join(script).rstrip() + "\n"


def parse_exercise(text: str) -> dict:
    parts = re.split(r"(?m)^---(title|prompt|hint|hint2|solution|script)---\s*$", text)
    # parts[0] is preamble with expect-exit
    data = {
        "expect": 0,
        "title": "",
        "prompt": "",
        "hint": "",
        "hint2": "",
        "solution": "",
        "script": "",
    }
    preamble = parts[0]
    match = re.search(r"(?m)^expect-exit:\s*(\d+)\s*$", preamble)
    if match:
        data["expect"] = int(match.group(1))
    index = 1
    while index + 1 < len(parts):
        data[parts[index]] = parts[index + 1].strip("\n")
        index += 2
    if not data["title"] or not data["script"]:
        fail("exercise missing title or script")
    return data


def run_script(script: str, env_extra: dict, timeout: int) -> tuple[str, str, int]:
    banned = [
        "drop_caches",
        "mkfs",
        "of=/dev/sd",
        "of=/dev/nvme",
        "of=/dev/loop",
        "rm -rf /",
        "rm -rf -- /",
        ":(){",
        "shutdown",
        "reboot",
        "sudo ",
        "sysctl",
    ]
    for item in banned:
        if item in script:
            fail(f"refusing script that contains {item!r}")
    sandbox = tempfile.mkdtemp(prefix="cuwb-")
    env = os.environ.copy()
    env["HOME"] = sandbox
    env["TMPDIR"] = sandbox
    env["LC_ALL"] = "en_US.UTF-8"
    env.update(env_extra)
    wrapped = "set -eo pipefail\n" + script
    proc = subprocess.Popen(
        ["bash", "-c", wrapped],
        cwd=sandbox,
        env=env,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        start_new_session=True,
    )
    try:
        stdout, stderr = proc.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        os.killpg(proc.pid, signal.SIGKILL)
        proc.communicate()
        shutil.rmtree(sandbox, ignore_errors=True)
        fail(f"script timed out after {timeout}s\nSCRIPT:\n{script[:800]}")
    code = proc.returncode if proc.returncode is not None else 1
    shutil.rmtree(sandbox, ignore_errors=True)
    return stdout, stderr, code


def clip(text: str) -> tuple[str, bool]:
    if len(text) <= MAX_OUTPUT:
        return text, False
    return text[:MAX_OUTPUT] + "\n…[truncated]\n", True


def prose_words(markdown: str) -> int:
    stripped = re.sub(r"```.*?```", " ", markdown, flags=re.S)
    stripped = re.sub(r"[#>*`|_\-\[\]()]", " ", stripped)
    return len(re.findall(r"[A-Za-z0-9']+", stripped))


def headings(markdown: str) -> list[dict]:
    found = []
    for line in markdown.splitlines():
        match = re.match(r"^(#{2,3}) (.+)$", line)
        if not match or line.startswith("```"):
            continue
        text = match.group(2).strip()
        slug = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
        found.append({"level": len(match.group(1)), "id": slug, "text": text})
    return found


def load_document(path: Path, kind: str) -> dict:
    meta, body = parse_frontmatter(path.read_text())
    examples = []
    exercises = []
    pieces = []
    cursor = 0
    pattern = re.compile(r"```(run|exercise)\n(.*?)```", re.S)
    for match in pattern.finditer(body):
        pieces.append(body[cursor : match.start()])
        block_kind, block = match.group(1), match.group(2)
        if block_kind == "run":
            info, script = parse_run(block)
            stdout, stderr, code = run_script(script, info["env"], info["timeout"])
            if code != info["expect"]:
                fail(
                    f"{path.name} example {len(examples)+1} exit {code}, expected {info['expect']}\n"
                    f"STDOUT:\n{stdout}\nSTDERR:\n{stderr}\nSCRIPT:\n{script}"
                )
            stdout, trunc_out = clip(stdout)
            stderr, trunc_err = clip(stderr)
            number = len(examples) + 1
            download = f"/downloads/examples/{meta['slug']}-{number:02d}.sh"
            example = {
                "id": f"{meta['slug']}-{number:02d}",
                "title": info["title"],
                "companion": info["companion"],
                "script": script,
                "stdout": stdout,
                "stderr": stderr,
                "exitCode": code,
                "download": download,
                "truncated": trunc_out or trunc_err,
            }
            examples.append(example)
            pieces.append("```example\n" + json.dumps(example) + "\n```\n")
            write_download(download, meta["slug"], script, info["expect"])
        else:
            info = parse_exercise(block)
            stdout, stderr, code = run_script(info["script"], {}, 20)
            if code != info["expect"]:
                fail(
                    f"{path.name} exercise {info['title']} exit {code}, expected {info['expect']}\n"
                    f"STDOUT:\n{stdout}\nSTDERR:\n{stderr}"
                )
            stdout, _ = clip(stdout)
            stderr, _ = clip(stderr)
            number = len(exercises) + 1
            download = f"/downloads/solutions/{meta['slug']}-ex{number:02d}.sh"
            exercise = {
                "id": f"{meta['slug']}-ex{number:02d}",
                "title": info["title"],
                "prompt": info["prompt"].strip(),
                "hint": info["hint"].strip(),
                "hint2": info["hint2"].strip(),
                "solution": info["solution"].strip(),
                "script": info["script"].strip() + "\n",
                "stdout": stdout,
                "stderr": stderr,
                "exitCode": code,
                "download": download,
            }
            exercises.append(exercise)
            pieces.append("```exercise\n" + json.dumps(exercise) + "\n```\n")
            write_download(download, meta["slug"], exercise["script"], info["expect"])
        cursor = match.end()
    pieces.append(body[cursor:])
    markdown = "".join(pieces)
    words = prose_words(body)
    if kind == "lesson":
        if len(meta["objectives"]) < 3:
            fail(f"{path.name} needs 3 objectives")
        if len(examples) < 4:
            fail(f"{path.name} needs 4 examples, has {len(examples)}")
        if len(exercises) < 3:
            fail(f"{path.name} needs 3 exercises")
        if words < 400:
            fail(f"{path.name} has {words} prose words; need 400")
        if "## Performance" not in body or "## Tips and pitfalls" not in body:
            fail(f"{path.name} missing required sections")
    else:
        if len(examples) < 2:
            fail(f"{path.name} cookbook needs 2 examples")
        if len(exercises) < 1:
            fail(f"{path.name} cookbook needs an exercise")
        if words < 180:
            fail(f"{path.name} cookbook has {words} words")
        if "## Performance" not in body:
            fail(f"{path.name} cookbook missing performance")
    if len(meta.get("gnu_vs_bsd", "")) < 60:
        fail(f"{path.name} gnu_vs_bsd is too short")
    if not meta["manual"]:
        fail(f"{path.name} needs a manual citation")
    return {
        "kind": kind,
        "slug": meta["slug"],
        "number": int(meta["number"]),
        "title": meta["title"],
        "module": meta["module"],
        "level": meta["level"],
        "minutes": int(meta["minutes"]),
        "summary": meta["summary"],
        "objectives": meta["objectives"],
        "manual": meta["manual"],
        "gnuVsBsd": meta["gnu_vs_bsd"],
        "prereq": meta.get("prereq", ""),
        "markdown": markdown,
        "headings": headings(body),
        "examples": examples,
        "exercises": exercises,
        "wordCount": words,
    }


def write_download(url_path: str, slug: str, script: str, expect: int) -> None:
    path = PUBLIC / url_path.lstrip("/")
    path.parent.mkdir(parents=True, exist_ok=True)
    strict = "set -eo pipefail\n" if expect == 0 else "set -u\n"
    header = textwrap.dedent(
        f"""\
        #!/usr/bin/env bash
        # Example from the GNU Coreutils Workbench ({slug}).
        # Re-run inside a scratch directory. Captured against GNU coreutils 9.4.
        {strict}
        if [ "$(id -u)" -eq 0 ]; then
          printf 'Refusing to run as root.\\n' >&2
          exit 1
        fi
        cd "$(mktemp -d)"
        """
    )
    path.write_text(header + script)
    path.chmod(0o755)


def reference_entries() -> list[dict]:
    notes = json.loads(NOTES.read_text())
    paths = []
    for line in subprocess.check_output(["dpkg", "-L", "coreutils"], text=True).splitlines():
        # /usr/sbin/chroot is coreutils. A /bin/-only scan drops it.
        if ("/bin/" in line or "/sbin/" in line) and not line.endswith(".textutils"):
            paths.append(line)
    seen = set()
    entries = []
    for path in sorted(paths, key=lambda item: Path(item).name):
        name = Path(path).name
        if name in seen:
            continue
        seen.add(name)
        if name not in notes:
            fail(f"missing reference note for {name}")
        note = notes[name]
        help_argv = [path, "--help"]
        version_argv = [path, "--version"]
        if name == "test":
            # argv0 `test` treats `--help` as a non-empty string, which is true.
            bracket = str(Path(path).with_name("["))
            help_argv = [bracket, "--help"]
            version_argv = [bracket, "--version"]
        help_proc = subprocess.run(help_argv, capture_output=True, text=True, timeout=8)
        help_text = help_proc.stdout or help_proc.stderr
        summary = ""
        for line in help_text.splitlines():
            stripped = line.strip()
            if not stripped or stripped.startswith("Usage") or stripped.startswith("or:"):
                continue
            if stripped.startswith("-"):
                continue
            summary = stripped
            break
        if not summary:
            fail(f"no summary from --help for {name}")
        version = subprocess.run(version_argv, capture_output=True, text=True, timeout=8)
        version_line = (version.stdout or version.stderr).splitlines()[0] if (version.stdout or version.stderr) else name
        if name == "test" and version_line.startswith("["):
            version_line = "test" + version_line[1:]
        slug = "bracket" if name == "[" else name
        node = note["manual"].replace(" ", "-")
        entries.append(
            {
                "name": name,
                "slug": slug,
                "section": note["section"],
                "summary": summary,
                "note": note["note"],
                "lesson": note.get("lesson") or None,
                "manualUrl": f"{MANUAL}/{node}.html",
                "versionLine": version_line,
            }
        )
    return entries


def owning_package(path: str) -> str:
    query = subprocess.run(["dpkg", "-S", path], capture_output=True, text=True)
    if query.returncode != 0:
        return ""
    for line in query.stdout.splitlines():
        # Diversion notices are not the owning package line.
        if line.startswith("diversion "):
            continue
        if ":" not in line:
            continue
        return line.split(":", 1)[0].split(",")[0].strip()
    return ""


def companions() -> list[dict]:
    # name, path, project, group, lesson slug, note.
    # Paths are absolute so a shell keyword cannot impersonate the binary.
    specs = [
        ("grep", "/usr/bin/grep", "GNU grep", "Text", "gnu-grep", "Line search. Not coreutils. Ubuntu package grep, upstream GNU grep."),
        ("sed", "/usr/bin/sed", "GNU sed", "Text", "gnu-sed", "Stream editor. Not coreutils. Ubuntu package sed, upstream GNU sed. sed -i rewrites a file."),
        ("awk", "/usr/bin/awk", "mawk (Ubuntu default awk)", "Text", "awk-family", "Not coreutils. On this host /usr/bin/awk resolves to mawk. Installing gawk normally steals the alternative; this host was set back to mawk."),
        ("gawk", "/usr/bin/gawk", "GNU awk", "Text", "awk-family", "Not coreutils. Ubuntu package gawk, upstream GNU awk. Call it by path. gensub is not in mawk."),
        ("mawk", "/usr/bin/mawk", "mawk", "Text", "awk-family", "Not coreutils. Ubuntu package mawk, upstream mawk by Michael Brennan. This is the awk Ubuntu selects by default."),
        ("diff", "/usr/bin/diff", "GNU diffutils", "Text", "diffutils-and-patch", "Not coreutils. Ubuntu package diffutils. Exit status 1 means the files differ."),
        ("cmp", "/usr/bin/cmp", "GNU diffutils", "Text", "diffutils-and-patch", "Not coreutils. Byte-wise compare from diffutils, not cmp from another project."),
        ("sdiff", "/usr/bin/sdiff", "GNU diffutils", "Text", "diffutils-and-patch", "Not coreutils. Side-by-side diff from diffutils."),
        ("diff3", "/usr/bin/diff3", "GNU diffutils", "Text", "diffutils-and-patch", "Not coreutils. Three-way merge from diffutils."),
        ("patch", "/usr/bin/patch", "GNU patch", "Text", "diffutils-and-patch", "Not coreutils. Ubuntu package patch, upstream GNU patch. It applies a diff; it does not compute one."),
        ("find", "/usr/bin/find", "GNU findutils", "Finding and batching", "findutils-and-nul", "Not coreutils. Directory walk. -print0 is the NUL producer."),
        ("xargs", "/usr/bin/xargs", "GNU findutils", "Finding and batching", "findutils-and-nul", "Not coreutils. Builds argument lists. -0 reads NUL names. -P is a process pool, not GNU parallel."),
        ("locate", "/usr/bin/locate", "plocate", "Finding and batching", "findutils-and-nul", "Not coreutils. On this host locate is the plocate alternative, not findutils locate."),
        ("plocate", "/usr/bin/plocate", "plocate", "Finding and batching", "findutils-and-nul", "Not coreutils. Ubuntu package plocate. It searches a database. A private updatedb needs a chown this sandbox cannot do."),
        ("parallel", "/usr/bin/parallel", "GNU parallel", "Finding and batching", "gnu-parallel", "Not coreutils. Ubuntu package parallel. It diverts moreutils parallel to parallel.moreutils."),
        ("tar", "/usr/bin/tar", "GNU tar", "Archives and compression", "gnu-tar", "Not coreutils. Ubuntu package tar. Sparse archives, --exclude, and reproducible metadata are tar's job, not cp's."),
        ("gzip", "/usr/bin/gzip", "GNU gzip", "Archives and compression", "compression", "Not coreutils. Single-threaded DEFLATE. -n drops the name and timestamp."),
        ("pigz", "/usr/bin/pigz", "pigz", "Archives and compression", "compression", "Not coreutils. Ubuntu package pigz, upstream pigz by Mark Adler. Threaded gzip-format compressor, not a better ratio."),
        ("bzip2", "/usr/bin/bzip2", "bzip2", "Archives and compression", "compression", "Not coreutils. Ubuntu package bzip2. Often slower than zstd and smaller only on some inputs."),
        ("xz", "/usr/bin/xz", "XZ Utils", "Archives and compression", "compression", "Not coreutils. Ubuntu package xz-utils. High ratio, high CPU, one thread unless you ask."),
        ("zstd", "/usr/bin/zstd", "Zstandard", "Archives and compression", "compression", "Not coreutils. Ubuntu package zstd, upstream Facebook Zstandard. -T sets threads. -T0 means one thread per core."),
        ("time", "/usr/bin/time", "GNU time", "Timing and tracing", "timing-tools", "Not coreutils. Ubuntu package time. The bash keyword time is a different command and does not take -v."),
        ("hyperfine", "/usr/bin/hyperfine", "hyperfine", "Timing and tracing", "timing-tools", "Not coreutils. Ubuntu package hyperfine, upstream sharkdp/hyperfine. A statistical timer. Sub-millisecond commands are inside its noise warning."),
        ("perf", "/usr/bin/perf", "Linux perf", "Timing and tracing", "tracing-processes", "Not coreutils and not installed here. Ubuntu 24.04 linux-tools builds track kernel 6.8. This host is 6.12.113+, so there is no matching perf binary and this course records no perf counters."),
        ("strace", "/usr/bin/strace", "strace", "Timing and tracing", "tracing-processes", "Not coreutils. Ubuntu package strace. -c summarizes syscalls, -f follows forks, -e selects calls. It is not a profiler of CPU cycles."),
        ("ltrace", "/usr/bin/ltrace", "ltrace", "Timing and tracing", "tracing-processes", "Not coreutils. Ubuntu package ltrace. Library calls, not syscalls. Addresses change every run under ASLR."),
        ("pv", "/usr/bin/pv", "pv", "Timing and tracing", "throughput-stats", "Not coreutils. Ubuntu package pv, upstream Pipe Viewer. It copies stdin to stdout and draws progress on stderr."),
        ("iostat", "/usr/bin/iostat", "sysstat", "Timing and tracing", "throughput-stats", "Not coreutils. Ubuntu package sysstat. Device and CPU counters. Not part of procps."),
        ("vmstat", "/usr/bin/vmstat", "procps-ng", "Timing and tracing", "throughput-stats", "Not coreutils. On Ubuntu this binary is the procps package (upstream procps-ng), not sysstat."),
        ("pidstat", "/usr/bin/pidstat", "sysstat", "Timing and tracing", "throughput-stats", "Not coreutils. Ubuntu package sysstat. Per-process CPU and IO. Not the same binary as ps."),
        ("ps", "/usr/bin/ps", "procps-ng", "Process and memory", "procps-processes", "Not coreutils. Ubuntu package procps. A snapshot of the process table."),
        ("top", "/usr/bin/top", "procps-ng", "Process and memory", "procps-processes", "Not coreutils. Ubuntu package procps. Interactive. Use -b -n 1 for a single batch frame."),
        ("free", "/usr/bin/free", "procps-ng", "Process and memory", "procps-processes", "Not coreutils. Ubuntu package procps. Memory totals from the kernel, not du."),
        ("pgrep", "/usr/bin/pgrep", "procps-ng", "Process and memory", "procps-processes", "Not coreutils. Ubuntu package procps. Matches processes. Exit 1 means no match."),
        ("pkill", "/usr/bin/pkill", "procps-ng", "Process and memory", "procps-processes", "Not coreutils. Ubuntu package procps. Sends a signal. A pattern that appears in your own shell command can match the shell."),
        ("lsof", "/usr/bin/lsof", "lsof", "Open files", "open-files", "Not coreutils. Ubuntu package lsof. Lists open file descriptors, including deleted paths a process still holds."),
        ("fuser", "/usr/bin/fuser", "psmisc", "Open files", "open-files", "Not coreutils. Ubuntu package psmisc. Which processes hold a path. Exit 1 means none."),
        ("column", "/usr/bin/column", "util-linux", "util-linux", "util-linux-toolbox", "Not coreutils. Ubuntu binary package bsdextrautils, source package util-linux."),
        ("rev", "/usr/bin/rev", "util-linux", "util-linux", "util-linux-toolbox", "Not coreutils. Ubuntu package util-linux. Reverses each line. It is not rev from elsewhere."),
        ("flock", "/usr/bin/flock", "util-linux", "util-linux", "util-linux-toolbox", "Not coreutils. Ubuntu package util-linux. Advisory lock around a command. -n fails instead of waiting."),
        ("taskset", "/usr/bin/taskset", "util-linux", "util-linux", "util-linux-toolbox", "Not coreutils. Ubuntu package util-linux. Pins a process to CPUs. The shell expands $$ before taskset runs."),
        ("ionice", "/usr/bin/ionice", "util-linux", "util-linux", "util-linux-toolbox", "Not coreutils. Ubuntu package util-linux. I/O scheduling class. Idle class is a hint, not a bandwidth cap."),
        ("fallocate", "/usr/bin/fallocate", "util-linux", "util-linux", "util-linux-toolbox", "Not coreutils. Ubuntu package util-linux. Allocates or punches holes. Apparent size stays; du may drop."),
        ("findmnt", "/usr/bin/findmnt", "util-linux", "util-linux", "util-linux-toolbox", "Not coreutils. Ubuntu package util-linux. Reads the mount table. df is the coreutils view of space."),
        ("lsblk", "/usr/bin/lsblk", "util-linux", "util-linux", "util-linux-toolbox", "Not coreutils. Ubuntu package util-linux. Block devices. Disk names are host-specific."),
        ("script", "/usr/bin/script", "util-linux", "util-linux", "util-linux-toolbox", "Not coreutils. Ubuntu binary package bsdutils, source package util-linux. Records a typescript, including a carriage return."),
        ("logger", "/usr/bin/logger", "util-linux", "util-linux", "util-linux-toolbox", "Not coreutils. Ubuntu binary package bsdutils, source package util-linux. Writes to syslog. This host has no /dev/log."),
        ("setsid", "/usr/bin/setsid", "util-linux", "util-linux", "util-linux-toolbox", "Not coreutils. Ubuntu package util-linux. Starts a new session. $$ in the parent is the parent's pid."),
        ("prlimit", "/usr/bin/prlimit", "util-linux", "util-linux", "util-linux-toolbox", "Not coreutils. Ubuntu package util-linux. Sets resource limits for a child. ulimit is the shell builtin."),
        ("bc", "/usr/bin/bc", "GNU bc", "Helpers", "helper-tools", "Not coreutils. Ubuntu package bc. Arbitrary precision. scale=2; 1/3 prints .33 with no leading zero."),
        ("jq", "/usr/bin/jq", "jq", "Helpers", "helper-tools", "Not coreutils. Ubuntu package jq, upstream jqlang jq. JSON filter. It is not a streaming awk for arbitrary text."),
        ("rg", "/usr/bin/rg", "ripgrep", "Helpers", "helper-tools", "Not coreutils. Ubuntu package ripgrep, binary rg, upstream BurntSushi ripgrep. Respects gitignore inside a git work tree."),
        ("fdfind", "/usr/bin/fdfind", "fd", "Helpers", "helper-tools", "Not coreutils. Ubuntu package fd-find ships fdfind, not fd. Upstream project is fd."),
        ("sponge", "/usr/bin/sponge", "moreutils", "Helpers", "helper-tools", "Not coreutils. Ubuntu package moreutils. Soaks stdin, then writes the file, so a pipeline can read and replace the same path."),
        ("ts", "/usr/bin/ts", "moreutils", "Helpers", "helper-tools", "Not coreutils. Ubuntu package moreutils. Prefixes timestamps. The clock value changes every run."),
        ("ifne", "/usr/bin/ifne", "moreutils", "Helpers", "helper-tools", "Not coreutils. Ubuntu package moreutils. Runs a command only when stdin is non-empty."),
        ("chronic", "/usr/bin/chronic", "moreutils", "Helpers", "helper-tools", "Not coreutils. Ubuntu package moreutils. Swallows output of a successful command and shows it when the command fails."),
        ("entr", "/usr/bin/entr", "entr", "Helpers", "helper-tools", "Not coreutils. Ubuntu package entr, upstream eradman entr. Runs a command when files change. -n skips the TTY, -z exits after the utility."),
        ("rsync", "/usr/bin/rsync", "rsync", "Boundary", "companion-boundary", "Not coreutils and not installed in the capture environment. No rsync flags are demonstrated."),
        ("hostname", "/usr/bin/hostname", "hostname", "Boundary", "companion-boundary", "Not coreutils. The GNU coreutils manual documents hostname, but Ubuntu's binary is the hostname package."),
        ("kill", "/usr/bin/kill", "procps-ng", "Boundary", "companion-boundary", "Not coreutils. The manual documents kill, but /usr/bin/kill on this image is procps. The shell also has a kill builtin."),
        ("uptime", "/usr/bin/uptime", "procps-ng", "Boundary", "companion-boundary", "Not coreutils. The manual's uptime node is not this binary. /usr/bin/uptime is procps."),
    ]
    rows = []
    for name, path, project, group, lesson, note in specs:
        installed = Path(path).is_file()
        package = ""
        if installed:
            package = owning_package(str(Path(path).resolve()))
        rows.append(
            {
                "name": name,
                "installed": installed,
                "path": path,
                "package": package,
                "project": project,
                "group": group,
                "lesson": lesson,
                "note": note,
            }
        )
    return rows


def meta() -> dict:
    version = subprocess.check_output(["ls", "--version"], text=True).splitlines()[0]
    package = subprocess.check_output(
        ["dpkg-query", "-W", "-f", "${Version}", "coreutils"], text=True
    ).strip()
    df_line = subprocess.check_output(["df", "-T", "/tmp"], text=True).splitlines()[-1].split()
    statfs = subprocess.check_output(["stat", "-f", "-c", "%T", "/tmp"], text=True).strip()
    umask = subprocess.check_output(["bash", "-lc", "umask"], text=True).strip()
    return {
        "title": "GNU Coreutils Workbench",
        "coreutilsVersion": version,
        "packageVersion": package,
        "uname": subprocess.check_output(["uname", "-srm"], text=True).strip(),
        "locale": "en_US.UTF-8",
        "umask": umask,
        "filesystemDf": df_line[1],
        "filesystemStat": statfs,
        "user": subprocess.check_output(["id", "-un"], text=True).strip(),
        "capturedAt": dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat(),
        "python": sys.version.split()[0],
        "kernelNote": (
            "stat -f prints ext2/ext3 on this ext4 filesystem because those "
            "filesystems share a statfs type code. df -T is the string to trust for the type name."
        ),
        "manualLocal": "/usr/share/info/coreutils.info.gz (coreutils 9.4)",
        "manualHtml": "https://www.gnu.org/software/coreutils/manual/html_node/",
        "stdbufLibrary": "/usr/libexec/coreutils/libstdbuf.so",
        "limits": [
            "No command targeted the real root directory, a block device, or another user's files.",
            "Caches were not dropped. No sysctl or other root tuning was applied.",
            "Allocations in benchmarks stay at or below 8 MiB of payload, plus sort's own buffers.",
            "BSD and macOS command lines were not executed. Those notes are documented differences.",
            "chown, chgrp to another user, chroot, mknod of devices, and SELinux changes fail or are not attempted where they need privileges this sandbox does not have.",
            "stty was not pointed at the session terminal, because it changes terminal modes.",
            "shred examples use one pass on a scratch file and do not claim the bytes are gone from the device.",
        ],
    }


def search_index(course: dict) -> list[dict]:
    rows = []
    for lesson in course["lessons"]:
        rows.append(
            {
                "kind": "lesson",
                "slug": lesson["slug"],
                "title": lesson["title"],
                "module": lesson["module"],
                "summary": lesson["summary"],
                "number": lesson["number"],
                "text": re.sub(r"```.*?```", " ", lesson["markdown"], flags=re.S)[:4000],
            }
        )
    for recipe in course["cookbook"]:
        rows.append(
            {
                "kind": "cookbook",
                "slug": recipe["slug"],
                "title": recipe["title"],
                "module": "Cookbook",
                "summary": recipe["summary"],
                "number": recipe["number"],
                "text": recipe["summary"],
            }
        )
    for entry in course["reference"]:
        rows.append(
            {
                "kind": "reference",
                "slug": entry["slug"],
                "title": entry["name"],
                "module": entry["section"],
                "summary": entry["summary"],
                "number": 0,
                "text": entry["note"],
            }
        )
    for entry in course.get("companions", []):
        rows.append(
            {
                "kind": "companion",
                "slug": entry.get("lesson") or "reference",
                "title": entry["name"],
                "module": entry.get("group") or "Companion Tools",
                "summary": entry["note"],
                "number": 0,
                "text": " ".join(
                    [
                        entry["name"],
                        entry.get("project", ""),
                        entry.get("package", ""),
                        entry["note"],
                        "not coreutils",
                    ]
                ),
            }
        )
    for slug, title, summary in (
        ("method", "Method and limits", "version filesystem benchmarks GNU versus BSD"),
        ("benchmarks", "Benchmarks", "median elapsed user system RSS warm cache"),
        ("progress", "Progress", "localStorage completion"),
    ):
        rows.append(
            {
                "kind": "page",
                "slug": slug,
                "title": title,
                "module": "Site",
                "summary": summary,
                "number": 0,
                "text": summary,
            }
        )
    return rows


def zip_examples() -> None:
    archive = PUBLIC / "downloads" / "coreutils-examples.zip"
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as handle:
        base = PUBLIC / "downloads"
        for path in sorted(base.rglob("*.sh")):
            handle.write(path, path.relative_to(base))
        for path in sorted((base / "benchmarks").glob("*")):
            if path.is_file():
                handle.write(path, path.relative_to(base))


def copy_benchmarks() -> None:
    dest = PUBLIC / "downloads" / "benchmarks"
    dest.mkdir(parents=True, exist_ok=True)
    for path in (ROOT / "benchmarks").iterdir():
        if path.is_file():
            shutil.copy2(path, dest / path.name)


def source_for(slug: str) -> tuple[Path, str]:
    for directory, kind in ((LESSONS, "lesson"), (COOKBOOK, "cookbook")):
        for path in sorted(directory.glob("*.md")):
            meta, _body = parse_frontmatter(path.read_text())
            if meta.get("slug") == slug:
                return path, kind
    fail(f"no lesson or cookbook with slug {slug}")
    raise AssertionError


def replace_document(rows: list[dict], document: dict) -> list[dict]:
    kept = [row for row in rows if row["slug"] != document["slug"]]
    kept.append(document)
    kept.sort(key=lambda item: item["number"])
    return kept


def main() -> None:
    skip_benches = "--skip-benches" in sys.argv
    refresh_reference = "--refresh-reference" in sys.argv
    only: list[str] = []
    if "--only" in sys.argv:
        index = sys.argv.index("--only")
        if index + 1 >= len(sys.argv):
            fail("--only needs a comma-separated slug list")
        only = [item for item in sys.argv[index + 1].split(",") if item]
        skip_benches = True
    partial = bool(only) or refresh_reference
    if not partial:
        if PUBLIC.joinpath("downloads", "examples").exists():
            shutil.rmtree(PUBLIC / "downloads" / "examples")
        if PUBLIC.joinpath("downloads", "solutions").exists():
            shutil.rmtree(PUBLIC / "downloads" / "solutions")
        lessons = []
        for path in sorted(LESSONS.glob("*.md")):
            print(f"lesson {path.name}", flush=True)
            lessons.append(load_document(path, "lesson"))
        cookbook = []
        for path in sorted(COOKBOOK.glob("*.md")):
            print(f"cookbook {path.name}", flush=True)
            cookbook.append(load_document(path, "cookbook"))
        lessons.sort(key=lambda item: item["number"])
        cookbook.sort(key=lambda item: item["number"])
        course = {
            "meta": meta(),
            "lessons": lessons,
            "cookbook": cookbook,
            "reference": reference_entries(),
            "companions": companions(),
        }
    else:
        course_path = GENERATED / "course.json"
        if not course_path.is_file():
            fail("partial assemble needs content/generated/course.json")
        course = json.loads(course_path.read_text())
        for slug in only:
            path, kind = source_for(slug)
            print(f"{kind} {path.name}", flush=True)
            document = load_document(path, kind)
            key = "lessons" if kind == "lesson" else "cookbook"
            course[key] = replace_document(course[key], document)
        if refresh_reference or not only:
            print("reference", flush=True)
            course["reference"] = reference_entries()
            course["companions"] = companions()
    if len(course["lessons"]) < 30:
        fail(f"only {len(course['lessons'])} lessons")
    GENERATED.mkdir(parents=True, exist_ok=True)
    (GENERATED / "course.json").write_text(json.dumps(course))
    (PUBLIC / "search-index.json").write_text(json.dumps(search_index(course)))
    copy_benchmarks()
    if not skip_benches:
        out = PUBLIC / "benchmarks" / "sample-run.json"
        out.parent.mkdir(parents=True, exist_ok=True)
        subprocess.check_call(
            [sys.executable, str(ROOT / "benchmarks" / "run_all.py"), str(out)]
        )
    elif not (PUBLIC / "benchmarks" / "sample-run.json").exists():
        fail("sample benchmark missing and --skip-benches was set")
    zip_examples()
    lessons = course["lessons"]
    cookbook = course["cookbook"]
    print(
        f"lessons={len(lessons)} cookbook={len(cookbook)} "
        f"examples={sum(len(item['examples']) for item in lessons)} "
        f"exercises={sum(len(item['exercises']) for item in lessons)} "
        f"cookbook_examples={sum(len(item['examples']) for item in cookbook)} "
        f"cookbook_exercises={sum(len(item['exercises']) for item in cookbook)} "
        f"reference={len(course['reference'])}"
    )


if __name__ == "__main__":
    main()
