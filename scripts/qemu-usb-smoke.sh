#!/usr/bin/env bash
# qemu-usb-smoke.sh — headless USB HID device smoke test (dev boot).
#
# Boots the S-mode kernel under OpenSBI with a PCIe xHCI controller and
# one or more USB devices per run. Runs (a)/(b) are the single-device
# scope; runs (c)-(e) are the multi-slot scenarios (one xHCI slot,
# registry slot and /dev/jsN per stick):
#
#   (a) -device qemu-xhci -device usb-kbd
#       The keyboard enumerates (QEMU usb-kbd is vendor 0x0627 product
#       0x0001, HID class) and gets a registry slot, but it is not a
#       stick: no HID session attaches, so no /dev/jsN devfs node may
#       exist. Asserts the enumeration klog line and the absence of a
#       stick session.
#
#   (b) -device qemu-xhci -device usb-tablet
#       The tablet enumerates AND reports X/Y axes, so a HID stick
#       session attaches; the /dev/jsN devfs node exists only while a
#       session is attached, so the "hid stick attached" klog line is
#       the js-node evidence. Asserts both klog lines.
#
#   (c) -device qemu-xhci -device usb-tablet -device usb-tablet
#       Two sticks at once: both enumerate, each gets its own xHCI slot
#       and a HID session (stick slot=0 AND slot=1 → /dev/js0 + /dev/js1).
#
#   (d) -device qemu-xhci -device usb-kbd -device usb-tablet
#       A non-stick next to a stick: both enumerate, exactly one stick
#       session attaches (the registry index of the tablet's js node).
#
#   (e) -device qemu-xhci -device usb-hub -device usb-tablet
#       A device the registry refuses (a hub has no HID interface): its
#       xHCI slot is disabled and released (error-path cleanup), and the
#       tablet behind it on the next port still attaches.
#
# Builds nothing: the kernel must be an S-mode build
# (`cd OnyxKernel && cargo kbuild --features smode`), because the plain
# `kbuild` artifact targets the M-mode OnyxBoot chain and cannot run
# under OpenSBI (no banner, no xHCI line).
#
# Usage: bash scripts/qemu-usb-smoke.sh [kernel.elf] [--kbd-only|--tablet-only|--multi-only]
#
# Env:
#   SMOKE_TIMEOUT  — max seconds per QEMU run (default 30)
#   QEMU_EXTRA     — extra qemu args (e.g. "-s -S" for gdb)
set -euo pipefail

cd "$(dirname "$0")/.."

KERNEL=""
RUN_KBD=1
RUN_TABLET=1
RUN_MULTI=1
for arg in "$@"; do
    case "$arg" in
        --kbd-only) RUN_TABLET=0; RUN_MULTI=0 ;;
        --tablet-only) RUN_KBD=0; RUN_MULTI=0 ;;
        --multi-only) RUN_KBD=0; RUN_TABLET=0 ;;
        *) KERNEL="$arg" ;;
    esac
done

# Both flags together would select no run at all — a silent no-op exit 0.
if [ "$RUN_KBD" = 0 ] && [ "$RUN_TABLET" = 0 ] && [ "$RUN_MULTI" = 0 ]; then
    echo "usage: $0 [kernel.elf] [--kbd-only|--tablet-only|--multi-only]" >&2
    echo "error: the selected flags together select no run" >&2
    exit 2
fi

KERNEL="${KERNEL:-../OnyxKernel/target/riscv64gc-unknown-none-elf/release/onyx-kernel}"
SMOKE_TIMEOUT="${SMOKE_TIMEOUT:-30}"

if [ ! -f "$KERNEL" ]; then
    echo "[-] $KERNEL not found"
    echo "    build it first: (cd OnyxKernel && cargo kbuild --features smode)"
    exit 1
fi

if ! command -v qemu-system-riscv64 >/dev/null 2>&1; then
    echo "[-] qemu-system-riscv64 not installed"
    exit 1
fi

LOG="$(mktemp /tmp/onyx-usb-smoke.XXXXXX.log)"

# Boot the kernel + xHCI + one USB device, headless, and capture serial.
boot() { # $@ = usb device args (one -device each)
    local devs=() d
    for d in "$@"; do devs+=(-device "$d"); done
    echo "[*] Booting kernel + qemu-xhci + $* (headless, timeout ${SMOKE_TIMEOUT}s)..."
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
            "${devs[@]}" \
            ${QEMU_EXTRA:-} \
            </dev/null >"$LOG" 2>&1
    set -e
    echo "[*] QEMU finished (timeout exit code is expected)"
}

fail() {
    echo "[-] FAIL: $1"
    echo "--- last 40 lines of serial log ---"
    tail -40 "$LOG" || true
    rm -f "$LOG"
    exit 1
}

# Common boot sanity: banner, no panic, xHCI found and initialized.
boot_sanity() {
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
}

# ---- (a) usb-kbd: enumerated, but NOT a stick -------------------------
if [ "$RUN_KBD" = 1 ]; then
    boot "usb-kbd"
    boot_sanity
    grep -qE "usb: dev vid=627 pid=1 class=3" "$LOG" \
        || fail "usb-kbd did not enumerate (no 'dev vid=' klog line)"
    echo "[+] usb-kbd enumeration OK"
    if grep -q "hid stick attached" "$LOG"; then
        fail "usb-kbd unexpectedly attached a stick session (a keyboard must not get a /dev/jsN node)"
    fi
    echo "[+] no stick session for usb-kbd OK"
    echo "[+] PASS: run (a) usb-kbd enumerated, no js node"
fi

# ---- (b) usb-tablet: enumerated + stick session ------------------------
if [ "$RUN_TABLET" = 1 ]; then
    boot "usb-tablet"
    boot_sanity
    grep -qE "usb: dev vid=627 pid=1 class=3" "$LOG" \
        || fail "usb-tablet did not enumerate (no 'dev vid=' klog line)"
    echo "[+] usb-tablet enumeration OK"
    grep -qE "usb: hid stick attached slot=[0-9]+ iface=[0-9]+" "$LOG" \
        || fail "usb-tablet did not attach a HID stick session (no /dev/jsN node is created without it)"
    echo "[+] usb-tablet stick session OK"
    echo "[+] PASS: run (b) usb-tablet enumerated + stick session"
fi

# Count log lines matching a pattern (0 when none: grep -c exits 1).
count() { grep -cE "$1" "$LOG" || true; }

# ---- (c)-(e) multi-slot scenarios ---------------------------------------
if [ "$RUN_MULTI" = 1 ]; then
    boot usb-tablet usb-tablet
    boot_sanity
    [ "$(count 'usb: dev vid=627 pid=1 class=3')" = 2 ] \
        || fail "two usb-tablets did not both enumerate"
    grep -qE "usb: hid stick attached slot=0 " "$LOG" \
        || fail "first tablet did not attach as /dev/js0 (stick slot=0)"
    grep -qE "usb: hid stick attached slot=1 " "$LOG" \
        || fail "second tablet did not attach as /dev/js1 (stick slot=1)"
    [ "$(count 'xhci: intr armed slot=')" = 2 ] \
        || fail "both tablets must arm their own interrupt endpoint"
    echo "[+] PASS: run (c) two usb-tablets -> /dev/js0 + /dev/js1"

    boot usb-kbd usb-tablet
    boot_sanity
    [ "$(count 'usb: dev vid=627 pid=1 class=3')" = 2 ] \
        || fail "usb-kbd + usb-tablet did not both enumerate"
    [ "$(count 'usb: hid stick attached slot=')" = 1 ] \
        || fail "exactly one stick session expected next to a keyboard"
    echo "[+] PASS: run (d) usb-kbd + usb-tablet -> one stick session"

    boot usb-hub usb-tablet
    boot_sanity
    grep -qE "xhci: slot=[0-9]+ released" "$LOG" \
        || fail "the refused hub's xHCI slot was not released"
    grep -qE "usb: hid stick attached slot=0 " "$LOG" \
        || fail "tablet next to a refused hub did not attach (registry slot must stay free)"
    echo "[+] PASS: run (e) refused hub released, tablet attached"
fi

rm -f "$LOG"
if [ "$RUN_KBD" = 1 ] || [ "$RUN_TABLET" = 1 ] || [ "$RUN_MULTI" = 1 ]; then
    echo "[+] PASS: USB HID smoke (enumeration, stick discrimination, multi-slot)"
fi
exit 0
