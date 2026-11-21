#!/usr/bin/env python3
"""gen-readme-logo.py - render the Onyx README banner for a repository.

Prints the shared Onyx block logo followed by the given word (or words)
in the same block-letter style. Letter cells were harvested from the
existing banners; C and D were drawn to match. Unknown letters abort.

Usage:
    gen-readme-logo.py WORD [WORD ...]   # banner to stdout
    gen-readme-logo.py --list            # available letters
"""
import sys

# Shared Onyx logo, copied verbatim from the repository banners.
ONYX_LOGO = [
    "    ███████                                     ",
    "  ███▒▒▒▒▒███                                   ",
    " ███     ▒▒███ ████████   █████ ████ █████ █████",
    "▒███      ▒███▒▒▒███▒▒▒███ ▒▒███ ▒███ ▒▒███ ▒▒███",
    "▒███      ▒███ ▒███ ▒███  ▒███ ▒███  ▒▒▒█████▒  ",
    "▒▒███     ███  ▒███ ▒███  ▒███ ▒███   ███▒▒▒███ ",
    " ▒▒▒███████▒   ████ █████ ▒▒███████  █████ █████",
    "   ▒▒▒▒▒▒▒    ▒▒▒▒ ▒▒▒▒▒   ▒▒▒▒▒███ ▒▒▒▒▒ ▒▒▒▒▒",
    "                           ███ ▒███             ",
    "                          ▒▒██████              ",
    "                           ▒▒▒▒▒▒               ",
]

# Letter cells: (rows, top_offset) inside the 8-row name band.
# The offsets mirror the original banners (O, S, C, D, K, T stand tall,
# N, Y sit two rows lower, P one row lower).
GLYPHS = {
    "O": ([
        "    ███████   ",
        "  ███▒▒▒▒▒███ ",
        " ███     ▒▒███",
        "▒███      ▒███",
        "▒███      ▒███",
        "▒▒███     ███ ",
        " ▒▒▒███████▒  ",
        "   ▒▒▒▒▒▒▒    ",
    ], 0),
    "N": ([
        " ████████ ",
        "▒▒███▒▒███",
        " ▒███ ▒███ ",
        " ▒███ ▒███ ",
        " ████ █████",
        " ▒▒▒▒ ▒▒▒▒▒",
    ], 2),
    "Y": ([
        "█████ ████ ",
        "▒███ ▒███  ",
        "▒███ ▒███  ",
        "▒███ ▒███  ",
        "▒▒███████ ",
        " ▒▒▒▒▒███ ",
    ], 2),
    "X": ([
        "█████ █████",
        "▒███ ▒▒███ ",
        "▒▒▒█████▒ ",
        " ███▒▒▒███ ",
        "█████ █████",
        "▒▒▒▒ ▒▒▒▒▒ ",
    ], 2),
    "S": ([
        "  █████████  ",
        " ███▒▒▒▒▒███▒",
        "▒███    ▒▒▒  ",
        "▒▒█████████  ",
        " ▒▒▒▒▒▒▒▒███ ",
        " ███    ▒███ ",
        "▒▒█████████  ",
        " ▒▒▒▒▒▒▒▒▒   ",
    ], 0),
    "C": ([
        "   ████████   ",
        " ███▒▒▒▒▒▒███ ",
        "███           ",
        "███           ",
        "███           ",
        " ███          ",
        " ███▒▒▒▒▒▒███▒ ",
        "  ▒▒▒▒▒▒▒▒▒▒   ",
    ], 0),
    "D": ([
        " ██████████    ",
        "▒▒███▒▒▒▒▒███▒ ",
        " ▒███     ▒███ ",
        " ▒███      ███ ",
        " ▒███      ███ ",
        " ▒███     ▒███ ",
        " ████████████  ",
        " ▒▒▒▒▒▒▒▒▒▒▒   ",
    ], 0),
    "E": ([
        " ██████  ",
        "███▒▒███ ",
        "▒███████ ",
        "▒███▒▒▒  ",
        "▒███     ",
        "▒███▒▒▒  ",
        "▒███████ ",
        " ▒▒▒▒▒▒  ",
    ], 0),
    "K": ([
        " █████   ████  ",
        "▒▒███   ███▒   ",
        " ▒▒███  ███    ",
        " ▒███████      ",
        " ▒███▒▒▒███    ",
        " ▒███ ▒▒███    ",
        " █████ ▒▒████  ",
        "▒▒▒▒▒   ▒▒▒▒   ",
    ], 0),
    "T": ([
        "   █████    ",
        "  ▒▒███     ",
        "  ███████   ",
        " █▒▒▒███▒   ",
        " █  ▒███    ",
        " █  ▒███ ███",
        "    ▒▒█████ ",
        "     ▒▒▒▒▒   ",
    ], 0),
    "P": ([
        " ████ █████",
        "▒▒███ ▒▒███",
        " ▒███  ▒███",
        " █████ ████",
        "▒███▒▒▒ ▒██",
        "▒███▒▒▒ ▒██",
        "▒███▒▒▒ ▒██",
    ], 1),
}

BAND = 8   # name-band height in rows
GAP = 1    # blank columns between letters


def render_word(word: str) -> list:
    band = ["" for _ in range(BAND)]
    for ch in word:
        if ch not in GLYPHS:
            sys.exit(f"gen-readme-logo: no glyph for '{ch}' (word: {word})")
        rows, off = GLYPHS[ch]
        width = max(len(r) for r in rows)
        cur = max(len(r) for r in band)
        for y in range(BAND):
            band[y] = band[y].ljust(cur)  # align columns before the letter
        for y in range(BAND):
            cell = rows[y - off] if 0 <= y - off < len(rows) else ""
            band[y] += cell.ljust(width)
        cur = max(len(r) for r in band)
        for y in range(BAND):
            band[y] = band[y].ljust(cur) + " " * GAP
    return [r.rstrip() for r in band]


def main() -> None:
    if "--list" in sys.argv:
        print(" ".join(sorted(GLYPHS)))
        return
    words = sys.argv[1:]
    if not words:
        sys.exit("usage: gen-readme-logo.py WORD [WORD ...] | --list")
    for line in ONYX_LOGO:
        print(line.rstrip())
    bands = [render_word(w) for w in words]
    for y in range(BAND):
        print("  " + "  ".join(b[y] for b in bands).rstrip())


if __name__ == "__main__":
    main()
