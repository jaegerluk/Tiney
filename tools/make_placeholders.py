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


def stone_floor() -> list[list[tuple]]:
    """64x16: vier schlichte Steinplatten-Varianten mit Fuge rechts und unten."""
    import random
    rnd = random.Random(7)
    base, light, dark, mortar = (86, 86, 98, 255), (100, 100, 112, 255), (74, 74, 86, 255), (56, 56, 66, 255)
    px = [[base for _ in range(64)] for _ in range(16)]
    for v in range(4):
        ox = v * 16
        for y in range(16):
            for x in range(16):
                if x == 15 or y == 15:
                    px[y][ox + x] = mortar
                elif x == 0 or y == 0:
                    px[y][ox + x] = light
                elif rnd.random() < 0.06:
                    px[y][ox + x] = dark if rnd.random() < 0.6 else light
        if v == 1:  # kleiner Riss
            for x, y in [(4, 5), (5, 6), (6, 6), (7, 7), (8, 8), (8, 9), (9, 10)]:
                px[y][ox + x] = mortar
        elif v == 2:  # Platte zweigeteilt
            for x in range(1, 15):
                px[7][ox + x] = mortar
                px[8][ox + x] = light
        elif v == 3:  # Kiesel
            for x, y in [(3, 3), (4, 3), (10, 9), (11, 9), (11, 10), (6, 11)]:
                px[y][ox + x] = dark
    return px


BIG_KEY = [  # 16x16, nicht gespiegelt: großer Schlüssel mit rotem Stein
    "................",
    ".....oooooo.....",
    "....oyyyyyyo....",
    "...oyyorroyyo...",
    "...oyorrrroyo...",
    "...oyyorroyyo...",
    "....oyyyyyyo....",
    ".....ooyyoo.....",
    ".......oyo......",
    ".......oyyoo....",
    ".......oyyyo....",
    ".......oyo......",
    ".......oyyoo....",
    ".......oyyyo....",
    "........ooo.....",
]


def chest() -> list[list[tuple]]:
    """32x16: links geschlossen, rechts offen."""
    wood, wood_dark, wood_light = (150, 95, 50, 255), (100, 60, 30, 255), (190, 130, 70, 255)
    gold, gold_dark, inner = (240, 200, 60, 255), (170, 120, 20, 255), (40, 25, 15, 255)
    px = [[(0, 0, 0, 0)] * 32 for _ in range(16)]
    for frame in range(2):
        ox = frame * 16
        lid_bottom = 7 if frame == 0 else 4
        for y in range(2, 15):
            for x in range(1, 15):
                edge = x in (1, 14) or y in (2, 14) or y == lid_bottom
                if edge:
                    c = OUTLINE
                elif frame == 1 and 3 <= y < 7:
                    c = inner
                elif y < lid_bottom:
                    c = wood_light
                else:
                    c = wood_dark if x % 4 == 0 else wood
                px[y][ox + x] = c
        if frame == 0:  # Schloss
            for y in range(6, 10):
                for x in range(7, 9):
                    px[y][ox + x] = gold if y < 9 else gold_dark
        for x in (3, 12):  # Beschläge
            for y in range(lid_bottom + 1, 14):
                px[y][ox + x] = gold_dark
    return px


def boss_door() -> list[list[tuple]]:
    """32x32: dunkelrote Tür mit großem goldenen Schloss."""
    px = locked_door()
    red, red_dark, red_light = (120, 30, 40, 255), (80, 15, 25, 255), (160, 50, 60, 255)
    for y in range(5, 31):
        for x in range(5, 27):
            if px[y][x] != OUTLINE:
                px[y][x] = red_dark if x % 6 == 3 else (red_light if x % 6 == 4 else red)
    gold, gold_dark = (240, 200, 60, 255), (170, 120, 20, 255)
    for y in range(9, 25):
        for x in range(9, 23):
            edge = x in (9, 22) or y in (9, 24)
            px[y][x] = OUTLINE if edge else (gold_dark if y > 20 else gold)
    for y in range(12, 22):
        for x in (15, 16):
            px[y][x] = OUTLINE
    for x in range(13, 19):
        px[13][x] = OUTLINE
    return px


HEART_CONTAINER = [  # großes Herz mit goldenem Rand, linke Hälfte
    "........",
    "..oooo..",
    ".oyyyyo.",
    "oyrrrryo",
    "oyrwrrry",
    "oyrwrrrr",
    "oyrrrrrr",
    "oyrrrrrr",
    ".oyrrrrr",
    "..oyrrrr",
    "...oyrrr",
    "....oyrr",
    ".....oyr",
    "......oy",
    ".......o",
]


def dungeon_walls() -> list[list[tuple]]:
    """32x16: zwei Varianten Steinziegel (Wand von oben), kachelbar."""
    brick, light, mortar, dark = (62, 62, 76, 255), (80, 80, 96, 255), (34, 34, 44, 255), (50, 50, 62, 255)
    px = [[brick for _ in range(32)] for _ in range(16)]
    for v in range(2):
        ox = v * 16
        for y in range(16):
            row = y // 4
            shift = 4 if row % 2 else 0
            for x in range(16):
                if y % 4 == 3 or (x + shift) % 8 == 7:
                    px[y][ox + x] = mortar
                elif y % 4 == 0:
                    px[y][ox + x] = light
        if v == 1:  # Riss und dunklere Steine
            for x, y in [(2, 5), (3, 6), (4, 6), (5, 7), (9, 9), (10, 10), (11, 10)]:
                px[y][ox + x] = mortar
            for x in range(8, 15):
                for y in (12, 13):
                    if px[y][ox + x] == brick:
                        px[y][ox + x] = dark
    return px


NPC = [  # linke Hälfte, 16x24
    "........",
    ".....ooo",
    "....ohhh",
    "...ohhhh",
    "...ohsss",
    "...osses",
    "...ossss",
    "....obbb",
    ".....obb",
    "....occc",
    "...occcc",
    "..oscccc",
    "..osccca",
    "..osccaa",
    "..occcaa",
    "...occaa",
    "...occcc",
    "...occcc",
    "...occcc",
    "....occc",
    "....odd.",
    "....odd.",
    "....ooo.",
    "........",
]
NPC_PALETTES = {
    "prisoner": {"h": (90, 70, 50, 255), "s": (230, 200, 170, 255), "e": (30, 30, 40, 255), "b": (160, 160, 160, 255),
                 "c": (125, 115, 95, 255), "a": (150, 150, 165, 255), "d": (85, 75, 65, 255)},
    "shopkeeper": {"h": (40, 35, 35, 255), "s": (235, 195, 160, 255), "e": (30, 30, 40, 255), "b": (235, 195, 160, 255),
                   "c": (60, 130, 80, 255), "a": (235, 235, 225, 255), "d": (100, 70, 45, 255)},
}


def npc(palette: dict) -> list[list[tuple]]:
    rows = [r + r[::-1] for r in NPC]
    pal = {".": (0, 0, 0, 0), "o": OUTLINE, **palette}
    return [[pal[c] for c in r] for r in rows]


def portrait(sprite: list[list[tuple]]) -> list[list[tuple]]:
    """32x32: Kopf (obere 16 Zeilen) doppelt vergrößert, auf Hintergrund."""
    bg = (60, 55, 70, 255)
    out = [[bg] * 32 for _ in range(32)]
    for y in range(16):
        for x in range(16):
            c = sprite[y + 1][x]
            if c[3]:
                for dy in range(2):
                    for dx in range(2):
                        out[y * 2 + dy][x * 2 + dx] = c
    return out


POTION = [  # linke Hälfte, Flasche mit rotem Trank
    "........",
    "........",
    "......oo",
    "......ow",
    ".....ooo",
    "......ol",
    ".....orw",
    "....orww",
    "...orrrr",
    "...orrrr",
    "...orrrr",
    "...odrrr",
    "....oddd",
    ".....ooo",
]


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
    write_png(ROOT / "assets" / "tilesets" / "stone_floor.png", stone_floor())
    write_png(ROOT / "assets" / "tilesets" / "dungeon_walls.png", dungeon_walls())
    write_png(out / "pickups" / "big_key.png", from_map(BIG_KEY, {"y": (240, 200, 60, 255), "r": (220, 40, 60, 255)}))
    write_png(out / "objects" / "chest.png", chest())
    write_png(out / "items" / "potion.png", from_map(POTION, {"w": (240, 240, 255, 255), "l": (200, 200, 220, 255), "r": (220, 40, 70, 255), "d": (150, 20, 45, 255)}, mirror=True))
    for name, pal in NPC_PALETTES.items():
        sprite = npc(pal)
        write_png(out / "npcs" / f"{name}.png", sprite)
        write_png(out / "npcs" / f"{name}_portrait.png", portrait(sprite))
    write_png(out / "pickups" / "heart_container.png", from_map(HEART_CONTAINER, {"r": (220, 40, 60, 255), "w": (255, 200, 200, 255), "y": (240, 200, 60, 255)}, mirror=True))
    write_png(out / "objects" / "boss_door.png", boss_door())
    statue_rows = STATUE + ["........"] * (32 - len(STATUE))
    write_png(out / "objects" / "save_statue.png",
              from_map(statue_rows, {"s": (140, 140, 155, 255), "l": (190, 190, 205, 255), "d": (95, 95, 110, 255),
                                     "b": (80, 160, 255, 255), "w": (220, 240, 255, 255)}, mirror=True))


if __name__ == "__main__":
    main()
