# Переключение контекста

Сохраняем/восстанавливаем callee-saved регистры:
ra, sp, s0-s11.

## save_context

Записывает регистры в структуру Context.

## restore_context

Загружает регистры из Context и переходит по ra.

**Статус**: `save_context()` / `restore_context()` написаны, но ещё не
вызываются из `sched_yield()`. Реальное переключение контекста появится
в v0.3 (см. roadmap и known_issues).
