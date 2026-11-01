"""Build Retail fallback shading masks from the authored region outlines."""

import re
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SIZE = 128


def contains(points, x, y):
    inside = False
    previous = points[-1]
    for current in points:
        xi, yi = current
        xj, yj = previous
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi:
            inside = not inside
        previous = current
    return inside


def main():
    source = (ROOT / "Compatibility/Maps.lua").read_text()
    regions = source.split("local retailRegions = {", 1)[1].split("\n}\n", 1)[0]
    output = ROOT / "Assets/Maps"
    output.mkdir(parents=True, exist_ok=True)
    for name, body in re.findall(r"    (\w+) = \{(.*?)\n    \},", regions, re.S):
        numbers = [float(value) for value in re.findall(r"\d+\.\d+", body)]
        points = list(zip(numbers[2::2], numbers[3::2]))
        xs, ys = zip(*points)
        left, right, top, bottom = min(xs), max(xs), min(ys), max(ys)
        pixels = bytearray()
        for row in range(SIZE):
            for column in range(SIZE):
                x = left + (column + 0.5) / SIZE * (right - left)
                y = top + (row + 0.5) / SIZE * (bottom - top)
                pixels.extend((110, 110, 110, 220 if contains(points, x, y) else 0))
        # Uncompressed BGRA, top-left origin, eight alpha bits.
        header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, SIZE, SIZE, 32, 40)
        (output / (name + ".tga")).write_bytes(header + pixels)


if __name__ == "__main__":
    main()
