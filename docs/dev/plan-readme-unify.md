# README Unify Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Все 7 README экосистемы Onyx в одном стиле: ASCII-баннер, EN+RU
в одном файле, ноль длинных тире и ИИ-паттернов, без CI/CD-бейджей.

**Architecture:** Спека стиля + генератор баннеров (уже написаны); каждый
репо перерабатывается отдельным исполнителем по одной и той же спеке.
Фаза A (Boot, Shell, Compiller, Apps) не зависит от занятости OnyxOS;
фаза B (OS, Kernel, Desktop) стартует после освобождения его чекаута.

**Tech Stack:** markdown, генератор `gen-readme-logo.py` (python3, будет
лежать в OnyxOS/scripts/), git push в каждый репо.

**Spec:** `/tmp/opencode/onyxdesktop-sdd/readme/readme-style.md` (в фазе B
копируется в `OnyxOS/docs/dev/readme-style.md` и коммитится).

## Global Constraints

- Ноль длинных тире («—») в EN и RU тексте, включая списки (спека, п. «Правила текста»).
- Никаких ИИ-паттернов и пафоса; конкретика и числа (спека).
- Бейджи CI/CD запрещены; шилдсы platform/language/version/license остаются.
- Один файл README.md: EN сверху, `## Русская версия` снизу; `README.ru.md` удаляется, перевод вкатывается.
- Таблица экосистемы — дословно из спеки, во всех 7 README.
- Баннеры: существующие (Kernel, Boot, Shell, Apps) не перегенерируются; новые (OS: `banner-OS.txt`, Compiller: `banner-ONYXCC.txt`, Desktop: `banner-DESKTOP.txt`) из каталога артов.
- Фактология существующих README сохраняется (команды, таблицы, разделы); меняется оформление и текст.
- Коммиты: `docs: unify readme style`, явные пути, без упоминаний ИИ/агентов, push в origin/main каждого репо.
- Checkout'ы общие: никакого `git add -A`, `git clean`, `reset`, `switch` в чужих ветках.

## Review Focus

1. **Скрытая потеря контента** при переписывании (команды сборки, опции, разделы) — сравнить старую и новую версию; всё существенное должно остаться.
2. **Уцелевшие тире/ИИ-паттерны** — grep по «—», «–», «not just», «это не просто» после правки должен быть пуст.
3. **Двухъязычность** — RU-секция полное зеркало EN; `README.ru.md` удалён; ссылок на удалённый файл не осталось.
4. **Сломанные ссылки** — относительные ссылки и якоря внутри README должны работать.
5. **Баннер** — вставлен в `<pre>` с center/monospace, не повреждён при вставке.

---

### Task 1: OnyxBoot + OnyxShell (фаза A, параллельно)

**Files:**
- Modify: `OnyxBoot/README.md` (вкатить README.ru.md, стиль)
- Delete: `OnyxBoot/README.ru.md`
- Modify: `OnyxShell/README.md` (написать RU-часть, стиль)
- Banner: существующие не трогать.

- [ ] Шаг 1: оба README по спеке; RU Boot из README.ru.md, RU Shell новый.
- [ ] Шаг 2: проверки: grep «—|–» пуст; grep "not just\|это не просто" пуст; README.ru.md отсутствует; таблица экосистемы дословна.
- [ ] Шаг 3: Коммиты `docs: unify readme style` в каждом репо, push.

### Task 2: OnyxCompiller + OnyxApps (фаза A, параллельно с Task 1)

**Files:**
- Modify: `OnyxCompiller/README.md` (+шапка `banner-ONYXCC.txt`, шилдсы, RU)
- Modify: `OnyxApps/README.md` (RU-часть, стиль)
- Banner: Apps существующий не трогать.

- [ ] Шаги как в Task 1 (проверки, коммиты, push).

### Task 3: OnyxOS (фаза B: после освобождения чекаута OnyxOS)

**Files:**
- Modify: `OnyxOS/README.md` (+шапка `banner-OS.txt`, снять CI/CD-бейджи, RU-часть)
- Create: `OnyxOS/scripts/gen-readme-logo.py` (тул из /tmp/opencode/onyxdesktop-sdd/readme/gen-readme-logo.py)
- Create: `OnyxOS/docs/dev/readme-style.md` (спека)
- Create: `OnyxOS/docs/dev/ecosystem.md` (граф зависимостей репо, роль каждого, 3-5 предложений что можно улучшить: кандидат-варианты без исполнения)

- [ ] Шаг 1: README по спеке; тул и спека скопированы; ecosystem.md написан (это ПРОЕКТ, не исполнение: предложения по изменению структуры репо только текстом).
- [ ] Шаг 2: проверки как выше + `python3 scripts/gen-readme-logo.py OS` воспроизводит шапку README.
- [ ] Шаг 3: Коммит `docs: unify readme style, add logo tool and ecosystem notes`, push.

### Task 4: OnyxKernel (фаза B)

**Files:**
- Modify: `OnyxKernel/README.md` (стиль; вкатить README.ru.md; вычистить тире; БЕЗ правки фактов)
- Delete: `OnyxKernel/README.ru.md`
- Banner: существующий не трогать.

- [ ] Шаги как в Task 1. Kernel README большой (406 строк): сохранить ВСЕ разделы (32-bit Support, Roadmap, Module Map) без потери.

### Task 5: OnyxDesktop (фаза B, последним)

**Files:**
- Modify: `OnyxDesktop/README.md` (шапка `banner-DESKTOP.txt`, шилдсы, EN+RU по текущему состоянию: v1 завершён, маркеры, desk.conf, сборка, тесты 237)

- [ ] Шаги как выше; RU-часть новая.

### Финальный гейт

- [ ] Во всех 7 репо: grep «—» в README пуст, CI/CD-бейджей нет, таблица экосистемы идентична, push выполнен.
