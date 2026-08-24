# Building

## Cargo commands

```bash
cargo build              # debug
cargo build --release    # release
cargo run --release      # build + QEMU
```

## Release flags

- panic = abort
- lto = true
- opt-level = z (minimal size)
- codegen-units = 1
- strip = true
