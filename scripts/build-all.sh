#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== OnyxOS Build All ==="
echo ""

# Bootstrap first if needed
if [ ! -d ".vent/repos/OnyxKernel" ]; then
    echo "[*] Bootstrap needed - resolving dependencies..."
    bash scripts/bootstrap.sh
fi

BUILD_DIR="$(pwd)/.build"
mkdir -p "$BUILD_DIR"

# 1. Build OnyxBoot
echo "[*] Building OnyxBoot..."
cd .vent/repos/OnyxBoot
make clean 2>/dev/null || true
make -j"$(nproc)" 2>&1
cp kernel.elf "$BUILD_DIR/onyx-boot.elf" 2>/dev/null || true
cd "$OLDPWD"
echo "[+] OnyxBoot done"

# 2. Build OnyxKernel
# We use the `kbuild` cargo alias (defined in
# .vent/repos/OnyxKernel/.cargo/config.toml) which expands to
# `cargo build --release -p onyx_kernel --target riscv64gc-unknown-none-elf`.
# Without --target, cargo would compile for the host (x86_64) and the
# init crate's RISC-V inline-asm (`in("a7")` etc.) would fail with
# "invalid register a7: unknown register".
echo "[*] Building OnyxKernel..."
cd .vent/repos/OnyxKernel
cargo kbuild 2>&1
cp target/riscv64gc-unknown-none-elf/release/Onyxos "$BUILD_DIR/onyx-kernel.elf" 2>/dev/null || true
cd "$OLDPWD"
echo "[+] OnyxKernel done"

# 3. Build OnyxShell
echo "[*] Building OnyxShell..."
cd .vent/repos/OnyxShell
bash build.sh 2>&1
cp build/osh.onx "$BUILD_DIR/" 2>/dev/null || true
cd "$OLDPWD"
echo "[+] OnyxShell done"

# 4. Build OnyxCompiller (host onyxcc + onyx-ld + libonyxc)
# OnyxCompiller's Makefile has no `host` target — the default `all`
# target builds both onyxcc (host C compiler) and onyx-ld (host linker).
echo "[*] Building OnyxCompiller (host onyxcc + onyx-ld)..."
cd .vent/repos/OnyxCompiller
make 2>&1
cp onyxcc "$BUILD_DIR/" 2>/dev/null || true
cp onyx-ld "$BUILD_DIR/" 2>/dev/null || true
cd "$OLDPWD"
echo "[+] OnyxCompiller done"

echo ""
echo "=== All builds complete ==="
echo "    Output: $BUILD_DIR/"
ls -lh "$BUILD_DIR/"
