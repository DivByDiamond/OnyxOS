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


## Tablet widget integration (16 MiB)

`OnyxTabletSmoke.java` uses Sedna's real RISC-V machine with exactly 16 MiB
RAM, one 256x160 RGB565 display and a combined absolute pointer/keyboard.
Compile it alongside `OnyxSednaSmoke.java` using the Sedna 5.4.0 dependency
classpath, then run:

```sh
javac -cp "$SEDNA_CLASSPATH" -d /tmp/onyx-tablet-qa scripts/qa/OnyxSednaSmoke.java scripts/qa/OnyxTabletSmoke.java
java -Xmx768m -cp "/tmp/onyx-tablet-qa:$SEDNA_CLASSPATH" OnyxTabletSmoke fw_jump.bin onyx-kernel.bin onyxfs.img
```

Use a fresh stock image (initial root account has no password). The check boots
to the shell, runs `otablet --device`, verifies real guest widget pixels and a
completed absolute pointer click, checks that releasing outside cancels an
action, watches for console overwrite, and exits through the VirtIO Q key back
to an executing shell. The short click overlaps the initial redraw and checks that queued button edges
survive between the application's pointer polls. A pass ends with
`ONYX_TABLET_SMOKE_PASS RAM=16 display=256x160 pointer=absolute counter=1 short-click=40ms exit=q`.

For process-death cleanup, compile `scripts/qa/tablet-kill.c` with the selected
OnyxCC (`--ring1 -I "$ONYX_REPOS/OnyxCompiller/include"`), add it only to a
separate QA manifest as `/bin/tablet-kill`, rebuild/pad that QA image to 16 MiB,
and append `kill-test` to the smoke command. The helper spawns the actual widget
application, verifies that another process cannot claim its console, sends
SIGKILL, waits for death, and verifies that the console can be claimed again.
The helper is excluded from the stock image.
