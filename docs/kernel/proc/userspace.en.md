# Userspace Processes

## ELF Loading

1. Read ELF header from disk (via VirtIO Block)
2. Validate magic (`0x7f ELF`), machine (`0xf3` = RISC-V), type (EXEC)
3. Read Program Headers
4. For each LOAD segment:
   - Allocate memory
   - Copy data from ELF file
   - Map virtual memory with U, R, W, X flags
5. Set entry point from `elf_hdr.entry_addr`
6. Configure stack (SP), SATP
7. Add to process list

## System Calls (ecall)

- U-mode ecall → cause 8
- Syscall number in a0, arguments in a1-a5
- Return in a0
- After handling: mepc += 4

### Numbers (libgloss convention)

| Number | Syscall |
|---|---|
| 63 | read |
| 64 | write |
| 93 | exit |
| 57 | close |
| 80 | fstat |
| 214 | brk |

## Switching to U-mode

```assembly
mstatus.MPP = 00   // User mode
mepc = entry_point
satp = process_table >> 12 | (8 << 60)
mret               // → U-mode
```

## Init Process

The first process (pid=1, init) starts immediately after the scheduler.
Loaded from disk via ELF or embedded as a function.
