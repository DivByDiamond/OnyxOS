# OnyxOS Userspace Software

Программы, собираемые одним вызовом `onyxcc -o X.onx X.c` (libonyxc
подхватывается автоматически).

## oed — текстовый редактор (nano/vim-style)

```bash
onyxcc -o /bin/oed.onx software/oed.c
oed /etc/passwd        # открыть файл
oed                    # новый файл
```

- Полноэкранный ANSI-интерфейс: номера строк, `~`-маркеры, статус-бар
- Перемещение: стрелки, Home/End, PageUp/PageDown
- Редактирование: символы, Enter, Backspace, Delete, Tab (4 пробела)
- Скроллинг, dirty-индикатор, счётчик строк/колонок
- `Ctrl+S` сохранить, `Ctrl+Q` выход (двойной при несохранённых правках),
  `Ctrl+G` справка
- Буфер до 2048 строк × 512 байт

Требует: termios raw mode (TCGETS/TCSETS + cfmakeraw), TIOCGWINSZ,
ANSI/VT100 консоль ядра.

## osysmon — системный монитор (btop/htop-style)

```bash
onyxcc -o /bin/osysmon.onx software/osysmon.c
osysmon 500            # обновление каждые 500 мс
```

- Панели System / Memory / CPU / Disk / Net с box-drawing
- Цветные load-бары (зелёный <50%, жёлтый <80%, красный выше)
- uname, uptime (CLOCK_MONOTONIC), PID, getcwd
- Оценка heap через sbrk(0), счётчик файлов в CWD
- `q` выход (raw mode, неблокирующее чтение)

Требует: ANSI-цвета, clock_gettime, sbrk, readdir, stat.

## Сборка всех

```bash
make -C ../OnyxCompiller
ONYXCC=../OnyxCompiller/onyxcc
$ONYXCC -o bin/oed.onx software/oed.c
$ONYXCC -o bin/osysmon.onx software/osysmon.c
```

## Тестирование на хосте

Эмулятор `onx-run` запускает .onx без QEMU:

```bash
cd ../OnyxCompiller
./onyxcc -o /tmp/oed.onx ../OnyxOS/software/oed.c
echo q | ./tools/onx-run /tmp/oed.onx /tmp/file.txt
```
