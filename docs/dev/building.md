# Сборка

## Cargo команды

```bash
cargo build              # debug
cargo build --release    # release
cargo run --release      # build + QEMU
```

## Флаги release

- panic = abort
- lto = true
- opt-level = z (минимальный размер)
- codegen-units = 1
- strip = true
