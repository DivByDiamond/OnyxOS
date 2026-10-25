#!/usr/bin/env bash
# Build the raw S-mode kernel and writable OnyxFS base used by OC2R/Sedna.
set -euo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
REPOS=${ONYX_REPOS:-$(cd "$HERE/.." && pwd)}
# Cap build memory (default 6 GiB); see scripts/mem-limit.sh.
# shellcheck source=scripts/mem-limit.sh
source "$HERE/scripts/mem-limit.sh"
onyx_limit_build_memory "$0" "$@"

python3 "$HERE/scripts/dependencies.py" "${ONYX_DEPS_MODE:-check}" --repos "$REPOS"
bash "$HERE/scripts/check-abi.sh" "$REPOS"
KERNEL="$REPOS/OnyxKernel"
SHELL_REPO="$REPOS/OnyxShell"
OUT=${ONYX_OUTPUT:-"$HERE/.build/oc2r"}
mkdir -p "$OUT"
OUT=$(cd "$OUT" && pwd)
(cd "$KERNEL" && cargo kbuild --features smode && cargo ibuild && cargo tbuild)
bash "$SHELL_REPO/build.sh"
TOOLS="$KERNEL/target/release"
TARGET="$KERNEL/target/riscv64gc-unknown-none-elf/release"
${OBJCOPY:-riscv64-elf-objcopy} -O binary "$TARGET/onyx-kernel" "$OUT/onyx-kernel.bin"
MANIFEST="$OUT/manifest.txt"
: > "$MANIFEST"
for name in bin etc font users tmp ipc proc dev service; do echo "dir /$name" >> "$MANIFEST"; done
for name in init login passwd su useradd userdel fb-draw; do
    "$TOOLS/elf2onx" --ring=1 "$TARGET/onyx-$name" "$OUT/$name.onx"
    echo "file $OUT/$name.onx /bin/$name" >> "$MANIFEST"
done
echo "file $SHELL_REPO/build/osh.onx /bin/osh" >> "$MANIFEST"
# Empty databases trigger first-boot root-account creation.
: > "$OUT/passwd.txt"
: > "$OUT/shadow.txt"
echo "file $OUT/passwd.txt /etc/passwd" >> "$MANIFEST"
echo "file $OUT/shadow.txt /etc/shadow" >> "$MANIFEST"
"$TOOLS/psfgen" "$OUT/default.psf"
echo "file $OUT/default.psf /font/default.psf" >> "$MANIFEST"
if [ "${ONYX_DEPS_MODE:-check}" = workspace ]; then
    # Explicit development mode preserves optional prebuilt applications.
    for app in "$REPOS/OnyxApps"/build/*.onx; do
        [ -f "$app" ] || continue
        echo "file $app /bin/$(basename "$app" .onx)" >> "$MANIFEST"
    done
else
    # Locked packaging must rebuild compiler and apps from selected sources.
    make -B -C "$REPOS/OnyxCompiller"
    python3 "$HERE/scripts/build-apps.py" "$REPOS" "$OUT" "$OUT/apps.list"
    while IFS= read -r app; do
        echo "file $app /bin/$(basename "$app" .onx)" >> "$MANIFEST"
    done < "$OUT/apps.list"
fi
"$TOOLS/mkimage" "$MANIFEST" "$OUT/onyxfs.img"
# The filesystem grows into this extra space on mount. The host shares this
# immutable base and stores each VM's writes in its own persistent COW layer.
if [ "$(stat -c %s "$OUT/onyxfs.img")" -gt 16777216 ]; then
    echo "OnyxFS contents exceed the 16 MiB OC2R base" >&2; exit 1
fi
truncate -s 16M "$OUT/onyxfs.img"
sha256sum "$OUT/onyx-kernel.bin" "$OUT/onyxfs.img"
