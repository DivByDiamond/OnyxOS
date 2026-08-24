# Panic Policy

## When to panic

- Division by zero
- Array out of bounds
- Fatal device error
- User requested panic (`panic` command)

## When NOT to panic

- VirtIO disk not found → just don't use it
- UART not responding → retry
- Out of pages → return None

Panic — always red text, always a clear reason. No silent crashes.
