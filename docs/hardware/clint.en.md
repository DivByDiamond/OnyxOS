# CLINT (Core-Local Interruptor)

- **Address**: 0x02000000

## Registers

| Offset | Register | Description |
|---|---|---|
| 0x4000 | mtimecmp | Timer compare (hart 0) |
| 0xBFF8 | mtime | Timer counter |

## Usage

- Read mtime
- Write mtimecmp = mtime + delay
- On match — timer interrupt fires
- To restart: write new mtimecmp
