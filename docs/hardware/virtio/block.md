# VirtIO Block (v2 MMIO)

Device ID: 2. PLIC IRQ — выделяется динамически, читать из FDT.

## Очередь

- 1 очередь (requestq), размер через `QueueNumMax`
- v2 MMIO: адреса vring пишутся в `QueueDescLow/High`,
  `QueueDriverLow/High`, `QueueDeviceLow/High`
- Готовность: `QueueReady = 1`

## Запрос (3 дескриптора)

1. **Header** — `struct { blktype: u32, ioprio: u32, sector: u64 }` (16 байт)
2. **Data** — буфер данных (in = устройство пишет, out = устройство читает)
3. **Status** — 1 байт (0=OK, 1=error, 2=unsupported)

## Типы запросов

| blktype | Операция |
|---|---|
| 0 | IN (читаем с диска) |
| 1 | OUT (пишем на диск) |
| 8 | FLUSH |

## Размер сектора

Один сектор = 512 байт. Все смещения в секторах.

## Инициализация (v2)

1. Reset → ACK → DRIVER
2. Читаем `HostFeatures0/1`, пишем `GuestFeatures0/1`
   с `VIRTIO_F_VERSION_1` (bit 32)
3. `FEATURES_OK` → проверяем подтверждение
4. Выбираем очередь: `QueueSel = 0`
5. Узнаём размер: читаем `QueueNumMax`
6. Ставим размер: `QueueNum = N`
7. Аллоцируем vring (phys contiguous):
   - пишем адреса в `QueueDescLow/High`, `QueueDriverLow/High`,
     `QueueDeviceLow/High`
   - `QueueReady = 1`
8. `DRIVER_OK` → device live

## Чтение сектора

```
header.blktype = 0 (IN)
header.sector = offset / 512
header.ioprio = 0

// 3 дескриптора в vring
desc[0] = { addr: &header, len: 16, flags: NEXT }
desc[1] = { addr: buffer,  len: 512, flags: NEXT | WRITE }
desc[2] = { addr: &status, len: 1,   flags: WRITE }

avail.ring[idx] = 0  // head descriptor index
avail.idx++
QueueNotify = 0      // kick device
```
