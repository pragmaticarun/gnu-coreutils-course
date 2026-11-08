#!/usr/bin/env python3
"""Check the static export for missing local targets and banned filler text."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "out"
BANNED = ("lorem ipsum", "todo:", "placeholder text", "welcome to your app")


def fail(message: str) -> None:
    raise SystemExit(message)


def local_targets(html_path: Path) -> list[str]:
    text = html_path.read_text(errors="replace")
    found = []
    for match in re.finditer(r"""(?:href|src)=["']([^"']+)["']""", text):
        raw = match.group(1).strip()
        if not raw or raw.startswith(("#", "mailto:", "data:", "javascript:")):
            continue
        parsed = urlparse(raw)
        if parsed.scheme in {"http", "https"} or parsed.netloc:
            continue
        found.append(unquote(parsed.path))
    return found


def resolve(url_path: str) -> Path | None:
    path = url_path.split("?", 1)[0]
    if not path.startswith("/"):
        return None
    rel = path.lstrip("/")
    candidate = OUT / rel
    if candidate.is_file():
        return candidate
    if candidate.is_dir() and (candidate / "index.html").is_file():
        return candidate / "index.html"
    index = OUT / rel / "index.html"
    if index.is_file():
        return index
    html = OUT / f"{rel}.html"
    if html.is_file():
        return html
    return None


def main() -> None:
    if not OUT.is_dir():
        fail("out/ is missing. Run npm run build first.")
    pages = list(OUT.rglob("*.html"))
    if not pages:
        fail("no html in out/")
    missing: list[str] = []
    banned_hits: list[str] = []
    checked = 0
    for page in pages:
        text = page.read_text(errors="replace").lower()
        for phrase in BANNED:
            if phrase in text:
                banned_hits.append(f"{page.relative_to(OUT)} contains {phrase!r}")
        for target in local_targets(page):
            checked += 1
            if resolve(target) is None:
                missing.append(f"{page.relative_to(OUT)} -> {target}")
    required = [
        OUT / "index.html",
        OUT / "lessons" / "index.html",
        OUT / "cookbook" / "index.html",
        OUT / "reference" / "index.html",
        OUT / "benchmarks" / "index.html",
        OUT / "method" / "index.html",
        OUT / "progress" / "index.html",
        OUT / "search-index.json",
        OUT / "downloads" / "coreutils-examples.zip",
        OUT / "benchmarks" / "sample-run.json",
    ]
    for path in required:
        if not path.is_file():
            missing.append(f"missing required file {path.relative_to(OUT)}")
    if banned_hits or missing:
        print("\n".join(banned_hits + missing[:80]))
        fail(f"{len(missing)} missing targets, {len(banned_hits)} banned phrases, {checked} local refs")
    print(f"ok pages={len(pages)} local_refs={checked}")


if __name__ == "__main__":
    main()
