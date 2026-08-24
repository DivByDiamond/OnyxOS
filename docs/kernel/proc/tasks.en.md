# Tasks

## Task

```rust
struct Task {
    id: usize,
    state: TaskState,  // Ready | Running | Blocked
    context: Context,  // saved registers
    stack: [u8; 4096],
}
```

## Lifecycle

- Created in Ready state
- Scheduler picks → Running
- Voluntarily yields → Ready
- Blocked → Blocked

## MAX_TASKS = 16

Static array of 16 tasks.
