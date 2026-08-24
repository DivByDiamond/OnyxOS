# Getting Started

## Toolchain

```bash
rustup target add riscv64gc-unknown-none-elf
```

## Build

```bash
cargo build --release
```

## Run in QEMU

```bash
qemu-system-riscv64 -machine virt -m 128M -nographic -bios default -kernel target/riscv64gc-unknown-none-elf/release/slipperos
```

## OC2r

Copy the image to an SD card and boot on OC2r.
