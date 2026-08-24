# PLIC (Platform-Level Interrupt Controller)

- **Адрес**: 0x0C000000
- Регистры 32-bit, MMIO

## Карта регистров

| Смещение | Описание |
|---|---|
| 0x000000 | Приоритеты (по 4 байта на источник) |
| 0x001000 | Pending bits |
| 0x002000 | Enable bits (per hart) |
| 0x200000 | Threshold (per hart) |
| 0x200004 | Claim/Complete (per hart) |

## Прерывания QEMU virt

Из `qemu/hw/riscv/virt.c`:

| Источник | ID | Устройство |
|---|---|---|
| 1 | 1 | VIRTIO 0 |
| 2 | 2 | VIRTIO 1 |
| ... | ... | ... |
| 8 | 8 | VIRTIO 7 |
| 10 | 10 | UART0 |
| 32-35 | 32-35 | PCI-E |

**Важно**: UART = ID 10, не 1. VIRTIO = 1-8.

## Порядок работы

1. **Priority** — `base + 4*id` (0-7, 7 = highest)
2. **Enable** — `enable |= 1 << id`
3. **Threshold** — `threshold = 0` (все пропускаем)
4. **Claim** — читаем `claim_reg`, получаем ID источника
5. **Обработка** — выполняем handler
6. **Complete** — пишем ID обратно в `claim_reg`

```
claim = plic_claim()     // читаем 0x200004
if claim != 0:
    handle_irq(claim)
    plic_complete(claim)  // пишем в 0x200004
```
