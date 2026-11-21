#!/usr/bin/env python3
"""Check that the ecosystem table is identical across repository READMEs.

The reference table lives in docs/dev/readme-style.md, section
"Таблица экосистемы". Every repository README must carry it verbatim
twice: once in the English part, once in the Russian part.

Usage:
    check-ecosystem-table.py [REPO ...]

Without arguments the script checks every sibling Onyx* checkout next
to this repository (the OnyxOS orchestrator). With arguments it checks
only the given repository directories, so CI can self-check the lone
OnyxOS checkout where no siblings exist.

Exit status: 0 if every README matches, 1 otherwise.
"""

import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
SPEC_PATH = REPO_ROOT / "docs" / "dev" / "readme-style.md"
SPEC_HEADING = "## Таблица экосистемы"
EXPECTED_OCCURRENCES = 2  # English part + Russian part.


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def reference_table() -> list[str]:
    """Return the reference table lines from the README style spec."""
    try:
        lines = SPEC_PATH.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        fail(f"cannot read {SPEC_PATH}: {exc}")
    heading = next((i for i, ln in enumerate(lines) if ln.startswith(SPEC_HEADING)), None)
    if heading is None:
        fail(f"section '{SPEC_HEADING}' not found in {SPEC_PATH}")
    table: list[str] = []
    for line in lines[heading + 1:]:
        if line.startswith("|"):
            table.append(line)
        elif table:
            break
    if len(table) < 3:
        fail(f"no table found under '{SPEC_HEADING}' in {SPEC_PATH}")
    return table


def count_occurrences(readme_lines: list[str], table: list[str]) -> int:
    """Count exact (verbatim, line-precise) occurrences of the table."""
    size = len(table)
    count = 0
    for start in range(len(readme_lines) - size + 1):
        if readme_lines[start:start + size] == table:
            count += 1
    return count


def main() -> int:
    if len(sys.argv) > 1:
        repos = [Path(arg).resolve() for arg in sys.argv[1:]]
    else:
        repos = sorted(
            path for path in REPO_ROOT.parent.glob("Onyx*")
            if (path / "README.md").is_file()
        )
    table = reference_table()
    failures = 0
    for repo in repos:
        readme = repo / "README.md"
        if not readme.is_file():
            print(f"FAIL {repo.name}: README.md not found in {repo}")
            failures += 1
            continue
        try:
            lines = readme.read_text(encoding="utf-8").splitlines()
        except OSError as exc:
            print(f"FAIL {repo.name}: cannot read README.md: {exc}")
            failures += 1
            continue
        count = count_occurrences(lines, table)
        if count == EXPECTED_OCCURRENCES:
            print(f"PASS {repo.name}: table verbatim in EN and RU parts")
        elif count == 0:
            print(f"FAIL {repo.name}: table missing or differs from the spec")
            failures += 1
        else:
            print(
                f"FAIL {repo.name}: {count} occurrence(s), "
                f"expected {EXPECTED_OCCURRENCES} (EN + RU)"
            )
            failures += 1
    print(f"checked {len(repos)} repo(s), {failures} failed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
