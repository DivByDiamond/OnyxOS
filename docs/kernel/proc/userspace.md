# Userspace процессы

## ELF загрузка

1. Читаем ELF header с диска (через VirtIO Block)
2. Проверяем magic (`0x7f ELF`), machine (`0xf3` = RISC-V), type (EXEC)
3. Читаем Program Headers
4. Для каждого LOAD сегмента:
   - Аллоцируем память
   - Копируем данные из ELF файла
   - Маппим виртуальную память с U, R, W, X флагами
5. Ставим entry point из `elf_hdr.entry_addr`
6. Настраиваем stack (SP), SATP
7. Добавляем в process list

## System calls (ecall)

- U-mode ecall → cause 8
- Номер syscall в a0, аргументы в a1-a5
- Возврат в a0
- После обработки: mepc += 4

### Номера (libgloss convention)

| Номер | Syscall |
|---|---|
| 63 | read |
| 64 | write |
| 93 | exit |
| 57 | close |
| 80 | fstat |
| 214 | brk |

## Переход U-mode

```assembly
mstatus.MPP = 00   // User mode
mepc = entry_point
satp = process_table >> 12 | (8 << 60)
mret               // → U-mode
```

## Init process

Первый процесс (pid=1, init) запускается сразу после scheduler.
Загружается с диска через ELF или встроен как функция.
