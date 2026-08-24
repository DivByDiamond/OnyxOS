# Последовательность загрузки

Трёхстадийная загрузка: OpenSBI → SlipperBoot → SlipperKernel.

```
OpenSBI (M-mode)
    ↓  a0=hart_id, a1=fdt_ptr
SlipperBoot (S-mode, C++)
    │  uart_init(), fdt_parse(), virtio_read(kernel.elf)
    ↓  a0=hart_id, a1=fdt_ptr
SlipperKernel (S-mode, Rust)
    │  kernel_main()
    │  uart, plic, clint, mm, sched, shell
    ↓
Slip shell (UART CLI)
```

---

## Стадия 1: OpenSBI (M-mode)

Встроен в OC2r или прошит на Milk-V Duo S. Настраивает делегирование
прерываний, передаёт управление на адрес 0x80000000 в S-mode.
Регистры: `a0 = hart_id`, `a1 = fdt_ptr`.

## Стадия 2: SlipperBoot (S-mode, C++) — в разработке

> **Текущий статус:** v0.4 — C++ загрузчик в `Slipper/SlipperBoot/`. UART, FDT, VirtIO, SDHCI, FAT32/EXT4, ELF, boot menu.

Встречает управление по адресу 0x80000000.

1. **Hart select** — `mhartid` → hart 0 работает, остальные `wfi`
2. **BSS clear** — обнуляет `.bss`
3. **Stack** — `sp = &_stack_end`
4. **UART init** — NS16550A, "SlipperBoot\n"
5. **FDT parse** — читает Device Tree (a1), определяет память, UART, VirtIO
6. **VirtIO probe** — ищет VirtIO block device, читает LBA 0
7. **ELF load** — находит `kernel.elf`, парсит Program Headers, копирует сегменты
8. **Entry** — прыгает на точку входа ядра (a0=hart_id, a1=fdt)

## Стадия 3: SlipperKernel (S-mode, Rust)

Загружается по адресу из ELF (0x80200000). Точка входа — `kernel_main`:

1. **UART init** — "SlipperOS v0.1 booting..."
2. **print_seal** — аски-тюлень
3. **PLIC init** — priority, enables, threshold
4. **CLINT init** — mtimecmp = mtime + slice
5. **MM init** — page allocator из `_end..memory_top`
6. **Sched init** — idle task
7. **Shell start** — "slip> ready"

## S-mode vs M-mode

SlipperKernel работает в S-mode. OpenSBI выполняет M-mode bootstrap
и делегирует трапы.

| Назначение | M-mode | S-mode |
|---|---|---|
| Trap vector | `mtvec` | `stvec` |
| Exception PC | `mepc` | `sepc` |
| Cause | `mcause` | `scause` |
| Trap value | `mtval` | `stval` |
| Status | `mstatus` | `sstatus` |
| IE | `mie` | `sie` |
| Return | `mret` | `sret` |
