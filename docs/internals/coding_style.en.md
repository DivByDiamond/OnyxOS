# Coding Style

## Principles: KISS · DRY · SOLID

- **KISS** — don't overcomplicate. Each function does exactly one thing. If a function doesn't fit on screen (50 lines) — split it.
- **DRY** — no copy-paste. Repeating pattern → function or macro.
- **SOLID** — single responsibility, open for extension, substitutability, interface segregation, dependency inversion. In a kernel this means: modules don't know about each other, they communicate through functions.

## Formatting

- `cargo fmt` is mandatory
- Names: snake_case for functions/variables, CamelCase for types
- Constants: UPPER_SNAKE_CASE
- unsafe — only MMIO and assembly inserts
- Minimal comments, only where logic is non-obvious

## Limits

- Maximum 150 lines per file. Doesn't fit → split into submodules.
- Maximum 3-6 files per directory. More → group into subdirectories.
