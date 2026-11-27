#!/usr/bin/env python3
"""Hilfen zum Erzeugen von Raumszenen (.tscn) für Tiney aus Python.

Wände und Boden werden als TileMapLayer mit assets/tilesets/basic_tileset.tres geschrieben
(Quelle 0 = Steinboden, Quelle 1 = Wand mit Kollision). Rechtecke in Pixeln, Vielfache von 16.
"""
import random
import struct


def tile_bytes(cells: list[tuple[int, int, int, int]]) -> str:
    """cells: (x, y, source, atlas_x) -> Inhalt für PackedByteArray(...)."""
    data = struct.pack("<H", 0)
    for x, y, source, atlas_x in cells:
        data += struct.pack("<hhHHHH", x, y, source, atlas_x, 0, 0)
    return ", ".join(map(str, data))


def floor_cells(w_tiles: int, h_tiles: int, seed: int) -> list:
    rnd = random.Random(seed)
    cells = []
    for y in range(h_tiles):
        for x in range(w_tiles):
            r = rnd.random()
            v = 0 if r < 0.76 else (1 if r < 0.84 else (2 if r < 0.92 else 3))
            cells.append((x, y, 0, v))
    return cells


def wall_cells(rects: list[tuple[int, int, int, int]], seed: int) -> list:
    rnd = random.Random(seed)
    seen = set()
    for x, y, w, h in rects:
        assert x % 16 == 0 and y % 16 == 0 and w % 16 == 0 and h % 16 == 0, (x, y, w, h)
        for cy in range(y // 16, (y + h) // 16):
            for cx in range(x // 16, (x + w) // 16):
                seen.add((cx, cy))
    return [(cx, cy, 1, 1 if rnd.random() < 0.15 else 0) for cx, cy in sorted(seen, key=lambda c: (c[1], c[0]))]


class RoomScene:
    """Baut eine Raumszene: Room-Wurzel, Boden, Wände, Kamera-Marker, Eingänge, beliebige Knoten."""

    def __init__(self, root_name: str, dungeon: str, size: tuple[int, int], seed: int = 1):
        self.root_name, self.dungeon, self.size, self.seed = root_name, dungeon, size, seed
        self.ext: dict[str, tuple[str, str]] = {}
        self.sub: list[str] = []
        self.nodes: list[str] = []
        self.conns: list[str] = []
        self.walls: list[tuple] = []
        self.root_props: list[str] = []  # zusätzliche Eigenschaften der Room-Wurzel, z. B. "screen_scroll = false"
        self.res("Script", "res://world/room.gd")
        self.res("TileSet", "res://assets/tilesets/basic_tileset.tres")

    def res(self, kind: str, path: str) -> str:
        if path not in self.ext:
            self.ext[path] = (kind, "r%d" % (len(self.ext) + 1))
        return 'ExtResource("%s")' % self.ext[path][1]

    def shape(self, sid: str, w: int, h: int) -> str:
        self.sub.append('[sub_resource type="RectangleShape2D" id="%s"]\nsize = Vector2(%d, %d)' % (sid, w, h))
        return 'SubResource("%s")' % sid

    def node(self, header: str, *props: str) -> None:
        self.nodes.append("\n".join([header, *props]))

    def inst(self, name: str, scene: str, pos: tuple, *props: str, parent: str = ".") -> None:
        self.node('[node name="%s" parent="%s" instance=%s]' % (name, parent, self.res("PackedScene", scene)),
                  "position = Vector2(%d, %d)" % pos, *props)

    def entry(self, name: str, pos: tuple, facing: tuple) -> None:
        self.node('[node name="%s" type="Marker2D" parent="Entries"]' % name, "position = Vector2(%d, %d)" % pos,
                  "script = " + self.res("Script", "res://world/room_entry.gd"), "facing = Vector2%s" % (facing,))

    def exit(self, name: str, pos: tuple, size: tuple, target: str, entry: str) -> None:
        self.inst(name, "res://objects/room_exit/room_exit.tscn", pos, 'target_room = "%s"' % target, 'target_entry = &"%s"' % entry)
        self.node('[node name="CollisionShape2D" parent="%s"]' % name, "shape = " + self.shape("Shape_" + name, *size))

    def write(self, path: str) -> None:
        w, h = self.size
        tileset = self.res("TileSet", "res://assets/tilesets/basic_tileset.tres")
        root = ['[node name="%s" type="Node2D" node_paths=PackedStringArray("camera_top_left", "camera_bottom_right")]' % self.root_name,
                "y_sort_enabled = true", "script = " + self.res("Script", "res://world/room.gd"),
                'dungeon_id = &"%s"' % self.dungeon, *self.root_props,
                'camera_top_left = NodePath("CameraBounds/TopLeft")', 'camera_bottom_right = NodePath("CameraBounds/BottomRight")']
        fixed = [
            '[node name="Floor" type="TileMapLayer" parent="."]\nz_index = -10\ntile_map_data = PackedByteArray(%s)\ntile_set = %s'
            % (tile_bytes(floor_cells(w // 16, h // 16, self.seed)), tileset),
            '[node name="Walls" type="TileMapLayer" parent="."]\nz_index = -5\ntile_map_data = PackedByteArray(%s)\ntile_set = %s'
            % (tile_bytes(wall_cells(self.walls, self.seed + 100)), tileset),
            '[node name="CameraBounds" type="Node2D" parent="."]',
            '[node name="TopLeft" type="Marker2D" parent="CameraBounds"]',
            '[node name="BottomRight" type="Marker2D" parent="CameraBounds"]\nposition = Vector2(%d, %d)' % (w, h),
            '[node name="Entries" type="Node2D" parent="."]',
        ]
        ext_lines = ['[ext_resource type="%s" path="%s" id="%s"]' % (k, p, i) for p, (k, i) in self.ext.items()]
        out = ["[gd_scene format=3]", "\n".join(ext_lines)] + self.sub + ["\n".join(root)] + fixed + self.nodes + self.conns
        with open(path, "w", encoding="utf-8") as f:
            f.write("\n\n".join(out) + "\n")
        print("geschrieben:", path)
