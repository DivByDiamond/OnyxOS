# Known Issues

Актуальные проблемы и недоделки в текущем коде.

## OnyxKernel

| Проблема | Файл | Статус |
|----------|------|--------|
| FAT32 read — lookup/read заглушены | `kernel/src/fs/fat32/` | TODO (см. ниже) |
| USB xHCI — только probe, нет URB transfer | `kernel/src/drivers/usb/` | TODO |
| `truncate/ftruncate` только до нуля | `kernel/src/fs/vfs/truncate.rs` | ✅ FIXED (v0.5) — `truncate_to_length(ino, length)` поддерживает zero/shrink/extend |
| symlink/readlink не реализованы | `kernel/src/fs/onyxfs/` | ✅ FIXED (v0.5) — symlink.rs + readlink syscall работают |
| `chmod/fchmod` — заглушки | `kernel/src/syscall/fs_sys3/` | ✅ FIXED (v0.5) — set_mode() в OnyxFS сохраняет mode в inode |
| `chown/fchown` | `kernel/src/syscall/fs_sys3/` | ✅ FIXED (v0.5) — set_uid_gid() сохраняет uid/gid в inode |
| `getdents64` без батчинга | `kernel/src/syscall/fs_sys3/` | TODO |
| fork без передачи argv/envp | `kernel/src/syscall/fs_sys3/extra.rs` | TODO |
| UDP/DHCP/DNS отсутствуют | `kernel/src/net/` | TODO |
| Нет unit-тестов | — | TODO |
| 32-bit порт (~50%) | `arch/bits.rs`, `boot_32.rs` | WIP |

## OnyxCompiller

| Проблема | Статус |
|----------|--------|
| Самокомпиляция | ✅ DONE (stage-1, `make selfhost` собирает onyxcc_self.onx) |
| Multi-file compilation (N `.c` файлов в один `.onx`) | ✅ DONE (см. main.c) |
| External library linking (.a архивы + .o объектники с релокациями) | TODO (см. onyx-ld roadmap) |
| Глобальные инициализаторы массивов/строк | ✅ DONE |
| C++ фронтенд не написан | TODO |
| Нет автоматического прогона тестов | ✅ DONE (`make test-runner`) |

## libonyxc

| Проблема | Статус |
|----------|--------|
| Нет `FILE*` buffered I/O | ✅ FIXED (v0.5) |
| Нет `sprintf`/`snprintf`/`sscanf` | ✅ FIXED (v0.5) |
| Нет `errno`/`strerror`/`perror` | ✅ FIXED (v0.5) |
| Нет `time.h` (time/localtime/strftime/clock_gettime/nanosleep) | ✅ FIXED (v0.5) |
| Нет `signal.h` (sigset ops, struct sigaction) | ✅ FIXED (v0.5) |
| Мало stdlib (qsort/bsearch/strtoul/strtoll/strtod/atexit) | ✅ FIXED (v0.5) |
| Мало string (strstr/strrchr/strtok_r/strcasecmp/strpbrk/memchr) | ✅ FIXED (v0.5) |

## OnyxOS

| Проблема | Статус |
|----------|--------|
| Makefile — скелет, не все цели работают | WIP |
| Нет CI/CD (GitHub Actions) | TODO |

## Решённые проблемы (исторические)

Все проблемы из предыдущей версии (`known_issues.md` SlipperOS) исправлены:

- ✅ Контекст свитч — работает (SMP, per-CPU run queues)
- ✅ Page allocator — bitmap + slab, есть contiguous
- ✅ VirtIO Legacy — не используется, только v2
- ✅ Trap handler — S-mode, stvec
- ✅ UART/VirtIO адреса — FDT-driven
- ✅ ELF загрузчик — onx::load работает
- ✅ Shell — все 20 команд работают
- ✅ Sv39 map_page — аллоцирует page tables
