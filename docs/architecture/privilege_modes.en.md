# Privilege Modes

- **M-mode** — OnyxBoot or OpenSBI (in OC2R).
- **S-mode / ring 0** — OnyxKernel and its drivers.
- **U-mode / ring 1 or 2** — init, login, shell, and applications.

Ring 1 (Root Space) and ring 2 (User Space) are software ACL levels,
not separate RISC-V hardware modes. `dropring` only lowers privileges;
`exec`/`execve` reject a RING1 image when called from ring 2.
Root login retains ring 1. Non-root login drops to ring 2, but the shipped
RING1 shell cannot launch through that path; installing passwd uid/gid
is also not implemented yet.
