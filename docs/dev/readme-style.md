# Onyx README style spec

Утверждён владельцем 2026-11-21. Единый стиль для README всех репозиториев
экосистемы Onyx: OnyxOS, OnyxKernel, OnyxBoot, OnyxShell, OnyxCompiller,
OnyxApps, OnyxDesktop.

## Шаблон файла (один README.md на репо)

1. ASCII-баннер: блок-лого «Onyx» + слово репо в том же стиле
   (генератор: `OnyxOS/scripts/gen-readme-logo.py WORD`, вывод вставить
   в `<pre>` с `text-align:center;font-family:monospace;`).
2. Под баннером курсивная строка-описание (`<p align="center"><em>…</em></p>`).
3. Ряд шилдсов img.shields.io: platform, language, version, license.
   **Бейджи CI/CD (workflow badges) запрещены во всех репо.**
4. `----`, затем английская часть: вступление (что это, часть экосистемы
   со ссылкой на OnyxOS, конкретика: версии, размеры, числа), сборка,
   использование, тесты, структура проекта, таблица экосистемы (ниже),
   лицензия. `----`.
5. `## Русская версия` — полное зеркало английской части на русском.
   Отдельные `README.ru.md` больше не используются: перевод вкатывается
   в общий файл, старый файл удаляется.

## Таблица экосистемы (одинаковая во всех README, без изменений текста)

| Repository | Role | Language |
|---|---|---|
| [OnyxOS](https://github.com/DivByDiamond/OnyxOS) | Ecosystem: build, disk image, docs | Bash / Python |
| [OnyxKernel](https://github.com/DivByDiamond/OnyxKernel) | RISC-V 64 kernel (Sv39, 3 rings) | Rust |
| [OnyxBoot](https://github.com/DivByDiamond/OnyxBoot) | Bootloader (M-mode, FDT) | C++20 |
| [OnyxShell](https://github.com/DivByDiamond/OnyxShell) | User shell `osh` | Rust |
| [OnyxCompiller](https://github.com/DivByDiamond/OnyxCompiller) | C99 compiler `onyxcc` + linker | C99 |
| [OnyxApps](https://github.com/DivByDiamond/OnyxApps) | Userland applications | C99 |
| [OnyxDesktop](https://github.com/DivByDiamond/OnyxDesktop) | Desktop environment `onyxdesk` | C99 |

## Правила текста (EN и RU)

- **Ноль длинных тире** («—», «–») во всём тексте, включая списки.
  Замены: двоеточие, точка, запятая, скобки, два предложения.
  В списках вместо «**Термин** — описание» писать «**Термин**: описание».
- Никаких ИИ-паттернов: «it's not just X, it's Y» / «это не просто X,
  это Y», «with that being said», «it is important to note», «in today's
  fast-paced world»; слова delve, robust, seamless, leverage, tapestry,
  elevate, crucial (в роли пафоса), showcase. Русские аналоги тоже под
  запретом.
- Никаких фальшивых триад (группы из трёх, когда суть не делится на три).
- Разная длина предложений; активный залог; конкретные числа и имена
  вместо эпитетов (не «lightweight and fast», а «~9.5 KB»).
- Никаких пафосных одиночных строк-финалов и «цитатных» афоризмов.
- Прямой сухой технический тон; без рекламных оборотов.

## Прочее

- Существующий фактологический контент каждого README сохраняется
  (команды сборки, таблицы, разделы), меняется оформление и текст.
- Коммит каждого репо: `docs: unify readme style`, явные пути, пуш.
