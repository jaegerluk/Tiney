#!/usr/bin/env python3
"""Erzeugt world/test_area/test_hall.tscn: große Halle (3×2 Bildschirme) mit mitlaufender Kamera."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from room_builder import RoomScene  # noqa: E402

W, H = 768, 448
room = RoomScene("TestHall", "test", (W, H), seed=7)
room.root_props = ["screen_scroll = false", "map_position = Vector2i(1, -2)"]

# Außenwände, unten eine Öffnung (x 112–144) zum Startraum
room.walls += [(0, 0, W, 16), (0, 0, 16, H), (W - 16, 0, 16, H), (0, H - 16, 112, 16), (144, H - 16, W - 144, 16)]
# Säulen als Deckung und ein Mittelblock
room.walls += [(192, 128, 32, 32), (544, 128, 32, 32), (192, 288, 32, 32), (544, 288, 32, 32), (352, 192, 64, 64)]

room.entry("from_test_area", (128, 416), (0, -1))
room.exit("ExitToTestArea", (128, 444), (32, 8), "res://world/test_area/test_area.tscn", "from_hall")

room.inst("SaveStatue", "res://objects/save_statue/save_statue.tscn", (64, 360))
room.inst("HeartChest", "res://objects/chest/chest.tscn", (712, 48),
          "content = " + room.res("PackedScene", "res://items/pickups/heart_container.tscn"))

for i, pos in enumerate([(400, 100), (600, 360)]):
    room.inst("Zombie%d" % (i + 1), "res://enemies/zombie/zombie.tscn", pos)
for i, pos in enumerate([(300, 330), (660, 220)]):
    room.inst("Slime%d" % (i + 1), "res://enemies/slime/slime.tscn", pos)
room.inst("Archer1", "res://enemies/archer/archer.tscn", (500, 72))
for i, pos in enumerate([(260, 160), (460, 360)]):
    room.inst("Bat%d" % (i + 1), "res://enemies/bat/bat.tscn", pos)

for i, x in enumerate((40, 56, 72)):
    room.inst("Pot%d" % (i + 1), "res://objects/breakable/pot.tscn", (x, 40))
for i, (x, y) in enumerate([(672, 376), (688, 376), (704, 376), (672, 392), (688, 392), (704, 392)]):
    room.inst("Grass%d" % (i + 1), "res://objects/breakable/grass.tscn", (x, y))
for i, x in enumerate((384, 400)):
    room.inst("Stone%d" % (i + 1), "res://objects/breakable/stone.tscn", (x, 400))

room.write(str(Path(__file__).resolve().parents[2] / "world/test_area/test_hall.tscn"))
