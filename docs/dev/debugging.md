# Отладка

## UART логи

Все логи через `print_log()`. Цвета ANSI.

## GDB через QEMU

```bash
qemu-system-riscv64 -s -S ... -kernel slipperos
# в другом терминале:
riscv64-unknown-elf-gdb target/riscv64gc-unknown-none-elf/release/slipperos
(gdb) target remote :1234
```

## Частые баги

- Линкер: секции не совпадают с `_start`
- Стек: переполнение стека → silent crash
- UART: забыли инициализировать FIFO
