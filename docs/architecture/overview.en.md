# OnyxOS Architecture

Five independent components, each in its own repository:

```
OpenSBI (M-mode)
    ↓
OnyxBoot (S-mode, C++)
    ↓
OnyxKernel (S-mode, Rust — no_std)
    ↓
init → login → OnyxShell (ring 1, Rust)
    ↓
OnyxCompiller (ring 2, C — userspace)
```

---

## OnyxBoot

C++20 bootloader (zero `.S` files). Runs in S-mode after OpenSBI.

**Responsibilities:**
- UART (NS16550A) — boot messages
- FDT parser — detect memory, devices (UART, VirtIO, SDHCI)
- VirtIO block / SDHCI — read `kernel.elf` from disk
- FAT32 + ext4 read, GPT + MBR
- ELF64 parser — load segments into memory
- Boot menu with timeout, device selection
- Jump to kernel (a0=hart_id, a1=fdt)

**Status:** v0.4 — stable, QEMU-tested

---

## OnyxKernel

Monolithic kernel in pure Rust (`no_std`, `no_main`). RISC-V 64-bit (rv64gc),
32-bit port WIP.

**Key subsystems:**
- `kernel/src/mm/` — PMM (bitmap+slab), VMM (Sv39), heap
- `kernel/src/proc/` — processes, SMP scheduler, signals, onx loader
- `kernel/src/fs/` — OnyxFS v2, VFS, FAT32, procfs, ipcfs, devfs
- `kernel/src/drivers/` — UART, VirtIO, SDHCI, PCI, PLIC, GMAC, USB, display
- `kernel/src/syscall/` — 77 syscalls (POSIX-flavored)
- `kernel/src/net/` — Ethernet, IP, TCP
- `kernel/src/ipc/` — IPC channels with ring buffer

**Status:** active development, ~30K+ LOC

---

## OnyxShell

Userspace shell (`/bin/osh`). Runs in ring 1 (root space).

**Features:**
- 20 built-in commands: ls, cat, cp, mv, rm, mkdir, touch, stat, cd, pwd, echo, whoami, uname, date, clear, help, exit, exec, run, ver
- Tab completion, arrow-key history
- History expansion (!! / !N / !-N)
- Pipe (|) and redirect (>, <)
- Wildcard globbing (*, ?, [...])

**Status:** v0.3, active

---

## OnyxCompiller

C → RISC-V 64-bit → `.onx` compiler. Single-pass, inspired by tcc.

**Features:**
- C99 parser (functions, struct/union/enum, pointers, arrays)
- Preprocessor (#include, #define, #if/#ifdef...)
- RV64IMA codegen
- libonyxc (printf, malloc, string)
- Dual build: native Linux + `.onx` for OnyxOS

**Status:** MVP, self-hosting in progress

---

## OnyxOS

System layer: documentation, build scripts, integration.

**Responsibilities:**
- `docs/` — project documentation
- `scripts/` — bootstrap, build-all, run-qemu
- `Onyx.vent` — dependency management via Vent
- Future: full userspace

**Status:** meta-repository
