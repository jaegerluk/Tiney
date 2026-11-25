#!/usr/bin/env python3
"""Einzelne Tiles in einer Raumszene (.tscn) ändern, z. B. eine Wandöffnung verschieben.

Beispiel:
    python3 tools/tile_edit.py world/test_area/test_shop.tscn Walls wall 7,13 8,13 clear 4,13 5,13
    → setzt Wand-Tiles auf (7,13) und (8,13), entfernt sie auf (4,13) und (5,13).
Koordinaten in Tiles (16 px). „wall“ setzt Quelle 1 (Wand), „floor“ Quelle 0, „clear“ entfernt.
"""
import re
import struct
import sys

SOURCES = {"floor": 0, "wall": 1}


def read_cells(text: str, layer: str) -> tuple[dict, tuple[int, int]]:
    span = _data_span(text, layer)
    raw = bytes(int(v) for v in text[span[0]:span[1]].split(","))
    cells = {}
    for i in range(2, len(raw), 12):
        x, y, src, ax, ay, alt = struct.unpack("<hhHHHH", raw[i:i + 12])
        cells[(x, y)] = (src, ax, ay, alt)
    return cells, span


def write_cells(text: str, layer: str, cells: dict) -> str:
    span = _data_span(text, layer)
    data = struct.pack("<H", 0)
    for (x, y), (src, ax, ay, alt) in sorted(cells.items(), key=lambda c: (c[0][1], c[0][0])):
        data += struct.pack("<hhHHHH", x, y, src, ax, ay, alt)
    return text[:span[0]] + ", ".join(map(str, data)) + text[span[1]:]


def _data_span(text: str, layer: str) -> tuple[int, int]:
    node = re.search(r'\[node name="%s" type="TileMapLayer"[^\]]*\]' % re.escape(layer), text)
    assert node, "Ebene %s nicht gefunden" % layer
    data = re.compile(r"tile_map_data = PackedByteArray\(").search(text, node.end())
    assert data, "keine tile_map_data"
    start = data.end()
    return start, text.index(")", start)


def main(args: list[str]) -> None:
    path, layer = args[0], args[1]
    text = open(path).read()
    cells, _ = read_cells(text, layer)
    mode = None
    for arg in args[2:]:
        if arg in ("wall", "floor", "clear"):
            mode = arg
            continue
        x, y = (int(v) for v in arg.split(","))
        if mode == "clear":
            cells.pop((x, y), None)
        else:
            cells[(x, y)] = (SOURCES[mode], 0, 0, 0)
    open(path, "w").write(write_cells(text, layer, cells))
    print("geändert:", path)


if __name__ == "__main__":
    main(sys.argv[1:])
