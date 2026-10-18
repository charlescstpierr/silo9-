"""Package verified binaries with notices, and only tracked project sources."""
import hashlib
import json
from pathlib import Path
import subprocess
import tarfile
import zipfile

root = Path(__file__).resolve().parent.parent
builds = root / "builds"
for platform in ("windows", "linux"):
    folder = builds / platform
    required = [folder / "README.md", folder / "docs/VALIDATION.md", folder / "docs/performance.json",
                folder / "docs/licenses/GODOT.txt", folder / "docs/licenses/GODOT-COPYRIGHT.txt",
                folder / "assets/kenney/LICENSE.txt", folder / "assets/quaternius/LICENSE.txt",
                folder / "assets/quaternius/PROVENANCE.json", folder / "assets/quaternius/asset-manifest.json"]
    if any(not path.is_file() for path in required):
        raise SystemExit(f"Missing distribution file for {platform}")
with zipfile.ZipFile(builds / "SILO9-Windows-x64.zip", "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    for path in sorted((builds / "windows").rglob("*")):
        if path.is_file():
            archive.write(path, "SILO9/" + str(path.relative_to(builds / "windows")))
with tarfile.open(builds / "SILO9-Linux-x64.tar.gz", "w:gz") as archive:
    archive.add(builds / "linux", arcname="SILO9")
tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=root).decode().split("\0")
if "project.godot" not in tracked:
    raise SystemExit("Stage or commit the verified project before packaging sources")
with zipfile.ZipFile(builds / "SILO9-Source.zip", "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    for name in tracked:
        if not name:
            continue
        if name.split("/")[0] in (".tools", ".cstack", ".godot", ".git", "builds"):
            raise SystemExit(f"Forbidden generated path tracked: {name}")
        archive.write(root / name, "SILO9/" + name)
artifacts = [builds / "SILO9-Windows-x64.zip", builds / "SILO9-Linux-x64.tar.gz", builds / "SILO9-Source.zip"]
manifest = {p.name: {"bytes": p.stat().st_size, "sha256": hashlib.sha256(p.read_bytes()).hexdigest()} for p in artifacts}
(builds / "SHA256.json").write_text(json.dumps(manifest, indent=2))
print(json.dumps(manifest, indent=2))
