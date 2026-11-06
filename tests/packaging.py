"""Archive contents, recursive includes, and invalid input checks."""
import importlib.util
from pathlib import Path
import tempfile
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("package", ROOT / "scripts/package.py")
package = importlib.util.module_from_spec(spec)
spec.loader.exec_module(package)

with tempfile.TemporaryDirectory() as directory:
    output = Path(directory)
    source = (ROOT / "AFKraft.toc").read_text()
    archive = package.build(output, "0.2.0-beta.1")
    with ZipFile(archive) as zipped:
        names = set(zipped.namelist())
        manifest = zipped.read("AFKraft/AFKraft.toc").decode()
        assert "## Interface: 16001\n" in manifest
        assert "## Version: 0.2.0-beta.1\n" in manifest
        assert manifest.split("\n\n", 1)[1] == source.split("\n\n", 1)[1]
        assert "## SavedVariables: AFKraftDB, AFKraftPreferencesDB" in manifest
        assert all(name.startswith("AFKraft/") for name in names)
        for path in package.runtime_files(ROOT, manifest):
            assert "AFKraft/" + path.relative_to(ROOT).as_posix() in names
        for name in ("LICENSE", "CHANGELOG.md", "Libs/Ace3-LICENSE.txt",
                     "Libs/LibDataBroker-1.1/README.textile", "Assets/Backdrops/SOURCES.md",
                     "Assets/Backdrops/elwynn.tga", "Libs/AceGUI-3.0/widgets/AceGUIWidget-Button.lua"):
            assert "AFKraft/" + name in names, name
        assert not any(name.startswith(("AFKraft/scripts/", "AFKraft/tests/", "AFKraft/."))
                       for name in names)
        assert zipped.testzip() is None
    assert (ROOT / "AFKraft.toc").read_text() == source
    for version in ("../bad", "v0.2.0", "0.2.0/escape"):
        try:
            package.build(output, version)
        except ValueError:
            pass
        else:
            raise AssertionError(version)
    fixture = output / "fixture"
    fixture.mkdir()
    (fixture / "nested.xml").write_text('<Ui><Include file="nested.xml"/></Ui>')
    assert len(package.runtime_files(fixture, "nested.xml")) == 1
    for manifest, error in (("missing.lua", FileNotFoundError), ("../outside.lua", ValueError)):
        try:
            package.runtime_files(fixture, manifest)
        except error:
            pass
        else:
            raise AssertionError(manifest)
print("Packaging checks passed")
