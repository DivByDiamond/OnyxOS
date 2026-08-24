# PLIC (Platform-Level Interrupt Controller)

- **Address**: 0x0C000000
- 32-bit registers, MMIO

## Register Map

| Offset | Description |
|---|---|
| 0x000000 | Priorities (4 bytes per source) |
| 0x001000 | Pending bits |
| 0x002000 | Enable bits (per hart) |
| 0x200000 | Threshold (per hart) |
| 0x200004 | Claim/Complete (per hart) |

## QEMU virt Interrupts

From `qemu/hw/riscv/virt.c`:

| Source | ID | Device |
|---|---|---|
| 1 | 1 | VIRTIO 0 |
| 2 | 2 | VIRTIO 1 |
| ... | ... | ... |
| 8 | 8 | VIRTIO 7 |
| 10 | 10 | UART0 |
| 32-35 | 32-35 | PCI-E |

**Important**: UART = ID 10, not 1. VIRTIO = 1-8.

## Operation Order

1. **Priority** — `base + 4*id` (0-7, 7 = highest)
2. **Enable** — `enable |= 1 << id`
3. **Threshold** — `threshold = 0` (allow all)
4. **Claim** — read `claim_reg`, get source ID
5. **Handle** — execute handler
6. **Complete** — write ID back to `claim_reg`

```
claim = plic_claim()     // read 0x200004
if claim != 0:
    handle_irq(claim)
    plic_complete(claim)  // write to 0x200004
```
