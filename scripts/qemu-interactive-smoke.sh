#!/usr/bin/env bash
# qemu-interactive-smoke.sh — interactive boot smoke test.
#
# Boots the full chain (OnyxBoot -> FAT32 kernel.elf -> OnyxKernel ->
# /bin/init -> login), logs in as root (empty password on first boot),
# runs whoami / echo / ls / uname in the osh shell, then exits.
#
# Verifies:
#   - SMOKE_ECHO_OK appears in serial output
#   - osh prompt is reached
#   - counts "illegal instruction" lines (known bug, tracked separately)
#
# Env:
#   DISK         — disk image override (default .build/onyx-boot-disk.img)
#   SMOKE_TOTAL  — total QEMU timeout in seconds (default 120)
set -u

cd "$(dirname "$0")/.."

LOG="${LOG:-/tmp/opencode/ismoke.log}"
: > "$LOG"
{
  sleep 40            # boot to login
  printf 'root\n'
  sleep 6
  printf '\n'         # empty password (first boot)
  sleep 6
  printf 'whoami\n'
  sleep 5
  printf 'echo SMOKE_ECHO_OK\n'
  sleep 5
  printf 'ls /bin\n'
  sleep 6
  printf 'uname\n'
  sleep 5
  printf 'exit\n'
  sleep 8
} | timeout --signal=KILL ${SMOKE_TOTAL:-120} qemu-system-riscv64 \
    -machine virt -m 256M -nographic \
    -bios .build/onyx-boot.bin \
    -drive file=${DISK:-.build/onyx-boot-disk.img},format=raw,if=none,id=drive0 \
    -device virtio-blk-device,drive=drive0 > "$LOG" 2>&1
grep -aq "SMOKE_ECHO_OK" "$LOG" && echo "[+] echo OK" || echo "[-] echo FAIL"
grep -aqE "osh\\\$" "$LOG" && echo "[+] osh prompt OK" || echo "[-] osh prompt FAIL"
grep -ac "illegal instruction" "$LOG"
