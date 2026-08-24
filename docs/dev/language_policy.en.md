# Language Policy

## Principle

Each system layer has its own language. At the boundary — only ELF + ABI.

```
SlipperBoot   → C++  (one naked entry, rest is pure C++)
SlipperOS     → Rust (kernel, drivers, shell, services)
Userspace C   → C    (picolibc only, if a port is needed)
Userspace C++ → C++  (only if porting Hyprland)
```

## SlipperBoot: C++ without assembly

The only `asm volatile` is the naked entry point `_start()`. Everything else
is pure C++: templates for MMIO registers, `constexpr` for addresses,
RAII for devices.

Why C++, not Rust:
- `#[naked]` in Rust is unstable, requires nightly feature gate
- `core::arch::asm!` syntax has changed between versions
- C++ naked + `asm volatile` works stably in GCC for years
- The bootloader is small — templates are beneficial, borrow checker is not

## SlipperOS: Rust

Kernel in Rust `#![no_std]` targeting `riscv64gc-unknown-none-elf`.
Allowed assembly — only inline `asm!` inside Rust files,
no separate `.S` files except `boot/boot.S` (which will be replaced by SlipperBoot).

## C — picolibc only for userspace

Appears after v0.5. One syscalls.c file, everything else is picolibc.

## C++ — Hyprland only, separate branch

No earlier than when we have our own Wayland compositor. Not blocking v1.0.

## Build

- **bootloader**: Makefile + `riscv64-unknown-elf-g++`
- **kernel**: Cargo + nightly + `riscv64gc-unknown-none-elf`
- **userspace C**: Makefile + `riscv64-unknown-elf-gcc` + picolibc
