#!/usr/bin/env bash
# qemu-smoke.sh — headless boot smoke test (full chain).
#
# Boots the complete chain: OnyxBoot (-bios) -> FAT32 (kernel.elf) ->
# OnyxKernel -> /bin/init -> login -> osh shell prompt.
#
# Prerequisites (.build/):
#   onyx-boot.bin          — scripts/build-all.sh
#   onyx-boot-disk.img     — scripts/mk-onyxfs-disk.sh
#
# Env:
#   SMOKE_TIMEOUT  — max seconds to wait for the shell prompt (default 60)
set -euo pipefail

cd "$(dirname "$0")/.."

BOOT_BIN="${1:-.build/onyx-boot.bin}"
DISK_IMG="${2:-.build/onyx-boot-disk.img}"
SMOKE_TIMEOUT="${SMOKE_TIMEOUT:-60}"
LOG="$(mktemp /tmp/onyx-smoke.XXXXXX.log)"

for f in "$BOOT_BIN" "$DISK_IMG"; do
    if [ ! -f "$f" ]; then
        echo "[-] $f not found — run 'bash scripts/build-all.sh' and 'bash scripts/mk-onyxfs-disk.sh' first"
        exit 1
    fi
done

if ! command -v qemu-system-riscv64 >/dev/null 2>&1; then
    echo "[-] qemu-system-riscv64 not installed"
    exit 1
fi

echo "[*] Booting full chain (headless, timeout ${SMOKE_TIMEOUT}s)..."
set +e
timeout --signal=KILL "$SMOKE_TIMEOUT" \
    qemu-system-riscv64 \
        -machine virt \
        -m 256M \
        -nographic \
        -bios "$BOOT_BIN" \
        -drive file="$DISK_IMG",format=raw,if=none,id=drive0 \
        -device virtio-blk-device,drive=drive0 \
        </dev/null >"$LOG" 2>&1
set -e

echo "[*] QEMU finished (timeout exit code is expected)"

fail() {
    echo "[-] FAIL: $1"
    echo "--- last 40 lines of serial log ---"
    tail -40 "$LOG" || true
    rm -f "$LOG"
    exit 1
}

grep -q "OnyxKernel v" "$LOG" || fail "no kernel banner in serial output"
echo "[+] kernel banner OK"

grep -q "root mounted on dev" "$LOG" || fail "rootfs did not mount"
echo "[+] rootfs mount OK"

grep -qE "osh\\\$|OnyxOS Login" "$LOG" || fail "did not reach userspace (login/shell)"
echo "[+] userspace OK (init -> login)"

echo "[+] PASS: full boot chain verified"
rm -f "$LOG"
exit 0
