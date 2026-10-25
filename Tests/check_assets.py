"""Check the dimensions consumed by actool without third-party dependencies."""
import json
import struct
from pathlib import Path

icon_dir = Path(__file__).resolve().parents[1] / "LanguageSwitcher/Assets.xcassets/AppIcon.appiconset"
images = json.loads((icon_dir / "Contents.json").read_text())["images"]
assert len(images) == 10, "Expected all ten macOS icon representations"
for entry in images:
    name = entry["filename"]
    assert Path(name).name == name, "Icon filename must stay in its asset catalog"
    header = (icon_dir / name).read_bytes()[:24]
    assert header[:8] == b"\x89PNG\r\n\x1a\n", f"Not a PNG: {name}"
    actual = struct.unpack(">II", header[16:24])
    points = int(entry["size"].split("x")[0])
    pixels = points * int(entry["scale"].removesuffix("x"))
    assert actual == (pixels, pixels), f"{name}: expected {pixels}px, got {actual}"
print("PASS: all macOS icon sizes (16–1024px)")
