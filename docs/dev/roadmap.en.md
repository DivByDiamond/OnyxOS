# Roadmap

## OnyxOS Ecosystem Roadmap

Cross-checked against the working tree on 2026-11-21. Implemented features
below do not imply full POSIX/C/C++ conformance; hardware verification is
listed separately.

### v0.4 - current release ✅

**OnyxBoot:**
- [x] UART, FDT, VirtIO v2 MMIO, SDHCI
- [x] FAT32 + ext4 read, GPT + MBR
- [x] Boot menu with timeout
- [x] ELF64 loader
- [x] QEMU integration tests

**OnyxKernel (core):**
- [x] UART, CLINT, PLIC, timer
- [x] PMM (bitmap+slab) + VMM (Sv39)
- [x] Heap allocator
- [x] Processes: dynamic list, spawn, exec, wait
- [x] Scheduler: SMP, per-CPU run queues, load balancing
- [x] 100 syscalls in the ABI registry (POSIX-flavoured)
- [x] OnyxFS v2 (journal, COW snapshots, indirect blocks)
- [x] OnyxExec v2 loader (RLE compression, ring1 flag)
- [x] VirtIO block/net, GMAC
- [x] TCP/IP (Ethernet, IP, TCP)
- [x] IPC channels (/ipc/*)
- [x] Framebuffer + PSF1/PSF2 fonts
- [x] /proc filesystem
- [x] Authentication (/etc/passwd + /etc/shadow)
- [x] INIT + LOGIN + userspace binaries (9 in total)
- [x] FDT-driven device addresses

**OnyxShell:**
- [x] 20 built-in commands
- [x] Tab completion + arrow-key history
- [x] History expansion (!! / !N / !-N)
- [x] Pipe (|) and redirect (>, <)
- [x] Wildcard globbing (*, ?, [...])
- [x] QEMU integration test

**OnyxCompiller:**
- [x] C99 lexer, preprocessor, parser
- [x] RV64IMA codegen
- [x] .onx v1 output
- [x] libonyxc (printf, malloc, string, syscall wrappers)
- [x] Frontend checks and executed-behaviour tests (`make check`)

**OnyxOS:**
- [x] Vent dependency management
- [x] Bootstrap/build/run scripts
- [x] Complete documentation

### v0.5 - kernel stabilisation

**OnyxKernel:**
- [x] FAT32 read/write, create/unlink/truncate, LFN and FSINFO (`5e92115`, 2026-10-25)
- [x] USB xHCI URB transfer and PCI probe; QEMU controller smoke (`7790fdf`, 2026-11-09)
- [x] USB HID joystick: device enumeration into the slot registry, HID
  report-descriptor parser, interrupt-IN polling, `/dev/jsN` joydev nodes;
  live QEMU smoke `qemu-usb-smoke.sh` (usb-kbd enumerates without a js node,
  usb-tablet gives a stick session; branch `feat/usb-hid-joystick`
  `a50d5fb`..`c3c619a`, live fixes `fe80f57`, `1e2d1f5`, `b7885a1`,
  `a181b22`, 2026-11-20)
- [ ] USB multi-device (multi-slot xHCI), EHCI interrupt transfers, USB mass-storage
- [x] symlink/readlink: syscall and VFS/OnyxFS paths (checked 2026-11-15)
- [x] chmod/fchmod: syscall and VFS paths (checked 2026-11-15)
- [x] truncate/ftruncate(>0): OnyxFS/FAT32 resize (checked 2026-11-15)
- [x] getdents64: batched syscall (checked 2026-11-15)
- [x] fork: argv/envp copying and child trap frame (checked 2026-11-15)
- [x] UDP/DHCP/DNS; DHCP and DNS verified on OC2R (2026-10-25, `OnyxKernel/todo.md` §5)

**OnyxCompiller:**
- [x] Build and run OnyxCC compiled by OnyxCC; compile a freestanding program
- [x] Several C translation units in one `.onx`
- [x] Basic global array/string initialisers
- [x] Automatic test runner that also checks execution
- [ ] Repeated full bootstrap and completion of C/libc support
- [x] Separate C/C++ -> ONYO -> `onyx-ld` compilation, libc objects (`bd14e5d`, 2026-11-15)
- [ ] Full-featured archive linker and external RISC-V ABI compatibility
  (archive member selection by unresolved names `c3d2bd7` and weak binding
  `4845c52` are done, 2026-11-15; `__.SYMDEF` indexes, COMDAT, section GC
  and external ABI compatibility remain)

**Quality:**
- [x] GitHub Actions CI: component workflows and the OnyxOS build/release (checked 2026-11-15)
- [x] Host unit tests for core/kernel and the separable init logic (`OnyxKernel/docs/TESTING.md`, checked 2026-11-15)
- [x] Full-stack QEMU boot/interactive smoke and xHCI smoke (`8c5ad8f`, 2026-11-15); USB HID smoke (`qemu-usb-smoke.sh`, 2026-11-20); desktop smoke (`qemu-desk-smoke.sh`, 2026-11-21)
- [x] OnyxFS: full-block undo, fault injection and remount (`cf6ca42`, 2026-11-15; `FS-J1/J2`)
- [ ] OnyxFS: flush/barrier and power-loss/partial-sector verification on OC2R/physical media

**Language priority ahead of GUI/Java:**
- [x] Standard Lua 5.5.1 and `luac`: CLI, REPL, Lua modules, bytecode and system checks
- [ ] Full C and C++ support, base and user libraries
- [ ] LuaJIT/Luau after standard Lua and a platform-requirements check
- [ ] Port the existing `rustc` target/runtime once the ABI stabilises

Compiler limitations: [compiler.md](compiler.md) and `OnyxCompiller/docs/STATUS.md`.
Lua is built without loading native shared libraries; the full upstream test
suite is not confirmed yet.

### v0.6 - expansion

**OnyxKernel:**
- [ ] 32-bit port (RV32)
- [ ] Multi-user mode
- [ ] Dynamic modules

**OnyxDesktop:**
- [x] `onyxdesk` desktop daemon (C99, ring 1): claims `/dev/fb0` for the
  session, panel + launcher from `/etc/desk.conf`, managed application
  launch with return on exit; 237 host checks GREEN (`7e131ec`, 2026-11-21)
- [x] Image integration: 7th `.vent` dependency, build step in
  `build-all.sh`, packaging of `/bin/onyxdesk` + `/etc/desk.conf`
  (`package-desktop.py`), smoke `qemu-desk-smoke.sh` with the
  `DESK_READY`/`APP_STARTED`/`APP_RETURN`/`DESK_EXIT 0` markers (2026-11-21)
- [ ] M3: hotkeys, input routing to the active window (kernel P2-A),
  `SIGSTOP`/`SIGCONT` switching
- [ ] M4: overlapping windows/composition (kernel P2-B)
- [ ] SBC track: board bring-up, DSI display and live USB HID

**OnyxCompiller:**
- [x] C++ subset: classes, RAII, virtual dispatch, exceptions without full unwinding (`ca8546d`, 2026-11-15)
- [ ] Optimisations (const propagation, dead code elimination)

### v1.0 - stable release

- [ ] Verification on real Milk-V Duo S hardware
- [ ] Documentation in two languages
- [ ] Self-hosting: OnyxOS compiles OnyxOS

## Snapshot 2026-11-21

- Checkbox cross-check for v0.4/v0.5/v0.6 at OnyxOS `45ffd2f`, OnyxKernel
  `113945a`: sources are `OnyxKernel/todo.md` (P1, §3, §4),
  `OnyxCompiller/docs/STATUS.md`, `OnyxApps/todo.md`, `OnyxBoot/roadmap.md`;
  disputed items stay open with a note.
- OnyxDesktop v1 is merged into the image (`312cce5`, `17688cb`): 7th
  `.vent` dependency, build step in `build-all.sh`, `package-desktop.py`
  packaging, design doc `docs/dev/onyxdesktop-design.md`, ecosystem
  overview `docs/dev/ecosystem.md`, smoke `qemu-desk-smoke.sh`.
- Smokes on the artifacts of the current locked build in `.build/`:
  `qemu-smoke.sh`, `qemu-interactive-smoke.sh`, `qemu-desk-smoke.sh`,
  all three PASS.
- CI is green at the listed heads: workflows of all six components plus
  the OnyxOS Build & Test / Release pipelines.
- `roadmap.en.md` is synced with this revision: the OnyxDesktop section,
  the USB HID entries and this snapshot were added.

## Snapshot 2026-11-18

- Compiler pin caught up with the tree: `OnyxCompiller 6fc1947`,
  `OnyxShell 82f0daa`. Before that the locked build failed
  `dependencies.py check`, because building rewrote tracked binaries
  (`DW_AT_comp_dir` depended on the invocation path and `build/osh.onx`
  lagged behind its sources).
- `onyxcc`/`onyx-ld` are now byte-identical from any build path, and
  `build-all.sh` in `check` mode verifies at the end that the locked
  checkouts stayed clean.
- Compiler validation at `6fc1947`: `make check` (66 frontend, 48 runtime,
  15 C++, 5 sepcomp, 44 archive, 36 weak, 48 source-weak, 26 storage, init),
  `make check-native` (7 ASan/UBSan suites) and `make selfhost-test` all pass.
- Full locked build: kernel, shell, compiler, 10 applications, disk image;
  `qemu-smoke.sh` and `qemu-interactive-smoke.sh` pass.
- `docs/dev/known_issues.md` was rewritten from the code: only open items
  remain, and the English version is in sync.

## Snapshot 2026-11-15

- Coordinated OnyxExec fixes: kernel `14937bc` rejects invalid permissions;
  the linker `e7a57ec` uses shared R/W/X and ring1 constants.
- OnyxFS `9215876`: shrink -> extend zeroes the tail of the retained block.
- Host: 70 core + 3 integration + 307 kernel + 4 init; native Apps;
  compiler `make check` (66 frontend, 43 runtime, 5 driver, 15 C++, 5 sepcomp)
  and seven ASan/UBSan suites; 10 dependency-resolver tests; ABI registry - 100.
- Full workspace build and a locked build in clean checkouts passed; the
  locked image reached login in QEMU.
- QEMU: boot and interactive smoke; separate guest runs for tail-zero,
  octal escape, linked-C++ virtual dispatch (`3 2`) and rejection of a
  corrupted ONX while the shell kept running. Bootloader: four QEMU
  scenarios passed.
- `cf6ca42`: OnyxFS keeps whole-block metadata before-images, rolls back
  incomplete operations and does not reuse the journal after a failed commit.
  Host write-cut tests and four QEMU legacy/undo checks passed. The guarantee
  is limited to ordered completed block writes, not physical power loss.
- `1c0f188`, `b8866e9`, `773a8b5`, `c27cc31`: full fmt/strict Clippy, shared
  init modules, removal of dead-code bypasses and unused scaffolds. CI no
  longer uses an advisory check for core tests.
- RV32 smode is rejected explicitly: that combination has no boot entry.
  The supported matrix is RV32 default and RV64 default/smode.

## Mandatory quality check

```sh
bash scripts/quality/check.sh /path/to/component/checkouts
```

The gate runs full fmt and Clippy for the supported host/target
configurations, asserts the explicit RV32 smode rejection and checks the
absence of dead-code bypasses across all six components. For local
`.vent/repos` the argument can be omitted.
The backend diagnostic for `reserve-x4` is kept without suppression: that
flag is needed for the `tp` register. Clippy commands still use `-D warnings`.
