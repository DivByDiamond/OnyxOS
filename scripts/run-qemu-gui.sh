#!/usr/bin/env bash
# run-qemu-gui.sh — launch OnyxOS in QEMU with a real GUI window.
#
# This is the primary script for run+test: same build/boot logic as
# run-qemu.sh, but instead of -nographic it opens a separate QEMU GUI
# window (GTK display) and streams the serial/UART boot log to this
# terminal (and to .build/serial.log) without blocking on it.
#
# `-device ramfb` attaches QEMU's fw_cfg-based framebuffer so the
# kernel's ramfb driver (drivers/video/ramfb.rs) has something real to
# paint into — without it, fb::init falls back to invisible pmm RAM
# and the GTK window only shows the QEMU monitor console, not the
# kernel's actual video output.
#
# Two modes (selected via $1 or first positional arg), same as run-qemu.sh:
#
#   default / boot     — Full boot chain: OpenSBI → OnyxBoot → kernel.elf
#                        from a FAT32 disk image.
#   dev                — Dev/test mode: OpenSBI → onyx-kernel.elf via QEMU's
#                        generic -kernel loader. Faster, skips OnyxBoot.
#
# Override defaults via env vars:
#   QEMU_MEM=256M          — RAM size
#   QEMU_DISPLAY=gtk       — QEMU display backend (gtk|sdl|none)
#   QEMU_EXTRA="..."       — extra qemu args (e.g. -s -S for gdb)
set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== OnyxOS QEMU Launcher (GUI) ==="
echo ""

BUILD_DIR="$(pwd)/.build"
MODE="${1:-boot}"

# Auto-build if no kernel artifact
if [ ! -f "$BUILD_DIR/onyx-kernel.elf" ]; then
    echo "[*] No builds found - running build-all first..."
    bash scripts/build-all.sh
fi

QEMU_MEM="${QEMU_MEM:-256M}"
QEMU_DISPLAY="${QEMU_DISPLAY:-gtk}"
SERIAL_LOG="$BUILD_DIR/serial.log"
: > "$SERIAL_LOG"

run_qemu() {
    qemu-system-riscv64 "$@" -serial stdio -display "$QEMU_DISPLAY" 2>&1 | tee "$SERIAL_LOG" &
    QEMU_PID=$!
    echo "[*] QEMU running (pid=$QEMU_PID) — GUI window should appear now."
    echo "    Serial log: $SERIAL_LOG (tail -f it to watch boot output here)"
    echo "    Press Ctrl+C here to stop, or close the QEMU window."
    wait "$QEMU_PID"
}

case "$MODE" in
    dev|quick)
        KERNEL="$BUILD_DIR/onyx-kernel.elf"
        echo "[*] Mode: dev (skipping OnyxBoot, QEMU loads kernel directly)"
        echo "    Kernel: $KERNEL"
        echo ""
        run_qemu \
            -machine virt \
            -m "$QEMU_MEM" \
            -bios default \
            -kernel "$KERNEL" \
            -device ramfb \
            ${QEMU_EXTRA:-}
        ;;

    boot|full)
        BOOT_BIN="$BUILD_DIR/onyx-boot.bin"
        DISK_IMG="$BUILD_DIR/onyx-boot-disk.img"

        if [ ! -f "$BOOT_BIN" ]; then
            echo "[-] $BOOT_BIN not found — run 'bash scripts/build-all.sh' first."
            exit 1
        fi
        if [ ! -f "$DISK_IMG" ]; then
            echo "[*] Boot disk not found — creating it now..."
            bash scripts/mk-boot-disk.sh
        fi

        echo "[*] Mode: full boot chain (OpenSBI is replaced by OnyxBoot as -bios)"
        echo "    BIOS:    $BOOT_BIN"
        echo "    Disk:    $DISK_IMG"
        echo ""
        run_qemu \
            -machine virt \
            -m "$QEMU_MEM" \
            -bios "$BOOT_BIN" \
            -drive file="$DISK_IMG",format=raw,if=none,id=drive0 \
            -device virtio-blk-device,drive=drive0 \
            -device ramfb \
            ${QEMU_EXTRA:-}
        ;;

    *)
        echo "Usage: $0 [dev|boot]"
        echo "  dev   — skip OnyxBoot, load kernel directly (faster, no disk)"
        echo "  boot  — full chain: OnyxBoot reads kernel.elf from FAT32 disk (default)"
        echo ""
        echo "Env vars:"
        echo "  QEMU_MEM=256M       — RAM size"
        echo "  QEMU_DISPLAY=gtk    — QEMU display backend (gtk|sdl|none)"
        echo "  QEMU_EXTRA=\"...\"   — extra qemu args"
        exit 1
        ;;
esac
