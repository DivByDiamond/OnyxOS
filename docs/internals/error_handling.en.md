# Error Handling

No std: no Result out of the box.

- Allocation errors → return Option
- Device errors → log and return error code
- Fatal errors → panic with description

## Rule

- Can recover → Option
- Cannot → panic
