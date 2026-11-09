# Tablet framebuffer and local widgets

Run `otablet --device` in the guest console, then select the Minecraft tablet
screen. Switching the host view leaves the guest process running. Device mode
shows monotonic uptime and an actual local click counter, with a progress bar
showing the count modulo 101. It does not report remote energy or radio status.
Q, Escape, or the right pointer button exits and restores the console.

## Hardware contract

The tablet publishes a standard `simple-framebuffer` device-tree node: width
256, height 160, stride 512, format `r5g6b5`. Pixels are little-endian RGB565;
the MMIO address is selected by the host allocator. `/dev/fb0` supports seek/write
and ioctl 0x4600, returning five u32 fields: width, height, bpp, pitch, size.
Ioctl 0x46f0 claims the primary console for the calling process; 0x46f1 releases
it. Claims are exclusive, idempotent for the same process, and released on
process exit. UART output remains available while framebuffer console painting
is suspended. These claims arbitrate the console; they are not an access
security boundary for framebuffer memory.

VirtIO input supplies EV_ABS(3), ABS_X(0) 0..255, ABS_Y(1) 0..159, EV_KEY(1)
with buttons 0x110..0x112, and SYN_REPORT. Each axis preserves the other axis.
Keyboard key codes share the existing VirtIO keyboard path. Mouse syscall 86
copies `{u16 x, u16 y, u8 buttons, u8 padding}` in guest pixels. Each read
consumes the oldest unread button transition, with coordinates captured at that
transition, before returning the current state. Pure motion is coalesced. The
32-entry history prevents short clicks from disappearing during rendering;
overflow first reports a released pointer at (65535,65535) to cancel an
incomplete gesture before retained transitions are delivered.

The 240x112 widget canvas is centered at (8,24). The ADD CLICK button covers
framebuffer coordinates [16,120) x [90,106); press and release must both land
on that button. Device startup prints `OTABLET_READY 256x160`, each completed
local action prints `OTABLET_CLICK=N`, and cleanup prints `OTABLET_EXIT`.
