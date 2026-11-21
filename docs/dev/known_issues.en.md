# Known Issues

> Current as of 2026-11-18. Only **open** limitations are listed here.
> Closed items live in `docs/dev/roadmap.md`, `OnyxKernel/todo.md` and
> `docs/history/`; anything done is not copied back here.

## OnyxKernel

| Limitation | Where | What remains |
|------------|-------|--------------|
| Blocking `recv` | `kernel/src/net/tcp` | There is no per-socket wait queue, so applications poll; a blocking path without busy-poll is needed |
| TCP sends 536 bytes per segment | `kernel/src/net/tcp` | No IP fragmentation; raise MSS and honour the path MTU |
| Server sockets are root-only admin | `kernel/src/net` | User-space `listen`/`accept` are unavailable and the contract is not documented in the README |
| No TLS | userspace (`obrowse`) | The browser stays HTTP-only |
| No dynamic kernel modules | `kernel/src/fs/procfs` | `/proc/modules` lists built-in drivers only |
| Journal has no flush/barrier | `kernel/src/fs/onyxfs` | Guarantees cover ordered block writes; power loss and partial sectors are untested on OC2R/physical media (L6) |
| Glyph blit is per-pixel over MMIO | `kernel/src/drivers/video/fb_term` | Scroll/clear copy words, glyph output does not (L4) |
| Double buffering unverified | `kernel/src/drivers/video/fb` | Tearing on a live OC2R monitor has not been measured (L5) |
| URB/HCD layer has no consumer | `kernel/src/drivers/bus/usb/hcd.rs` | Needs USB core enumeration (descriptors, addressing, mass storage) or removal |
| `nanosleep` on rv32 non-smode | `kernel/src/arch` | Goes through SBI; a direct CLINT MMIO path plus `mtrap_32` is required |
| RV32 smode unsupported | build | That combination has no boot entry and is rejected explicitly; the supported matrix is RV32 default and RV64 default/smode |
| No EOF after RST | `kernel/src/net/tcp/sock.rs` | `recv` reports `Err(Io)` rather than `Ok(0)` - deliberate, but applications must distinguish reset from FIN (L3) |

## Userland

| Limitation | Where | What remains |
|------------|-------|--------------|
| No GUI window manager/compositor/cursor | userspace | Separate windows, z-order/clipping, click handling, richer widgets |
| No Java runtime | userspace | Class loader, bytecode interpreter, JDK subset, GC, hello-world in QEMU/OC2R |
| Applications not run live | `OnyxApps` | osnake, otop, ochat, ochat-gui are covered by host tests; interactive runs in QEMU/with the mod are unconfirmed |

## OnyxCompiller

| Limitation | What remains |
|------------|--------------|
| One input per `-c` | Several translation units cannot be compiled in one invocation |
| Archives without an index | Lazy linear extraction; `__.SYMDEF` is not read |
| No COMDAT/versioning/relaxation/section GC | Linking neither drops dead sections nor handles symbol versions |
| `-e` accepts GLOBAL symbols only | An entry point cannot be a local symbol |
| PCREL relocations are not emitted | The compiler never produces them; the linker relies on absolute ones |
| Hard caps | 64 objects and 4 sections per object |
| Single pass, no optimisation | No IR: const propagation, DCE and loop folding are absent |
| C++ is a subset | No multiple/virtual inheritance, RTTI/`dynamic_cast`, class templates, virtual destructors or full unwinding - see `OnyxCompiller/docs/STATUS.md` |
| Repeated full bootstrap | Stage-one self-hosting works; a full self-build cycle is not complete |

## OnyxOS

| Limitation | What remains |
|------------|--------------|
| CI cannot see local commits | The `Onyx.lock.json` pin is only usable after the components are pushed; otherwise a locked build on GitHub cannot fetch the revision |
| Two-language documentation | The English versions lag behind; keep them up to date when editing `.md` |

## How this was checked

Cross-checked against code and plans on 2026-11-18: `abi/syscalls.csv`
(100 syscalls), `docs/dev/roadmap.md` (v0.4/v0.5 snapshot),
`OnyxKernel/todo.md` §3-4, `OnyxCompiller/docs/STATUS.md`
("Remaining limitations") and `OnyxApps/todo.md`.
