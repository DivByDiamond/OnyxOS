# OnyxOS

[![Build & Test](https://github.com/DivByDiamond/OnyxOS/actions/workflows/build.yml/badge.svg)](https://github.com/DivByDiamond/OnyxOS/actions/workflows/build.yml) [![Release](https://github.com/DivByDiamond/OnyxOS/actions/workflows/release.yml/badge.svg)](https://github.com/DivByDiamond/OnyxOS/actions/workflows/release.yml)

<p align="center">
  <img src="https://img.shields.io/badge/arch-RISC--V%2064--bit%20%7C%20RV32-green" alt="RISC-V">
  <img src="https://img.shields.io/badge/kernel-Rust-orange" alt="Rust">
  <img src="https://img.shields.io/badge/boot-C++20-blue" alt="C++20">
  <img src="https://img.shields.io/badge/shell-Rust-orange" alt="Shell">
  <img src="https://img.shields.io/badge/compiler-C99-yellow" alt="Compiler">
  <img src="https://img.shields.io/badge/license-GPL--3.0-red" alt="GPL-3.0">
</p>

An operating system for RISC-V (QEMU virt, OC2R, Milk-V Duo S). A monolithic
kernel in Rust, a bootloader in C++, a userspace shell in Rust, and a
self-hosting C compiler - all built from source and assembled into one
bootable image.

This repository is the meta-project: it vendors the other Onyx repositories
as sibling checkouts, builds all of them, and assembles the boot disk image
and QEMU launch scripts.

----

## Components

| Component | Language | Description |
|-----------|----------|-------------|
| [OnyxBoot](https://github.com/DivByDiamond/OnyxBoot) | C++20 | Bootloader: FDT, VirtIO, SDHCI, FAT32/ext4, GPT, boot menu |
| [OnyxKernel](https://github.com/DivByDiamond/OnyxKernel) | Rust | Monolithic kernel: SMP, Sv39 MM, VFS, TCP/IP, OnyxFS v2, FAT32, wide syscall ABI |
| [OnyxShell](https://github.com/DivByDiamond/OnyxShell) | Rust | `/bin/osh`: built-in commands, tab completion, history, pipes/redirects, globbing, job control |
| [OnyxCompiller](https://github.com/DivByDiamond/OnyxCompiller) | C99 | Self-hosting C compiler: C99 -> RV64 -> `.onx`, `libonyxc` |
| [OnyxApps](https://github.com/DivByDiamond/OnyxApps) | C99 | Optional userland applications, built with OnyxCompiller |
| OnyxOS (this repo) | - | Build orchestration, docs, disk image assembly |

----

## Quick Start

```console
$ # 1. Install build dependencies
$ sudo pacman -S cmake base-devel curl libarchive             # Arch
$ sudo apt install cmake build-essential libcurl4-openssl-dev libarchive-dev  # Debian/Ubuntu

$ # 2. Clone every Onyx repository as a sibling checkout
$ bash scripts/bootstrap.sh

$ # 3. Build every component and assemble the boot disk image
$ bash scripts/build-all.sh

$ # 4. Boot it in QEMU
$ bash scripts/run-qemu.sh
```

`scripts/bootstrap.sh` fetches [Vent](https://github.com/grafmorkov/vent)
(building it from source on first run if needed) and resolves the
dependency manifest in `Onyx.vent`, cloning OnyxBoot, OnyxKernel,
OnyxShell, and OnyxCompiller into `.vent/repos/`. `scripts/build-all.sh`
then builds each component in turn and writes everything to `.build/`.

----

## Repository Layout

```
OnyxOS/
├── Onyx.vent               # Dependency manifest for Vent
├── .vent/
│   ├── vent                # Vent binary
│   └── repos/               # Sibling checkouts (after bootstrap.sh)
├── scripts/
│   ├── bootstrap.sh         # Install Vent, clone dependent repositories
│   ├── build-all.sh         # Build every component + assemble the disk image
│   ├── run-qemu.sh          # Boot in QEMU (dev mode or full boot chain)
│   ├── mk-onyxfs-disk.sh    # Build the FAT32 + OnyxFS partitioned disk image
│   ├── qemu-smoke.sh        # Headless boot smoke test
│   └── qemu-interactive-smoke.sh  # Interactive boot smoke test
├── docs/
│   ├── architecture/        # Boot chain, memory layout, privilege rings
│   ├── dev/                 # Building, contributing, roadmap
│   ├── hardware/            # UART, PLIC, CLINT, VirtIO
│   ├── internals/            # Coding style, error handling conventions
│   ├── kernel/               # Process model, memory management, interrupts
│   ├── shell/                 # Shell commands and internals
│   └── lore/                  # Project history and notes
├── Makefile
└── README.md
```

----

## Running QEMU

`scripts/run-qemu.sh` supports two modes:

```console
$ bash scripts/run-qemu.sh boot    # default: full chain via OnyxBoot + a disk image
$ bash scripts/run-qemu.sh dev     # fast dev loop: QEMU loads the kernel ELF directly, no disk image
```

Useful environment variables:

| Variable | Effect |
|----------|--------|
| `QEMU_MEM` | RAM size (default `256M`) |
| `QEMU_EXTRA` | Extra QEMU flags, e.g. `-s -S` for GDB |

SMP is controlled by passing `-smp N` via `QEMU_EXTRA`, or by invoking QEMU
directly (see the [OnyxKernel README](https://github.com/DivByDiamond/OnyxKernel)
for the full manual command line and its multi-hart caveat - the kernel
supports up to 8 harts, but multi-hart boots are still experimental).

----

## Building Components Individually

### OnyxKernel

```console
$ cd .vent/repos/OnyxKernel
$ cargo kbuild    # alias for: cargo build --release -p onyx_kernel --target riscv64gc-unknown-none-elf
```

### OnyxBoot

```console
$ cd .vent/repos/OnyxBoot
$ make -j$(nproc)
```

### OnyxShell

```console
$ cd .vent/repos/OnyxShell
$ bash build.sh
```

### OnyxCompiller

```console
$ cd .vent/repos/OnyxCompiller
$ make            # native Linux binary
$ make onyxcc-onx # cross-compiled .onx for OnyxOS
```

----

## Building a Firmware Image for OC2R

> [OC2R](https://github.com/TumRedSun/OC2R) is a Minecraft (NeoForge) mod
> that adds virtual computers with 64-bit RISC-V emulation. OnyxOS can boot
> directly inside the game.

OC2R downloads a computer's firmware from a GitHub repository using an
`oc2r-firmware.json` manifest at the repository root. The mod reads it,
follows the `image` link, and flashes that image into the virtual machine.

### Manifest format (`oc2r-firmware.json`)

```json
{
  "name": "OnyxOS",
  "version": "0.3.0",
  "layout": "minux",
  "image": "https://github.com/DivByDiamond/OnyxOS/releases/latest/download/onyx-flash.img"
}
```

| Field | Value | Description |
|-------|-------|-------------|
| `name` | `OnyxOS` | Firmware name |
| `version` | e.g. `0.3.0` | Matches the OnyxKernel workspace `Cargo.toml` version |
| `layout` | `minux` | Flash layout scheme (below) |
| `image` | direct link to `onyx-flash.img` | The flat flash image attached to a GitHub Release |

`minux` layout (flash is exactly 15 MB):

| Offset | Size | Contents |
|--------|------|----------|
| `0x000000` | - | `fw_jump.bin` (OpenSBI, from the OC2R mod's `src/main/scripts/firmware_files/`) |
| `0x200000` (2 MB) | - | OnyxKernel image (ELF, built by cargo) |
| up to 15 MB | - | zero-filled |

### Building the image manually

```console
$ # 1. Resolve dependencies (vent clones the repos into .vent/repos/)
$ make deps

$ # 2. Build the bootloader and kernel
$ make -C .vent/repos/OnyxBoot
$ cargo build --release -p onyx_kernel --target riscv64gc-unknown-none-elf \
    --manifest-path .vent/repos/OnyxKernel/Cargo.toml

$ # 3. Place a real OpenSBI build at firmware/fw_jump.bin
$ #    (from the OC2R mod: src/main/scripts/firmware_files/fw_jump.bin)

$ # 4. Assemble a 15 MB image using the minux layout
$ dd if=/dev/zero of=onyx-flash.img bs=1M count=15
$ dd if=firmware/fw_jump.bin of=onyx-flash.img conv=notrunc
$ dd if=.vent/repos/OnyxKernel/target/riscv64gc-unknown-none-elf/release/onyx-kernel \
    of=onyx-flash.img bs=1M seek=2 conv=notrunc
```

### Automated builds via GitHub Actions

`.github/workflows/release.yml` runs on every pushed git tag (e.g. `v0.3.0`):

1. Builds every component (`make deps` resolves OnyxKernel/OnyxBoot/OnyxShell/OnyxCompiller via Vent).
2. Assembles `onyx-flash.img` (15 MB, `minux` layout).
3. Creates a GitHub Release and attaches the image.

The manifest's `image` field points at
`/releases/latest/download/onyx-flash.img`, which GitHub resolves to the
newest release's asset automatically.

To produce a working release you need to either:

1. Commit a real `fw_jump.bin` (OpenSBI) at `firmware/fw_jump.bin`, or set the
   repository variable `OC2R_FW_JUMP_URL` (without either, CI builds an image
   with a placeholder that will not boot); and
2. Push a tag such as `v0.3.0` - CI builds and uploads the image.

Every push to `main` also publishes a preview image as a workflow artifact,
without creating a Release.

----

## Userspace Applications

Optional userspace programs live in the
[OnyxApps](https://github.com/DivByDiamond/OnyxApps) monorepo (a text
editor, a system monitor, an HTTP client, and more). Each application has
its own `README.md` under `apps/<name>/`. Build with `make` in the OnyxApps
repository root; CI also publishes `build/*.onx` artifacts.

All applications run on top of the kernel's ANSI/VT100 framebuffer
terminal (`fb_term`/`ansi.rs`): SGR colors, cursor positioning, erase
sequences, scroll regions, per-process `termios` via `TCGETS`/`TCSETS`, and
`TIOCGWINSZ` reporting the real framebuffer grid.

----

## Roadmap

Planned work and open issues are tracked in
[`docs/dev/roadmap.md`](docs/dev/roadmap.md) (project-wide milestones) and
[OnyxKernel's `todo.md`](https://github.com/DivByDiamond/OnyxKernel/blob/main/todo.md)
(kernel-level tracking, including in-progress investigations).

----

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
