# Design Decisions

Deliberate differences between OnyxOS and Linux, favoring simplicity and embedded use.

## 1. Custom binary format (OnyxExec), not ELF

**Linux problem**: ELF64 is complex — sections, relocations, dynamic linking, GOT/PLT, .interp, .dynamic, .init_array. Overkill for embedded bootloaders.

**OnyxOS solution**: OnyxExec format — 344-byte header, 40 bytes per segment. No relocations, no GOT, no dynamic linking. What you load is what runs.

**Why it wins**: 10x faster loading, 100-line parser, no dynamic linking headaches. Ideal for embedded.

## 2. No Linux driver model

**Linux problem**: Device tree, platform drivers, driver model, deferred probe, kernel modules — thousands of lines of infrastructure.

**OnyxOS solution**: `fdt_find_uart()` → MMIO address → use it. All drivers compiled in, no modules. Hardware is detected via FDT and initialized directly.

**Why it wins**: Hardware init in microseconds, not seconds. No deferred probe, no dependency hell.

## 3. Tools in C, not Python

**Linux problem**: buildroot, Yocto, genimage — all require Python. Building a kernel needs an interpreter, packages, virtual environments.

**OnyxOS solution**: `elf2onx.c` (ELF→OnyxExec converter), `mkimage.c` (OnyxFS builder). 150 lines of C each, compile in 0.1 seconds, zero dependencies.

**Why it wins**: Build once, run anywhere. No `ModuleNotFoundError`, no `pip install`, no Python runtime. Just Make + GCC.
