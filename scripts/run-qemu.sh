#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== OnyxOS QEMU Launcher ==="
echo ""

BUILD_DIR="$(pwd)/.build"

# Auto-build if no kernel artifact
if [ ! -f "$BUILD_DIR/onyx-kernel.elf" ]; then
    echo "[*] No builds found - running build-all first..."
    bash scripts/build-all.sh
fi

KERNEL="$BUILD_DIR/onyx-kernel.elf"

echo "[*] Launching QEMU..."
echo "    Kernel: ${KERNEL}"
echo ""

# QEMU virt machine has a built-in ROM loader at the default -bios that
# jumps to 0x80000000. We pass the kernel via -kernel which QEMU loads
# directly via its generic kernel loader. For a real Milk-V Duo S boot,
# you would write bootloader.bin to SD and the bootloader would chain-load
# onyx-kernel.elf from OnyxFS — but for dev/test we skip the bootloader.
qemu-system-riscv64 \
    -machine virt \
    -m 128M \
    -nographic \
    -bios default \
    -kernel "$KERNEL" \
    "$@"
