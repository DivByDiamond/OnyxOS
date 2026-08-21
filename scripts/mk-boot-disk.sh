#!/usr/bin/env bash
# mk-boot-disk.sh — create a FAT32 disk image with onyx-kernel.elf at the root,
# suitable for chain-loading by OnyxBoot.
#
# OnyxBoot scans VirtIO/SDHCI for storage devices, parses MBR or GPT,
# mounts the first FAT32 or ext4 partition, and looks for a file called
# `kernel.elf` at the root. It then parses the ELF64, copies segments
# to their virtual addresses, and jumps to the entry point.
#
# This script creates a minimal MBR + FAT32 disk image that contains
# only `kernel.elf` (the OnyxKernel binary). For real production use
# you'd also put /bin/osh, /bin/login, /etc/passwd etc. on the disk,
# but for a smoke-test of the boot chain this is enough.
#
# Usage:
#   bash scripts/mk-boot-disk.sh
#
# Output:
#   .build/onyx-boot-disk.img  (a ~64MB raw disk image)
#
# Requires:
#   - parted (partition table)
#   - dosfstools (mkfs.fat, mcopy)
#   - OnyxKernel already built (.build/onyx-kernel.elf)
set -euo pipefail

cd "$(dirname "$0")/.."

BUILD_DIR="$(pwd)/.build"
DISK_IMG="$BUILD_DIR/onyx-boot-disk.img"
KERNEL_ELF="$BUILD_DIR/onyx-kernel.elf"

if [ ! -f "$KERNEL_ELF" ]; then
    echo "[-] $KERNEL_ELF not found — run 'bash scripts/build-all.sh' first."
    exit 1
fi

# Sanity check that we have the partitioning/format tools.
for tool in parted mkfs.fat mcopy; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "[-] Required tool '$tool' not found."
        echo "    Arch:  sudo pacman -S parted dosfstools mtools"
        echo "    Debian: sudo apt install parted dosfstools mtools"
        exit 1
    fi
done

echo "=== Creating FAT32 boot disk ==="
echo "    Image:  $DISK_IMG"
echo "    Kernel: $KERNEL_ELF"
echo ""

# 1. Create a 64 MiB zeroed image.
dd if=/dev/zero of="$DISK_IMG" bs=1M count=64 status=none

# 2. Create MBR partition table + one primary FAT32 partition starting at 1MiB.
#    Sector 2048 (1 MiB offset) is the conventional first-partition start
#    for 512-byte sectors; OnyxBoot understands this layout (MBR scan).
parted -s "$DISK_IMG" mklabel msdos
parted -s "$DISK_IMG" mkpart primary fat32 1MiB 100%

# 3. Format the partition as FAT32.
#    `--offset=2048` tells mkfs.fat to start the FAT at sector 2048, matching
#    the partition start. mcopy's `@@$((2048*512))` syntax addresses that
#    same offset within the image file.
PART_START_SECTORS=2048
mkfs.fat -F 32 "$DISK_IMG" --offset="$PART_START_SECTORS" >/dev/null

# 4. Copy onyx-kernel.elf → kernel.elf at the FAT32 partition root.
#    OnyxBoot looks specifically for the name `kernel.elf` — keep this name.
mcopy -i "$DISK_IMG@@$((PART_START_SECTORS * 512))" "$KERNEL_ELF" ::kernel.elf

echo "[+] Boot disk created: $DISK_IMG"
echo "    Size: $(du -h "$DISK_IMG" | cut -f1)"
echo "    Layout: MBR + 1 FAT32 partition with kernel.elf at root"
echo ""
echo "Use with OnyxBoot via:"
echo "    qemu-system-riscv64 -M virt -m 256M -bios .build/onyx-boot.bin \\"
echo "        -drive file=.build/onyx-boot-disk.img,format=raw,if=none,id=drive0 \\"
echo "        -device virtio-blk-device,drive=drive0 -nographic"
