# Вклад в проект

## Стиль кода

- `cargo fmt` перед коммитом
- no unsafe в публичных API (кроме MMIO)
- Комментарии к сложным моментам

## Правила

- Никаких unwrap() — только match/if let
- Паника только в безвыходных ситуациях
- Все MMIO адреса — константы
- Документация к каждому модулю

## Обязательно перед пушем / PR

Каждый PR проходит CI, включая **QEMU boot smoke test** — полную загрузку
`OnyxBoot → ядро → OnyxFS rootfs → init → login` в headless QEMU.
Чтобы не гонять красные прогоны, проверяй локально перед пушем:

```bash
# 1. Собрать все компоненты (bootloader, kernel, userspace)
bash scripts/build-all.sh

# 2. Собрать образ диска с rootfs
bash scripts/mk-onyxfs-disk.sh

# 3. Прогнать smoke-тест (headless, ~60 сек)
bash scripts/qemu-smoke.sh
```

Тест проверяет по serial-логу:
- баннер `OnyxKernel v...`
- монтирование rootfs (`root mounted on dev ...`)
- вход в userspace (`login:` или `osh$`)

Если изменил что-то в загрузке, VFS, OnyxFS или userspace — smoke-тест
обязателен. Для изменений ядра без сборки диска можно быстро проверить
баннер ядра: `QEMU_EXTRA=... bash scripts/run-qemu.sh dev`.

Зависимости для smoke-теста: `qemu-system-riscv64 dosfstools mtools parted`
(плюс обычный тулчейн из building.md).
