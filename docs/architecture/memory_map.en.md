# Memory Map

> UART, VirtIO, and other MMIO device addresses (except CLINT, PLIC, SYSCON)
> are allocated dynamically via FDT. The values below are for QEMU
> virt and the test bench; on OC2r addresses may differ.

## Fixed devices (MMIO)

| Address | Device | Notes |
|---|---|---|
| 0x01000000 | SYSCON | System controller (poweroff, reboot) |
| 0x02000000 | CLINT | Timer (mtime/mtimecmp) |
| 0x0C000000 | PLIC | Interrupt controller |

## Dynamic devices (MMIO, from FDT)

Devices are added via `addDevice()` in bus registration order.
Start address: 0x10000000, step 0x1000. Search by `compatible`:

| compatible | Device | Type |
|---|---|---|
| `"ns16550a"` | UART (NS16550A) | serial port |
| `"virtio,mmio"` | VirtIO MMIO | block/network/console/9p |

For UART and each VirtIO device, the PLIC interrupt ID is also assigned
dynamically — read from the FDT node's `interrupts` property.

## RAM

| Address | What | Size |
|---|---|---|
| 0x80000000 | SlipperBoot (text + data) | ≤ 32KB |
| 0x80008000 | SlipperBoot stack | 4KB |
| 0x80100000 | SlipperBoot bss/data (optional reserve) | — |
| 0x80200000 | **SlipperOS kernel** (from ELF) | variable |
| 0x80200000 + kernel_size | Heap (bump, page allocator) | up to top |
| memory_top | end of RAM (from FDT) | — |

> RAM on OC2r: memory is assembled from memory cards (Items.java),
> `maxAllocatedMemory = 512MB`. Actual size depends on the number
> of installed cards (2/4/8/16MB each).

## SlipperBoot layout (inside 0x80000000)

```
.text.boot   → _start() naked (inline asm)
.text        → boot_main, uart, virtio, elf, fdt
.rodata      → strings, constants
.data        → globals (few, only fifo)
.bss         → buffers (kernel_buf[2MB])
_stack       → 4KB at end
```
