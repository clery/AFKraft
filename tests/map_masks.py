"""Artwork mask regressions. Run with python3 tests/map_masks.py."""

import re
import unittest
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


class MapMasks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source = (ROOT / "Compatibility/MapMasks.lua").read_text()
        cls.bounds = {
            key: [float(value) for value in values.split(",") if value.strip()]
            for key, values in re.findall(
                r'(\w+) = \{\s*continent = "[^"]+",\s*bounds = \{([^}]+)\}', source
            )
        }

    def alpha(self, key, x, y):
        left, top, right, bottom = self.bounds[key]
        x, y = x / 1200, y / 800
        if not (left <= x < right and top <= y < bottom):
            return 0
        with Image.open(ROOT / "Assets/Maps" / (key + ".tga")) as image:
            pixel = (int((x - left) / (right - left) * image.width),
                     int((y - top) / (bottom - top) * image.height))
            return image.getchannel("A").getpixel(pixel)

    def test_sea_and_decorations_remain_unmasked(self):
        for key, x, y in [("kalimdor", 150, 500), ("kalimdor", 20, 30),
                          ("kalimdor", 510, 5), ("eastern", 900, 500),
                          ("eastern", 50, 50)]:
            with self.subTest(key=key, x=x, y=y):
                self.assertEqual(0, self.alpha(key, x, y))

    def test_land_and_previously_missing_zone_edges_are_covered(self):
        for key, x, y in [("kalimdor", 600, 600), ("kalimdor", 510, 70),
                          ("eastern", 650, 300), ("elwynn", 535, 640),
                          ("barrens", 610, 365), ("durotar", 712, 416)]:
            with self.subTest(key=key, x=x, y=y):
                self.assertGreater(self.alpha(key, x, y), 200)

    def test_every_descriptor_has_a_client_compatible_alpha_texture(self):
        self.assertEqual(14, len(self.bounds))
        for key in self.bounds:
            with self.subTest(key=key):
                with Image.open(ROOT / "Assets/Maps" / (key + ".tga")) as image:
                    self.assertEqual("RGBA", image.mode)
                    self.assertEqual(0, image.width & (image.width - 1))
                    self.assertEqual(0, image.height & (image.height - 1))


if __name__ == "__main__":
    unittest.main()
