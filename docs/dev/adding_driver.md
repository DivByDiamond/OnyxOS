# Как добавить новый драйвер

1. Создать файл в `drivers/xxx.rs`
2. Описать MMIO регистры (константы для смещений)
3. Реализовать `init()` и базовые операции
4. Подключить в `kernel/lib.rs` — добавить `pub mod drivers::xxx`
5. Вызвать инициализацию из `kernel/main.rs`
6. Написать тест (если возможно)

## Пример

```rust
// drivers/xxx.rs
const BASE: usize = 0x...;

pub fn xxx_init() {
    // ...
}
```

## Важно

- Все MMIO через `read_volatile`/`write_volatile`
- No std, no alloc (кроме статического)
