# Debugging

## UART logs

All logging via `print_log()`. ANSI colors.

## GDB via QEMU

```bash
qemu-system-riscv64 -s -S ... -kernel slipperos
# in another terminal:
riscv64-unknown-elf-gdb target/riscv64gc-unknown-none-elf/release/slipperos
(gdb) target remote :1234
```

## Common bugs

- Linker: sections don't match `_start`
- Stack: stack overflow → silent crash
- UART: forgot to initialize FIFO
