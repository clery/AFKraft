"""Partition client continent artwork into seamless destination masks.

Only Pillow and the Python standard library are required. Client textures and
optional native map-query exports are supplied separately, never downloaded.
"""

import argparse
from array import array
from collections import deque
import heapq
import json
import math
import re
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]


def polygon_mask(size, outlines):
    image = Image.new("L", size)
    draw = ImageDraw.Draw(image)
    for outline in outlines:
        draw.polygon([tuple(point) for point in outline], fill=255)
    return image


def artwork(source, spec, size):
    """Use the same unlabeled title tiles as the addon, at the client's aspect."""
    name = spec["directory"]
    columns, rows = spec["tiles"]
    image = Image.new("RGB", tuple(spec["size"]))
    tile_width = math.ceil(image.width / columns)
    tile_height = math.ceil(image.height / rows)
    for index in range(columns * rows):
        tile = source / name / (name + str(index + 1) + ".blp")
        row, column = divmod(index, columns)
        # Match Client.MapTileTexture, retaining the original sea and decorations.
        if columns == 15 and rows == 10 and 5 <= column <= 9 and (
            (name == "kalimdor" and row == 4)
            or (name == "easternkingdoms" and row in (6, 7))
        ):
            alternative = source.parent / "adventuremap" / name / (name + "taxi" + str(index) + ".blp")
            if alternative.exists():
                tile = alternative
        with Image.open(tile) as part:
            image.paste(part.convert("RGB"), (column * tile_width, row * tile_height))
    return image.resize(size, Image.Resampling.LANCZOS)


def fill_holes(mask):
    flooded = mask.copy()
    ImageDraw.floodfill(flooded, (0, 0), 128)
    return flooded.point(lambda value: 0 if value == 128 else 255)


def land_mask(image, outlines, caps):
    """Trace the actual coast by chroma; coarse guides exclude warm parchment.

    Guides do not define destination edges. In particular, do not dilate the
    classified shore or force island guide polygons opaque: both tint seawater.
    """
    original = polygon_mask(image.size, outlines)
    guide = original.filter(ImageFilter.MaxFilter(41))
    capped = original.filter(ImageFilter.MaxFilter(5))
    for box in caps:
        guide.paste(capped.crop(tuple(box)), tuple(box[:2]))
    warm = Image.new("L", image.size)
    pixels = image.tobytes()
    warm.putdata([255 if (pixels[i] - pixels[i + 2] > 70
                         or (pixels[i + 1] - pixels[i + 2] > 45 and pixels[i + 1] > pixels[i]))
                  else 0 for i in range(0, len(pixels), 3)])
    result = ImageChops.multiply(guide, warm)
    # Remove thin sea hatching that shares the land palette near a coast.
    result = result.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))
    # Close tiny texture-grain interruptions, without the old seven-pixel halo.
    result = result.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))
    return ImageChops.multiply(fill_holes(result), guide)


def partition(image, land, seeds):
    """Multi-source geodesic watershed, following dark painted boundary strokes.

    All destinations and excluded regions compete in ONE label field. A pixel
    has exactly one owner, so independently traced polygons cannot overlap or
    leave cracks. Only thin dark strokes are expensive; gradual terrain shading
    and different biome colors do not act as arbitrary borders.
    """
    width, height = image.size
    count = width * height
    allowed = land.tobytes()
    luminance = image.convert("L")
    smooth = luminance.filter(ImageFilter.GaussianBlur(5)).tobytes()
    raw = luminance.tobytes()
    ridge = [max(0, local - pixel) for pixel, local in zip(raw, smooth)]
    labels = array("h", [-1]) * count
    distance = array("d", [float("inf")]) * count
    names = list(seeds)
    queue = []
    for label, name in enumerate(names):
        for x, y in seeds[name]:
            if not (0 <= x < width and 0 <= y < height and allowed[y * width + x]):
                raise ValueError("Seed is outside land: " + name + " " + str((x, y)))
            pixel = y * width + x
            if labels[pixel] >= 0 and labels[pixel] != label:
                raise ValueError("Conflicting region seeds")
            labels[pixel], distance[pixel] = label, 0
            heapq.heappush(queue, (0, pixel, label))
    while queue:
        cost, pixel, label = heapq.heappop(queue)
        if cost != distance[pixel]:
            continue
        x = pixel % width
        neighbors = [pixel - width, pixel + width]
        if x:
            neighbors.append(pixel - 1)
        if x + 1 < width:
            neighbors.append(pixel + 1)
        for neighbor in neighbors:
            if not 0 <= neighbor < count or not allowed[neighbor]:
                continue
            candidate = cost + 1 + ridge[neighbor] ** 4 / 30
            if candidate < distance[neighbor]:
                labels[neighbor], distance[neighbor] = label, candidate
                heapq.heappush(queue, (candidate, neighbor, label))
    # Small offshore components without a marker inherit the nearest region.
    # Process each whole component once; never leave an isolated island gray by
    # accident or split it between unrelated zones due to raster iteration order.
    unclaimed = {pixel for pixel, value in enumerate(allowed) if value and labels[pixel] < 0}
    points = [(x, y, label) for label, name in enumerate(names) for x, y in seeds[name]]
    while unclaimed:
        first = min(unclaimed)
        pending, component = deque([first]), []
        unclaimed.remove(first)
        while pending:
            pixel = pending.popleft()
            component.append(pixel)
            x = pixel % width
            for neighbor in (pixel - width, pixel + width,
                             pixel - 1 if x else -1,
                             pixel + 1 if x + 1 < width else -1):
                if neighbor in unclaimed:
                    unclaimed.remove(neighbor)
                    pending.append(neighbor)
        cx = sum(pixel % width for pixel in component) / len(component)
        cy = sum(pixel // width for pixel in component) / len(component)
        label = min(points, key=lambda p: (p[0] - cx) ** 2 + (p[1] - cy) ** 2)[2]
        for pixel in component:
            labels[pixel] = label
    return names, labels


def native_labels(data, continent, size, expected_art):
    """Read an explicit client export; never import another client's coordinates."""
    if data.get("version") != 1 or data.get("profile") != expected_art["profile"]:
        raise ValueError("Client export profile/version does not match the requested profile")
    source = data["continents"][continent]
    if (source["mapID"] != expected_art["mapID"] or source["artSize"] != expected_art["size"]
            or source.get("firstTexture") != expected_art["firstTexture"]):
        raise ValueError("Client export artwork does not match the supplied textures")
    width, height = source["size"]
    if not (16 <= width <= 1200 and 16 <= height <= 800) or len(source["rows"]) != height:
        raise ValueError("Invalid client export dimensions")
    names = source["names"]
    if (len(names) != len(set(names)) or len(names) > 32767
            or any(not isinstance(name, str) or not re.fullmatch(r"[a-z_][a-z0-9_]*", name) for name in names)):
        raise ValueError("Invalid client export region names")
    labels = Image.new("I", (width, height), -1)
    decoded = []
    for row in source["rows"]:
        total = 0
        for length, label in row:
            if not isinstance(length, int) or length < 1 or not isinstance(label, int) or not -1 <= label < len(names):
                raise ValueError("Invalid client export run")
            total += length
            if total > width:
                raise ValueError("Client export row overflows")
            decoded.extend([label] * length)
        if total != width:
            raise ValueError("Client export row has the wrong width")
    labels.putdata(decoded)
    labels = labels.resize(size, Image.Resampling.NEAREST)
    return names, array("h", list(labels.get_flattened_data() if hasattr(labels, "get_flattened_data") else labels.getdata()))


def rows_for_labels(labels, width, height):
    """Compact lossless lookup shared by hit testing and the color masks."""
    rows = []
    for y in range(height):
        row = labels[y * width:(y + 1) * width]
        runs, previous, length = [], row[0], 0
        for label in row:
            if label != previous:
                runs.append(f"{length}:{previous + 1}")
                previous, length = label, 0
            length += 1
        runs.append(f"{length}:{previous + 1}")
        rows.append(",".join(runs))
    return rows


def save_mask(output, key, mask):
    box = mask.getbbox()
    if not box:
        raise ValueError("Empty map mask: " + key)
    left, top, right, bottom = box
    left, top = max(0, left - 1), max(0, top - 1)
    right, bottom = min(mask.width, right + 1), min(mask.height, bottom + 1)
    cropped = mask.crop((left, top, right, bottom))
    width = 2 ** math.ceil(math.log2(cropped.width))
    height = 2 ** math.ceil(math.log2(cropped.height))
    # Pad, NEVER rescale each crop independently. Every mask uses the same pixel
    # lattice and filter footprint, including shared edges and one-pixel borders.
    image = Image.new("RGBA", (width, height), (255, 255, 255, 0))
    alpha = Image.new("L", image.size)
    alpha.paste(cropped, (0, 0))
    image.putalpha(alpha)
    image.save(output / (key + ".tga"), compression=None)
    return {"bounds": [left / mask.width, top / mask.height, right / mask.width, bottom / mask.height],
            "texCoord": [cropped.width / width, cropped.height / height]}


def write_lua(path, profile, metadata):
    quote = json.dumps
    lines = ["-- Generated by scripts/prepare_map_masks.py; masks and hit tests share one partition.",
             "local _, W = ...", "W.MapGeometry = W.MapGeometry or {}",
             f"W.MapGeometry.{profile} = {{", f'    textureRoot = "Interface\\\\AddOns\\\\WoWIdle\\\\Assets\\\\Maps\\\\{profile}\\\\",',
             "    masks = {"]
    for key, mask in sorted(metadata["masks"].items()):
        values = ", ".join(format(value, ".9f") for value in mask["bounds"])
        uv = ", ".join(format(value, ".9f") for value in mask["texCoord"])
        lines.append(f'        {key} = {{ continent = {quote(mask["continent"])}, bounds = {{ {values} }}, texCoord = {{ {uv} }} }},')
    lines.extend(["    },", "    continents = {"])
    for key, entry in metadata["continents"].items():
        w, h = metadata["canvas"]
        aw, ah = entry["artSize"]
        lines.extend([f"        {key} = {{", f'            mapID = {entry["mapID"]},',
                      f"            width = {w}, height = {h},",
                      f"            artWidth = {aw}, artHeight = {ah},",
                      f'            firstTexture = {entry["firstTexture"]},',
                      "            names = { " + ", ".join(map(quote, entry["names"])) + " },",
                      "            centers = {"])
        for name, center in entry["centers"].items():
            lines.append(f"                {name} = {{ {center[0] / w:.9f}, {center[1] / h:.9f} }},")
        lines.extend(["            },", "            rows = {"])
        lines.extend("                " + quote(row) + "," for row in entry["rows"])
        lines.extend(["            },", "        },"])
    lines.extend(["    },", "}", ""])
    path.write_text("\n".join(lines))


def build(data, source, output, client_data=None, preview=None):
    size = tuple(data["canvas"])
    metadata = {"profile": data["profile"], "canvas": list(size), "masks": {}, "continents": {}}
    output.mkdir(parents=True, exist_ok=True)
    for continent, spec in data["artwork"].items():
        image = artwork(source, spec, size)
        land = land_mask(image, data["land"][continent], data["caps"].get(continent, []))
        # Ownership propagates across inland water and decorative city/lake
        # icons. Only the final color masks are clipped to the actual coastline.
        domain = ImageChops.lighter(polygon_mask(size, data["land"][continent]), land)
        names, labels = partition(image, domain, data["seeds"][continent])
        # Remove single-pixel paths along roads/decorations without changing the
        # shared ownership invariant or erasing small offshore components.
        indexed = Image.new("L", size)
        indexed.putdata([label + 1 for label in labels])
        filtered = indexed.filter(ImageFilter.ModeFilter(5)).filter(ImageFilter.ModeFilter(5)).tobytes()
        for index, label in enumerate(labels):
            if label >= 0 and filtered[index]:
                labels[index] = filtered[index] - 1
        fallbacks = []
        if client_data:
            native_names, native = native_labels(client_data, continent, size, dict(spec, profile=data["profile"]))
            present = {native_names[label] for label in native if label >= 0}
            # Some clients merge Classic destinations (notably Alterac). Only
            # those missing native subdivisions retain the artwork partition.
            fallbacks = [name for name in names if not name.startswith("_") and name not in present]
            all_names = names + [name for name in native_names if name not in names]
            indices = {name: index for index, name in enumerate(all_names)}
            allowed = domain.tobytes()
            for index, value in enumerate(allowed):
                old_name = names[labels[index]] if labels[index] >= 0 else None
                if not value:
                    labels[index] = -1
                elif old_name in fallbacks:
                    labels[index] = indices[old_name]
                elif native[index] >= 0:
                    labels[index] = indices[native_names[native[index]]]
                else:
                    labels[index] = -1
            names = all_names
        entry = dict(save_mask(output, continent, land), continent=continent)
        metadata["masks"][continent] = entry
        centers, review_tiles = {}, []
        for label, name in enumerate(names):
            if name.startswith("_"):
                continue
            mask = Image.new("L", size)
            mask.putdata([255 if owner == label else 0 for owner in labels])
            mask = ImageChops.multiply(mask, land)
            if not mask.getbbox():
                if name not in data["seeds"][continent]:
                    continue
                raise ValueError("No land pixels for destination: " + name)
            # A single common blur kernel gives neighboring masks complementary
            # antialiasing; the whole continent remains the union of all regions.
            descriptor = save_mask(output, name, ImageChops.multiply(
                mask.filter(ImageFilter.GaussianBlur(0.4)), land))
            metadata["masks"][name] = dict(descriptor, continent=continent)
            if preview:
                rendered = Image.composite(image, image.convert("L").convert("RGB"), mask)
                bounds = mask.getbbox()
                left, top, right, bottom = bounds
                crop = rendered.crop((max(0, left - 12), max(0, top - 12),
                                      min(size[0], right + 12), min(size[1], bottom + 12)))
                crop.thumbnail((380, 240))
                review_tiles.append((name, crop))
            points = data["seeds"][continent].get(name, [])
            valid = [(x, y) for x, y in points
                     if labels[y * size[0] + x] == label and land.getpixel((x, y))]
            if valid:
                centers[name] = [valid[0][0] + 0.5, valid[0][1] + 0.5]
            else:
                preferred = points[0] if points else (size[0] / 2, size[1] / 2)
                pixel = min((index for index, owner in enumerate(labels)
                             if owner == label and land.getpixel((index % size[0], index // size[0]))),
                            key=lambda index: (index % size[0] - preferred[0]) ** 2
                            + (index // size[0] - preferred[1]) ** 2)
                centers[name] = [pixel % size[0] + 0.5, pixel // size[0] + 0.5]
        rows = rows_for_labels(labels, *size)
        metadata["continents"][continent] = {"mapID": spec["mapID"], "artSize": spec["size"],
                                             "firstTexture": spec["firstTexture"], "names": names, "centers": centers, "rows": rows,
                                             "source": "native" if client_data else "artwork", "fallbackZones": fallbacks}
        if preview:
            preview.mkdir(parents=True, exist_ok=True)
            colors = [tuple(((i + 1) * channel) % 190 + 45 for channel in (67, 131, 191))
                      for i in range(len(names))]
            regions = Image.new("RGB", size)
            regions.putdata([colors[label] if label >= 0 else image.getpixel((index % size[0], index // size[0]))
                             for index, label in enumerate(labels)])
            rendered = Image.blend(image, regions, 0.45)
            draw = ImageDraw.Draw(rendered)
            for name, points in data["seeds"][continent].items():
                for point in points:
                    draw.text(tuple(point), name, fill="white")
            rendered.save(preview / (continent + ".png"))
            sheet = Image.new("RGB", (1600, math.ceil(len(review_tiles) / 4) * 280), (20, 20, 20))
            draw = ImageDraw.Draw(sheet)
            for index, (name, crop) in enumerate(review_tiles):
                x, y = index % 4 * 400, index // 4 * 280
                sheet.paste(crop, (x + (400 - crop.width) // 2, y + (245 - crop.height) // 2))
                draw.text((x + 8, y + 255), name, fill="white")
            sheet.save(preview / (continent + "-destinations.png"))
    (output / "geometry.json").write_text(json.dumps(metadata, separators=(",", ":")) + "\n")
    return metadata


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path, required=True,
                        help="Extracted interface/worldmap directory, outside the repository")
    parser.add_argument("--regions", type=Path, default=ROOT / "Assets/Maps/regions.json")
    parser.add_argument("--client-data", type=Path, help="Native query export from the same client/artwork")
    parser.add_argument("--preview-dir", type=Path, help="Optional review images outside the repository")
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--lua-output", type=Path, default=ROOT / "Compatibility/MapMasks.lua")
    args = parser.parse_args()
    data = json.loads(args.regions.read_text())
    output = args.output_dir or ROOT / "Assets/Maps" / data["profile"]
    native = json.loads(args.client_data.read_text()) if args.client_data else None
    metadata = build(data, args.source_dir, output, native, args.preview_dir)
    write_lua(args.lua_output, data["profile"], metadata)
    print(f'{len(metadata["masks"]) - len(metadata["continents"])} destination masks generated for {data["profile"]}.')


if __name__ == "__main__":
    main()
