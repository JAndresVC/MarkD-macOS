"""Validate a mounted installer, using the isolated DMG tooling environment."""
import hashlib
import os
from pathlib import Path
import sys

from ds_store import DSStore
from mac_alias import Alias

root = Path(sys.argv[1])
assert os.path.ismount(root), "Pass the root of the mounted installer"
assert {p.name for p in root.iterdir() if not p.name.startswith(".")} == {"MarkD.app", "Applications"}
assert (root / "Applications").is_symlink()
assert os.readlink(root / "Applications") == "/Applications"
assert (root / "MarkD.app/Contents/Info.plist").is_file()

with DSStore.open(str(root / ".DS_Store"), "r") as store:
    assert store["MarkD.app"]["Iloc"] == (165, 200)
    assert store["Applications"]["Iloc"] == (495, 200)
    window = store["."]["bwsp"]
    assert window["WindowBounds"].endswith("{660, 488}}")
    assert not window["ShowToolbar"] and not window["ShowSidebar"]
    icons = store["."]["icvp"]
    assert icons["iconSize"] == 160 and icons["textSize"] == 16
    assert icons["arrangeBy"] == "none" and icons["labelOnBottom"]
    assert icons["backgroundType"] == 2
    alias = Alias.from_bytes(icons["backgroundImageAlias"])
    assert alias.target.filename == ".background.png"
    assert alias.volume.name == "Instalar MarkD"

expected = Path(__file__).parent / "dmg/background.png"
assert hashlib.sha256((root / ".background.png").read_bytes()).digest() == hashlib.sha256(expected.read_bytes()).digest()
print("DMGLayoutTests: passed (payload, alias, window, icons and embedded background)")
