# Обработка прерываний и трапов

## RISC-V Trap System

Все трапы приходят на вектор `stvec` (S-mode) или `mtvec` (M-mode).
OpenSBI делегирует часть трапов в S-mode.

## scause / cause

Формат: бит 63 = async (1) / sync (0), остальное — код причины.

### Synchronous (0)

| Код | Причина |
|---|---|
| 2 | Illegal instruction |
| 8 | Ecall from U-mode |
| 9 | Ecall from S-mode |
| 12 | Instruction page fault |
| 13 | Load page fault |
| 15 | Store page fault |

### Asynchronous (1)

| Код | Причина |
|---|---|
| 3 | Machine software (IPI) |
| 7 | Machine timer (CLINT) |
| 11 | Machine external (PLIC) |

## Trap frame

При входе в трап нужно сохранить контекст:

```rust
struct TrapFrame {
    regs:       [usize; 32],   // 0-255
    fregs:      [usize; 32],   // 256-511
    satp:       usize,         // 512-519
    trap_stack: *mut u8,       // 520
    hartid:     usize,         // 528
}
```

## S-mode Trap Flow

Ядро работает в S-mode. OpenSBI делегирует трапы через `stvec`.
Используются исключительно S-mode регистры:

| Назначение | M-mode (OpenSBI) | S-mode (SlipperOS) |
|---|---|---|
| Trap vector | `mtvec` | `stvec` |
| Exception PC | `mepc` | `sepc` |
| Cause | `mcause` | `scause` |
| Trap value | `mtval` | `stval` |
| Status | `mstatus` | `sstatus` |
| Return | `mret` | `sret` |

### Flow

1. CPU входит в `stvec`
2. Сохраняем `sepc`, `stval`, `scause`, `sstatus`
3. Сохраняем все GPR в TrapFrame
4. Меняем SP на kernel stack
5. Вызываем Rust handler
6. Handler возвращает новый `sepc` (для ecall: `epc + 4`)
7. Восстанавливаем регистры из TrapFrame
8. `sret`

## Системные вызовы (ecall)

- U-mode ecall → cause 8, S-mode ecall → cause 9
- Номер системного вызова в `a0`
- Аргументы в `a1`-`a7`
- Возврат в `a0`
- `sepc += 4` после ecall (иначе infinite loop)

## Timer (CLINT)

- mtime увеличивается с частотой ~10MHz (QEMU)
- mtimecmp = mtime + delay → прерывание при совпадении
- Cause 7 (async)
- Для preemption: ставим mtimecmp на будущее, в обработчике вызываем sched_yield

## External (PLIC)

- Cause 11 (async)
- Читаем claim register → ID источника
- Вызываем обработчик по ID
- Пишем complete
