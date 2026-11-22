#!/usr/bin/env python3
"""Erzeugt einfache 16x16-Platzhalter-Sprites (eigene Arbeit, frei nutzbar).

Aufruf im Projektordner:  python3 tools/make_placeholders.py
Symmetrische Sprites werden als linke Hälfte (8 Zeichen pro Zeile) definiert und gespiegelt.
"""
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

OUTLINE = (26, 26, 34, 255)


def write_png(path: Path, pixels: list[list[tuple]]) -> None:
    h, w = len(pixels), len(pixels[0])
    raw = b"".join(b"\x00" + b"".join(bytes(px) for px in row) for row in pixels)

    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)
    print("geschrieben:", path.relative_to(ROOT))


def from_map(rows: list[str], palette: dict, mirror: bool = False) -> list[list[tuple]]:
    if mirror:
        rows = [r + r[::-1] for r in rows]
    height = max(16, len(rows))
    rows = rows + ["." * len(rows[0])] * (height - len(rows))
    assert all(len(r) == 16 for r in rows), "jede Zeile muss 16 Pixel breit sein"
    pal = {".": (0, 0, 0, 0), "o": OUTLINE, **palette}
    return [[pal[c] for c in r] for r in rows]


RUPEE = [  # linke Hälfte
    "........",
    "......oo",
    ".....owl",
    "....owlm",
    "....olmm",
    "....olmm",
    "....olmm",
    "....olmm",
    "....olmm",
    "....olmm",
    "....olmm",
    ".....olm",
    "......oo",
]
RUPEE_COLORS = {
    "green": {"w": (230, 255, 230, 255), "l": (130, 230, 120, 255), "m": (40, 170, 80, 255)},
    "blue": {"w": (230, 240, 255, 255), "l": (120, 170, 255, 255), "m": (40, 80, 210, 255)},
    "red": {"w": (255, 230, 230, 255), "l": (255, 120, 120, 255), "m": (200, 30, 50, 255)},
}

HEART = [  # kleines Herz (8x7) mittig auf 16x16, nicht gespiegelt
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    ".....oo..oo.....",
    "....orroorro....",
    "....orwrrrro....",
    "....orrrrrro....",
    ".....orrrro.....",
    "......orro......",
    ".......oo.......",
]

KEY = [  # volle Breite, nicht gespiegelt
    "................",
    "......ooo.......",
    ".....oyyyo......",
    "....oyo.oyo.....",
    "....oyo.oyo.....",
    ".....oyyyo......",
    "......oyo.......",
    "......oyo.......",
    "......oyyo......",
    "......oyo.......",
    "......oyyo......",
    "......oyo.......",
    ".......o........",
]

POT = [
    "........",
    "........",
    "....oooo",
    "....ohbb",
    ".....odd",
    "....ohbb",
    "...ohbbb",
    "..ohbbbb",
    "..ohbbbb",
    "..ohbbbb",
    "..obbbbb",
    "..odbbbb",
    "...odddd",
    "....oooo",
]

GRASS = [
    "........",
    "........",
    "........",
    ".....ooo",
    "...oogll",
    "..oggglg",
    ".oggggll",
    ".oglgggg",
    "oggggggg",
    "ogglgggg",
    "oggggdgg",
    ".oggdggg",
    ".odgggdg",
    "..oddddd",
    "...ooooo",
]


STATUE = [  # linke Hälfte, 16x32
    "........",
    "........",
    "......oo",
    ".....obw",
    ".....obb",
    ".....obb",
    "......oo",
    ".....ooo",
    "....osll",
    "....osls",
    "....osls",
    "....osls",
    "....osls",
    "....osdd",
    "....osdl",
    "....osdd",
    "....osls",
    "....osls",
    "....osls",
    "....osls",
    "....osls",
    "....odss",
    "...ooooo",
    "..osllll",
    "..osssss",
    "..osssss",
    "..oddddd",
    "..oooooo",
]


def locked_door() -> list[list[tuple]]:
    """32x32: Holztür in Steinrahmen mit goldenem Schloss."""
    stone, stone_dark = (110, 110, 125, 255), (70, 70, 85, 255)
    wood, wood_dark, wood_light = (140, 90, 50, 255), (95, 55, 30, 255), (175, 120, 70, 255)
    gold, gold_dark = (240, 200, 60, 255), (170, 120, 20, 255)
    px = [[stone for _ in range(32)] for _ in range(32)]
    for y in range(32):
        for x in range(32):
            if x in (0, 31) or y in (0, 31):
                px[y][x] = OUTLINE
            elif 4 <= x <= 27 and 4 <= y <= 30:
                px[y][x] = wood_dark if x % 6 == 3 else (wood_light if x % 6 == 4 else wood)
                if x in (4, 27) or y == 4:
                    px[y][x] = OUTLINE
            elif (x + y) % 7 == 0:
                px[y][x] = stone_dark
    for y in range(12, 22):  # Schloss
        for x in range(11, 21):
            edge = x in (11, 20) or y in (12, 21)
            px[y][x] = OUTLINE if edge else (gold_dark if y > 18 else gold)
    for y, x in [(14, 15), (14, 16), (15, 15), (15, 16), (16, 15), (16, 16), (17, 15), (17, 16), (18, 15), (18, 16)]:
        px[y][x] = OUTLINE  # Schlüsselloch
    return px


def main() -> None:
    out = ROOT / "assets" / "sprites"
    for name, colors in RUPEE_COLORS.items():
        write_png(out / "pickups" / f"rupee_{name}.png", from_map(RUPEE, colors, mirror=True))
    write_png(out / "pickups" / "heart.png",
              from_map(HEART, {"r": (220, 40, 60, 255), "w": (255, 200, 200, 255)}))
    write_png(out / "pickups" / "small_key.png",
              from_map(KEY, {"y": (240, 200, 60, 255)}))
    write_png(out / "objects" / "pot.png",
              from_map(POT, {"b": (170, 100, 60, 255), "h": (215, 150, 100, 255), "d": (110, 60, 35, 255)}, mirror=True))
    write_png(out / "objects" / "grass.png",
              from_map(GRASS, {"g": (60, 160, 60, 255), "l": (120, 210, 90, 255), "d": (30, 100, 40, 255)}, mirror=True))
    write_png(out / "objects" / "locked_door.png", locked_door())
    statue_rows = STATUE + ["........"] * (32 - len(STATUE))
    write_png(out / "objects" / "save_statue.png",
              from_map(statue_rows, {"s": (140, 140, 155, 255), "l": (190, 190, 205, 255), "d": (95, 95, 110, 255),
                                     "b": (80, 160, 255, 255), "w": (220, 240, 255, 255)}, mirror=True))


if __name__ == "__main__":
    main()
