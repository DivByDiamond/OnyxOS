# Interrupt and Trap Handling

## RISC-V Trap System

All traps arrive at vector `stvec` (S-mode) or `mtvec` (M-mode).
OpenSBI delegates some traps to S-mode.

## scause / cause

Format: bit 63 = async (1) / sync (0), rest is cause code.

### Synchronous (0)

| Code | Cause |
|---|---|
| 2 | Illegal instruction |
| 8 | Ecall from U-mode |
| 9 | Ecall from S-mode |
| 12 | Instruction page fault |
| 13 | Load page fault |
| 15 | Store page fault |

### Asynchronous (1)

| Code | Cause |
|---|---|
| 3 | Machine software (IPI) |
| 7 | Machine timer (CLINT) |
| 11 | Machine external (PLIC) |

## Trap frame

On trap entry, context must be saved:

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

The kernel runs in S-mode. OpenSBI delegates traps via `stvec`.
Only S-mode registers are used:

| Purpose | M-mode (OpenSBI) | S-mode (SlipperOS) |
|---|---|---|
| Trap vector | `mtvec` | `stvec` |
| Exception PC | `mepc` | `sepc` |
| Cause | `mcause` | `scause` |
| Trap value | `mtval` | `stval` |
| Status | `mstatus` | `sstatus` |
| Return | `mret` | `sret` |

### Flow

1. CPU enters `stvec`
2. Save `sepc`, `stval`, `scause`, `sstatus`
3. Save all GPRs to TrapFrame
4. Change SP to kernel stack
5. Call Rust handler
6. Handler returns new `sepc` (for ecall: `epc + 4`)
7. Restore registers from TrapFrame
8. `sret`

## System Calls (ecall)

- U-mode ecall → cause 8, S-mode ecall → cause 9
- Syscall number in `a0`
- Arguments in `a1`-`a7`
- Return in `a0`
- `sepc += 4` after ecall (otherwise infinite loop)

## Timer (CLINT)

- mtime increments at ~10MHz (QEMU)
- mtimecmp = mtime + delay → interrupt on match
- Cause 7 (async)
- For preemption: set mtimecmp in the future, call sched_yield in handler

## External (PLIC)

- Cause 11 (async)
- Read claim register → source ID
- Call handler by ID
- Write complete
