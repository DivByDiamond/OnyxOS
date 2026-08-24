# SlipperOS Roadmap

## v0.1 — Skeleton
- [x] UART console (NS16550A)
- [x] CLINT timer
- [x] PLIC interrupts
- [x] Bump + Page allocator
- [x] Sv39 identity map
- [x] Slip shell (7 commands)
- [x] Panic handler

## SlipperBoot (v0.4)
- [x] _start entry (naked C++, inline asm)
- [x] UART driver (NS16550A, address from FDT)
- [x] VirtIO block v2 MMIO (probe, read_sector)
- [x] SDHCI driver (probe, read_sector)
- [x] FAT32 + EXT4 reader
- [x] ELF64 parser (valid, check_safe, load_all)
- [x] FDT parser (memory, UART, VirtIO, SDHCI)
- [x] Boot menu (device selection)
- [x] Load & jump to `kernel.elf`

## v0.3 — Interrupts and tasks
- [ ] Trap handler (S-mode, `stvec`)
- [ ] Real context switching in `sched_yield()`
- [ ] Round-robin scheduler via CLINT
- [ ] syscall: ecall handler

## v0.4 — VirtIO block in kernel (v2 MMIO)
- [x] v2 MMIO confirmed (Sedna: `VIRTIO_MMIO_VERSION = 2`, requires `VIRTIO_F_VERSION_1`)
- [ ] Descriptor-based page allocator (contiguous)
- [ ] Sector read/write (v2 driver)
- [ ] I/O completion interrupts

## v0.5 — SlipFS + userspace
- [ ] SlipFS (block filesystem in Rust)
- [ ] Mount, read, write
- [ ] ELF loader in kernel
- [ ] First userspace process

## v0.6 — Stable kernel
- [ ] CLI tools (ls, cat, echo, ps)
- [ ] Init process
- [ ] Runs on OC2r
- [ ] Full documentation

## v1.0 — Release
- [ ] Slip shell as userspace program
- [ ] Port picolibc for C software
- [ ] Module loading via SlipperBoot
