# How to Add a New Driver

1. Create a file in `drivers/xxx.rs`
2. Describe MMIO registers (offset constants)
3. Implement `init()` and basic operations
4. Wire it up in `kernel/lib.rs` — add `pub mod drivers::xxx`
5. Call initialization from `kernel/main.rs`
6. Write a test (if possible)

## Example

```rust
// drivers/xxx.rs
const BASE: usize = 0x...;

pub fn xxx_init() {
    // ...
}
```

## Important

- All MMIO via `read_volatile`/`write_volatile`
- No std, no alloc (except static)
