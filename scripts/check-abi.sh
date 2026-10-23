#!/usr/bin/env bash
# Validate coordinated ABI snapshots when using the registry-aware kernel.
set -euo pipefail
REPOS=${1:?component checkout directory required}
GENERATOR="$REPOS/OnyxKernel/scripts/generate-syscalls.py"
if [ -f "$GENERATOR" ]; then
    python3 "$GENERATOR" --check \
        --shell-dir "$REPOS/OnyxShell" \
        --compiler-dir "$REPOS/OnyxCompiller"
else
    echo "[ABI] Legacy kernel revision: no registry generator; using its committed ABI snapshots."
fi
