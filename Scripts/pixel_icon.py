#!/usr/bin/env python3
"""Render the iCodexBar pixel-art app icon (1024x1024 PNG, stdlib only).

The art is a 16x16 cell grid: a ">_" prompt over a usage bar on black.
Cells are large on purpose so the pixel look survives the system squircle
mask and small Dock/Home Screen sizes.

Usage: Scripts/pixel_icon.py OUT.png
"""
import struct
import sys
import zlib

SIZE = 1024
GRID = 16

BLACK = (0, 0, 0)
WHITE = (242, 242, 242)
TEAL = (110, 214, 186)
RED = (240, 110, 110)
TRACK = (48, 48, 52)

# ">_" terminal prompt with a stair-stepped chevron (two cells thick), then a
# usage bar: teal fill, red limit tick, dark remaining track.
CHEVRON = {3: 3, 4: 4, 5: 5, 6: 6, 7: 6, 8: 5, 9: 4, 10: 3}  # row -> first col
CURSOR = (10, range(9, 13))
BAR_ROW = 12
BAR = [(range(3, 10), TEAL), (range(10, 11), RED), (range(11, 13), TRACK)]


def cells():
    grid = [[BLACK] * GRID for _ in range(GRID)]
    for row, col in CHEVRON.items():
        grid[row][col] = grid[row][col + 1] = WHITE
    row, cols = CURSOR
    for c in cols:
        grid[row][c] = WHITE
    for cols, color in BAR:
        for c in cols:
            grid[BAR_ROW][c] = color
    return grid


def render(path):
    grid = cells()
    cell_of = [min(i * GRID // SIZE, GRID - 1) for i in range(SIZE)]
    rows = []
    for y in range(SIZE):
        line = grid[cell_of[y]]
        rows.append(b"\x00" + b"".join(bytes(line[cell_of[x]]) for x in range(SIZE)))
    raw = zlib.compress(b"".join(rows), 9)

    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    header = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) + chunk(b"IDAT", raw) + chunk(b"IEND", b""))


if __name__ == "__main__":
    render(sys.argv[1])
