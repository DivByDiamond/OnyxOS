# Bump Allocator

The simplest allocator: pointer moves forward, no deallocation.

- Heap size: 1MB
- Used as `#[global_allocator]`.
- Suitable for the initial stage, before the page allocator is ready.

When the page allocator takes over, bump remains for small kernel allocations.
