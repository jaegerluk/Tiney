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


SCROLL = [  # Schriftrolle für den Hinweis, 16x16, nicht gespiegelt
    "................",
    "................",
    "...oooooooooo...",
    "..oppppppppppo..",
    "..opoooooooopo..",
    "...oppppppppo...",
    "...opkkkkkkpo...",
    "...oppppppppo...",
    "...opkkkkkppo...",
    "...oppppppppo...",
    "...opkkkkkkpo...",
    "..opoooooooopo..",
    "..oppppppppppo..",
    "...oooooooooo...",
]


ZOMBIE_BODY = [
    "................",
    ".....oooooo.....",
    "....oggggggo....",
    "....ogegggego...",
    "....oggggggo....",
    "....ogdddddgo...",
    ".....oggggo.....",
    "....occcccco....",
    "...occcccccco...",
    "..ogocccccccogo.",
    "..ogocccccccogo.",
    "....occcccco....",
    "....occcccco....",
]
ZOMBIE_LEGS = [
    ["....oll..llo....", "....oll..llo....", "....oll...ooo...", "....ooo........."],
    ["....oll..llo....", "....oll..llo....", "...ooo...llo....", ".........ooo...."],
]
ZOMBIE_PALETTE = {"g": (110, 160, 90, 255), "e": (200, 40, 40, 255), "d": (40, 50, 30, 255),
                  "c": (90, 80, 110, 255), "l": (70, 60, 80, 255)}


def zombie_sheet() -> list[list[tuple]]:
    """32x20: zwei Lauf-Frames."""
    pal = {".": (0, 0, 0, 0), "o": OUTLINE, **ZOMBIE_PALETTE}
    rows = [[(0, 0, 0, 0)] * 32 for _ in range(20)]
    for f in range(2):
        frame = ZOMBIE_BODY + ZOMBIE_LEGS[f]
        for y, line in enumerate(frame):
            for x, c in enumerate(line):
                rows[y + 2][f * 16 + x] = pal[c]
    return rows


def zombie_king_sheet() -> list[list[tuple]]:
    """64x48: Zombie doppelt so groß, dunkler, mit goldener Krone."""
    small = zombie_sheet()
    out = [[(0, 0, 0, 0)] * 64 for _ in range(48)]
    for y in range(20):
        for x in range(32):
            c = small[y][x]
            if c[3] and c != OUTLINE:
                c = (int(c[0] * 0.8), int(c[1] * 0.75), int(c[2] * 0.9), 255)
            for dy in range(2):
                for dx in range(2):
                    out[y * 2 + dy + 8][x * 2 + dx] = c
    gold, gold_dark = (240, 200, 60, 255), (170, 120, 20, 255)
    for f in range(2):
        ox = f * 32
        for x in range(10, 22):
            out[14][ox + x] = gold_dark
            out[13][ox + x] = gold
        for x in (10, 13, 16, 18, 21):
            for y in (10, 11, 12):
                out[y][ox + x] = gold
    return out


def shutter_door() -> list[list[tuple]]:
    """64x32: links geschlossen (Gitter), rechts offen (nur Rahmen, Gitter im Boden)."""
    frame, frame_dark = (110, 110, 125, 255), (70, 70, 85, 255)
    bar, bar_light, floor_slot = (150, 155, 165, 255), (200, 205, 215, 255), (30, 30, 38, 255)
    px = [[(0, 0, 0, 0)] * 64 for _ in range(32)]
    for f in range(2):
        ox = f * 32
        for y in range(32):
            for x in range(32):
                if x in (0, 31) or y in (0, 31):
                    px[y][ox + x] = OUTLINE
                elif x < 4 or x > 27 or y < 4:
                    px[y][ox + x] = frame_dark if (x + y) % 5 == 0 else frame
                elif f == 0:
                    if x % 5 == 1:
                        px[y][ox + x] = OUTLINE
                    elif x % 5 in (2, 3):
                        px[y][ox + x] = bar_light if x % 5 == 2 else bar
                    elif y in (12, 22):
                        px[y][ox + x] = bar
                elif y >= 28:
                    px[y][ox + x] = floor_slot
    return px


ORB = [  # linke Hälfte, leuchtende Kugel
    "........",
    "........",
    ".....ooo",
    "....obbb",
    "...obwwb",
    "..obwwbb",
    "..obwbbb",
    "..obbbbb",
    "..obbbbb",
    "..obbbbp",
    "...obbpp",
    "....oppp",
    ".....ooo",
]


def push_block() -> list[list[tuple]]:
    """16x16: Steinblock mit Kanten (zum Schieben)."""
    top, side, light, dark = (130, 125, 140, 255), (95, 90, 105, 255), (170, 165, 180, 255), (65, 60, 75, 255)
    px = [[top] * 16 for _ in range(16)]
    for y in range(16):
        for x in range(16):
            if x in (0, 15) or y in (0, 15):
                px[y][x] = OUTLINE
            elif y >= 12:
                px[y][x] = side if y < 14 else dark
            elif x == 1 or y == 1:
                px[y][x] = light
            elif x == 14 or y == 11:
                px[y][x] = dark
    for x, y in [(5, 5), (6, 5), (10, 7), (4, 8)]:
        px[y][x] = side
    return px


def stairs() -> list[list[tuple]]:
    """32x16: links Treppe nach unten (dunkler werdend), rechts nach oben (heller werdend)."""
    px = [[(0, 0, 0, 0)] * 32 for _ in range(16)]
    for f in range(2):
        ox = f * 16
        for y in range(16):
            step = y // 4
            shade = 110 - step * 25 if f == 0 else 70 + step * 25
            for x in range(16):
                if x in (0, 15) or y in (0, 15):
                    px[y][ox + x] = OUTLINE
                elif y % 4 == 3:
                    px[y][ox + x] = (max(shade - 30, 10), max(shade - 30, 10), max(shade - 20, 15), 255)
                else:
                    px[y][ox + x] = (shade, shade, shade + 10, 255)
    return px


def puddle() -> list[list[tuple]]:
    """48x32: flache Wasserpfütze (Oval) mit hellen Wellen."""
    water, deep, light, edge = (70, 120, 190, 220), (55, 95, 160, 230), (150, 200, 240, 230), (40, 70, 120, 255)
    px = [[(0, 0, 0, 0)] * 48 for _ in range(32)]
    cx, cy, rx, ry = 23.5, 15.5, 23.5, 15.5
    for y in range(32):
        for x in range(48):
            d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
            if d <= 1.0:
                px[y][x] = edge if d > 0.82 else (deep if d > 0.55 else water)
    for x, y in [(10, 10), (11, 10), (12, 10), (30, 8), (31, 8), (32, 8), (33, 8), (20, 22), (21, 22), (22, 22), (36, 19), (37, 19)]:
        px[y][x] = light
    return px


def hold_switch() -> list[list[tuple]]:
    """32x16: orangefarbener Halteschalter, links oben (aus), rechts gedrückt (an)."""
    rim, rim_dark = (120, 110, 100, 255), (80, 72, 66, 255)
    up, up_light, down, down_dark = (230, 140, 40, 255), (255, 190, 90, 255), (170, 90, 20, 255), (120, 60, 10, 255)
    px = [[(0, 0, 0, 0)] * 32 for _ in range(16)]
    for f in range(2):
        ox = f * 16
        for y in range(1, 15):
            for x in range(1, 15):
                edge = x in (1, 14) or y in (1, 14)
                ring = x in (2, 13) or y in (2, 13)
                if edge:
                    px[y][ox + x] = OUTLINE
                elif ring:
                    px[y][ox + x] = rim if (x + y) % 2 else rim_dark
                elif f == 0:
                    px[y][ox + x] = up_light if y <= 5 else up
                else:
                    px[y][ox + x] = down_dark if y >= 10 else down
    return px


CRYSTAL = [  # 16x24, nicht gespiegelt; k = Kristall hell, c = Kristall, d = Kristall dunkel
    "................",
    ".......oo.......",
    "......okco......",
    ".....okkcco.....",
    ".....okccdo.....",
    "....okkccddo....",
    "....okcccddo....",
    "....okcccddo....",
    "....okcccddo....",
    ".....okccdo.....",
    ".....okccdo.....",
    "......occo......",
    ".......oo.......",
    "....oooooooo....",
    "...osssssssso...",
    "...ossllllsso...",
    "....osssssso....",
    "....osssssso....",
    "....osssssso....",
    "...osssssssso...",
    "...oddddddddo...",
    "...oooooooooo...",
]
CRYSTAL_COLORS = [  # (hell, mittel, dunkel) je Frame
    ((170, 210, 255), (70, 130, 230), (40, 70, 160)),     # Umschalter aus: blau
    ((255, 170, 170), (220, 60, 60), (140, 30, 30)),      # Umschalter an: rot
    ((180, 255, 180), (60, 190, 90), (30, 110, 50)),      # Einmalig bereit: grün
    ((200, 200, 200), (130, 130, 130), (80, 80, 80)),     # Einmalig benutzt: grau
    ((255, 245, 160), (230, 200, 40), (150, 120, 20)),    # Zeit bereit: gelb
    ((255, 220, 150), (250, 140, 30), (170, 80, 10)),     # Zeit läuft: orange
]


def crystal_sheet() -> list[list[tuple]]:
    """96x24: sechs Zustände des Kristallschalters."""
    stone = {"s": (140, 140, 155, 255), "l": (190, 190, 205, 255), "d": (95, 95, 110, 255)}
    px = [[(0, 0, 0, 0)] * 96 for _ in range(24)]
    for f, (k, c, d) in enumerate(CRYSTAL_COLORS):
        pal = {".": (0, 0, 0, 0), "o": OUTLINE, "k": (*k, 255), "c": (*c, 255), **stone}
        for y, line in enumerate(CRYSTAL):
            for x, ch in enumerate(line):
                if ch == "d" and y < 13:
                    col = (*d, 255)
                else:
                    col = pal[ch]
                px[y + 1][f * 16 + x] = col
    return px


def spikes_sheet() -> list[list[tuple]]:
    """48x16: eingefahren (Löcher), Warnung (Spitzen schauen raus), ausgefahren."""
    plate, plate_dark, hole = (90, 88, 100, 255), (70, 68, 80, 255), (30, 28, 36, 255)
    steel, steel_light, steel_dark = (170, 175, 190, 255), (225, 230, 240, 255), (110, 115, 130, 255)
    px = [[(0, 0, 0, 0)] * 48 for _ in range(16)]
    spots = [(4, 4), (11, 4), (4, 11), (11, 11)]
    for f in range(3):
        ox = f * 16
        for y in range(16):
            for x in range(16):
                px[y][ox + x] = plate_dark if x in (0, 15) or y in (0, 15) else plate
        for sx, sy in spots:
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    px[sy + dy][ox + sx + dx] = hole
            if f == 1:
                px[sy][ox + sx] = steel_light
            elif f == 2:
                for h in range(4):
                    for dx in range(-(3 - h) // 2, (3 - h) // 2 + 1):
                        x, y = sx + dx, sy + 1 - h
                        px[y][ox + x] = steel_light if dx < 0 else (steel if dx == 0 else steel_dark)
                px[sy + 1][ox + sx - 1] = steel_dark
                px[sy + 1][ox + sx + 1] = steel_dark
    return px


def blade_sheet() -> list[list[tuple]]:
    """32x16: Klingenfalle, links stahlblau (lauert), rechts bronze (pendelt)."""
    colors = [((150, 170, 200, 255), (210, 225, 245, 255), (90, 105, 135, 255)),
              ((190, 140, 70, 255), (240, 200, 130, 255), (120, 80, 35, 255))]
    px = [[(0, 0, 0, 0)] * 32 for _ in range(16)]
    for f, (mid, light, dark) in enumerate(colors):
        ox = f * 16
        for y in range(16):
            for x in range(16):
                cx, cy = x - 7.5, y - 7.5
                spike = (abs(cx) < 1.5 or abs(cy) < 1.5) and max(abs(cx), abs(cy)) <= 7.5
                diag = abs(abs(cx) - abs(cy)) < 1.2 and max(abs(cx), abs(cy)) <= 7
                body = max(abs(cx), abs(cy)) <= 4.5
                if body:
                    edge = max(abs(cx), abs(cy)) > 3.6
                    px[y][ox + x] = OUTLINE if edge else (light if cx + cy < -2 else (dark if cx + cy > 2 else mid))
                elif spike or diag:
                    px[y][ox + x] = light if cx + cy < 0 else dark
        for x, y in [(7, 7), (8, 7), (7, 8), (8, 8)]:
            px[y][ox + x] = OUTLINE
    return px


def crumble_sheet() -> list[list[tuple]]:
    """32x16: rissige Bodenplatte, rechts kurz vor dem Zerfallen."""
    base, light, mortar, crack = (96, 88, 80, 255), (116, 108, 98, 255), (56, 52, 48, 255), (35, 30, 28, 255)
    px = [[base] * 32 for _ in range(16)]
    cracks = [[(3, 3), (4, 4), (5, 4), (6, 5), (9, 9), (10, 10), (10, 11), (12, 6), (12, 7)],
              [(2, 2), (3, 3), (4, 4), (5, 4), (6, 5), (7, 6), (8, 7), (9, 8), (9, 9), (10, 10), (10, 11), (11, 12),
               (12, 6), (12, 7), (13, 8), (4, 10), (5, 11), (6, 11), (3, 12)]]
    for f in range(2):
        ox = f * 16
        for y in range(16):
            for x in range(16):
                if x == 15 or y == 15:
                    px[y][ox + x] = mortar
                elif x == 0 or y == 0:
                    px[y][ox + x] = light
        for x, y in cracks[f]:
            px[y][ox + x] = crack
    return px


BAT_FRAMES = [
    [  # Flügel oben
        "................",
        "..o..........o..",
        ".obo........obo.",
        ".obbo..oo..obbo.",
        "obbbbooddoobbbbo",
        "obbbbbdeedbbbbbo",
        ".obbbbddddbbbbo.",
        "..oo.oddddo.oo..",
        "......oddo......",
        ".......oo.......",
    ],
    [  # Flügel unten
        "................",
        "................",
        "................",
        ".......oo.......",
        "......oddo......",
        "..oooodeedoooo..",
        ".obbbbddddbbbbo.",
        "obbbbbbddbbbbbbo",
        "obbo.obbbbo.obbo",
        ".oo...oooo...oo.",
    ],
    [  # sitzend, Flügel angelegt
        "................",
        "................",
        "................",
        "................",
        "......oooo......",
        ".....obddbo.....",
        "....obdeedbo....",
        "....obddddbo....",
        ".....obddbo.....",
        "......oooo......",
    ],
]


def bat_sheet() -> list[list[tuple]]:
    """48x16: zwei Flügelschläge und sitzend."""
    pal = {".": (0, 0, 0, 0), "o": OUTLINE, "b": (90, 60, 120, 255), "d": (60, 40, 80, 255), "e": (230, 50, 60, 255)}
    px = [[(0, 0, 0, 0)] * 48 for _ in range(16)]
    for f, rows in enumerate(BAT_FRAMES):
        for y, line in enumerate(rows):
            for x, c in enumerate(line):
                px[y + 3][f * 16 + x] = pal[c]
    return px


ARROW = [  # 16x16, zeigt nach rechts
    "................",
    "................",
    "................",
    "................",
    "................",
    "..f.........w...",
    "...f........ww..",
    "..ffssssssssswww",
    "...f........ww..",
    "..f.........w...",
]

SKELETON_FRAMES = [
    [  # stehend
        "................", ".....oooooo.....", "....owwwwwwo....", "....owkwwkwo....", "....owwwwwwo....",
        ".....owkkwo.....", "......owwo......", "....oowwwwoo....", "...owowwwwowo...", "..ow.owwwwo.wo..",
        "..o..owwwwo..o..", ".....ow..wo.....", ".....ow..wo.....", ".....ow..wo.....", "....oo....oo....",
    ],
    [  # Schritt
        "................", ".....oooooo.....", "....owwwwwwo....", "....owkwwkwo....", "....owwwwwwo....",
        ".....owkkwo.....", "......owwo......", "....oowwwwoo....", "...owowwwwowo...", "..ow.owwwwo.wo..",
        "..o..owwwwo..o..", ".....ow..wo.....", "....ow....wo....", "...ow......wo...", "...o........o...",
    ],
    [  # zielt (Bogen vorne)
        "................", ".....oooooo.....", "....owwwwwwo....", "....owkwwkwo....", "....owwwwwwo....",
        ".....owkkwo.....", "......owwo...b..", "....oowwwwoob.b.", "...owowwwwowwb.b", "..ow.owwwwo..b.b",
        "..o..owwwwo...b.", ".....ow..wo.....", ".....ow..wo.....", ".....ow..wo.....", "....oo....oo....",
    ],
]


def arrow_sprite() -> list[list[tuple]]:
    return from_map(ARROW, {"f": (220, 220, 230, 255), "s": (150, 110, 70, 255), "w": (200, 200, 210, 255)})


def skeleton_sheet() -> list[list[tuple]]:
    """48x16: stehend, Schritt, zielend."""
    pal = {".": (0, 0, 0, 0), "o": OUTLINE, "w": (225, 220, 205, 255), "k": (40, 30, 30, 255), "b": (140, 95, 50, 255)}
    px = [[(0, 0, 0, 0)] * 48 for _ in range(16)]
    for f, rows in enumerate(SKELETON_FRAMES):
        for y, line in enumerate(rows):
            for x, c in enumerate(line):
                px[y + 1][f * 16 + x] = pal[c]
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
    write_png(ROOT / "assets" / "tilesets" / "stone_floor.png", stone_floor())
    write_png(ROOT / "assets" / "tilesets" / "dungeon_walls.png", dungeon_walls())
    write_png(out / "pickups" / "big_key.png", from_map(BIG_KEY, {"y": (240, 200, 60, 255), "r": (220, 40, 60, 255)}))
    write_png(out / "objects" / "chest.png", chest())
    write_png(out / "enemies" / "arrow.png", arrow_sprite())
    write_png(out / "enemies" / "skeleton_archer.png", skeleton_sheet())
    write_png(out / "enemies" / "bat.png", bat_sheet())
    write_png(out / "objects" / "spikes.png", spikes_sheet())
    write_png(out / "objects" / "blade_trap.png", blade_sheet())
    write_png(out / "objects" / "crumble_floor.png", crumble_sheet())
    write_png(out / "objects" / "hold_switch.png", hold_switch())
    write_png(out / "objects" / "crystal_switch.png", crystal_sheet())
    write_png(out / "objects" / "save_puddle.png", puddle())
    write_png(out / "objects" / "stairs.png", stairs())
    write_png(out / "objects" / "push_block.png", push_block())
    write_png(out / "pickups" / "orb.png", from_map(ORB, {"b": (120, 90, 230, 255), "w": (220, 210, 255, 255), "p": (70, 40, 150, 255)}, mirror=True))
    write_png(out / "objects" / "shutter_door.png", shutter_door())
    write_png(out / "enemies" / "zombie.png", zombie_sheet())
    write_png(out / "enemies" / "zombie_king.png", zombie_king_sheet())
    write_png(out / "items" / "hint_scroll.png", from_map(SCROLL, {"p": (235, 220, 180, 255), "k": (120, 100, 80, 255)}))
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
