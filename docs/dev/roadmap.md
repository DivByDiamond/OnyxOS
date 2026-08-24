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
- [x] 58 тестовых программ

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
- [ ] **Самокомпиляция** (P0)
- [ ] Multi-file linking
- [ ] Глобальные инициализаторы массивов/строк
- [ ] Автоматический test runner

**Quality:**
- [ ] GitHub Actions CI
- [ ] Unit-тесты ядра
- [ ] Full-stack QEMU test suite

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
