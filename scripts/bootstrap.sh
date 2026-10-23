#!/usr/bin/env bash
# Fetch exact component revisions; refuse dirty or symlinked worktrees.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 scripts/dependencies.py sync
