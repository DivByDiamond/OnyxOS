#!/usr/bin/env bash
# mk-onyxfs-disk.sh — create a complete OnyxOS disk image with two partitions:
#
#   Partition 1 (FAT32, ~16 MiB)  — kernel.elf (loaded by OnyxBoot)
#   Partition 2 (OnyxFS, ~32 MiB) — rootfs:
#       /bin/init        (PID 1 — service manager)
#       /bin/login       (auth)
#       /bin/osh         (shell)
#       /bin/passwd      (change password)
#       /bin/useradd     (add user)
#       /bin/userdel     (remove user)
#       /etc/passwd      (user database)
#       /etc/shadow      (password hashes — empty on first boot)
#       /font/default.psf (PSF1 font for framebuffer console)
#       /users/          (home dirs created on first boot)
#       /tmp/            (writable temp dir)
#       /ipc/            (IPC mountpoint, created by kernel)
#       /proc/           (procfs mountpoint, created by kernel)
#       /dev/            (devfs mountpoint, created by kernel)
#
# Layout: MBR + 2 primary partitions. OnyxBoot scans all partitions and
# loads kernel.elf from the first FAT32 it finds. OnyxKernel then mounts
# the OnyxFS partition as the root filesystem (it tries every partition).
#
# Output: .build/onyx-boot-disk.img (a ~50 MiB raw disk image)
#
# Requires:
#   - parted (partition table)
#   - dosfstools (mkfs.fat, mcopy)
#   - OnyxKernel's mkimage + elf2onx tools (built via `cargo tbuild`)
#   - All Onyx components already built (run build-all.sh first)
set -euo pipefail

cd "$(dirname "$0")/.."

BUILD_DIR="$(pwd)/.build"
VENT_REPOS="$(pwd)/.vent/repos"
DISK_IMG="$BUILD_DIR/onyx-boot-disk.img"
ROOTFS_IMG="$BUILD_DIR/onyxfs-rootfs.img"   # intermediate file

# Sanity checks
KERNEL_ELF="$BUILD_DIR/onyx-kernel.elf"
OSH_ONX="$BUILD_DIR/osh.onx"
if [ ! -f "$KERNEL_ELF" ]; then
    echo "[-] $KERNEL_ELF not found — run 'bash scripts/build-all.sh' first."
    exit 1
fi
if [ ! -f "$OSH_ONX" ]; then
    echo "[-] $OSH_ONX not found — run 'bash scripts/build-all.sh' first."
    exit 1
fi

for tool in parted mkfs.fat mcopy; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "[-] Required tool '$tool' not found."
        echo "    Arch:   sudo pacman -S parted dosfstools mtools"
        echo "    Debian: sudo apt install parted dosfstools mtools"
        exit 1
    fi
done

# Locate mkimage and elf2onx — they are built by `cargo tbuild` from
# OnyxKernel/tools. build-all.sh runs cargo kbuild which builds the kernel
# but does NOT build the tools. We trigger the build here on first use.
ONYXKERNEL_DIR="$VENT_REPOS/OnyxKernel"
HOST_TARGET=$(rustc -vV 2>/dev/null | sed -ne 's/^host: //p')
if [ -z "$HOST_TARGET" ]; then
    echo "[-] Cannot determine rustc host target. Is rustup in PATH?"
    exit 1
fi
MKIMAGE="$ONYXKERNEL_DIR/target/$HOST_TARGET/release/mkimage"
ELF2ONX="$ONYXKERNEL_DIR/target/$HOST_TARGET/release/elf2onx"
PSFGEN="$ONYXKERNEL_DIR/target/$HOST_TARGET/release/psfgen"

if [ ! -x "$MKIMAGE" ] || [ ! -x "$ELF2ONX" ] || [ ! -x "$PSFGEN" ]; then
    echo "[*] Building OnyxKernel tools (mkimage, elf2onx, psfgen)..."
    (cd "$ONYXKERNEL_DIR" && cargo tbuild 2>&1 | tail -5)
fi
if [ ! -x "$MKIMAGE" ] || [ ! -x "$ELF2ONX" ] || [ ! -x "$PSFGEN" ]; then
    echo "[-] Tools missing after build attempt. Check cargo output above."
    exit 1
fi

# ── 1. Build init + login + passwd + useradd + userdel as .onx binaries ──
# These are Rust binaries from OnyxKernel/init, each with its own [[bin]]
# entry in Cargo.toml. We build them all in release mode for riscv64gc, then
# convert each to .onx with elf2onx --ring=1 (they run in root space).
echo "[*] Building init/login/passwd/useradd/userdel (onyx_init crate)..."
(
    cd "$ONYXKERNEL_DIR"
    cargo ibuild 2>&1 | tail -5
)
INIT_TARGET="$ONYXKERNEL_DIR/target/riscv64gc-unknown-none-elf/release"

# Locate each binary; build will produce onyx-init, onyx-login, etc.
INIT_ELF="$INIT_TARGET/onyx-init"
LOGIN_ELF="$INIT_TARGET/onyx-login"
PASSWD_ELF="$INIT_TARGET/onyx-passwd"
USERADD_ELF="$INIT_TARGET/onyx-useradd"
USERDEL_ELF="$INIT_TARGET/onyx-userdel"

for elf in "$INIT_ELF" "$LOGIN_ELF" "$PASSWD_ELF" "$USERADD_ELF" "$USERDEL_ELF"; do
    if [ ! -f "$elf" ]; then
        echo "[-] Expected binary not found: $elf"
        echo "    (Did cargo ibuild succeed? Check 'init/Cargo.toml [[bin]]' entries.)"
        exit 1
    fi
done

# Convert each ELF → .onx (ring 1, root space)
echo "[*] Converting ELFs → .onx (ring 1)..."
TMP_ONX_DIR="$BUILD_DIR/.tmp-onx"
mkdir -p "$TMP_ONX_DIR"
"$ELF2ONX" --ring=1 "$INIT_ELF"   "$TMP_ONX_DIR/init.onx"
"$ELF2ONX" --ring=1 "$LOGIN_ELF"  "$TMP_ONX_DIR/login.onx"
"$ELF2ONX" --ring=1 "$PASSWD_ELF"  "$TMP_ONX_DIR/passwd.onx"
"$ELF2ONX" --ring=1 "$USERADD_ELF" "$TMP_ONX_DIR/useradd.onx"
"$ELF2ONX" --ring=1 "$USERDEL_ELF" "$TMP_ONX_DIR/userdel.onx"
cp "$OSH_ONX" "$TMP_ONX_DIR/osh.onx"

# ── 2. Generate the PSF1 font ─────────────────────────────────────────
echo "[*] Generating PSF1 font..."
"$PSFGEN" "$TMP_ONX_DIR/default.psf"

# ── 3. Write /etc/passwd and /etc/shadow (empty — first-boot setup) ────
# OnyxKernel's /bin/login detects when /etc/passwd is empty and prompts
# the user to set a root password interactively.
cat > "$TMP_ONX_DIR/passwd.txt" <<'EOF'
EOF
cat > "$TMP_ONX_DIR/shadow.txt" <<'EOF'
EOF

# ── 4. Create a manifest for mkimage ────────────────────────────────────
# mkimage reads a manifest listing all directories and files to put on the
# OnyxFS partition.
MANIFEST="$TMP_ONX_DIR/manifest.txt"
cat > "$MANIFEST" <<'EOF'
# OnyxFS rootfs manifest
dir /bin
dir /etc
dir /font
dir /users
dir /tmp
dir /ipc
dir /proc
dir /dev
dir /service
# NOTE: mkimage expects "file <host_path> <fs_path>" — host path FIRST.
file $TMP_ONX_DIR/init.onx /bin/init
file $TMP_ONX_DIR/login.onx /bin/login
file $TMP_ONX_DIR/osh.onx /bin/osh
file $TMP_ONX_DIR/passwd.onx /bin/passwd
file $TMP_ONX_DIR/useradd.onx /bin/useradd
file $TMP_ONX_DIR/userdel.onx /bin/userdel
file $TMP_ONX_DIR/passwd.txt /etc/passwd
file $TMP_ONX_DIR/shadow.txt /etc/shadow
file $TMP_ONX_DIR/default.psf /font/default.psf
EOF

# mkimage uses literal path strings in the manifest — substitute $TMP_ONX_DIR
sed -i "s|\$TMP_ONX_DIR|$TMP_ONX_DIR|g" "$MANIFEST"

# ── 5. Build the OnyxFS rootfs image ───────────────────────────────────
echo "[*] Building OnyxFS rootfs image..."
"$MKIMAGE" "$MANIFEST" "$ROOTFS_IMG"
ROOTFS_SIZE=$(stat -c%s "$ROOTFS_IMG")
echo "    OnyxFS image: $ROOTFS_IMG ($((ROOTFS_SIZE / 1024)) KiB)"

# ── 6. Build the final two-partition disk image ────────────────────────
# Layout (MBR, 512-byte sectors):
#   0 - 2047            : MBR + reserved
#   2048 - 10239        : FAT32 partition 1 (4 MiB), kernel.elf at root
#   10240 - end         : OnyxFS partition 2 (rootfs)
#
# IMPORTANT: partition 2 MUST start at sector 10240 — OnyxKernel hardcodes
# ONYXFS_LBA=10240 (arch/regs.rs) and scans exactly LBA 0 and LBA 10240.
DISK_SIZE_MB=64
PART1_START=2048                 # 1 MiB offset (conventional)
PART1_END=10239                  # -> FAT32 partition is exactly 4 MiB
PART2_START=10240                # = kernel's ONYXFS_LBA
echo "[*] Creating disk image ($DISK_SIZE_MB MiB, 2 partitions)..."
dd if=/dev/zero of="$DISK_IMG" bs=1M count="$DISK_SIZE_MB" status=none

# MBR partition table with two primary partitions
parted -s "$DISK_IMG" mklabel msdos
parted -s "$DISK_IMG" mkpart primary fat32 "${PART1_START}s" "${PART1_END}s"
# NOTE: parted has no "onyxfs" type — ext4 hint gives MBR type 0x83 (Linux),
# which is what OnyxBoot's MBR scan expects for the rootfs partition.
parted -s "$DISK_IMG" mkpart primary ext4 "${PART2_START}s" 100%

# Format + populate FAT32 partition 1 with kernel.elf.
# IMPORTANT: we build the FAT filesystem in a standalone temp file sized
# exactly to the partition (8192 sectors), then dd it into the disk image.
# Using 'mkfs.fat --offset' without an explicit size makes mkfs.fat assume
# the FS extends to end-of-image, so later mtools writes can dirty metadata
# beyond the partition boundary and corrupt partition 2's OnyxFS superblock.
PART1_SECTORS=$((PART1_END - PART1_START + 1))
FAT_TMP="$BUILD_DIR/.fat32-p1.img"
echo "[*] Formatting FAT32 partition 1..."
truncate -s $((PART1_SECTORS * 512)) "$FAT_TMP"
mkfs.fat -F 32 "$FAT_TMP" >/dev/null
mcopy -i "$FAT_TMP" "$KERNEL_ELF" ::kernel.elf
dd if="$FAT_TMP" of="$DISK_IMG" bs=512 seek="$PART1_START" conv=notrunc status=none
rm -f "$FAT_TMP"

# Write the OnyxFS image into partition 2.
# We can't use mcopy (OnyxFS isn't a FAT). Instead we dd the pre-built
# OnyxFS image directly into the disk at the partition 2 offset.
PART2_OFFSET_BYTES=$((PART2_START * 512))
PART2_AVAILABLE=$((DISK_SIZE_MB * 1024 * 1024 - PART2_OFFSET_BYTES))
if [ "$ROOTFS_SIZE" -gt "$PART2_AVAILABLE" ]; then
    echo "[-] OnyxFS image ($ROOTFS_SIZE bytes) doesn't fit in partition 2"
    echo "    (available: $PART2_AVAILABLE bytes, $((PART2_AVAILABLE / 1024 / 1024)) MiB)"
    echo "    Increase DISK_SIZE_MB in $0"
    exit 1
fi
echo "[*] Writing OnyxFS into partition 2 (offset $PART2_OFFSET_BYTES bytes)..."
dd if="$ROOTFS_IMG" of="$DISK_IMG" bs=512 seek="$PART2_START" conv=notrunc status=none

# Cleanup intermediate files
rm -f "$ROOTFS_IMG"
# Keep $TMP_ONX_DIR for debugging — remove with: rm -rf "$TMP_ONX_DIR"

echo ""
echo "[+] Boot disk created: $DISK_IMG"
echo "    Size: $(du -h "$DISK_IMG" | cut -f1)"
echo "    Layout: MBR + 2 partitions"
echo "      p1: FAT32 $((PART1_END - PART1_START + 1)) sectors ($(echo "scale=1;($PART1_END-$PART1_START+1)/2/1024" | bc) MiB) — kernel.elf"
echo "      p2: OnyxFS ($(echo "scale=1;$PART2_AVAILABLE/1024/1024" | bc) MiB) — /bin/init /bin/login /bin/osh /etc/passwd ..."
echo ""
echo "Use with OnyxBoot via:"
echo "    qemu-system-riscv64 -M virt -m 256M -bios .build/onyx-boot.bin \\"
echo "        -drive file=.build/onyx-boot-disk.img,format=raw,if=none,id=drive0 \\"
echo "        -device virtio-blk-device,drive=drive0 -nographic"
