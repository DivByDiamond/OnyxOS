# VirtIO — MMIO Interface (v2, Modern)

VirtIO is a standard virtual device interface. Sedna/OC2r
implements **only v2 (modern) MMIO transport**:
`VIRTIO_MMIO_VERSION = 0x2`, requires flag `VIRTIO_F_VERSION_1`
during feature negotiation.

> Legacy (v1) transport with `QueuePfn` register is not supported.

## MMIO Addresses

Addresses are allocated dynamically via FDT, starting from 0x10000000
with a step of 0x1000. Order depends on machine configuration.
See `compatible = "virtio,mmio"` in device tree.

## Magic Number

`0x74726976` = "triv" (little-endian "virt").

## Device IDs

| ID | Device | In Sedna? |
|---|---|---|
| 0 | none (not connected) | — |
| 1 | Network | yes |
| 2 | Block | yes |
| 3 | Console | yes |
| 4 | Entropy (RNG) | no |
| 9 | 9P (filesystem) | yes |
| 16 | GPU (VirtIO-GPU) | **no** in Sedna |
| 18 | Sound | no |

**Note**: GPU (ID 16) is absent in Sedna. Display output is via
`SimpleFramebufferDevice` (not VirtIO), see `wayland.md`.

## MMIO Registers (v2, Modern)

| Offset | Register | Description |
|---|---|---|
| 0x000 | MagicValue | 0x74726976 |
| 0x004 | Version | 2 (modern) |
| 0x008 | DeviceID | device type |
| 0x00C | VendorID | 0x554D (Quz) |
| 0x010 | HostFeatures0 | Device features [31:0] |
| 0x014 | HostFeatures1 | Device features [63:32] |
| 0x020 | GuestFeatures0 | Driver features [31:0] |
| 0x024 | GuestFeatures1 | Driver features [63:32] |
| 0x030 | QueueSel | Queue select (0..N-1) |
| 0x034 | QueueNumMax | Max queue size |
| 0x038 | QueueNum | Set queue size |
| 0x044 | QueueReady | 1 = queue ready |
| 0x050 | QueueNotify | Kick device |
| 0x060 | InterruptStatus | Interrupt flags |
| 0x064 | InterruptAck | Clear flags |
| 0x070 | Status | Device status |
| 0x080 | QueueDescLow | phys addr desc table [31:0] |
| 0x084 | QueueDescHigh | [63:32] |
| 0x090 | QueueDriverLow | phys addr avail ring [31:0] |
| 0x094 | QueueDriverHigh | [63:32] |
| 0x0A0 | QueueDeviceLow | phys addr used ring [31:0] |
| 0x0A4 | QueueDeviceHigh | [63:32] |
| 0x100 | Config | Device-specific |

## Initialization

1. **Reset** — `Status = 0`
2. **ACK** — `Status |= 1`
3. **DRIVER** — `Status |= 2`
4. **Features** — read `HostFeatures0/1`, write `GuestFeatures0/1`
   **must** include `VIRTIO_F_VERSION_1` (bit 32 = `1 << 0` in GuestFeatures1)
5. **FEATURES_OK** — `Status |= 8`, read `Status`: bit 7 must be 1
6. **Queue setup** — `QueueSel = 0` → `QueueNum = N` → write physical
   addresses to `QueueDescLow/High`, `QueueDriverLow/High`, `QueueDeviceLow/High`
   → `QueueReady = 1`
7. **DRIVER_OK** — `Status |= 4` → device live

## VirtQueue (vring)

vring format is unchanged: Descriptor Table (16 bytes), Available Ring,
Used Ring. Addresses are passed as 64-bit via two 32-bit halves.

```
Descriptor Table (16 bytes × N)
  [addr (u64), len (u32), flags (u16), next (u16)]

Available Ring (driver → device)
  [flags (u16), idx (u16), ring[N] (u16)]

Used Ring (device → driver)
  [flags (u16), idx (u16), ring[N] { id (u32), len (u32) }]
```

- Descriptor: physical address, length, flags (NEXT=1, WRITE=2), next idx
- Available: driver places descriptor head index
- Used: device returns processed request index
