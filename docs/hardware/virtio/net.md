# VirtIO Net (future)

Device ID: 1

## Queues

- RX queue (receive)
- TX queue (transmit)
- (optional) Control queue, Event queue

## Descriptors

Same vring format as block device. Headers are `virtio_net_hdr`:

```rust
struct VirtioNetHdr {
    flags: u8,
    gso_type: u8,
    hdr_len: u16,
    gso_size: u16,
    csum_start: u16,
    csum_offset: u16,
    num_buffers: u16,
}
```

TODO: реализация после стабилизации остальных компонентов.
