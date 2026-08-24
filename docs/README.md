# Документация Onyx

Проект состоит из трёх компонентов. Документация описывает каждый из них.

## Структура docs/

```
docs/
├── architecture/    — общая архитектура, boot flow, memory map
├── dev/             — разработка: сборка, отладка, contributing
├── hardware/        — железо: UART, CLINT, PLIC, VirtIO
├── internals/       — внутренности: coding style, panic policy
├── kernel/          — ядро OnyxKernel: прерывания, mm, proc
├── lore/            — история, философия
├── shell/           — slip shell: команды, внутренности
└── README.md        — этот файл
```

## Что где описывается

| Раздел | Про что | Компонент |
|--------|---------|-----------|
| `architecture/` | Как всё работает вместе | Все |
| `dev/` | Разработка и план | Все |
| `hardware/` | Драйверы устройств | OnyxKernel |
| `internals/` | Соглашения и политики | OnyxKernel |
| `kernel/` | Внутренности ядра | OnyxKernel |
| `shell/` | Slip shell | OnyxKernel |
| `lore/` | Почему Onyx | Проект в целом |

## Репозитории

| Компонент | Репозиторий |
|-----------|------------|
| OnyxBoot | https://github.com/loki5512344/OnyxBoot |
| OnyxKernel | https://github.com/loki5512344/OnyxKernel |
| OnyxOS | (корень — этот репозиторий) |

## План

См. [dev/roadmap.md](dev/roadmap.md).
