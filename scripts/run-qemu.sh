#!/usr/bin/env bash
# run-qemu.sh — launch OnyxOS in QEMU.
#
# Two modes (selected via $1 or first positional arg):
#
#   default / boot     — Full boot chain: OpenSBI → OnyxBoot → kernel.elf
#                        from a FAT32 disk image. This is the realistic
#                        OnyxOS boot path on Milk-V Duo S.
#
#   dev                — Dev/test mode: OpenSBI → onyx-kernel.elf via QEMU's
#                        generic -kernel loader. Faster (no disk image
#                        creation) but skips OnyxBoot entirely.
#
# Override defaults via env vars:
#   QEMU_MEM=256M              — RAM size
#   QEMU_EXTRA="..."           — extra qemu args (e.g. -s -S for gdb)
set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== OnyxOS QEMU Launcher ==="
echo ""

BUILD_DIR="$(pwd)/.build"
MODE="${1:-boot}"

# Auto-build if no kernel artifact
if [ ! -f "$BUILD_DIR/onyx-kernel.elf" ]; then
    echo "[*] No builds found - running build-all first..."
    bash scripts/build-all.sh
fi

QEMU_MEM="${QEMU_MEM:-256M}"

case "$MODE" in
    dev|quick)
        # Dev mode: skip OnyxBoot entirely, load kernel via QEMU loader.
        # This is fastest for kernel development — no disk image, no
        # bootloader logic, just OpenSBI → kernel.
        KERNEL="$BUILD_DIR/onyx-kernel.elf"
        echo "[*] Mode: dev (skipping OnyxBoot, QEMU loads kernel directly)"
        echo "    Kernel: $KERNEL"
        echo ""
        exec qemu-system-riscv64 \
            -machine virt \
            -m "$QEMU_MEM" \
            -nographic \
            -bios default \
            -kernel "$KERNEL" \
            ${QEMU_EXTRA:-}
        ;;

    boot|full)
        # Full boot mode: OnyxBoot scans VirtIO for the disk image,
        # parses MBR/FAT32, loads kernel.elf, jumps to entry.
        BOOT_BIN="$BUILD_DIR/onyx-boot.bin"
        DISK_IMG="$BUILD_DIR/onyx-boot-disk.img"

        if [ ! -f "$BOOT_BIN" ]; then
            echo "[-] $BOOT_BIN not found — run 'bash scripts/build-all.sh' first."
            exit 1
        fi
        if [ ! -f "$DISK_IMG" ]; then
            # Same script build-all.sh step 5 runs. It needs the artifacts
            # produced by build-all.sh (onyx-kernel.elf, osh.onx, apps.list)
            # plus parted/mkfs.fat/mcopy, so it is the only supported way to
            # produce the disk outside the full pipeline.
            echo "[*] Boot disk not found — creating it now..."
            if ! bash scripts/mk-onyxfs-disk.sh; then
                echo "[-] Failed to create $DISK_IMG." >&2
                echo "    Run 'bash scripts/build-all.sh' (needs parted, dosfstools, mtools)" >&2
                echo "    or use 'bash scripts/run-qemu.sh dev' to skip OnyxBoot." >&2
                exit 1
            fi
        fi

        echo "[*] Mode: full boot chain (OpenSBI is replaced by OnyxBoot as -bios)"
        echo "    BIOS:    $BOOT_BIN"
        echo "    Disk:    $DISK_IMG"
        echo ""
        exec qemu-system-riscv64 \
            -machine virt \
            -m "$QEMU_MEM" \
            -nographic \
            -bios "$BOOT_BIN" \
            -drive file="$DISK_IMG",format=raw,if=none,id=drive0 \
            -device virtio-blk-device,drive=drive0 \
            ${QEMU_EXTRA:-}
        ;;

    *)
        echo "Usage: $0 [dev|boot]"
        echo "  dev   — skip OnyxBoot, load kernel directly (faster, no disk)"
        echo "  boot  — full chain: OnyxBoot reads kernel.elf from FAT32 disk (default)"
        echo ""
        echo "Env vars:"
        echo "  QEMU_MEM=256M     — RAM size"
        echo "  QEMU_EXTRA=\"...\" — extra qemu args"
        exit 1
        ;;
esac
