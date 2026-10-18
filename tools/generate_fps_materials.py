#!/usr/bin/env python3
"""Rebuild the four original, tileable FPS maps with Python's standard library."""
import hashlib
import json
import math
from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1] / "assets/fps"
SIZE = 128


def write_png(path, pixels):
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
    rows = b"".join(b"\0" + bytes(pixels[y * SIZE:(y + 1) * SIZE]) for y in range(SIZE))
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 0, 0, 0, 0))
                     + chunk(b"IDAT", zlib.compress(rows, 9)) + chunk(b"IEND", b""))


def generate():
    target = ROOT / "textures"
    target.mkdir(parents=True, exist_ok=True)
    for family in ["glove", "cloth"]:
        albedo, roughness = [], []
        for y in range(SIZE):
            for x in range(SIZE):
                u, v = x / SIZE, y / SIZE
                if family == "glove":
                    seam = min((x + y) % 32, (x - y) % 32) < 3
                    value, rough = (195, 245) if seam else (245, 222)
                else:
                    warp = math.cos(math.tau * u * 8)
                    weft = math.cos(math.tau * v * 8)
                    value, rough = 235 + 8 * warp + 5 * weft, 242 + 5 * warp
                albedo.append(round(value))
                roughness.append(round(rough))
        write_png(target / f"{family}_albedo.png", albedo)
        write_png(target / f"{family}_roughness.png", roughness)
    manifest = {path.name: {"sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "width": SIZE,
                           "height": SIZE, "source_format": "grayscale8"} for path in sorted(target.glob("*.png"))}
    (ROOT / "textures.json").write_text(json.dumps(manifest, indent=2) + "\n")


if __name__ == "__main__":
    generate()
