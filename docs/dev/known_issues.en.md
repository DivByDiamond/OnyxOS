# Known Issues

Documented issues currently present in the code.

## Scheduler: context switch not wired up

`sched_yield()` advances `CURRENT` and returns. `save_context()` /
`restore_context()` are written in `context.rs` but never called.
The scheduler does not actually switch tasks — it just cycles through.

**Plan**: v0.3 — trap handler + calling `sched_yield` from CLINT interrupt.

## Page allocator: no contiguous allocations

The current free list returns one page at a time. There is no guarantee
that two sequential `alloc()` calls return adjacent pages.

This will block VirtIO block (v0.4): vring must reside in physically
contiguous memory. Either implement a descriptor-based allocator (Taken/Last
flags) or support N-page contiguous allocations.

**Plan**: resolve before v0.4.

## VirtIO: Legacy vs v2 MMIO — resolved

Verified against Sedna sources (`AbstractVirtIODevice.java`):
`VIRTIO_MMIO_VERSION = 0x2`, requires `VIRTIO_F_VERSION_1` during negotiation.
**Legacy transport is not supported**.

Documentation (`hardware/virtio/overview.md`, `hardware/virtio/block.md`,
`dev/bootloader.md`) rewritten for v2 MMIO:
`QueueDescLow/High`, `QueueDriverLow/High`, `QueueDeviceLow/High`,
`QueueReady`. Kernel driver (`kernel/drivers/virtio/block.rs`) — v0.4.

**Risk resolved**. Confirmed: v2 only.

## Trap handling: S-mode registers

Documentation has been corrected (`sepc`/`scause`/`stval`/`stvec`/`sret`),
but no trap handler code exists yet. When implementing, avoid copying M-mode
wording from old docs — configure `stvec`, not `mtvec`.

**Plan**: v0.3, via `global_asm!` or `naked_asm!` inside a Rust file.

## UART/VirtIO addresses hardcoded, not from FDT

`kernel/drivers/uart.rs` (0x10000000), `kernel/drivers/virtio/block.rs`
(0x10001000, IRQ 1-8), both kernel and bootloader currently hardcode
addresses and IRQs. This will not work on OC2r with dynamic device placement.

**Plan**: SlipperBoot — FDT parser for UART and VirtIO;
v0.3 or v0.4 — pass FDT to kernel and remove hardcoding.

## Userspace: ELF load + syscalls not implemented

ELF loader (`elf_loading.md`) is designed but not implemented.
Depends on v0.4 (VirtIO block) and v0.5 (SlipFS).

## Shell: read_line() always returns None

`shell/slip.rs` — bug: `INPUT_LEN` is reset to 0 before the line is
processed, causing `read_line()` to always return `None`, so commands
are never executed.

**Plan**: fix in SlipperBoot.

## Sv39: map_page() does not allocate page tables

`mm/map.rs` — `map_page()` checks `pte.is_valid()` but when the table
is missing it simply returns instead of allocating a new page for the
page table.

**Plan**: v0.3, together with real context switching.
