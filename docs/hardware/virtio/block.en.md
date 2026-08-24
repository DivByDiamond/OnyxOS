# VirtIO Block (v2 MMIO)

Device ID: 2. PLIC IRQ — allocated dynamically, read from FDT.

## Queue

- 1 queue (requestq), size via `QueueNumMax`
- v2 MMIO: vring addresses written to `QueueDescLow/High`,
  `QueueDriverLow/High`, `QueueDeviceLow/High`
- Ready: `QueueReady = 1`

## Request (3 descriptors)

1. **Header** — `struct { blktype: u32, ioprio: u32, sector: u64 }` (16 bytes)
2. **Data** — data buffer (in = device writes, out = device reads)
3. **Status** — 1 byte (0=OK, 1=error, 2=unsupported)

## Request Types

| blktype | Operation |
|---|---|
| 0 | IN (read from disk) |
| 1 | OUT (write to disk) |
| 8 | FLUSH |

## Sector Size

One sector = 512 bytes. All offsets in sectors.

## Initialization (v2)

1. Reset → ACK → DRIVER
2. Read `HostFeatures0/1`, write `GuestFeatures0/1`
   with `VIRTIO_F_VERSION_1` (bit 32)
3. `FEATURES_OK` → verify confirmation
4. Select queue: `QueueSel = 0`
5. Get size: read `QueueNumMax`
6. Set size: `QueueNum = N`
7. Allocate vring (phys contiguous):
   - write addresses to `QueueDescLow/High`, `QueueDriverLow/High`,
     `QueueDeviceLow/High`
   - `QueueReady = 1`
8. `DRIVER_OK` → device live

## Reading a Sector

```
header.blktype = 0 (IN)
header.sector = offset / 512
header.ioprio = 0

// 3 descriptors in vring
desc[0] = { addr: &header, len: 16, flags: NEXT }
desc[1] = { addr: buffer,  len: 512, flags: NEXT | WRITE }
desc[2] = { addr: &status, len: 1,   flags: WRITE }

avail.ring[idx] = 0  // head descriptor index
avail.idx++
QueueNotify = 0      // kick device
```
