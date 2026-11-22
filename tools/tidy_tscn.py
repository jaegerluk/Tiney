#!/usr/bin/env python3
"""Ordnet eine .tscn-Datei: Kopf, alle ext_resource, alle sub_resource, dann Knoten und Verbindungen.

Aufruf:  python3 tools/tidy_tscn.py datei.tscn [...]
Hilft, wenn Skripte Ressourcen an falscher Stelle eingefügt haben. Godot verlangt diese Reihenfolge.
"""
import sys


def sections(text: str) -> list[str]:
    parts, current = [], []
    for line in text.splitlines():
        if line.startswith("[") and current:
            parts.append("\n".join(current).strip("\n"))
            current = []
        current.append(line)
    if current:
        parts.append("\n".join(current).strip("\n"))
    return [p for p in parts if p.strip()]


def tidy(path: str) -> None:
    parts = sections(open(path, encoding="utf-8").read())
    head = [p for p in parts if p.startswith("[gd_scene") or p.startswith("[gd_resource")]
    ext = [p for p in parts if p.startswith("[ext_resource")]
    sub = [p for p in parts if p.startswith("[sub_resource")]
    rest = [p for p in parts if p not in head and p not in ext and p not in sub]
    out = "\n\n".join(head) + "\n\n" + "\n".join(ext) + "\n\n" + "\n\n".join(sub + rest) + "\n"
    open(path, "w", encoding="utf-8").write(out)
    print("geordnet:", path)


if __name__ == "__main__":
    for p in sys.argv[1:]:
        tidy(p)
