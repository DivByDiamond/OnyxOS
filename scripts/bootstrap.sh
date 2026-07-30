#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "=== OnyxOS Bootstrap ==="
echo ""

# Check for vent
if [ ! -f .vent/vent ]; then
    echo "[!] Vent not found. Building from source..."
    if ! command -v cmake &>/dev/null || ! command -v gcc &>/dev/null; then
        echo "[-] Need cmake + gcc to build vent"
        echo "    On Arch:  sudo pacman -S cmake base-devel curl libarchive"
        echo "    On deb:   sudo apt install cmake build-essential libcurl4-openssl-dev libarchive-dev"
        exit 1
    fi
    git clone https://github.com/grafmorkov/vent.git /tmp/vent-build 2>/dev/null
    cmake -B /tmp/vent-build/build /tmp/vent-build
    cmake --build /tmp/vent-build/build
    cp /tmp/vent-build/build/vent .vent/vent
    rm -rf /tmp/vent-build
    echo "[+] Vent built"
fi

# Resolve all Onyx dependencies
echo "[*] Resolving Onyx dependencies..."
.vent/vent -j 4 Onyx.vent
echo "[+] All Onyx repos cloned under .vent/repos/"
echo ""

# Verify
for repo in OnyxKernel OnyxBoot OnyxShell OnyxCompiller; do
    if [ -d ".vent/repos/$repo" ]; then
        echo "  ✓ $repo"
    else
        echo "  ✗ $repo - missing"
    fi
done
echo ""
echo "=== Bootstrap complete ==="
