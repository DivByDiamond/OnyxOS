# Карта памяти

> Адреса UART, VirtIO и других MMIO-устройств (кроме CLINT, PLIC, SYSCON)
> выделяются динамически через FDT. Нижеприведённые значения — для QEMU
> virt и тестового стенда; на OC2r адреса могут отличаться.

## Фиксированные устройства (MMIO)

| Адрес | Устройство | Примечание |
|---|---|---|
| 0x01000000 | SYSCON | Системный контроллер (poweroff, reboot) |
| 0x02000000 | CLINT | Таймер (mtime/mtimecmp) |
| 0x0C000000 | PLIC | Контроллер прерываний |

## Динамические устройства (MMIO, из FDT)

Устройства добавляются через `addDevice()` в порядке регистрации на шине.
Стартовый адрес: 0x10000000, шаг 0x1000. Искать по `compatible`:

| compatible | Устройство | Тип |
|---|---|---|
| `"ns16550a"` | UART (NS16550A) | последовательный порт |
| `"virtio,mmio"` | VirtIO MMIO | block/network/console/9p |

Для UART и каждого VirtIO-устройства PLIC interrupt ID также назначается
динамически — брать из `interrupts` свойства FDT-ноды.

## RAM

| Адрес | Что | Размер |
|---|---|---|
| 0x80000000 | SlipperBoot (текст + данные) | ≤ 32KB |
| 0x80008000 | SlipperBoot стек | 4KB |
| 0x80100000 | SlipperBoot bss/data (опциональный резерв) | — |
| 0x80200000 | **SlipperOS kernel** (из ELF) | переменный |
| 0x80200000 + kernel_size | Heap (bump, page allocator) | до top |
| memory_top | конец RAM (из FDT) | — |

> RAM на OC2r: память собирается из карт памяти (Items.java),
> `maxAllocatedMemory = 512MB`. Реальный объём зависит от количества
> установленных карт (2/4/8/16MB каждая).

## SlipperBoot layout (внутри 0x80000000)

```
.text.boot   → _start() naked (inline asm)
.text        → boot_main, uart, virtio, elf, fdt
.rodata      → строки, константы
.data        → глобалы (мало, только fifo)
.bss         → буферы (kernel_buf[2MB])
_stack       → 4KB в конце
```
