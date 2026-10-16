OnyxSednaSmoke executes the real RV64 kernel and userspace using Sedna 5.2.
Two real virtio keyboard devices reproduce the host input topology. The harness
starts an echo command with a real key event from the selected keyboard, then
finishes via UART and checks its output. It boots with 64 MiB, logs in as root (empty first-boot password), exercises
shell redirection (including an in-process builtin), file creation/copy/rename/
delete, then writes distinct red/green/blue patterns to three independent
MMIO displays. It validates ioctl rejection, framebuffer read/write EOF bounds,
geometry and mmap through /bin/fb-draw. The rootfs growth assertion catches
incorrect VirtIO capacity units. The first display also carries the console.

Build images with `bash scripts/build-oc2r.sh`. Set SEDNA_CLASSPATH to Sedna
and its runtime dependencies, then:

```sh
javac -cp "$SEDNA_CLASSPATH" -d /tmp/onyx-qa scripts/qa/OnyxSednaSmoke.java
java -cp "/tmp/onyx-qa:$SEDNA_CLASSPATH" OnyxSednaSmoke \
  /path/to/fw_jump.bin .build/oc2r/onyx-kernel.bin .build/oc2r/onyxfs.img \
  64 /tmp/onyx-saved.img
java -cp "/tmp/onyx-qa:$SEDNA_CLASSPATH" OnyxSednaSmoke \
  /path/to/fw_jump.bin .build/oc2r/onyx-kernel.bin /tmp/onyx-saved.img \
  64 /tmp/onyx-saved-again.img reload
```

The second run checks that the marker persists across a fresh VM boot.
64 MiB is a verified configuration, not a claimed minimum. This harness does
not test Minecraft networking/rendering, audio, multiple simultaneously active keyboards or network
hardware; those require separate host integration checks. Applications already
built in sibling OnyxApps/build are included; absent optional apps are omitted.

The current kernel selects one primary virtio-input device. Additional keyboards
return Busy before resetting hardware or allocating queues; they do not replace
the primary device. Multiple displays are independent, but simultaneous input
from every monitor keyboard is not implemented. UART input remains available.

The original OC2R crash after loading /bin/init was reproduced with actual
Sedna keyboard devices. Failed feature negotiation left an input MMIO base
published while its used-ring pointer was null; the timer then read NULL+2.
The driver now accepts VIRTIO_F_VERSION_1, retains FEATURES_OK, and publishes
readiness only after successful setup. Failed setup resets the device and
releases partial queue allocations. Console reads also drain input while waiting.

A separate earlier FDT walker defect revisited the final child while closing
ancestor nodes. Duplicate discovery initialized one VirtIO block device twice
and stalled root mounting. That issue is covered by the native walker regression;
it is distinct from the reproduced keyboard NULL+2 fault. Framebuffer discovery
also deduplicates legacy /chosen and /soc aliases by physical MMIO address.

The display fixture uses the packed physical addresses observed after a real
world reload: 0x30190400, 0x3020d600 and 0x3028a800. Keyboard MMIO devices occupy
0x3020d400 and 0x3028a600 between the displays. The test checks first/last RGB565
writes on every surface, final corner colors on non-console surfaces, and both
keyboard magic/status registers. This catches physical-page rounding that would
otherwise shift an image into a preceding surface, keyboard or unmapped gap.
Device mmap preserves the physical sub-page offset in its returned user pointer
and reserves the full rounded extent; callers unmap the aligned base and include
the prefix in the length, as /bin/fb-draw demonstrates.
