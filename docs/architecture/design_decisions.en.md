# Design Decisions

Deliberate differences between SlipperOS and Linux, favoring simplicity and embedded use.

## 1. Custom binary format (SPX), not ELF

**Linux problem**: ELF64 is complex — sections, relocations, dynamic linking, GOT/PLT, .interp, .dynamic, .init_array. Overkill for embedded bootloaders.

**SlipperOS solution**: SPX format — 344-byte header, 40 bytes per segment. No relocations, no GOT, no dynamic linking. What you load is what runs.

**Why it wins**: 10x faster loading, 100-line parser, no dynamic linking headaches. Ideal for embedded.

## 2. No Linux driver model

**Linux problem**: Device tree, platform drivers, driver model, deferred probe, kernel modules — thousands of lines of infrastructure.

**SlipperOS solution**: `fdt_find_uart()` → MMIO address → use it. All drivers compiled in, no modules. Hardware is detected via FDT and initialized directly.

**Why it wins**: Hardware init in microseconds, not seconds. No deferred probe, no dependency hell.

## 3. Tools in C, not Python

**Linux problem**: buildroot, Yocto, genimage — all require Python. Building a kernel needs an interpreter, packages, virtual environments.

**SlipperOS solution**: `elf2spx.c` (ELF→SPX converter), `mkimage.c` (SlipperFS builder). 150 lines of C each, compile in 0.1 seconds, zero dependencies.

**Why it wins**: Build once, run anywhere. No `ModuleNotFoundError`, no `pip install`, no Python runtime. Just Make + GCC.
