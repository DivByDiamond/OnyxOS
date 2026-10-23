# Привилегированные режимы

- **M-mode** — OnyxBoot либо OpenSBI (в OC2R).
- **S-mode / ring 0** — ядро OnyxKernel и драйверы.
- **U-mode / ring 1 или 2** — init, login, shell и приложения.

Ring 1 (Root Space) и ring 2 (User Space) — программные уровни ACL,
а не отдельные аппаратные режимы RISC-V. `dropring` только понижает
привилегии; `exec`/`execve` не разрешают ring 2 загрузить RING1-образ.
Root-login сохраняет ring 1. Непривилегированный login вызывает переход
в ring 2, но стандартный RING1-shell несовместим с этим путём; установка
uid/gid из passwd также пока не реализована.
