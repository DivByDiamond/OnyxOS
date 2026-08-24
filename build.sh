#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-normal}"

KTOML="$ROOT/../OnyxKernel/Cargo.toml"
STOML="$ROOT/../OnyxShell/Cargo.toml"

write_profiles() {
  local kopt="$1" kdebug="$2" kstrip="$3"
  local sopt="$4" sdebug="$5" sstrip="$6"
  sed -i "/^\[profile.release\]/,/^\[/{
    s/opt-level = .*/opt-level = $kopt/;
    s/debug = .*/debug = $kdebug/;
    s/strip = .*/strip = $kstrip/;
  }" "$KTOML"
  sed -i "/^\[profile.release\]/,/^\[/{
    s/opt-level = .*/opt-level = $sopt/;
    s/debug = .*/debug = $sdebug/;
    s/strip = .*/strip = $sstrip/;
  }" "$STOML"
}

case "$MODE" in
  normal)
    echo "=== BUILD: NORMAL (debug symbols) ==="
    write_profiles '2'  'true' 'false'  '0'  'true' 'false'
    ;;
  ultra)
    echo "=== BUILD: ULTRA (opt-level=z, stripped) ==="
    write_profiles '"z"' 'false' '"symbols"'  '"z"' 'false' '"symbols"'
    ;;
  *)
    echo "Usage: $0 [normal|ultra]"
    exit 1
    ;;
esac

# Bootloader
CC=""
for p in /tmp/xpack-riscv-none-elf-gcc-*/bin/riscv64-unknown-elf-gcc; do
  [ -x "$p" ] && { CC="${p%/*}/riscv64-unknown-elf"; break; }
done
if [ -n "$CC" ]; then
  make -C "$ROOT/../OnyxBoot" clean 2>/dev/null || true
  make -C "$ROOT/../OnyxBoot" CROSS="$CC" 2>&1 | tail -1
  ls -lh "$ROOT/../OnyxBoot/bootloader.bin" | awk '{printf "  boot → %s\n", $5}'
fi

# Kernel + Init
cargo build --release --target riscv64gc-unknown-none-elf -p onyx_kernel -p onyx_init \
  --manifest-path "$KTOML" 2>&1 | tail -1

# Shell
bash "$ROOT/../OnyxShell/build.sh" 2>&1 | tail -1

echo ""
echo "=== SIZES ($MODE) ==="
for f in "$ROOT"/../OnyxKernel/target/riscv64gc-unknown-none-elf/release/onyx-{kernel,init,login,passwd,su,useradd,userdel,groups,lsblk}; do
  [ -f "$f" ] && ls -lh "$f" | awk '{printf "  %s %s\n", $5, $9}'
done
ls -lh "$ROOT/../OnyxShell/build/osh.onx" | awk '{printf "  %s %s (osh.onx)\n", $5, $9}'
echo "=== DONE ==="
