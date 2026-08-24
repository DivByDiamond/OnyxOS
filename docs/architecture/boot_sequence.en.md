# Boot Sequence

> **Status**: v0.4 — C++ bootloader. UART, FDT, VirtIO, SDHCI, FAT32/EXT4, ELF, boot menu.
> Current boot: OpenSBI → `boot/boot.S` → `kernel_main`.

## OpenSBI (M-mode)

OpenSBI (built into OC2r) starts in M-mode. Configures interrupt
delegation, passes control to 0x80000000 in S-mode.

## SlipperBoot (S-mode, C++) — in development

Receives control at address 0x80000000. Written in pure C++,
the only `asm volatile` is the naked `_start()`.

1. **Hart select** — `mhartid` → hart 0 runs, others `wfi`.
2. **BSS clear** — zeroes `.bss` via inline asm in _start().
3. **Stack** — `sp = &_stack_end`.
4. **UART init** — NS16550A, prints "SlipperBoot v0.1\n".
5. **FDT parse** — reads Device Tree (a1), determines memory size.
6. **VirtIO probe** — finds VirtIO block device, reads LBA.
7. **ELF load** — finds `kernel.elf` on disk, parses Program Headers,
   copies segments to ELF addresses (0x80200000).
8. **Entry** — jumps to kernel entry, passing a0=hart_id, a1=fdt.

```
OpenSBI (M-mode)
    ↓
SlipperBoot @ 0x80000000 (S-mode, C++)
    │  uart_init()
    │  fdt_parse()
    │  virtio_read(kernel.elf)
    │  elf_load()
    ↓
SlipperOS @ 0x80200000 (S-mode, Rust)
```

## SlipperOS kernel (S-mode, Rust) — implemented (v0.1)

Loaded by SlipperBoot at the address from ELF. Entry point: `kernel_main`.

1. **UART init** — "SlipperOS v0.1 booting..."
2. **print_seal** — ASCII seal
3. **PLIC init** — priority, enables, threshold
4. **CLINT init** — mtimecmp = mtime + slice
5. **MM init** — page allocator from _end..memory_top
6. **Sched init** — idle task
7. **Shell start** — "slip> ready"

## S-mode vs M-mode

SlipperOS runs in S-mode. OpenSBI performs M-mode bootstrap
and delegates traps.

### Registers

| Purpose | M-mode | S-mode |
|---|---|---|
| Trap vector | `mtvec` | `stvec` |
| Exception PC | `mepc` | `sepc` |
| Cause | `mcause` | `scause` |
| Trap value | `mtval` | `stval` |
| Status | `mstatus` | `sstatus` |
| IE | `mie` | `sie` |
| Return | `mret` | `sret` |
