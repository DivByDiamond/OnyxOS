#!/usr/bin/env bash
# qemu-xhci-smoke.sh — headless xHCI discovery/init smoke test (dev boot).
#
# Boots the kernel directly under OpenSBI with a PCIe xHCI controller
# (`-device qemu-xhci`) and checks that the kernel finds it over ECAM,
# places/enables its BAR and initializes the controller. There is no USB
# mass-storage driver yet, so only detection/init is asserted.
#
# Builds nothing: the kernel must be an S-mode build
# (`cd OnyxKernel && cargo kbuild --features smode`), because the plain
# `kbuild` artifact targets the M-mode OnyxBoot chain and cannot run under
# OpenSBI (no banner, no xHCI line).
#
# Usage: bash scripts/qemu-xhci-smoke.sh [kernel.elf] [--usb-storage]
#
# Env:
#   SMOKE_TIMEOUT  — max seconds before QEMU is killed (default 30)
#   QEMU_EXTRA     — extra qemu args (e.g. "-s -S" for gdb)
set -euo pipefail

cd "$(dirname "$0")/.."

KERNEL=""
USB_STORAGE=0
for arg in "$@"; do
    case "$arg" in
        --usb-storage) USB_STORAGE=1 ;;
        *) KERNEL="$arg" ;;
    esac
done
KERNEL="${KERNEL:-../OnyxKernel/target/riscv64gc-unknown-none-elf/release/onyx-kernel}"
SMOKE_TIMEOUT="${SMOKE_TIMEOUT:-30}"
LOG="$(mktemp /tmp/onyx-xhci-smoke.XXXXXX.log)"
USB_IMG="$(mktemp /tmp/onyx-usb-stick.XXXXXX.img)"

if [ ! -f "$KERNEL" ]; then
    echo "[-] $KERNEL not found"
    echo "    build it first: (cd OnyxKernel && cargo kbuild --features smode)"
    exit 1
fi

if ! command -v qemu-system-riscv64 >/dev/null 2>&1; then
    echo "[-] qemu-system-riscv64 not installed"
    exit 1
fi

EXTRA=()
if [ "$USB_STORAGE" = 1 ]; then
    truncate -s 8M "$USB_IMG"
    EXTRA=(-drive "if=none,id=usbstick,file=$USB_IMG,format=raw" -device usb-storage,drive=usbstick)
fi

echo "[*] Booting kernel + qemu-xhci (headless, timeout ${SMOKE_TIMEOUT}s)..."
set +e
# shellcheck disable=SC2086
timeout --signal=KILL "$SMOKE_TIMEOUT" \
    qemu-system-riscv64 \
        -machine virt \
        -m 256M \
        -nographic \
        -bios default \
        -kernel "$KERNEL" \
        -device qemu-xhci \
        "${EXTRA[@]}" \
        ${QEMU_EXTRA:-} \
        </dev/null >"$LOG" 2>&1
set -e

echo "[*] QEMU finished (timeout exit code is expected)"

fail() {
    echo "[-] FAIL: $1"
    echo "--- last 40 lines of serial log ---"
    tail -40 "$LOG" || true
    rm -f "$LOG" "$USB_IMG"
    exit 1
}

grep -q "OnyxKernel v" "$LOG" \
    || fail "no kernel banner (is this an S-mode build? cargo kbuild --features smode)"
echo "[+] kernel banner OK"

if grep -qE "kpanic|kernel panic|unhandled trap" "$LOG"; then
    fail "kernel panicked during the run"
fi

grep -qE "pci: xhci [0-9a-f]+:[0-9a-f]+\.[0-9a-f]+ bar0=0x[0-9a-f]+" "$LOG" \
    || fail "xHCI PCI function not found or its BAR0 was not placed"
echo "[+] xHCI PCI discovery OK"

grep -qE "xhci: initialized base=0x[0-9a-f]+ hci=[0-9a-f]+ max_slots=[0-9]+ max_ports=[1-9]" "$LOG" \
    || fail "xHCI controller did not initialize"
echo "[+] xHCI controller init OK"

echo "[+] PASS: xHCI discovered and initialized"
rm -f "$LOG" "$USB_IMG"
exit 0
