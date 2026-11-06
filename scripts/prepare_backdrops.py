"""Package credited zone screenshots as textures supported by the WoW client."""

import argparse
import json
import urllib.request
from pathlib import Path

from PIL import Image, ImageOps


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path)
    parser.add_argument("--download", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    output = project / "Assets" / "Backdrops"
    manifest = json.loads((output / "sources.json").read_text())
    screenshots = manifest["screenshots"]
    ids = [entry["id"] for entry in screenshots]
    if len(ids) != len(set(ids)):
        raise ValueError("Duplicate screenshot IDs")

    if args.check:
        for entry in screenshots:
            with Image.open(output / (entry["id"] + ".tga")) as image:
                assert image.size == (2048, 512), entry["id"]
                assert image.mode == "RGB", entry["id"]
        print(f"Checked {len(screenshots)} zone textures")
        return

    if args.source_dir is None:
        parser.error("--source-dir is required when packaging screenshots")
    args.source_dir.mkdir(parents=True, exist_ok=True)
    descriptor = [
        "local _, W = ...",
        "-- Zone screenshot paths. Credits: Assets/Backdrops/SOURCES.md.",
        "W.Content.backdrops = {",
    ]
    credits = [
        "# Zone screenshot credits",
        "",
        "Temporary in-game landscape backdrops. World of Warcraft and the depicted "
        "game artwork are © Blizzard Entertainment. Screenshot captures belong to "
        "their respective contributors; the source pages identify the original uploads.",
        "",
        "Images are cropped for the adventure viewport and packaged as uncompressed, "
        "24-bit TGA textures. No game client or network access is needed to load them.",
        "",
        "These are reference screenshots from existing WoW versions, not verified "
        "Forever captures. Replace them with Forever screenshots when available.",
        "",
        "| Zone | Source page | Original screenshot |",
        "| --- | --- | --- |",
    ]
    for entry in screenshots:
        key = entry["id"]
        source = args.source_dir / (key + ".jpg")
        if args.download:
            with urllib.request.urlopen(entry["source_image"], timeout=30) as response:
                source.write_bytes(response.read())
        with Image.open(source) as original:
            image = ImageOps.exif_transpose(original).convert("RGB")
            crop_height = min(image.height, round(image.width / manifest["aspect"]))
            crop_width = min(image.width, crop_height * manifest["aspect"])
            left = (image.width - crop_width) // 2
            center = round(image.height * entry["focal_y"])
            top = max(0, min(image.height - crop_height, center - crop_height // 2))
            image = image.crop((left, top, left + crop_width, top + crop_height))
            image = image.resize((2048, 512), Image.Resampling.LANCZOS)
            # A fresh RGB image omits the source's EXIF, paths, and other metadata.
            texture = Image.new("RGB", image.size)
            texture.paste(image)
            texture.save(output / (key + ".tga"), compression=None)
        descriptor.append(
            f'    {key} = "Interface\\\\AddOns\\\\AFKraft\\\\Assets\\\\Backdrops\\\\{key}.tga",'
        )
        credits.append(
            f'| {entry["name"]} | [Source]({entry["source_page"]}) '
            f'| [Image]({entry["source_image"]}) |'
        )
    descriptor.append("}")
    content = project / "Content"
    content.mkdir(exist_ok=True)
    (content / "Backdrops.lua").write_text("\n".join(descriptor) + "\n")
    (output / "SOURCES.md").write_text("\n".join(credits) + "\n")
    print(f"Packaged {len(screenshots)} zone textures")


if __name__ == "__main__":
    main()
