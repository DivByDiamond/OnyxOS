# Языковая политика

## Принцип

Каждый слой системы — свой язык. На стыке — только ELF + ABI.

```
SlipperBoot   → C++  (один naked entry, остальное чистый C++)
SlipperOS     → Rust (ядро, драйверы, shell, сервисы)
Userspace C   → C    (только picolibc, если нужен порт)
Userspace C++ → C++  (только если реальный порт Hyprland)
```

## SlipperBoot: C++ без ассемблера

Единственный `asm volatile` — naked entry point `_start()`. Всё остальное
чистый C++: шаблоны для MMIO-регистров, `constexpr` для адресов,
RAII для устройств.

Почему C++, не Rust:
- `#[naked]` в Rust нестабилен, требует nightly feature gate
- `core::arch::asm!` синтаксис менялся между версиями
- C++ naked + `asm volatile` стабильно работает в GCC годами
- bootloader маленький — выгода от шаблонов есть, от borrow checker нет

## SlipperOS: Rust

Ядро на Rust `#![no_std]` под `riscv64gc-unknown-none-elf`.
Допустимый ассемблер — только inline `asm!` внутри Rust-файлов,
никаких отдельных `.S` кроме `boot/boot.S` (который заменится SlipperBoot).

## C — только если picolibc в userspace

Появляется после v0.5. Один файл syscalls.c, всё остальное — picolibc.

## C++ — только Hyprland, отдельная ветка

Не раньше чем появится свой Wayland compositor. Не блокирует v1.0.

## Сборка

- **bootloader**: Makefile + `riscv64-unknown-elf-g++`
- **kernel**: Cargo + nightly + `riscv64gc-unknown-none-elf`
- **userspace C**: Makefile + `riscv64-unknown-elf-gcc` + picolibc
