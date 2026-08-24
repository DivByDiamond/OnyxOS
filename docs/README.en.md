# OnyxOS

A minimalist kernel for OC2r, written in Rust + C++ (bootloader).

## Quick Start

```bash
# Build
cargo build --release

# Run in QEMU
cargo run --release
```

## Structure

- `boot/` — entry point, linker script
- `kernel/` — kernel: main, panic, lib
- `drivers/` — UART, CLINT, PLIC, VirtIO
- `mm/` — memory managers
- `proc/` — tasks and scheduler
- `fs/` — filesystem
- `shell/` — slip shell
- `docs/` — documentation
