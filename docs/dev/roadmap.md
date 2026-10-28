# Roadmap

## OnyxOS Ecosystem Roadmap

### v0.4 — текущий релиз ✅

**OnyxBoot:**
- [x] UART, FDT, VirtIO v2 MMIO, SDHCI
- [x] FAT32 + ext4 read, GPT + MBR
- [x] Boot menu с timeout
- [x] ELF64 загрузчик
- [x] QEMU интеграционные тесты

**OnyxKernel (core):**
- [x] UART, CLINT, PLIC, таймер
- [x] PMM (bitmap+slab) + VMM (Sv39)
- [x] Heap allocator
- [x] Процессы: динамический список, spawn, exec, wait
- [x] Scheduler: SMP, per-CPU run queues, load balancing
- [x] 77 syscalls (POSIX-flavored)
- [x] OnyxFS v2 (журналирование, COW snapshots, indirect blocks)
- [x] OnyxExec v2 загрузчик (RLE compression, ring1 flag)
- [x] VirtIO block/net, GMAC
- [x] TCP/IP (Ethernet, IP, TCP)
- [x] IPC каналы (/ipc/*)
- [x] Framebuffer + PSF1/PSF2 шрифты
- [x] /proc filesystem
- [x] Аутентификация (/etc/passwd + /etc/shadow)
- [x] INIT + LOGIN + userspace binaries (9 штук)
- [x] FDT-driven адреса устройств

**OnyxShell:**
- [x] 20 built-in команд
- [x] Tab completion + arrow-key history
- [x] History expansion (!! / !N / !-N)
- [x] Pipe (|) и redirect (>, <)
- [x] Wildcard globbing (*, ?, [...])
- [x] QEMU integration test

**OnyxCompiller:**
- [x] C99 lexer, preprocessor, parser
- [x] RV64IMA codegen
- [x] .onx v1 output
- [x] libonyxc (printf, malloc, string, syscall wrappers)
- [x] Проверки фронтенда и тесты с исполнением (`make check`)

**OnyxOS:**
- [x] Vent dependency management
- [x] Bootstrap/build/run скрипты
- [x] Полная документация

### v0.5 — стабилизация ядра

**OnyxKernel:**
- [ ] FAT32 read (lookup/read)
- [ ] USB xHCI URB transfer
- [ ] symlink/readlink
- [ ] chmod/fchmod
- [ ] truncate/ftruncate(>0)
- [ ] getdents64 batched
- [ ] fork c argv/envp
- [ ] UDP/DHCP/DNS

**OnyxCompiller:**
- [x] Сборка и запуск OnyxCC, собранного самим OnyxCC; компиляция freestanding-программы
- [x] Несколько C translation units в одном `.onx`
- [x] Базовые глобальные инициализаторы массивов/строк
- [x] Автоматический test runner с проверкой исполнения
- [ ] Повторный полный bootstrap и завершение поддержки C/libc
- [ ] Отдельная компиляция `.o`, статические библиотеки и совместимый ABI

**Quality:**
- [ ] GitHub Actions CI
- [ ] Unit-тесты ядра
- [ ] Full-stack QEMU test suite

**Приоритет языков перед GUI/Java:**
- [x] Стандартные Lua 5.5.1 и `luac`: CLI, REPL, Lua-модули, байткод и системные проверки
- [ ] Полная поддержка C и C++, базовых и пользовательских библиотек
- [ ] LuaJIT/Luau после стандартной Lua и проверки требований платформы
- [ ] Портирование существующего `rustc` target/runtime после стабилизации ABI

Ограничения компилятора: [compiler.md](compiler.md) и `OnyxCompiller/docs/STATUS.md`.
Lua собрана без загрузки нативных shared libraries; полный upstream test suite ещё не подтверждён.

### v0.6 — расширение

**OnyxKernel:**
- [ ] 32-bit порт (RV32)
- [ ] Многопользовательский режим
- [ ] Динамические модули

**OnyxCompiller:**
- [ ] C++ фронтенд (начало)
- [ ] Оптимизации (const propagation, dead code elimination)

### v1.0 — стабильный релиз

- [ ] Проверка на реальном Milk-V Duo S
- [ ] Документация на двух языках
- [ ] Self-hosting: OnyxOS компилирует OnyxOS
