#!/usr/bin/env bash
# qemu-jstest-smoke.sh — live /dev/jsN validation of jstest in QEMU.
#
# Boots the S-mode kernel (OpenSBI -kernel) with the OnyxFS disk image,
# qemu-xhci and usb-tablet device(s), logs in as root, runs
# `jstest -t 12 /dev/js0` (bounded: must exit 0) and injects tablet motion + left-button presses
# through the QEMU monitor (QMP input-send-event). Asserts in the serial log:
#   - the open-time init burst (axis 0/1, button 0..3 "(init)" lines),
#   - live axis 0/1 events and button 0 down/up after the injection.
# Run (b) uses two tablets: /dev lists js0 + js1 cleanly, js0 gets the live
# events, js1 gets its init burst, exits cleanly and sees no foreign events.
# Limit: the second tablet's live reports never complete under QEMU (its
# wakeups kick xHCI slot 1 in the xhci trace), so live input of
# the second slot is not exercised here.
#
# Needs: .build/onyx-boot-disk.img with jstest (build-all.sh), and an
# S-mode kernel (`cd OnyxKernel && cargo kbuild --features smode`);
# build-all.sh overwrites target/.../onyx-kernel with the M-mode build.
# The disk is attached with -snapshot, the image is never modified.
#
# Usage: bash scripts/qemu-jstest-smoke.sh [kernel.elf] [--single-only|--dual-only]
# Env: DISK (default .build/onyx-boot-disk.img), SMOKE_TOTAL (per run, 150 s)
set -euo pipefail
cd "$(dirname "$0")/.."

KERNEL=""
RUN_ONE=1
RUN_TWO=1
for arg in "$@"; do
    case "$arg" in
        --single-only) RUN_TWO=0 ;;
        --dual-only) RUN_ONE=0 ;;
        *) KERNEL="$arg" ;;
    esac
done
KERNEL="${KERNEL:-../OnyxKernel/target/riscv64gc-unknown-none-elf/release/onyx-kernel}"
DISK="${DISK:-.build/onyx-boot-disk.img}"
SMOKE_TOTAL="${SMOKE_TOTAL:-150}"
for f in "$KERNEL" "$DISK"; do
    [ -f "$f" ] || { echo "[-] $f not found"; exit 1; }
done
command -v qemu-system-riscv64 >/dev/null || { echo "[-] qemu-system-riscv64 not installed"; exit 1; }

LOG="$(mktemp /tmp/onyx-jstest-smoke.XXXXXX.log)"
run() { # $1 = tablet count
    echo "[*] jstest live run with $1 usb-tablet(s)..."
    python3 -I scripts/qemu-jstest-drive.py --kernel "$KERNEL" --disk "$DISK" \
        --log "$LOG" --tablets "$1" --timeout "$SMOKE_TOTAL" || {
        echo "--- last 40 lines of serial log ($LOG) ---"
        tail -40 "$LOG"
        exit 1
    }
}
[ "$RUN_ONE" = 1 ] && { run 1; echo "[+] PASS: run (a) one tablet, jstest js0 live"; }
[ "$RUN_TWO" = 1 ] && { run 2; echo "[+] PASS: run (b) two tablets, jstest js0 + js1 live"; }
rm -f "$LOG"
echo "[+] PASS: jstest live smoke"
