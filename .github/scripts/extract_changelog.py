#!/usr/bin/env python3
"""Print one version section of CHANGELOG.md for use as GitHub Release body.

Usage: extract_changelog.py <version>
Exits non-zero when the file or the requested section is missing/empty, so a
version bump without release notes fails the workflow instead of publishing an
empty announcement.
"""

import re
import sys
from pathlib import Path

CHANGELOG = Path("CHANGELOG.md")
HEADING = re.compile(r"^##\s+\[?v?(\d+(?:\.\d+)+[^\s\]]*)\]?")


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit("usage: extract_changelog.py <version>")

    version = sys.argv[1].strip()
    if not CHANGELOG.is_file():
        sys.exit("CHANGELOG.md not found in repository root")

    lines = CHANGELOG.read_text(encoding="utf-8").splitlines()
    sections = []
    for index, line in enumerate(lines):
        match = HEADING.match(line)
        if match:
            sections.append((index, match.group(1)))

    target = next((item for item in sections if item[1] == version), None)
    if target is None:
        available = ", ".join(v for _, v in sections[:6]) or "(none)"
        sys.exit(
            f"CHANGELOG.md has no section for version {version}. "
            f"Available sections: {available}"
        )

    start = target[0]
    end = next((i for i, _ in sections if i > start), len(lines))
    body = "\n".join(lines[start + 1:end]).strip()
    if not body:
        sys.exit(f"CHANGELOG.md section {version} is empty")

    print(body)


if __name__ == "__main__":
    main()
