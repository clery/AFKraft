"""Shared map partition regressions. Run with python3 tests/map_masks.py."""

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("map_builder", ROOT / "scripts/prepare_map_masks.py")
BUILDER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BUILDER)


def pixels(image):
    return image.get_flattened_data() if hasattr(image, "get_flattened_data") else image.getdata()


class MapMasks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.folder = ROOT / "Assets/Maps/retail"
        cls.geometry = json.loads((cls.folder / "geometry.json").read_text())
        cls.source = json.loads((ROOT / "Assets/Maps/regions.json").read_text())
        cls.size = tuple(cls.geometry["canvas"])
        cls.fields = {}
        for continent, entry in cls.geometry["continents"].items():
            decoded = []
            for row in entry["rows"]:
                values = []
                for run in row.split(","):
                    length, label = map(int, run.split(":"))
                    values.extend([label - 1] * length)
                assert len(values) == cls.size[0]
                decoded.extend(values)
            cls.fields[continent] = decoded

    def mask(self, key):
        descriptor = self.geometry["masks"][key]
        left, top, right, bottom = descriptor["bounds"]
        x, y, end_x, end_y = [round(value * scale) for value, scale in
                              zip((left, top, right, bottom), self.size * 2)]
        result = Image.new("L", self.size)
        with Image.open(self.folder / (key + ".tga")) as image:
            self.assertNotIn("texCoord", descriptor)
            # Model native full-texture projection, without any mask UV cropping.
            self.assertEqual((end_x - x, end_y - y), image.size)
            result.paste(image.getchannel("A"), (x, y))
        return result

    def test_every_destination_has_geometry_and_an_interior_center(self):
        destinations = {name for regions in self.source["seeds"].values()
                        for name in regions if not name.startswith("_")}
        self.assertEqual(41, len(destinations))
        self.assertEqual(destinations | {"kalimdor", "eastern"}, set(self.geometry["masks"]))
        for continent, entry in self.geometry["continents"].items():
            for name, (x, y) in entry["centers"].items():
                with self.subTest(name=name):
                    label = self.fields[continent][int(y) * self.size[0] + int(x)]
                    self.assertEqual(name, entry["names"][label])
                    self.assertGreater(self.mask(name).getpixel((int(x), int(y))), 120)

    def test_destination_masks_cover_regions_instead_of_decorative_icons(self):
        # Water-heavy Thousand Needles and the small Blackrock hub legitimately
        # have little land. Ordinary zones must not collapse to a lake/city icon.
        minimum = {"thousand_needles": 150, "blackrock_mountain": 250, "deadwind": 250}
        for continent, entry in self.geometry["continents"].items():
            for name in entry["centers"]:
                with self.subTest(name=name):
                    area = sum(alpha > 127 for alpha in self.mask(name).tobytes())
                    self.assertGreater(area, minimum.get(name, 500))

    def test_masks_never_tint_water_and_match_their_shared_owner_field(self):
        for continent, entry in self.geometry["continents"].items():
            land = self.mask(continent)
            self.assertEqual({0, 255}, set(land.tobytes()))
            for name in entry["centers"]:
                with self.subTest(name=name):
                    mask = self.mask(name)
                    self.assertIsNone(ImageChops.subtract(mask, land).getbbox())
                    label = entry["names"].index(name)
                    # Every opaque mask pixel belongs to this region. Antialiasing
                    # can touch its immediate neighbor but cannot color its interior.
                    for owner, alpha in zip(self.fields[continent], mask.tobytes()):
                        if alpha > 127:
                            self.assertEqual(label, owner)

    def test_no_holes_or_overlaps_in_any_region_interior(self):
        for continent, entry in self.geometry["continents"].items():
            field = self.fields[continent]
            total = [0] * len(field)
            for name in entry["centers"]:
                data = self.mask(name).tobytes()
                for index, alpha in enumerate(data):
                    total[index] += alpha
            supported = {entry["names"].index(name) for name in entry["centers"]}
            land = self.mask(continent).tobytes()
            width, height = self.size
            for y in range(1, height - 1):
                for x in range(1, width - 1):
                    index = y * width + x
                    owner = field[index]
                    if owner in supported and land[index] and all(field[p] in supported and land[p] for p in
                                                   (index - 1, index + 1, index - width, index + width)):
                        self.assertLessEqual(abs(total[index] - 255), 4)
                    self.assertLessEqual(total[index], 259)

    def test_sea_and_parchment_are_unmasked(self):
        for continent, x, y in [("kalimdor", 150, 500), ("kalimdor", 20, 30),
                                ("kalimdor", 440, 80), ("eastern", 900, 500),
                                ("eastern", 50, 50), ("eastern", 500, 240)]:
            with self.subTest(continent=continent, x=x, y=y):
                self.assertEqual(0, self.mask(continent).getpixel((x, y)))

    def test_client_texture_format_and_transparent_padding(self):
        for key in self.geometry["masks"]:
            with self.subTest(key=key), Image.open(self.folder / (key + ".tga")) as image:
                self.assertEqual("RGBA", image.mode)
                self.assertEqual(0, image.width & (image.width - 1))
                self.assertEqual(0, image.height & (image.height - 1))
                alpha = image.getchannel("A").tobytes()
                for channel in image.split()[:3]:
                    self.assertEqual(alpha, channel.tobytes())
                self.assertEqual(0, image.getchannel("A").getpixel((image.width - 1, image.height - 1)))

    def test_generator_uses_one_partition_and_preserves_offshore_components(self):
        image = Image.new("RGB", (32, 20), (150, 120, 60))
        land = Image.new("L", image.size)
        for y in range(2, 18):
            for x in range(2, 28):
                land.putpixel((x, y), 255)
        land.putpixel((30, 10), 255)
        names, labels = BUILDER.partition(image, land, {"west": [(5, 10)], "east": [(24, 10)]})
        self.assertEqual(["west", "east"], names)
        self.assertEqual(1, labels[10 * 32 + 30])
        self.assertTrue(all((label >= 0) == bool(value) for label, value in zip(labels, land.tobytes())))
        self.assertEqual(BUILDER.rows_for_labels(labels, 32, 20),
                         BUILDER.rows_for_labels(BUILDER.partition(image, land,
                             {"west": [(5, 10)], "east": [(24, 10)]})[1], 32, 20))

    def test_plaguelands_and_alterac_are_not_shifted_into_each_other(self):
        entry = self.geometry["continents"]["eastern"]
        for name, points in {
            "western_plaguelands": [(590, 280), (600, 300)],
            "eastern_plaguelands": [(640, 280), (700, 300), (755, 250)],
            "alterac": [(610, 337), (620, 342)],
            "hillsbrad": [(596, 360), (616, 363)],
            "tirisfal": [(534, 289)],
            "silverpine": [(520, 350), (550, 350)],
            "hinterlands": [(650, 350)],
        }.items():
            for x, y in points:
                with self.subTest(name=name, x=x, y=y):
                    label = self.fields["eastern"][y * self.size[0] + x]
                    self.assertEqual(name, entry["names"][label])
                    self.assertGreater(self.mask(name).getpixel((x, y)), 127)

    def test_deadwind_corridor_is_distinct_from_both_neighbors(self):
        entry = self.geometry["continents"]["eastern"]
        for name, points in {
            "duskwood": [(588, 655), (595, 670)],
            "deadwind": [(595, 650), (603, 663), (607, 679)],
            "swamp_sorrows": [(625, 650), (648, 655), (655, 666)],
            "blasted_lands": [(620, 690), (627, 710), (646, 698)],
            "stranglethorn": [(595, 700)],
        }.items():
            for x, y in points:
                with self.subTest(name=name, x=x, y=y):
                    label = self.fields["eastern"][y * self.size[0] + x]
                    self.assertEqual(name, entry["names"][label])
                    self.assertGreater(self.mask(name).getpixel((x, y)), 127)

        # The pass ends above the southern regions, rather than following a
        # decorative path down Blasted Lands' western edge.
        deadwind = entry["names"].index("deadwind")
        self.assertNotIn(deadwind, self.fields["eastern"][690 * self.size[0]:])

    def test_darkshore_and_felwood_keep_their_sides_of_the_northern_border(self):
        entry = self.geometry["continents"]["kalimdor"]
        for name, points in {
            "darkshore": [(552, 170), (578, 170), (560, 194), (552, 250)],
            "felwood": [(592, 185), (603, 205), (590, 225), (580, 250)],
        }.items():
            for x, y in points:
                with self.subTest(name=name, x=x, y=y):
                    label = self.fields["kalimdor"][y * self.size[0] + x]
                    self.assertEqual(name, entry["names"][label])

    def test_every_non_land_hit_is_explicitly_reviewed_inland_water(self):
        for continent, entry in self.geometry["continents"].items():
            land = self.mask(continent).tobytes()
            water = {entry["names"].index(name): BUILDER.polygon_mask(self.size, outlines).tobytes()
                     for name, outlines in self.source.get("inlandWater", {}).get(continent, {}).items()}
            for index, owner in enumerate(self.fields[continent]):
                if owner >= 0 and not land[index]:
                    self.assertTrue(owner in water and water[owner][index],
                                    (continent, index % self.size[0], index // self.size[0], entry["names"][owner]))
        entry = self.geometry["continents"]["kalimdor"]
        self.assertEqual(-1, self.fields["kalimdor"][205 * self.size[0] + 536])
        self.assertEqual("thousand_needles", entry["names"][self.fields["kalimdor"][566 * self.size[0] + 628]])

    def test_detached_sea_hatching_is_not_land_or_a_click_target(self):
        mask = Image.new("L", (64, 32))
        from PIL import ImageDraw
        draw = ImageDraw.Draw(mask)
        draw.rectangle((2, 2, 25, 3), fill=255)
        draw.rectangle((4, 12, 9, 17), fill=255)
        draw.rectangle((30, 10, 60, 28), fill=255)
        cleaned = BUILDER.remove_detached_hatching(mask)
        self.assertEqual(0, cleaned.getpixel((12, 2)))
        self.assertEqual(255, cleaned.getpixel((6, 14)))
        self.assertEqual(255, cleaned.getpixel((45, 18)))

    def test_propagation_margins_are_not_clickable_and_water_cannot_borrow_an_owner(self):
        from array import array
        land = Image.new("L", (8, 4))
        land.putpixel((1, 1), 255)
        owners = array("h", [0] * 32)
        owners[1 * 8 + 6] = 1
        outlines = {"lake": [[[4, 0], [7, 0], [7, 3], [4, 3]]]}
        clipped = BUILDER.clip_click_regions(owners, ["lake", "coast"], land, outlines)
        self.assertEqual(0, clipped[1 * 8 + 1])
        self.assertEqual(-1, clipped[1 * 8 + 2])
        self.assertEqual(0, clipped[1 * 8 + 5])
        self.assertEqual(-1, clipped[1 * 8 + 6])
        with self.assertRaises(ValueError):
            BUILDER.clip_click_regions(owners, ["lake", "coast"], land, {"unknown": outlines["lake"]})

    def test_native_import_rejects_wrong_artwork_and_malformed_runs(self):
        expected = {"profile": "forever", "mapID": 1414, "size": [1024, 768], "firstTexture": 123}
        source = {"mapID": 1414, "artSize": [1024, 768], "firstTexture": 123, "size": [16, 16],
                  "names": ["elwynn"], "rows": [[[16, 0]] for _ in range(16)]}
        data = {"version": 1, "profile": "forever", "continents": {"kalimdor": source}}
        names, labels = BUILDER.native_labels(data, "kalimdor", (32, 32), expected)
        self.assertEqual(["elwynn"], names)
        self.assertEqual({0}, set(labels))
        data["profile"] = "retail"
        with self.assertRaises(ValueError):
            BUILDER.native_labels(data, "kalimdor", (32, 32), expected)
        data["profile"] = "forever"
        source["rows"][0] = [[17, 0]]
        with self.assertRaises(ValueError):
            BUILDER.native_labels(data, "kalimdor", (32, 32), expected)

    def test_power_of_two_padding_does_not_resample_mask_geometry(self):
        mask = Image.new("L", (19, 17))
        mask.putpixel((9, 8), 255)
        with tempfile.TemporaryDirectory() as directory:
            descriptor = BUILDER.save_mask(Path(directory), "dot", mask)
            with Image.open(Path(directory) / "dot.tga") as image:
                self.assertEqual((4, 4), image.size)
                self.assertEqual(255, image.getchannel("A").getpixel((1, 1)))
                self.assertNotIn("texCoord", descriptor)
                left, top, right, bottom = descriptor["bounds"]
                self.assertAlmostEqual(4 / 19, right - left)
                self.assertAlmostEqual(4 / 17, bottom - top)
                self.assertEqual((0, 0, 0, 0), image.getpixel((3, 3)))


if __name__ == "__main__":
    unittest.main()
