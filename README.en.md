# OnyxOS

<p align="center">
  <img src="https://img.shields.io/badge/arch-RISC--V%2064--bit%20%7C%20RV32-green" alt="RISC-V">
  <img src="https://img.shields.io/badge/kernel-Rust-orange" alt="Rust">
  <img src="https://img.shields.io/badge/boot-C++20-blue" alt="C++20">
  <img src="https://img.shields.io/badge/shell-Rust-orange" alt="Shell">
  <img src="https://img.shields.io/badge/compiler-C99-yellow" alt="Compiler">
  <img src="https://img.shields.io/badge/license-GPL--3.0-red" alt="GPL-3.0">
</p>

A RISC-V operating system for OC2r / Milk-V Duo S. Monolithic kernel in Rust,
bootloader in C++, userspace shell in Rust, and a self-hosted C compiler.

## Components

| Component | Language | Description | Status |
|-----------|----------|-------------|--------|
| **OnyxBoot** | C++20 | Bootloader: FDT, VirtIO, SDHCI, FAT32/ext4, GPT, boot menu | v0.4 |
| **OnyxKernel** | Rust | Monolithic kernel: MM (Sv39), SMP, VFS, TCP/IP, drivers, 77 syscalls | active |
| **OnyxShell** | Rust | Shell: 20 commands, tabs, history, pipes/redirects, globbing | v0.3 |
| **OnyxCompiller** | C99 | C → RV64 → `.onx`, single-pass, self-hosting WIP | MVP |
| **OnyxOS** | — | Documentation, scripts, integration | meta |

## Quick Start

```bash
# 1. Install system deps
sudo pacman -S cmake base-devel curl libarchive    # Arch
sudo apt install cmake build-essential libcurl4-openssl-dev libarchive-dev  # Debian

# 2. Fetch all Onyx repositories via Vent
./.vent/vent -j 4 Onyx.vent

# 3. Build everything
bash scripts/build-all.sh

# 4. Run in QEMU
bash scripts/run-qemu.sh
```

## Repository Structure

```
OnyxOS/
├── Onyx.vent              # Vent dependency file
├── .vent/
│   ├── vent               # Vent binary
│   └── repos/             # Cloned repositories (after running Vent)
├── scripts/
│   ├── bootstrap.sh       # Install Vent + clone all repos
│   ├── build-all.sh       # Build all components
│   └── run-qemu.sh        # Launch QEMU (OnyxBoot + OnyxKernel)
├── docs/                  # Documentation
│   ├── architecture/      # Boot, memory, privilege modes
│   ├── dev/               # Building, contributing, roadmap
│   ├── hardware/          # UART, PLIC, CLINT, VirtIO
│   ├── internals/         # Coding style, error handling
│   ├── kernel/            # Processes, MM, interrupts
│   ├── shell/             # Commands, internals
│   └── lore/              # Project lore
├── Makefile               # Skeleton (WIP)
└── README.md
```

## Building Individual Components

### OnyxKernel

```bash
cd .vent/repos/OnyxKernel
cargo build --release
```

### OnyxBoot

```bash
cd .vent/repos/OnyxBoot
make -j$(nproc)
```

### OnyxShell

```bash
cd .vent/repos/OnyxShell
bash build.sh
```

### OnyxCompiller

```bash
cd .vent/repos/OnyxCompiller
make host          # native Linux binary
make onyx          # cross-compile to .onx
```

## Roadmap

| Area | What's next |
|------|-------------|
| **OnyxKernel** | FAT32 read, USB URB, symlink, chmod, 32-bit port, unit tests |
| **OnyxCompiller** | Self-hosting, multi-file linking, C++ |
| **CI/CD** | GitHub Actions, automated QEMU tests |
| **Hardware** | Verification on Milk-V Duo S |

See [docs/dev/roadmap.md](docs/dev/roadmap.md) and [OnyxKernel todo.md](https://github.com/loki5512344/OnyxKernel/blob/main/todo.md).

## License

GPL-3.0-or-later
