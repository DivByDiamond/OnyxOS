# Wayland + GPU — Display Output

## Goal

Run a Wayland compositor on SlipperOS, eventually Hyprland.

## Layers

```
[Hardware] VirtIO-GPU (QEMU)
    ↓
[Kernel] virtio-gpu driver
    → dumb buffer allocation
    → mmap → framebuffer
    → plane / cursor
    ↓
[Compositor] Wayland protocol
    → wl_display, wl_surface, wl_buffer
    ↓
[Client] application (slipper-app, shell, etc)
```

## VirtIO-GPU in kernel

VirtIO-GPU (device ID 0x1F) is a standard QEMU virtual device.

### MMIO

Same scheme as VirtIO block: feature negotiation, vrings, queue.

### Ctrl Queue

Commands via vring:
- `VIRTIO_GPU_CMD_GET_DISPLAY_INFO` — resolution, EDID
- `VIRTIO_GPU_CMD_RESOURCE_CREATE_2D` — create dumb buffer
- `VIRTIO_GPU_CMD_RESOURCE_ATTACH_BACKING` — attach pages
- `VIRTIO_GPU_CMD_SET_SCANOUT` — which buffer to display
- `VIRTIO_GPU_CMD_RESOURCE_FLUSH` — refresh display

### Model

```rust
struct VirtioGpu {
    queue: CtrlQueue,
    caps: Vec<DisplayMode>,
    scanout: Option<Resource>,
}

struct Resource {
    width: u32,
    height: u32,
    format: u32,      // VIRTIO_GPU_FORMAT_B8G8R8A8_UNORM
    addr: usize,      // physical address
    backing_pages: Vec<usize>,
}
```

### Flow

```
kernel:
  virtio_gpu_init() → create_2d(1024, 768) → set_scanout(0, res)

compositor (userspace):
  mmap(res.addr, res.size) → write pixels → flush
```

## Wayland compositor

Minimal compositor for SlipperOS:

```rust
// wl_display — shared display
// wl_surface — surface (layer)
// wl_buffer — buffer (reference to GPU resource)
// wl_compositor — create_surface
// wl_shell — bind surface to window

fn wl_display_loop() {
    // socket read → dispatch → render
    // flush gpu → next frame
}
```

### Order

1. **VirtIO-GPU driver in kernel** — just show an image (framebuffer)
2. **mmap for userspace** — so programs can draw
3. **Simple compositor** — surface switching, keyboard input
4. **Port wlroots** — if Hyprland is needed

## Hyprland

Hyprland requires:
- wlroots (libudev, epoll, libinput, DRM, ...)
- C++17
- OpenGL ES (VirGL on QEMU)

Realistic: first our own compositor. Port wlroots after stabilization.

## When (see roadmap.md)

1. v0.4 — VirtIO block in kernel
2. v0.6 — VirtIO-GPU (dumb buffer + mmap)
3. v0.7 — minimal compositor
4. v0.8 — stable kernel + input
5. v1.0 — framebuffer + mouse/keyboard
6. v1.x — wlroots / weston / hyprland (separate C++ branch)
