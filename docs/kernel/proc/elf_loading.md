# ELF Loading

## ELF Header

```rust
struct ElfHeader {
    magic:          u32,     // 0x464c457f
    bitsize:        u8,      // 2 = 64-bit
    endian:         u8,      // 1 = little
    ident_abi:      [u8; 9],
    obj_type:       u16,     // 2 = EXEC
    machine:        u16,     // 0xF3 = RISC-V
    version:        u32,
    entry_addr:     usize,
    phoff:          usize,   // offset to program headers
    shoff:          usize,
    flags:          u32,
    ehsize:         u16,
    phentsize:      u16,
    phnum:          u16,
    shentsize:      u16,
    shnum:          u16,
    shstrndx:       u16,
}
```

## Program Header

```rust
struct ProgHeader {
    seg_type: u32,   // 1 = LOAD
    flags:    u32,   // 1=X, 2=W, 4=R
    off:      usize, // offset in file
    vaddr:    usize, // virtual addr
    paddr:    usize, // physical addr
    filesz:   usize, // size in file
    memsz:    usize, // size in memory
    align:    usize,
}
```

## loading

1. Читаем ELF header (через fs_read)
2. Валидируем magic, machine, type
3. Вычисляем phoff, читаем program headers
4. Для каждого LOAD сегмента:
   - Аллоцируем `memsz` в физической памяти (выравнено по страницам)
   - Копируем `filesz` байт из файла
   - Обнуляем `memsz - filesz` (bss-like)
   - Маппим в адресное пространство процесса с нужными флагами
5. Entry point = `entry_addr` (из ElfHeader)

## startlib (userspace startup)

```asm
.section .text.init
.global _start
_start:
    call main
    li a0, 93   // SYS_exit
    ecall
```
