# VirtIO — MMIO Interface (v2, Modern)

VirtIO — стандартный интерфейс виртуальных устройств. Sedna/OC2r
реализует **только v2 (modern) MMIO-транспорт**:
`VIRTIO_MMIO_VERSION = 0x2`, требует флаг `VIRTIO_F_VERSION_1`
при негоциации фич.

> Legacy (v1) транспорт с регистром `QueuePfn` не поддерживается.

## MMIO адреса

Адреса выделяются динамически через FDT, начиная от 0x10000000
с шагом 0x1000. Порядок зависит от конфигурации машины.
См. `compatible = "virtio,mmio"` в device tree.

## Магическое число

`0x74726976` = "triv" (little-endian "virt").

## Device IDs

| ID | Устройство | В Sedna? |
|---|---|---|
| 0 | none (not connected) | — |
| 1 | Network | да |
| 2 | Block | да |
| 3 | Console | да |
| 4 | Entropy (RNG) | нет |
| 9 | 9P (filesystem) | да |
| 16 | GPU (VirtIO-GPU) | **нет** в Sedna |
| 18 | Sound | нет |

**Важно**: GPU (ID 16) в Sedna отсутствует. Вывод картинки — через
`SimpleFramebufferDevice` (не VirtIO), см. `wayland.md`.

## MMIO регистры (v2, Modern)

| Смещение | Регистр | Описание |
|---|---|---|
| 0x000 | MagicValue | 0x74726976 |
| 0x004 | Version | 2 (modern) |
| 0x008 | DeviceID | тип устройства |
| 0x00C | VendorID | 0x554D (умный) |
| 0x010 | HostFeatures0 | Фичи устройства [31:0] |
| 0x014 | HostFeatures1 | Фичи устройства [63:32] |
| 0x020 | GuestFeatures0 | Фичи драйвера [31:0] |
| 0x024 | GuestFeatures1 | Фичи драйвера [63:32] |
| 0x030 | QueueSel | Выбор очереди (0..N-1) |
| 0x034 | QueueNumMax | Макс. размер очереди |
| 0x038 | QueueNum | Установить размер |
| 0x044 | QueueReady | 1 = очередь готова |
| 0x050 | QueueNotify | Kick устройству |
| 0x060 | InterruptStatus | Флаги прерываний |
| 0x064 | InterruptAck | Сброс флагов |
| 0x070 | Status | Статус устройства |
| 0x080 | QueueDescLow | phys addr desc table [31:0] |
| 0x084 | QueueDescHigh | [63:32] |
| 0x090 | QueueDriverLow | phys addr avail ring [31:0] |
| 0x094 | QueueDriverHigh | [63:32] |
| 0x0A0 | QueueDeviceLow | phys addr used ring [31:0] |
| 0x0A4 | QueueDeviceHigh | [63:32] |
| 0x100 | Config | Device-specific |

## Инициализация

1. **Reset** — `Status = 0`
2. **ACK** — `Status |= 1`
3. **DRIVER** — `Status |= 2`
4. **Features** — читаем `HostFeatures0/1`, пишем `GuestFeatures0/1`
   **обязательно** включив `VIRTIO_F_VERSION_1` (bit 32 = `1 << 0` в GuestFeatures1)
5. **FEATURES_OK** — `Status |= 8`, читаем `Status`: бит 7 должен быть 1
6. **Queue setup** — `QueueSel = 0` → `QueueNum = N` → пишем физические
   адреса в `QueueDescLow/High`, `QueueDriverLow/High`, `QueueDeviceLow/High`
   → `QueueReady = 1`
7. **DRIVER_OK** — `Status |= 4` → device live

## VirtQueue (vring)

Формат vring не изменился: Descriptor Table (16 байт), Available Ring,
Used Ring. Адреса передаются 64-битными через две 32-битные половинки.

```
Descriptor Table (16 байт × N)
  [addr (u64), len (u32), flags (u16), next (u16)]

Available Ring (driver → device)
  [flags (u16), idx (u16), ring[N] (u16)]

Used Ring (device → driver)
  [flags (u16), idx (u16), ring[N] { id (u32), len (u32) }]
```

- Descriptor: физический адрес, длина, флаги (NEXT=1, WRITE=2), next idx
- Available: драйвер помещает индекс descriptor head
- Used: устройство возвращает индекс обработанного запроса
