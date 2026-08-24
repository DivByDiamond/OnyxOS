# Задачи (Tasks)

## Task

```rust
struct Task {
    id: usize,
    state: TaskState,  // Ready | Running | Blocked
    context: Context,  // сохранённые регистры
    stack: [u8; 4096],
}
```

## Жизненный цикл

- Создаётся в состоянии Ready
- Шедулер выбирает → Running
- Добровольно уступает → Ready
- Блокируется → Blocked

## MAX_TASKS = 16

Статический массив на 16 задач.
