# Slip Shell Internals

## Parsing

- Character-by-character reads from UART
- 128-byte buffer
- Split by spaces
- First word is the command, rest are arguments

## Adding a Command

1. Add `fn cmd_xxx()` in `slip.rs`
2. Add match arm in `exec_cmd()`
3. Add to `cmd_help()`
