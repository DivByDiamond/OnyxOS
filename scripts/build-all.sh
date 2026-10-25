#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Cap build memory (default 6 GiB) so a runaway compiler cannot OOM the host.
# Override with ONYX_BUILD_MEM_LIMIT=<size> or disable with 0/off.
# shellcheck source=scripts/mem-limit.sh
source scripts/mem-limit.sh
onyx_limit_build_memory "$0" "$@"

echo "=== OnyxOS Build All ==="
echo ""

# Bootstrap first if needed
if [ ! -d ".vent/repos/OnyxKernel" ]; then
    echo "[*] Bootstrap needed - resolving dependencies..."
    bash scripts/bootstrap.sh
fi

# Locked builds are the default. Local sibling/symlink trees require opt-in.
python3 scripts/dependencies.py "${ONYX_DEPS_MODE:-check}"
bash scripts/check-abi.sh "$(pwd)/.vent/repos"

BUILD_DIR="$(pwd)/.build"
mkdir -p "$BUILD_DIR"

# 1. Build OnyxBoot
# OnyxBoot's Makefile (default CROSS=riscv64-elf) produces:
#   - bootloader.elf   (ELF64 with debug info stripped)
#   - bootloader.bin    (raw binary, what MaskROM loads)
# We copy both into .build/ for run-qemu.sh and for flashing onto SD.
echo "[*] Building OnyxBoot..."
cd .vent/repos/OnyxBoot
make clean 2>/dev/null || true
make -j"$(nproc)" 2>&1
cp bootloader.elf "$BUILD_DIR/onyx-boot.elf"
cp bootloader.bin "$BUILD_DIR/onyx-boot.bin"
cd "$OLDPWD"
echo "[+] OnyxBoot done"

# 2. Build OnyxKernel
# We use the `kbuild` cargo alias (defined in
# .vent/repos/OnyxKernel/.cargo/config.toml) which expands to
# `cargo build --release -p onyx_kernel --target riscv64gc-unknown-none-elf`.
# Without --target, cargo would compile for the host (x86_64) and the
# init crate's RISC-V inline-asm (`in("a7")` etc.) would fail with
# "invalid register a7: unknown register".
#
# The OnyxKernel Cargo.toml `[[bin]] name = "onyx-kernel"` (not "Onyxos"),
# so the produced binary is at:
#   target/riscv64gc-unknown-none-elf/release/onyx-kernel
echo "[*] Building OnyxKernel..."
cd .vent/repos/OnyxKernel
cargo kbuild 2>&1
cp target/riscv64gc-unknown-none-elf/release/onyx-kernel "$BUILD_DIR/onyx-kernel.elf"
cd "$OLDPWD"
echo "[+] OnyxKernel done"

# 3. Build OnyxShell
# build.sh produces build/osh.onx (OnyxExec v2, ring 1, compressed).
echo "[*] Building OnyxShell..."
cd .vent/repos/OnyxShell
bash build.sh 2>&1
cp build/osh.onx "$BUILD_DIR/"
cd "$OLDPWD"
echo "[+] OnyxShell done"

# 4. Build OnyxCompiller (host onyxcc + onyx-ld)
# OnyxCompiller's Makefile has no `host` target — the default `all`
# target builds both onyxcc (host C compiler) and onyx-ld (host linker).
echo "[*] Building OnyxCompiller (host onyxcc + onyx-ld)..."
ONYXCOMPILLER_DIR="$(pwd)/.vent/repos/OnyxCompiller"
cd .vent/repos/OnyxCompiller
make -B 2>&1
cp onyxcc "$BUILD_DIR/"
cp onyx-ld "$BUILD_DIR/"
cd "$OLDPWD"
echo "[+] OnyxCompiller done"

# 4.5 Compile every app into a fresh stage with the just-built compiler.
# Do not package ignored/stale OnyxApps/build or .tmp-onx outputs.
echo "[*] Building OnyxApps into fresh staging..."
python3 scripts/build-apps.py "$(pwd)/.vent/repos" "$BUILD_DIR" "$BUILD_DIR/apps.list"

# 5. Create boot disk image (FAT32 + OnyxFS two-partition) for OnyxBoot.
#    Requires: parted, mkfs.fat, mcopy (Arch: pacman -S parted dosfstools mtools)
#    + OnyxKernel's mkimage, elf2onx, psfgen tools (built via cargo tbuild)
#    + All userspace binaries (init, login, osh, passwd, useradd, userdel)
#    Safe to skip if any of these are missing — run-qemu.sh 'dev' mode works
#    without a disk image, only 'boot' mode needs it.
echo "[*] Creating boot disk image (FAT32 kernel partition + OnyxFS rootfs)..."
if bash scripts/mk-onyxfs-disk.sh 2>&1; then
    echo "[+] Boot disk ready"
elif [ "${ONYX_DEPS_MODE:-check}" = workspace ]; then
    echo "[!] Boot disk creation skipped — 'bash scripts/run-qemu.sh boot' will fail"
    echo "    Use 'bash scripts/run-qemu.sh dev' to skip OnyxBoot (faster dev mode)"
else
    echo "[-] Locked build failed to create its boot disk" >&2
    exit 1
fi

echo ""
echo "=== All builds complete ==="
echo "    Output: $BUILD_DIR/"
ls -lh "$BUILD_DIR/"
