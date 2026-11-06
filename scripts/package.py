#!/usr/bin/env python3
"""Build the Forever distribution without publishing or changing source metadata."""
import argparse
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parent.parent


def runtime_files(root, manifest):
    files = set()

    def visit(path):
        path = path.resolve()
        if not path.is_relative_to(root.resolve()):
            raise ValueError(f"Runtime include escapes addon: {path}")
        if not path.is_file():
            raise FileNotFoundError(path)
        if path in files:
            return
        files.add(path)
        if path.suffix.lower() == ".xml":
            for node in ET.parse(path).getroot().iter():
                if node.tag.rsplit("}", 1)[-1] in {"Script", "Include"} and node.get("file"):
                    visit(path.parent / node.get("file").replace("\\", "/"))

    for line in manifest.splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            visit(root / line.replace("\\", "/"))
    return files


def build(output, version=None, root=ROOT):
    source = (root / "AFKraft.toc").read_text()
    version = version or re.search(r"^## Version: (.+)$", source, re.M)[1]
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+(?:[-.][A-Za-z0-9]+)*", version):
        raise ValueError("Version must look like 0.2.0 or 0.2.0-beta.1")
    manifest = re.sub(r"^## Interface: .+$", "## Interface: 16001", source, flags=re.M)
    manifest = re.sub(r"^## Version: .+$", f"## Version: {version}", manifest, flags=re.M)
    files = runtime_files(root, manifest)
    files.update(path.resolve() for path in (root / "Assets").rglob("*") if path.is_file())
    files.update((root / name).resolve() for name in (
        "LICENSE", "README.md", "CHANGELOG.md", "Content/ITEMS.md", "Libs/README.md",
    ))
    # Keep embedded library terms even when their notice is outside the load graph.
    files.update(path.resolve() for path in (root / "Libs").rglob("*")
                 if path.is_file() and any(word in path.name.lower()
                                          for word in ("license", "copying", "notice", "readme")))
    output.mkdir(parents=True, exist_ok=True)
    archive = output / f"AFKcraft-{version}-forever.zip"
    with ZipFile(archive, "w", compression=ZIP_DEFLATED) as package:
        package.writestr("WoWIdle/WoWIdle.toc", manifest)
        for path in sorted(files):
            package.write(path, "WoWIdle/" + path.relative_to(root.resolve()).as_posix())
    return archive


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "artifacts")
    parser.add_argument("--version", help="Override the source TOC version in the ZIP only")
    args = parser.parse_args()
    print(build(args.output, args.version))
