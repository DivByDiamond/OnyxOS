# Contributing

## Code style

- `cargo fmt` before committing
- no unsafe in public APIs (except MMIO)
- Comments for non-obvious logic

## Rules

- No unwrap() — only match/if let
- Panic only in unrecoverable situations
- All MMIO addresses are constants
- Documentation for every module

## Required before push / PR

Every PR runs CI, including the **QEMU boot smoke test** — a full
`OnyxBoot → kernel → OnyxFS rootfs → init → login` boot in headless QEMU.
Run it locally before pushing to avoid red CI runs:

```bash
# 1. Build all components (bootloader, kernel, userspace)
bash scripts/build-all.sh

# 2. Build the rootfs disk image
bash scripts/mk-onyxfs-disk.sh

# 3. Run the smoke test (headless, ~60 sec)
bash scripts/qemu-smoke.sh
```

The test checks the serial log for:
- the `OnyxKernel v...` banner
- rootfs mount (`root mounted on dev ...`)
- userspace entry (`login:` or `osh$`)

If you touched boot, VFS, OnyxFS or userspace — the smoke test is mandatory.
For kernel-only changes you can quickly check just the banner:
`bash scripts/run-qemu.sh dev`.

Smoke test dependencies: `qemu-system-riscv64 dosfstools mtools parted`
(plus the regular toolchain from building.md).
