# Page Frame Allocator

## Descriptor-based (from osblog)

Instead of a free list, use a descriptor array with flags:

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

- One `Page` per physical page (4KB)
- Descriptors stored at the start of the heap
- alloc(n): find n consecutive Empty pages, set Taken, set Last on the last one
- free(ptr): walk from ptr until Last, clear all

## Formulas

```
num_pages = HEAP_SIZE / PAGE_SIZE
idx = (ptr - ALLOC_START) / PAGE_SIZE
phys_addr = ALLOC_START + idx * PAGE_SIZE
```

## zalloc

alloc + zero (clear via u64 pointers, 512 iterations per page).

## Free list (also OK)

Our current PageAllocator uses a singly-linked free list.
Simpler, but no contiguous allocation support.
