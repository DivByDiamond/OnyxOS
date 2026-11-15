#!/usr/bin/env bash
# Run the complete Rust lint matrix and dead-code guard for all components.
set -euo pipefail
cd "$(dirname "$0")/../.."
repos="${1:-$(pwd)/.vent/repos}"
repos="$(cd "$repos" && pwd)"
for name in OnyxKernel OnyxBoot OnyxShell OnyxCompiller OnyxApps OnyxOS; do
    repo="$repos/$name"
    if [ "$name" = OnyxOS ]; then repo="$(pwd)"; fi
    python3 "$repos/OnyxKernel/scripts/quality/no-dead-allow.py" "$repo"
done
(cd "$repos/OnyxKernel" && bash scripts/quality/check.sh)
(
    cd "$repos/OnyxShell"
    cargo fmt --all -- --check
    cargo clippy --target x86_64-unknown-linux-gnu --test stdio --test quoting -- -D warnings
    cargo clippy --target riscv64gc-unknown-none-elf --bin onyx-osh -- -D warnings
)
