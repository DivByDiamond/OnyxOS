# Быстрый старт

## Тулчейн

```bash
rustup target add riscv64gc-unknown-none-elf
```

## Сборка

```bash
cargo build --release
```

## Запуск в QEMU

```bash
qemu-system-riscv64 -machine virt -m 128M -nographic -bios default -kernel target/riscv64gc-unknown-none-elf/release/slipperos
```

## OC2r

Скопируйте образ на SD-карту и загрузитесь на OC2r.
