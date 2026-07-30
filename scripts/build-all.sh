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
echo "[*] Building OnyxKernel..."
cd .vent/repos/OnyxKernel
cargo build --release 2>&1
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

# 4. Build OnyxCompiller (host)
echo "[*] Building OnyxCompiller (host)..."
cd .vent/repos/OnyxCompiller
make host 2>&1
cp onyxcc "$BUILD_DIR/" 2>/dev/null || true
cd "$OLDPWD"
echo "[+] OnyxCompiller done"

echo ""
echo "=== All builds complete ==="
echo "    Output: $BUILD_DIR/"
ls -lh "$BUILD_DIR/"
