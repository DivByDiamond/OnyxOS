# Архитектура OnyxOS

Проект состоит из пяти компонентов:

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

Загрузчик на C++20 (ни одного `.S` файла). Работает в S-mode, получает управление после OpenSBI.

**Ответственность:**
- UART (NS16550A) — вывод сообщений
- FDT-парсер — определение памяти, устройств (UART, VirtIO, SDHCI)
- VirtIO block / SDHCI — чтение `kernel.elf` с диска
- FAT32 + ext4 read, GPT + MBR
- ELF64-парсер — загрузка сегментов в память
- Boot menu с timeout и выбором устройства
- Передача управления ядру (a0=hart_id, a1=fdt)

**Статус:** v0.4 — стабильный, протестирован в QEMU

---

## OnyxKernel

Монолитное ядро на Rust (`no_std`, `no_main`). RISC-V 64-bit (rv64gc) с 32-bit портом в разработке.

**Ключевые подсистемы:**
- `kernel/src/mm/` — PMM (bitmap+slab), VMM (Sv39), heap allocator
- `kernel/src/proc/` — процессы, SMP scheduler, сигналы, onx загрузчик
- `kernel/src/fs/` — OnyxFS v2, VFS, FAT32, procfs, ipcfs, devfs
- `kernel/src/drivers/` — UART, VirtIO, SDHCI, PCI, PLIC, GMAC, USB, display
- `kernel/src/syscall/` — 77 syscalls (POSIX-flavored)
- `kernel/src/net/` — Ethernet, IP, TCP
- `kernel/src/ipc/` — IPC каналы с ring buffer

**Статус:** активная разработка, ~30K+ строк

---

## OnyxShell

Пользовательский shell (`/bin/osh`). Работает в ring 1 (root space).

**Возможности:**
- 20 built-in команд: ls, cat, cp, mv, rm, mkdir, touch, stat, cd, pwd, echo, whoami, uname, date, clear, help, exit, exec, run, ver
- Tab completion, arrow-key history
- History expansion (!! / !N / !-N)
- Pipe (|) и redirect (>, <)
- Wildcard globbing (*, ?, [...])

**Статус:** v0.3, активно

---

## OnyxCompiller

C → RISC-V 64-bit → `.onx` компилятор. Single-pass, вдохновлён tcc.

**Возможности:**
- C99 парсер (функции, struct/union/enum, указатели, массивы)
- Препроцессор (#include, #define, #if/#ifdef...)
- RV64IMA codegen
- libonyxc (printf, malloc, string)
- Двойная сборка: нативный Linux + `.onx` для OnyxOS

**Статус:** MVP, самокомпиляция в процессе

---

## OnyxOS

Системный слой: документация, скрипты сборки, интеграция.

**Ответственность:**
- `docs/` — вся документация проекта
- `scripts/` — bootstrap, build-all, run-qemu
- `Onyx.vent` — dependency management через Vent
- В будущем: полноценный userspace

**Статус:** meta-репозиторий
