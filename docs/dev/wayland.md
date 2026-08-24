# Wayland + GPU — вывод на экран

## Цель

Запустить Wayland compositor на SlipperOS, в перспективе — Hyprland.

## Слои

```
[Hardware] VirtIO-GPU (QEMU)
    ↓
[Kernel] virtio-gpu драйвер
    → dumb buffer allocation
    → mmap → framebuffer
    → plane / cursor
    ↓
[Compositor] Wayland protocol
    → wl_display, wl_surface, wl_buffer
    ↓
[Client] приложение (slipper-app, shell, etc)
```

## VirtIO-GPU в ядре

VirtIO-GPU (device ID 0x1F) — стандартное виртуальное устройство QEMU.

### MMIO

Та же схема, что и VirtIO block: feature negotiation, vrings, queue.

### Ctrl Queue

Команды через vring:
- `VIRTIO_GPU_CMD_GET_DISPLAY_INFO` — разрешение, EDID
- `VIRTIO_GPU_CMD_RESOURCE_CREATE_2D` — создать dumb buffer
- `VIRTIO_GPU_CMD_RESOURCE_ATTACH_BACKING` — прикрепить страницы
- `VIRTIO_GPU_CMD_SET_SCANOUT` — какой буфер на экран
- `VIRTIO_GPU_CMD_RESOURCE_FLUSH` — обновить экран

### Модель

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
    addr: usize,      // физический адрес
    backing_pages: Vec<usize>,
}
```

### Поток

```
kernel:
  virtio_gpu_init() → create_2d(1024, 768) → set_scanout(0, res)

compositor (userspace):
  mmap(res.addr, res.size) → пишем пиксели → flush
```

## Wayland compositor

Минимальный compositor для SlipperOS:

```rust
// wl_display — общий дисплей
// wl_surface — поверхность (слой)
// wl_buffer — буфер (ссылкa на GPU resource)
// wl_compositor — create_surface
// wl_shell — привязать surface к окну

fn wl_display_loop() {
    // socket read → dispatch → render
    // flush gpu → next frame
}
```

### Очередность

1. **Драйвер VirtIO-GPU в ядре** — просто показать картинку (framebuffer)
2. **mmap для userspace** — чтобы программы могли рисовать
3. **Простой compositor** — переключение surface, keyboard input
4. **Порт wlroots** — если нужен Hyprland

## Hyprland

Hyprland требует:
- wlroots (libudev, epoll, libinput, DRM, ...)
- C++17
- OpenGL ES (VirGL на QEMU)

Реалистично: сначала свой compositor. wlroots портировать после стабилизации.

## Когда (см. roadmap.md)

1. v0.4 — VirtIO block в ядре
2. v0.6 — VirtIO-GPU (dumb buffer + mmap)
3. v0.7 — минимальный compositor
4. v0.8 — стабильное ядро + ввод
5. v1.0 — framebuffer + мышь/клавиатура
6. v1.x — wlroots / weston / hyprland (отдельная ветка C++)
