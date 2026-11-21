#!/usr/bin/env bash
# qemu-desk-smoke.sh — desktop daemon boot smoke test.
#
# Boots the full chain (OnyxBoot -> FAT32 kernel.elf -> OnyxKernel ->
# /bin/init -> login), logs in as root (empty password on first boot),
# then runs `onyxdesk --autostart osnake --once` from the osh shell.
# The daemon claims /dev/fb0, launches osnake and waits; osnake is a
# terminal game that dies on its own when it hits a wall, so --once
# lets the daemon exit cleanly right after the child returns.
#
# `-device ramfb` attaches QEMU's fw_cfg framebuffer so the kernel's
# ramfb driver provides the real display geometry (same path as
# run-qemu-gui.sh); without it the kernel silently falls back to an
# invisible RAM framebuffer.
#
# Verifies in the serial log:
#   - DESK_READY                (fb open + GET_INFO + CLAIM ok)
#   - APP_STARTED osnake        (managed spawn ok)
#   - APP_RETURN                (osnake terminated, waitpid ok)
#   - DESK_EXIT 0               (clean session end, fb released)
#   - no "illegal instruction" lines
#
# Env:
#   DISK         — disk image override (default .build/onyx-boot-disk.img)
#   SMOKE_TOTAL  — total QEMU timeout in seconds (default 180)
set -u

cd "$(dirname "$0")/.."

LOG="${LOG:-/tmp/opencode/dsmoke.log}"
: > "$LOG"
{
  sleep 40            # boot to login
  printf 'root\n'
  sleep 6
  printf '\n'         # empty password (first boot)
  sleep 6
  printf 'onyxdesk --autostart osnake --once\n'
  sleep 30            # osnake runs to its wall death; desk then exits
  printf '\n'         # extra newline for the returning osh prompt
  sleep 5
} | timeout --signal=KILL ${SMOKE_TOTAL:-180} qemu-system-riscv64 \
    -machine virt -m 256M -nographic \
    -bios .build/onyx-boot.bin \
    -drive file=${DISK:-.build/onyx-boot-disk.img},format=raw,if=none,id=drive0 \
    -device virtio-blk-device,drive=drive0 \
    -device ramfb > "$LOG" 2>&1

check() {
    if ! grep -aq "$1" "$LOG"; then
        echo "[-] $2 FAIL"
        echo "--- tail of $LOG ---"
        tail -30 "$LOG"
        exit 1
    fi
    echo "[+] $2 OK"
}

check "DESK_READY" "desk ready"
check "APP_STARTED osnake" "osnake launched"
check "APP_RETURN" "osnake returned"
check "DESK_EXIT 0" "clean desk exit"
illegal=$(grep -ac "illegal instruction" "$LOG" || true)
if [ "$illegal" -ne 0 ]; then
    echo "[-] illegal instructions: $illegal"
    tail -30 "$LOG"
    exit 1
fi
echo "[+] no illegal instructions"
