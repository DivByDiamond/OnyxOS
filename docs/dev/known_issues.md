# Known Issues

> Актуально на 2026-11-18. Здесь только **открытые** ограничения.
> Закрытые пункты живут в `docs/dev/roadmap.md`, `OnyxKernel/todo.md`
> и `docs/history/`; «сделано» сюда не переносится.

## OnyxKernel

| Ограничение | Где | Что осталось |
|-------------|-----|--------------|
| Блокирующий `recv` | `kernel/src/net/tcp` | В ядре нет wait-очереди по сокетам, приложение опрашивает само; нужен блокирующий путь без busy-poll |
| Отправка TCP по 536 байт на сегмент | `kernel/src/net/tcp` | IP-фрагментации нет; поднять MSS и учитывать MTU пути |
| Server sockets только root-only admin | `kernel/src/net` | Пользовательские `listen`/`accept` недоступны, контракт не описан в README |
| TLS отсутствует | userspace (`obrowse`) | Браузер остаётся HTTP-only |
| Динамические kernel-модули | `kernel/src/fs/procfs` | `/proc/modules` показывает только встроенные драйверы |
| Журнал без flush/barrier | `kernel/src/fs/onyxfs` | Гарантия ограничена упорядоченными блочными записями; power-loss и частичные секторы на OC2R/физическом носителе не проверены (L6) |
| Glyph-blit попиксельно по MMIO | `kernel/src/drivers/video/fb_term` | Scroll/clear копируют словами, вывод глифа — нет (L4) |
| Двойная буферизация не проверена | `kernel/src/drivers/video/fb` | Tearing на живом мониторе OC2R не измерялся (L5) |
| URB/HCD-слой без потребителя | `kernel/src/drivers/bus/usb/hcd.rs` | Нужен USB core enumeration (дескрипторы, адресация, mass-storage) или удаление слоя |
| `nanosleep` на rv32 non-smode | `kernel/src/arch` | Идёт через SBI; нужен прямой CLINT MMIO и `mtrap_32`-путь |
| RV32 smode не поддержан | сборка | У комбинации нет boot entry, она отклоняется явно; поддерживаемая матрица — RV32 default и RV64 default/smode |
| Нет EOF после RST | `kernel/src/net/tcp/sock.rs` | `recv` возвращает `Err(Io)`, а не `Ok(0)` — сознательно, но приложение обязано различать сброс и FIN (L3) |

## Userland

| Ограничение | Где | Что осталось |
|-------------|-----|--------------|
| GUI: нет WM/compositor/курсора | userspace | Отдельные окна, z-order/clipping, обработка кликов, продвинутые виджеты |
| Java runtime отсутствует | userspace | Class loader, интерпретатор байткода, подмножество JDK, GC, hello-world в QEMU/OC2R |
| Живые прогоны приложений | `OnyxApps` | osnake, otop, ochat, ochat-gui — логика покрыта host-тестами, интерактив в QEMU/с модом не подтверждён |

## OnyxCompiller

| Ограничение | Что осталось |
|-------------|--------------|
| Один вход на `-c` | Несколько translation units за один вызов не поддержано |
| Архивы без индекса | Ленивое линейное извлечение, `__.SYMDEF` не читается |
| Нет COMDAT/versioning/relaxation/section GC | Компоновка без удаления мёртвых секций и без версий символов |
| `-e` принимает только GLOBAL | Точка входа из локального символа невозможна |
| PCREL-релокации не эмитятся | Компилятор их не порождает, линкер полагается на абсолютные |
| Жёсткие лимиты | 64 объекта и 4 секции на объект |
| Один проход, без оптимизаций | Нет IR: const propagation, DCE, свёртка циклов не реализованы |
| C++ только подмножество | Нет множественного/виртуального наследования, RTTI/`dynamic_cast`, шаблонов классов, виртуальных деструкторов, полного unwinding — детали в `OnyxCompiller/docs/STATUS.md` |
| Повторный полный bootstrap | Stage-one self-host проходит, полный цикл «собрать себя собой» не завершён |

## OnyxOS

| Ограничение | Что осталось |
|-------------|--------------|
| CI не видит локальных коммитов | Пин `Onyx.lock.json` валиден только после пуша компонентов; иначе locked-сборка на GitHub не получит ревизию |
| Документация на двух языках | Английские версии отстают; при правке `.md` пересобирать через `build-docs.sh` |

## Как это проверялось

Сверка с кодом и планами на 2026-11-18: `abi/syscalls.csv` (100 вызовов),
`docs/dev/roadmap.md` (срез v0.4/v0.5), `OnyxKernel/todo.md` §3–4,
`OnyxCompiller/docs/STATUS.md` §«Remaining limitations»,
`OnyxApps/todo.md`.
