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

Профили живут только в Cargo.toml каждого репозитория. Корневые
build.sh и build-ultra.sh, правившие их через sed, удалены. Для
пересборки ядра, init и шелла по локальным деревьям вместо залоченных
чекаутов используйте workspace-режим оркестратора:

```bash
ONYX_DEPS_MODE=workspace bash scripts/build-all.sh
```
