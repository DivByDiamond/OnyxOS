#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== OnyxOS QEMU Launcher ==="
echo ""

BUILD_DIR="$(pwd)/.build"

# Auto-build if no artifacts
if [ ! -f "$BUILD_DIR/onyx-kernel.elf" ]; then
    echo "[*] No builds found - running build-all first..."
    bash scripts/build-all.sh
fi

KERNEL="$BUILD_DIR/onyx-kernel.elf"
BOOT="$BUILD_DIR/onyx-boot.elf"

echo "[*] Launching QEMU..."
echo "    Kernel: ${KERNEL}"
echo ""

qemu-system-riscv64 \
    -machine virt \
    -m 128M \
    -nographic \
    -bios default \
    -kernel "$KERNEL" \
    "$@"
