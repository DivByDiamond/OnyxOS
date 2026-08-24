#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "=== ULTRA BUILD (opt-level=z + strip) ==="

KTOML="$ROOT/../OnyxKernel/Cargo.toml"
STOML="$ROOT/../OnyxShell/Cargo.toml"

# Save originals
cp "$KTOML" "${KTOML}.bak"
cp "$STOML" "${STOML}.bak"

# Patch → ultra
sed -i 's/opt-level = .*/opt-level = "z"/; s/debug = .*/debug = false/; s/strip = .*/strip = "symbols"/' "$KTOML"
sed -i 's/opt-level = .*/opt-level = "z"/; s/debug = .*/debug = false/; s/strip = .*/strip = "symbols"/' "$STOML"

# Build kernel + init
cargo build --release --target riscv64gc-unknown-none-elf -p onyx_kernel -p onyx_init \
  --manifest-path "$KTOML" 2>&1 | tail -1

# Build shell
bash "$ROOT/../OnyxShell/build.sh" 2>&1 | tail -1

# Restore originals
mv "${KTOML}.bak" "$KTOML"
mv "${STOML}.bak" "$STOML"

echo ""
echo "=== ULTRA SIZES ==="
for f in "$ROOT/../OnyxKernel/target/riscv64gc-unknown-none-elf/release/onyx-"*; do
  [ -f "$f" ] && ls -lh "$f" | awk '{printf "  %s %s\n", $5, $9}'
done
ls -lh "$ROOT/../OnyxShell/build/osh.onx" | awk '{printf "  %s %s\n", $5, $9}'
echo "=== DONE ==="
