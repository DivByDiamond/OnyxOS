# Page Frame Allocator

## Descriptor-based (из osblog)

Вместо free list используем массив дескрипторов с флагами:

```rust
enum PageBits {
    Empty = 0,
    Taken = 1 << 0,
    Last  = 1 << 1,
}

struct Page {
    flags: u8,
}
```

- Один `Page` на каждую физическую страницу (4KB)
- Дескрипторы хранятся в начале кучи
- alloc(n): ищем n последовательных Empty, ставим Taken, последней — Last
- free(ptr): идём от ptr пока не встретим Last, все сбрасываем

## Формулы

```
num_pages = HEAP_SIZE / PAGE_SIZE
idx = (ptr - ALLOC_START) / PAGE_SIZE
phys_addr = ALLOC_START + idx * PAGE_SIZE
```

## zalloc

alloc + zero (сброс через u64 указатели, 512 итераций на страницу).

## Free list (тоже ок)

Наш текущий PageAllocator использует односвязный free list.
Проще, но без учёта contiguous allocation.
