# SlipperBoot — C++ Bootloader

## Design

Pure C++, not a single `.S` file. Everything the assembler needs is inline asm
in a `[[gnu::naked]]` entry point. Single goal: read the kernel from disk and jump to it.

## Why C++, not Rust or C

| Language | Pros | Cons |
|---|---|---|
| Rust | type safety | `#[naked]` unstable, extra toolchain |
| C | simplicity | no templates for MMIO wrappers |
| **C++** | register templates, `constexpr` for MMIO, naked entry | — |

C++ was chosen because the bootloader is small, `volatile` + templates are
convenient for MMIO, and naked entry works stably in GCC.

## Entry point (zero assembly)

The only function with inline asm is `_start`. Everything else is pure C++.

```cpp
// boot_entry.cpp
#include <cstdint>

extern "C" {
    extern uint8_t _sbss[], _ebss[], _stack_end[];
    void boot_main();
}

[[gnu::naked]] [[gnu::section(".text.boot")]]
void _start() {
    asm volatile(
        "csrr    t0, mhartid\n"
        "li      t1, 0\n"
        "bne     t0, t1, _hang\n"
        "la      t0, _sbss\n"
        "la      t1, _ebss\n"
        "li      t2, 0\n"
        "1:\n"
        "bgeu    t0, t1, 2f\n"
        "sw      t2, 0(t0)\n"
        "addi    t0, t0, 4\n"
        "j       1b\n"
        "2:\n"
        "la      sp, _stack_end\n"
        "call    boot_main\n"
        "_hang:\n"
        "wfi\n"
        "j       _hang\n"
    );
}
```

This is the only `asm volatile` in the project. Everything below is C++.

## Structure

```
bootloader/
├── linker.ld              # links at 0x80000000
├── Makefile                # cross-riscv64 g++
├── boot_entry.cpp          # _start (inline asm, 1 file)
├── boot_main.cpp           # boot_main(), init sequence
├── uart.hpp                # NS16550A MMIO wrapper (template)
├── uart.cpp
├── virtio.hpp              # VirtIO block v2 MMIO (QueueDesc/QueueReady)
├── virtio.cpp
├── elf.hpp                 # ELF64 header parser
├── elf.cpp
├── fdt.hpp                 # DeviceTree parser
└── fdt.cpp
```

## boot_main()

```cpp
void boot_main() {
    FDT fdt(fdt_addr);

    auto uart_addr = fdt.find_uart();       // compatible = "ns16550a"
    auto uart_irq  = fdt.uart_interrupt();
    UART uart(uart_addr);
    uart.init();
    uart.puts("SlipperBoot v0.1\n");

    auto mem = fdt.memory();
    auto virtio_addrs = fdt.find_virtio();  // compatible = "virtio,mmio"

    VirtIOBlock disk(virtio_addrs[0]);
    if (!disk.probe()) fail("no disk");

    static uint8_t kernel_buf[2_MB] __attribute__((aligned(512)));

    for (int i = 0; i < KERNEL_SECTORS; i++) {
        disk.read(KERNEL_LBA + i, &kernel_buf[i * 512]);
    }

    ELF elf(kernel_buf);
    if (!elf.valid()) fail("bad ELF");

    elf.load_all();
    uart.puts("jumping to kernel\n");
    elf.entry()(hart_id, fdt_addr);
}
```

## UART (NS16550A)

```cpp
struct UART {
    uintptr_t base;

    UART(uintptr_t addr) : base(addr) {}

    volatile uint8_t* reg(uintptr_t off) {
        return reinterpret_cast<volatile uint8_t*>(base + off);
    }

    void init() {
        reg(3)[0] = 0x03;  // LCR: 8N1
        reg(2)[0] = 0x07;  // FCR: FIFO
        reg(1)[0] = 0x01;  // IER: RX IRQ
    }

    void put(char c) {
        while (!(reg(5)[0] & (1 << 5)));
        reg(0)[0] = c;
    }

    char get() {
        while (!(reg(5)[0] & 1));
        return reg(0)[0];
    }
};
```

The address comes from FDT, not hardcoded.

## VirtIO Block (v2 MMIO)

Sedna/OC2r implements **only v2 (modern) MMIO transport**:
`VIRTIO_MMIO_VERSION = 2`, flag `VIRTIO_F_VERSION_1` (bit 32) is mandatory.

- Registers: `QueueDescLow/High`, `QueueDriverLow/High`,
  `QueueDeviceLow/High` + `QueueReady` (replaces Legacy `QueuePfn`)
- Feature negotiation: ACK → DRIVER → negotiate (incl. `VIRTIO_F_VERSION_1`)
  → `FEATURES_OK` → Queue setup → `QueueReady = 1` → `DRIVER_OK`
- 3 descriptors per request: header + data + status
- Polling used ring (no interrupts needed in bootloader)
- Device address and PLIC ID — from FDT, not hardcoded

## ELF Parser

- Reads ELF64 header: magic, machine=RISCV(0xF3), type=EXEC
- Iterates Program Headers
- For each PT_LOAD: copies `filesz` bytes from ELF, zeroes `memsz-filesz`
- Returns entry point

## FDT Parser

- Finds `memory` node in tree — reads `reg` (start, size)
- Finds `compatible = "ns16550a"` — UART address + PLIC interrupt ID
- Finds `compatible = "virtio,mmio"` — VirtIO device addresses + IRQ
- Memory fallback: 0x80000000, 128MB if no FDT
- UART fallback: 0x10000000, IRQ 10 (QEMU only)
- Device addresses are dynamic — no hardcoding

## Build

```makefile
CXX = riscv64-unknown-elf-g++
CXXFLAGS = -march=rv64gc -mabi=lp64d -ffreestanding -nostdlib -O2
LDFLAGS = -T linker.ld -nostdlib

bootloader.bin: bootloader.elf
    riscv64-unknown-elf-objcopy -O binary $< $@
```

## Linker Script

```
BASE = 0x80000000;
.text : { *(.text.boot) *(.text) }
.rodata : { *(.rodata) }
.data : { *(.data) }
.bss : { _sbss = .; *(.bss); _ebss = .; }
. = ALIGN(16);
_stack_start = .;
. += 4K;
_stack_end = .;
```

## Constraints

- Maximum: 32KB for entire bootloader
- Stack: 4KB
- bss zeroed in _start inline asm
- No global constructors (no static objects)
