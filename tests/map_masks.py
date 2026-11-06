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


class MapGeometryChecks:
    @classmethod
    def setUpClass(cls):
        cls.folder = ROOT / "Assets/Maps" / cls.profile
        cls.geometry = json.loads((cls.folder / "geometry.json").read_text())
        cls.source = json.loads((ROOT / "Assets/Maps" / cls.manifest).read_text())
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
                                ("eastern", 50, 50)]:
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

class MapMasks(MapGeometryChecks, unittest.TestCase):
    profile = "retail"
    manifest = "regions.json"

    def test_retail_sea_regression(self):
        self.assertEqual(0, self.mask("eastern").getpixel((500, 240)))

    def test_plaguelands_and_alterac_are_not_shifted_into_each_other(self):
        entry = self.geometry["continents"]["eastern"]
        for name, points in {
            "western_plaguelands": [(580, 265), (605, 250), (590, 280), (600, 300)],
            "eastern_plaguelands": [(640, 280), (700, 300), (755, 250), (650, 305), (675, 320)],
            "alterac": [(610, 337), (620, 342)],
            "hillsbrad": [(555, 345), (560, 360), (578, 350), (596, 360), (616, 363)],
            "tirisfal": [(534, 289)],
            "silverpine": [(520, 350), (530, 350), (530, 365)],
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
            "darkshore": [(545, 190), (551, 207), (552, 250)],
            "felwood": [(552, 170), (578, 170), (592, 185), (603, 205), (590, 225), (580, 250)],
        }.items():
            for x, y in points:
                with self.subTest(name=name, x=x, y=y):
                    label = self.fields["kalimdor"][y * self.size[0] + x]
                    self.assertEqual(name, entry["names"][label])

    def test_blackrock_neighbors_keep_their_full_interiors(self):
        entry = self.geometry["continents"]["eastern"]
        for name, points in {
            "searing_gorge": [(562, 550), (578, 546), (595, 540)],
            "blackrock_mountain": [(575, 565)],
            "burning_steppes": [(565, 580), (615, 580), (640, 585)],
            "badlands": [(625, 550), (640, 555)],
            "elwynn": [(550, 585), (570, 610)],
        }.items():
            for x, y in points:
                with self.subTest(name=name, x=x, y=y):
                    label = self.fields["eastern"][y * self.size[0] + x]
                    self.assertGreaterEqual(label, 0)
                    self.assertEqual(name, entry["names"][label])
                    self.assertGreater(self.mask(name).getpixel((x, y)), 127)

    def test_slanted_sea_hatching_is_not_land_or_clickable(self):
        for x, y in [(435, 266), (493, 233), (476, 247), (552, 222)]:
            with self.subTest(x=x, y=y):
                self.assertEqual(0, self.mask("eastern").getpixel((x, y)))
                self.assertEqual(-1, self.fields["eastern"][y * self.size[0] + x])

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
        draw.polygon([(30, 2), (54, 0), (54, 5), (30, 7)], fill=255)
        cleaned = BUILDER.remove_detached_hatching(mask)
        self.assertEqual(0, cleaned.getpixel((12, 2)))
        self.assertEqual(255, cleaned.getpixel((6, 14)))
        self.assertEqual(255, cleaned.getpixel((45, 18)))
        self.assertEqual(0, cleaned.getpixel((42, 4)))

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


class ForeverMapMasks(MapGeometryChecks, unittest.TestCase):
    profile = "forever"
    manifest = "regions-forever.json"

    def test_reviewed_borders_reject_open_edges_and_keep_their_owners(self):
        domain = Image.new("L", (12, 10), 255)
        seeds = {"west": [(2, 5)], "east": [(9, 5)]}
        names, owners = BUILDER.partition_boundaries(domain, seeds, [[[6, 0], [6, 9]]])
        self.assertEqual("west", names[owners[5 * 12 + 5]])
        self.assertEqual("east", names[owners[5 * 12 + 7]])
        self.assertNotIn(-1, owners)
        with self.assertRaisesRegex(ValueError, "Open border joins zones"):
            BUILDER.partition_boundaries(domain, seeds, [[[6, 1], [6, 9]]])
        with self.assertRaisesRegex(ValueError, "Marker outside"):
            BUILDER.partition_boundaries(domain, {"west": [(6, 5)]}, [[[6, 0], [6, 9]]])
        with self.assertRaisesRegex(ValueError, "Unmarked border interior"):
            BUILDER.partition_boundaries(Image.new("L", (24, 24), 255), {"west": [(2, 5)]},
                                         [[[12, 2], [20, 2], [20, 12], [12, 12], [12, 2]]])

    def test_junction_owner_does_not_spread_down_a_neighbors_border(self):
        names, owners = BUILDER.partition_boundaries(
            Image.new("L", (12, 12), 255),
            {"northwest": [(2, 2)], "southwest": [(2, 8)], "east": [(9, 6)]},
            [[[5, 0], [5, 11]], [[0, 4], [5, 4]]],
        )
        for y in range(6, 12):
            self.assertIn(names[owners[y * 12 + 5]], {"southwest", "east"})

    def test_every_reviewed_marker_keeps_its_owner(self):
        for continent, regions in self.source["seeds"].items():
            entry = self.geometry["continents"][continent]
            for name, points in regions.items():
                for x, y in points:
                    with self.subTest(name=name, point=(x, y)):
                        owner = self.fields[continent][y * self.size[0] + x]
                        self.assertGreaterEqual(owner, 0)
                        self.assertEqual(name, entry["names"][owner])
                        if not name.startswith("_"):
                            self.assertGreater(self.mask(name).getpixel((x, y)), 127)

    def test_forever_artwork_and_coast_regressions(self):
        for continent, map_id, texture in [("kalimdor", 1414, 8025526),
                                            ("eastern", 1415, 8023297)]:
            entry = self.geometry["continents"][continent]
            self.assertEqual(map_id, entry["mapID"])
            self.assertEqual(texture, entry["firstTexture"])
            self.assertEqual([1002, 668], entry["artSize"])
        for continent, x, y in [("kalimdor", 390, 170), ("kalimdor", 790, 450),
                                 ("kalimdor", 580, 785), ("eastern", 450, 375),
                                 ("eastern", 700, 700)]:
            self.assertEqual(-1, self.fields[continent][y * self.size[0] + x])
            self.assertEqual(0, self.mask(continent).getpixel((x, y)))

    def test_coastal_land_is_in_the_gray_mask_without_coloring_the_sea(self):
        for continent, name, x, y in [
            ("kalimdor", "stonetalon", 460, 337),
            ("kalimdor", "tanaris", 710, 734),
            ("eastern", "eastern_plaguelands", 746, 191),
            ("eastern", "blasted_lands", 640, 685),
        ]:
            with self.subTest(continent=continent, point=(x, y)):
                entry = self.geometry["continents"][continent]
                owner = self.fields[continent][y * self.size[0] + x]
                self.assertEqual(name, entry["names"][owner])
                self.assertEqual(255, self.mask(continent).getpixel((x, y)))
                self.assertGreater(self.mask(name).getpixel((x, y)), 127)

    def test_forever_boundaries_use_the_new_geography(self):
        probes = {
            "kalimdor": {
                "darkshore": [(551, 217), (547, 266), (616, 155), (616, 170)],
                "felwood": [(587, 207), (574, 262)],
                "moonglade": [(648, 150), (626, 155), (630, 177)],
                "winterspring": [(691, 189), (706, 268), (697, 275), (700, 286), (690, 289)],
                "azshara": [(718, 307), (774, 268), (700, 293), (710, 290)],
                "durotar": [(704, 433), (695, 378)],
                "thousand_needles": [(605, 570), (658, 593), (590, 558), (620, 576)],
                "barrens": [(605, 550), (620, 555), (638, 570), (590, 550), (620, 569)],
            },
            "eastern": {
                "elwynn": [(550, 567)], "westfall": [(498, 614)],
                "duskwood": [(568, 619), (590, 616)], "deadwind": [(610, 615), (614, 616)],
                "swamp_sorrows": [(662, 610)], "blasted_lands": [(648, 658)],
                "dun_morogh": [(541, 481), (560, 434)],
                "searing_gorge": [(574, 491)], "blackrock_mountain": [(578, 517)],
                "burning_steppes": [(619, 529)],
                "tirisfal": [(516, 178), (540, 220), (554, 212), (552, 225)],
                "alterac": [(555, 231)], "silverpine": [(523, 248)],
                "_riverglades": [(704, 527)], "_gilneas": [(481, 314)],
                "_quelthalas": [(742, 82)],
            },
        }
        for continent, regions in probes.items():
            entry = self.geometry["continents"][continent]
            for name, points in regions.items():
                for x, y in points:
                    with self.subTest(name=name, point=(x, y)):
                        owner = self.fields[continent][y * self.size[0] + x]
                        self.assertGreaterEqual(owner, 0)
                        self.assertEqual(name, entry["names"][owner])
                        if not name.startswith("_"):
                            self.assertGreater(self.mask(name).getpixel((x, y)), 127)

    def test_forever_reported_corners_and_adjacent_regions(self):
        probes = {
            "eastern": {
                "tirisfal": [(558, 216), (555, 225)],
                "alterac": [(565, 220)],
                "wetlands": [(680, 380), (675, 395)],
                "loch_modan": [(685, 420), (692, 430)],
                "duskwood": [(592, 615)],
                "deadwind": [(604, 615)],
                "stranglethorn": [(615, 670)],
                "blasted_lands": [(625, 670)],
            },
            "kalimdor": {
                "tanaris": [(680, 743), (688, 746), (698, 737)],
                "thousand_needles": [(680, 630), (700, 620)],
                "silithus": [(540, 752)],
                "ungoro": [(580, 710)],
                "darkshore": [(555, 240)],
                "felwood": [(569, 240)],
                "mulgore": [(546, 515)],
                "feralas": [(516, 515)],
            },
        }
        for continent, regions in probes.items():
            entry = self.geometry["continents"][continent]
            for name, points in regions.items():
                for x, y in points:
                    with self.subTest(name=name, point=(x, y)):
                        owner = self.fields[continent][y * self.size[0] + x]
                        self.assertGreaterEqual(owner, 0)
                        self.assertEqual(name, entry["names"][owner])
                        self.assertGreater(self.mask(name).getpixel((x, y)), 127)
        for continent, x, y in [("kalimdor", 700, 757), ("kalimdor", 600, 740),
                                 ("eastern", 650, 338)]:
            with self.subTest(continent=continent, sea=(x, y)):
                self.assertEqual(0, self.mask(continent).getpixel((x, y)))
                self.assertEqual(-1, self.fields[continent][y * self.size[0] + x])

    def test_shendralas_does_not_borrow_mulgore_or_feralas_unlocks(self):
        entry = self.geometry["continents"]["kalimdor"]
        for name, x, y in [("_shendralas", 530, 510), ("mulgore", 546, 515),
                            ("feralas", 516, 515), ("desolace", 530, 490)]:
            with self.subTest(name=name):
                owner = self.fields["kalimdor"][y * self.size[0] + x]
                self.assertGreaterEqual(owner, 0)
                self.assertEqual(name, entry["names"][owner])
        self.assertNotIn("_shendralas", self.geometry["masks"])
        self.assertEqual(255, self.mask("kalimdor").getpixel((530, 510)))
        for name in ["mulgore", "feralas", "desolace"]:
            self.assertEqual(0, self.mask(name).getpixel((530, 510)))

    def test_loch_silverpine_and_hillsbrad_follow_the_painted_borders(self):
        entry = self.geometry["continents"]["eastern"]
        probes = {
            "silverpine": [(524, 250), (528, 262), (523, 270)],
            "alterac": [(533, 250), (539, 258), (556, 258)],
            "hillsbrad": [(541, 269), (556, 267), (525, 279)],
            "tirisfal": [(512, 213), (515, 232)],
            "dun_morogh": [(624, 423)],
            "loch_modan": [(636, 423), (685, 420), (694, 441), (689, 460)],
            "wetlands": [(676, 392), (657, 402)],
            "badlands": [(687, 475)],
            "_eastern_mountains": [(695, 380), (695, 395), (700, 430), (711, 426)],
        }
        for name, points in probes.items():
            for x, y in points:
                with self.subTest(name=name, point=(x, y)):
                    owner = self.fields["eastern"][y * self.size[0] + x]
                    self.assertGreaterEqual(owner, 0)
                    self.assertEqual(name, entry["names"][owner])
                    self.assertEqual(255, self.mask("eastern").getpixel((x, y)))
                    if not name.startswith("_"):
                        self.assertGreater(self.mask(name).getpixel((x, y)), 127)
        self.assertNotIn("_eastern_mountains", self.geometry["masks"])
        for x, y in probes["_eastern_mountains"]:
            for name in ["loch_modan", "wetlands", "badlands"]:
                self.assertLessEqual(self.mask(name).getpixel((x, y)), 127)
        for x, y in [(746, 427), (474, 255), (563, 305)]:
            self.assertEqual(-1, self.fields["eastern"][y * self.size[0] + x])

    def test_reported_zone_edges_keep_both_neighbors_on_their_painted_sides(self):
        probes = {
            "kalimdor": {
                "ashenvale": [(675, 310), (682, 308)], "azshara": [(690, 308)],
                "darkshore": [(572, 200), (566, 216)], "felwood": [(580, 200), (575, 216)],
                "feralas": [(510, 612), (516, 613)], "silithus": [(510, 619), (516, 619)],
            },
            "eastern": {
                "dun_morogh": [(530, 500), (547, 490)], "searing_gorge": [(556, 490)],
                "badlands": [(639, 460), (655, 462)], "loch_modan": [(646, 451)],
                "eastern_plaguelands": [(660, 140), (634, 151)],
                "western_plaguelands": [(610, 150)],
                "silverpine": [(510, 269), (488, 268), (523, 274)],
                "hillsbrad": [(525, 279)],
            },
        }
        for continent, regions in probes.items():
            entry = self.geometry["continents"][continent]
            for name, points in regions.items():
                for x, y in points:
                    with self.subTest(name=name, point=(x, y)):
                        owner = self.fields[continent][y * self.size[0] + x]
                        self.assertGreaterEqual(owner, 0)
                        self.assertEqual(name, entry["names"][owner])
                        self.assertGreater(self.mask(name).getpixel((x, y)), 127)

    def test_non_playable_land_does_not_borrow_neighboring_unlocks(self):
        entry = self.geometry["continents"]["eastern"]
        for name, zone, points in [
            ("_western_mountains", "dun_morogh", [(530, 515), (520, 520)]),
            ("_quelthalas", "eastern_plaguelands", [(660, 120), (640, 125)]),
            ("_gilneas", "silverpine", [(488, 277), (510, 278)]),
        ]:
            for x, y in points:
                with self.subTest(name=name, point=(x, y)):
                    owner = self.fields["eastern"][y * self.size[0] + x]
                    self.assertGreaterEqual(owner, 0)
                    self.assertEqual(name, entry["names"][owner])
                    self.assertEqual(255, self.mask("eastern").getpixel((x, y)))
                    self.assertEqual(0, self.mask(zone).getpixel((x, y)))
            self.assertNotIn(name, self.geometry["masks"])
        for x, y in [(476, 250), (700, 700), (450, 375)]:
            self.assertEqual(-1, self.fields["eastern"][y * self.size[0] + x])

    def test_cropped_classic_tiles_keep_native_pixel_spacing(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory)
            (source / "c60").mkdir()
            for index in range(12):
                Image.new("RGB", (256, 256), (index + 1, 0, 0)).save(
                    source / "c60" / ("c60" + str(index + 1) + ".blp"), format="PNG")
            image = BUILDER.artwork(source, {"directory": "c60", "tiles": [4, 3],
                                            "size": [1002, 668], "tileSize": [256, 256]}, (1002, 668))
            for point, value in [((255, 0), 1), ((256, 0), 2), ((0, 256), 5), ((1001, 667), 12)]:
                self.assertEqual(value, image.getpixel(point)[0])


if __name__ == "__main__":
    unittest.main()
