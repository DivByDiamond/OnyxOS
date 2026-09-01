# OnyxOS

[![Build & Test](https://github.com/DivByDiamond/OnyxOS/actions/workflows/build.yml/badge.svg)](https://github.com/DivByDiamond/OnyxOS/actions/workflows/build.yml) [![Release](https://github.com/DivByDiamond/OnyxOS/actions/workflows/release.yml/badge.svg)](https://github.com/DivByDiamond/OnyxOS/actions/workflows/release.yml)

<p align="center">
  <img src="https://img.shields.io/badge/arch-RISC--V%2064--bit%20%7C%20RV32-green" alt="RISC-V">
  <img src="https://img.shields.io/badge/kernel-Rust-orange" alt="Rust">
  <img src="https://img.shields.io/badge/boot-C++20-blue" alt="C++20">
  <img src="https://img.shields.io/badge/shell-Rust-orange" alt="Shell">
  <img src="https://img.shields.io/badge/compiler-C99-yellow" alt="Compiler">
  <img src="https://img.shields.io/badge/license-GPL--3.0-red" alt="GPL-3.0">
</p>

Операционная система для RISC-V (OC2r / Milk-V Duo S). Монолитное ядро на Rust,
загрузчик на C++, userspace shell на Rust, собственный C-компилятор.

## Компоненты

| Компонент | Язык | Описание | Статус |
|-----------|------|----------|--------|
| **OnyxBoot** | C++20 | Загрузчик: FDT, VirtIO, SDHCI, FAT32/ext4, GPT, boot menu | v0.7 |
| **OnyxKernel** | Rust | Монолитное ядро: MM (Sv39), SMP, VFS, TCP/IP, OnyxFS v2 (chmod/symlink/truncate-to-N), FAT32 read+write, 85 syscalls | v0.5 |
| **OnyxShell** | Rust | Шелл: 20 команд, табы, история, пайпы/редиректы, globbing, background jobs | v0.3 |
| **OnyxCompiller** | C99 | C → RV64 → `.onx`, автолинковка libonyxc, function-like макросы (#/##/____VA_ARGS____), FP-кодген, onx-run эмулятор | v0.6 |
| **libonyxc** | C99 | libc: stdio/stdlib/string/ctype/time + termios (raw mode), math (soft-float), assert, buffered I/O, printf %f | v0.6 |
| **OnyxApps** | C99 | Userland-приложения: vim, oed, osysmon (монорепо, CI собирает .onx) | v0.1 |
| **OnyxOS** | — | Документация, скрипты, интеграция | meta |

## Быстрый старт

```bash
# 1. Установить зависимости
sudo pacman -S cmake base-devel curl libarchive    # Arch
sudo apt install cmake build-essential libcurl4-openssl-dev libarchive-dev  # Deb

# 2. Скачать все Onyx-репозитории
./.vent/vent -j 4 Onyx.vent

# 3. Собрать всё
bash scripts/build-all.sh

# 4. Запустить в QEMU
bash scripts/run-qemu.sh
```

## Структура репозитория

```
OnyxOS/
├── Onyx.vent              # Dependency-файл для Vent
├── .vent/
│   ├── vent               # Vent binary
│   └── repos/             # Стянутые репозитории (после запуска Vent)
├── scripts/
│   ├── bootstrap.sh       # Установка Vent + клонирование репозиториев
│   ├── build-all.sh       # Сборка всех компонентов
│   └── run-qemu.sh        # Запуск QEMU (OnyxBoot + OnyxKernel)
├── docs/                  # Документация
│   ├── architecture/      # Архитектура: boot, memory, privilege modes
│   ├── dev/               # Разработка: building, contributing, roadmap
│   ├── hardware/          # Железо: UART, PLIC, CLINT, VirtIO
│   ├── internals/         # Внутренности: coding style, error handling
│   ├── kernel/            # Ядро: процессы, MM, прерывания
│   ├── shell/             # Шелл: команды, internals
│   └── lore/              # Фольклор
├── Makefile               # Skeleton (WIP)
└── README.md
```

## Сборка компонентов по отдельности

### OnyxKernel

```bash
cd .vent/repos/OnyxKernel
cargo kbuild    # alias: cargo build --release -p onyx_kernel --target riscv64gc-unknown-none-elf
```

### OnyxBoot

```bash
cd .vent/repos/OnyxBoot
make -j$(nproc)
```

### OnyxShell

```bash
cd .vent/repos/OnyxShell
bash build.sh
```

### OnyxCompiller

```bash
cd .vent/repos/OnyxCompiller
make host          # нативный бинар для Linux
make onyx          # кросс-компиляция в .onx
```

## Как сделать свою прошивку (OC2R)

> **OC2R** — мод для Minecraft (NeoForge), добавляющий виртуальные компьютеры с
> 64-битной RISC-V эмуляцией: <https://github.com/TumRedSun/OC2R>.
> OnyxOS можно загрузить прямо внутри игры.

Мод OC2R умеет скачивать прошивку компьютера из GitHub-репозитория по манифесту
`oc2r-firmware.json` в корне репозитория. Мод читает его, берёт ссылку `image`
и заливает flash-образ в виртуальную машину.

### Формат манифеста `oc2r-firmware.json`

```json
{
  "name": "OnyxOS",
  "version": "0.3.0",
  "layout": "minux",
  "image": "https://github.com/DivByDiamond/OnyxOS/releases/latest/download/onyx-flash.img"
}
```

| Поле | Значение | Описание |
|------|----------|----------|
| `name` | `OnyxOS` | Название прошивки |
| `version` | `0.3.0` | Версия из `Cargo.toml` воркспейса OnyxKernel |
| `layout` | `minux` | Схема раскладки flash (см. ниже) |
| `image` | прямая ссылка на `onyx-flash.img` | Цельный flash-образ, прикреплённый к GitHub Release |

Раскладка `minux` (flash ровно 15 МБ):

| Offset | Размер | Содержимое |
|--------|--------|------------|
| `0x000000` (0) | — | `fw_jump.bin` — OpenSBI (файл из мода OC2R: `src/main/scripts/firmware_files/fw_jump.bin`) |
| `0x200000` (2 МБ) | — | Образ ядра OnyxKernel (ELF, собранный cargo) |
| до 15 МБ | — | Нули |

### Сборка образа вручную

```bash
# 1. Разрешить зависимости — vent клонирует репозитории в .vent/repos/
make deps

# 2. Собрать bootloader и ядро
make -C .vent/repos/OnyxBoot
cargo build --release -p onyx_kernel --target riscv64gc-unknown-none-elf \
  --manifest-path .vent/repos/OnyxKernel/Cargo.toml

# 3. Положить настоящий OpenSBI как firmware/fw_jump.bin
#    (берётся из мода OC2R: src/main/scripts/firmware_files/fw_jump.bin)

# 4. Склеить образ ровно 15 МБ по схеме minux
dd if=/dev/zero of=onyx-flash.img bs=1M count=15
dd if=firmware/fw_jump.bin of=onyx-flash.img conv=notrunc
dd if=.vent/repos/OnyxKernel/target/riscv64gc-unknown-none-elf/release/onyx-kernel \
   of=onyx-flash.img bs=1M seek=2 conv=notrunc
```

### Автоматическая сборка через GitHub Actions

`.github/workflows/release.yml` при пуше git-тега (например `v0.3.0`):
1. Собирает все компоненты (`make deps` → vent клонирует OnyxKernel/OnyxBoot/OnyxShell/OnyxCompiller);
2. Склеивает `onyx-flash.img` (15 МБ, layout `minux`);
3. Создаёт GitHub Release и прикрепляет образ.

Ссылка `image` в манифесте указывает на `/releases/latest/download/onyx-flash.img` —
GitHub сам отдаёт ассет последнего релиза по тегу.

Для рабочего релиза нужно:
1. Положить настоящий `fw_jump.bin` (OpenSBI) в `firmware/fw_jump.bin` репозитория
   либо задать переменную репозитория `OC2R_FW_JUMP_URL` (если файла нет, CI
   соберёт образ с заглушкой — он не загрузится);
2. Создать тег `v0.3.0` и запушить — CI соберёт и зальёт образ.

На каждый пуш в `main` workflow дополнительно публикует превью-образ как
artifact (без создания Release).

## Userspace-софт (v0.6 → OnyxApps)

Опциональные userspace-программы переехали в монорепозиторий
[OnyxApps](https://github.com/DivByDiamond/OnyxApps) (vim, oed, osysmon).
Полная документация каждого приложения — в его собственном `README.md`
внутри `apps/<name>/`. Сборка: `make` в корне OnyxApps, артефакты
`build/*.onx` также публикуются CI.

Ранее `software/` содержал программы, собираемые одним вызовом
`onyxcc -o X.onx X.c`:

| Программа | Стиль | Что демонстрирует |
|-----------|-------|-------------------|
| **oed** | nano/vim | Полноэкранный редактор: raw mode (termios), ANSI-курсор, стрелки/Home/End/PgUp/PgDn, редактирование, Ctrl+S/Q/G, статус-бар, буфер 2048 строк |
| **osysmon** | btop/htop | Монитор: box-drawing, цветные load-бары, uname/uptime/PID/CWD, дисковые/сетевые панели, обновление по интервалу |

Обе работают поверх нового ANSI/VT100-терминала ядра (fb_term/ansi.rs):
цвета SGR 30-37/90-97, позиционирование CSI H, erase J/K, scroll-regions,
per-process termios через TCGETS/TCSETS, TIOCGWINSZ возвращает реальную
сетку фреймбуфера.

## План развития

Дедлайн v0.6 (15 сентября 2026) закрыт: non-blocking I/O (poll/FIONREAD/O_NONBLOCK/
VMIN-VTIME), сигналы (SIGWINCH/SIGCHLD/SIGTSTP/SIGCONT), TUI-библиотека
(mouse syscall, double buffering, event loop, widget rendering) и PTY +
мультиплексоры — всё сделано 2026-09-01.

| Область | Что делаем |
|---------|-----------|
| **OC2R-стенд** | Проверка загрузки через OnyxOSFirmware, snapshot на несъёмном диске (нужно реальное железо/OC2R) |
| **Java runtime** | Class loader, байткод-интерпретатор, подмножество JDK, GC — для совместимости с Java-модами OC2R |
| **GUI (v0.7+)** | Window manager, compositor, mouse cursor/click, продвинутый widget toolkit |
| **Безопасность userland** | umask/права OnyxFS, $5$-хэш совместимость с crypt(3), passwd с пустым текущим паролем |
| **Платформа/время** | RTC под sedna, точность nanosleep, SBI-звонки (get_spec_version, reboot/shutdown) |
| **Ввод/QoL** | Ctrl+D = EOF, backspace/стрелки в raw-режиме, история+tab-completion в osh, UART IRQ-driven rx |
| **Тесты** | journal crash-recovery с реальным блочным I/O (пока ручной QEMU-цикл) |

Подробнее — [docs/dev/roadmap.md](docs/dev/roadmap.md) и [todo.md](https://github.com/DivByDiamond/OnyxKernel/blob/main/todo.md).

## Лицензия

GPL-3.0-or-later