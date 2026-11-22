# Roadmap

## OnyxOS Ecosystem Roadmap

Сверка рабочего дерева: 2026-11-21. Реализованные возможности ниже не
означают полной POSIX/C/C++ совместимости; аппаратные проверки указаны отдельно.

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
- [x] 100 syscalls в ABI registry (POSIX-flavored)
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
- [x] FAT32 read/write, create/unlink/truncate, LFN и FSINFO (`5e92115`, 2026-10-25)
- [x] USB xHCI URB transfer и PCI probe; QEMU controller smoke (`7790fdf`, 2026-11-09)
- [x] USB HID-джойстик: перечисление устройств в реестр слотов, HID report-descriptor парсер, interrupt-IN опрос, `/dev/jsN` joydev-узлы; live QEMU smoke `qemu-usb-smoke.sh` (usb-kbd — перечислен, js-узла нет; usb-tablet — stick-сессия) — ветка feat/usb-hid-joystick `a50d5fb`..`c3c619a`, live-фиксы `fe80f57`, `1e2d1f5`, `b7885a1`, `a181b22`, 2026-11-20
- [x] USB multi-device (multi-slot xHCI): несколько одновременных `/dev/jsN`, smoke `qemu-usb-smoke.sh` (c)-(e); 2026-11-22
- [ ] EHCI interrupt-передачи, USB mass-storage
- [x] symlink/readlink: syscall и VFS/OnyxFS paths (сверено 2026-11-15)
- [x] chmod/fchmod: syscall и VFS paths (сверено 2026-11-15)
- [x] truncate/ftruncate(>0): OnyxFS/FAT32 resize (сверено 2026-11-15)
- [x] getdents64: пакетный syscall (сверено 2026-11-15)
- [x] fork: копирование argv/envp и child trap frame (сверено 2026-11-15)
- [x] UDP/DHCP/DNS; DHCP и DNS проверялись в OC2R (2026-10-25, `OnyxKernel/todo.md` §5)

**OnyxCompiller:**
- [x] Сборка и запуск OnyxCC, собранного самим OnyxCC; компиляция freestanding-программы
- [x] Несколько C translation units в одном `.onx`
- [x] Базовые глобальные инициализаторы массивов/строк
- [x] Автоматический test runner с проверкой исполнения
- [ ] Повторный полный bootstrap и завершение поддержки C/libc
- [x] Отдельная компиляция C/C++ → ONYO → `onyx-ld`, libc objects (`bd14e5d`, 2026-11-15)
- [ ] Полноценный архивный линкер и совместимость с внешним RISC-V ABI
  (выбор членов архива по неразрешённым именам `c3d2bd7` и weak binding
  `4845c52` готовы, 2026-11-15; остаются `__.SYMDEF`-индекс, COMDAT,
  section GC и внешняя ABI-совместимость)

**Quality:**
- [x] GitHub Actions CI: component workflows и OnyxOS build/release (сверено 2026-11-15)
- [x] Host unit-тесты core/kernel и отдельной логики init (`OnyxKernel/docs/TESTING.md`, сверено 2026-11-15)
- [x] Full-stack QEMU boot/interactive smoke и xHCI smoke (`8c5ad8f`, 2026-11-15); USB HID smoke (`qemu-usb-smoke.sh`, 2026-11-20); desktop smoke (`qemu-desk-smoke.sh`, 2026-11-21)
- [x] OnyxFS: full-block undo, fault injection и remount (`cf6ca42`, 2026-11-15; `FS-J1/J2`)
- [ ] OnyxFS: flush/barrier и проверка power loss/частичных секторов на OC2R/физических носителях

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

**OnyxDesktop:**
- [x] `onyxdesk` — десктоп-демон (C99, ring 1): claim `/dev/fb0` на сеанс,
  панель + лаунчер из `/etc/desk.conf`, managed-запуск приложений с
  возвратом по выходу; 237 host-проверок GREEN (`7e131ec`, 2026-11-21)
- [x] Интеграция в образ: 7-я `.vent`-зависимость, шаг сборки в
  `build-all.sh`, упаковка `/bin/onyxdesk` + `/etc/desk.conf`
  (`package-desktop.py`), smoke `qemu-desk-smoke.sh` — маркеры
  `DESK_READY`/`APP_STARTED`/`APP_RETURN`/`DESK_EXIT 0` (2026-11-21)
- [ ] M3: хоткеи, маршрутизация ввода активному окну (ядро P2-A),
  `SIGSTOP`/`SIGCONT`-переключение
- [ ] M4: перекрывающиеся окна/композиция (ядро P2-B)
- [ ] SBC-трек: bring-up на плате, DSI-экран и USB-HID вживую

**OnyxCompiller:**
- [x] C++ subset: классы, RAII, virtual dispatch, exceptions без полного unwinding (`ca8546d`, 2026-11-15)
- [ ] Оптимизации (const propagation, dead code elimination)

### v1.0 — стабильный релиз

- [ ] Проверка на реальном Milk-V Duo S
- [ ] Документация на двух языках
- [ ] Self-hosting: OnyxOS компилирует OnyxOS

## Проверка среза 2026-11-21

- Сверка чекбоксов v0.4/v0.5/v0.6 по heads OnyxOS `45ffd2f`, OnyxKernel
  `113945a`: источники `OnyxKernel/todo.md` (P1, §3, §4),
  `OnyxCompiller/docs/STATUS.md`, `OnyxApps/todo.md`, `OnyxBoot/roadmap.md`;
  спорные пункты оставлены открытыми с примечанием.
- OnyxDesktop v1 влит в образ (`312cce5`, `17688cb`): 7-я `.vent`-зависимость,
  шаг сборки в `build-all.sh`, упаковка `package-desktop.py`, дизайн-док
  `docs/dev/onyxdesktop-design.md`, обзор экосистемы `docs/dev/ecosystem.md`,
  smoke `qemu-desk-smoke.sh`.
- Смоки на артефактах текущей locked-сборки `.build/`: `qemu-smoke.sh`,
  `qemu-interactive-smoke.sh`, `qemu-desk-smoke.sh`, все три PASS.
- CI на указанных heads зелёный: workflows всех шести компонентов и OnyxOS
  Build & Test / Release.
- `roadmap.en.md` синхронизирован с этой ревизией: добавлены секция
  OnyxDesktop, USB HID-записи и этот срез.

## Проверка среза 2026-11-18

- Пин компилятора догнал дерево: `OnyxCompiller 6fc1947`, `OnyxShell 82f0daa`.
  До этого locked-сборка падала на `dependencies.py check`, потому что сборка
  переписывала отслеживаемые бинарники (`DW_AT_comp_dir` зависел от пути
  вызова, `build/osh.onx` отставал от исходников).
- `onyxcc`/`onyx-ld` теперь побайтно воспроизводятся из любого пути сборки;
  `build-all.sh` в режиме `check` в конце проверяет, что locked-деревья
  остались чистыми.
- Валидация компилятора на `6fc1947`: `make check` (66 frontend, 48 runtime,
  15 C++, 5 sepcomp, 44 archive, 36 weak, 48 source-weak, 26 storage, init),
  `make check-native` (7 наборов ASan/UBSan), `make selfhost-test` — всё PASS.
- Полная locked-сборка: ядро, шелл, компилятор, 10 приложений, образ диска;
  `qemu-smoke.sh` и `qemu-interactive-smoke.sh` PASS.
- `docs/dev/known_issues.md` переписан по факту: остались только открытые
  пункты, английская версия синхронизирована.

## Проверка среза 2026-11-15

- Согласованные исправления OnyxExec: kernel `14937bc` отклоняет неверные
  permissions; linker `e7a57ec` использует общие R/W/X и ring1-константы.
- OnyxFS `9215876`: shrink → extend обнуляет хвост сохранённого блока.
- Host: 70 core + 3 integration + 307 kernel + 4 init; native Apps;
  compiler `make check` (66 frontend, 43 runtime, 5 driver, 15 C++, 5 sepcomp)
  и семь ASan/UBSan suites; 10 тестов dependency resolver; ABI registry — 100.
- Полная workspace-сборка и locked-сборка в чистых checkout’ах прошли;
  locked-образ дошёл до login в QEMU.
- QEMU: boot и interactive smoke; отдельный гостевой прогон tail-zero,
  octal escape, linked-C++ virtual dispatch (`3 2`) и отказ испорченному ONX
  с продолжением работы shell. Bootloader: четыре QEMU-сценария прошли.
- `cf6ca42`: OnyxFS сохраняет полные before-images метаданных, откатывает
  незавершённые операции, не переиспользует журнал после неудачного commit.
  Host write-cut тесты и четыре QEMU-контроля legacy/undo прошли. Гарантия
  ограничена упорядоченными завершёнными блочными write, не physical power loss.
- `1c0f188`, `b8866e9`, `773a8b5`, `c27cc31`: полный fmt/строгий Clippy,
  общие init-модули, удаление dead-code bypass и неиспользуемых заготовок.
  CI больше не использует advisory-проверку core tests.
- RV32 smode явно отклоняется: у этой комбинации нет boot entry.
  Поддерживаемая матрица — RV32 default и RV64 default/smode.

## Обязательная проверка качества

```sh
bash scripts/quality/check.sh /path/to/component/checkouts
```

Gate запускает полный fmt и Clippy для поддерживаемых host/target-конфигураций,
проверяет явный отказ RV32 smode и отсутствие dead-code bypass во всех шести
компонентах. Для локальных `.vent/repos` аргумент можно опустить.
Диагностика backend-флага `reserve-x4` сохраняется без подавления: этот флаг
нужен для регистра `tp`; команды Clippy по-прежнему используют `-D warnings`.
