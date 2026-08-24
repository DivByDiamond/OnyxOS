# NS16550A UART

- **Address**: dynamic, from FDT (`compatible = "ns16550a"`).
  On QEMU virt: 0x10000000. On OC2r — depends on device order.
- **MMIO**, 8-bit registers
- **PLIC interrupt ID**: dynamic, from FDT

## Registers

| Offset | DLAB=0 | DLAB=1 | Description |
|---|---|---|---|
| 0 | RBR/THR | DLL | Receive/Transmit / divisor (low) |
| 1 | IER | DLM | Interrupts / divisor (high) |
| 2 | FCR/IIR | — | FIFO control / identification |
| 3 | LCR | LCR | Line control |
| 4 | MCR | MCR | Modem control |
| 5 | LSR | LSR | Line status |
| 6 | MSR | MSR | Modem status |
| 7 | SCR | SCR | Scratch |

## Initialization

```rust
base[3] = 0x03;         // LCR: 8N1 (word length 8, no parity, 1 stop)
base[2] = 0x07;         // FCR: FIFO enable, clear
base[1] = 0x01;         // IER: enable RX interrupt
```

### Baud rate

```rust
// Divisor = clock_hz / (baud * 16)
// OC2r (UART16550AProvider): clock = 3_686_400
//   divisor = ceil(3_686_400 / (115200 * 16)) = 2
// QEMU: clock = 22_729_000 (for reference)
base[3] |= 1 << 7;      // DLAB = 1
base[0] = divisor & 0xFF;
base[1] = divisor >> 8;
base[3] &= !(1 << 7);   // DLAB = 0
```

## LSR (Line Status Register)

- Bit 0 (DR): data ready to read
- Bit 5 (THRE): transmit buffer empty
- Bit 6 (TEMT): transmitter empty

## Modes

1. **Polling** — poll LSR.DR in a loop
2. **Interrupt** — UART triggers PLIC IRQ (number from FDT), read in handler
