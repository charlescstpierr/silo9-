#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p builds/windows builds/linux
./tools/godot.sh --headless --path . --export-release 'Windows Desktop' builds/windows/SILO9.exe
./tools/godot.sh --headless --path . --export-release Linux builds/linux/SILO9.x86_64

for target in windows linux; do
    mkdir -p "builds/$target/licenses"
    cp docs/licenses/GODOT.txt docs/licenses/GODOT-COPYRIGHT.txt "builds/$target/licenses/"
    cp assets/kenney/LICENSE.txt "builds/$target/licenses/KENNEY.txt"
    cp README.md "builds/$target/README.md"
    mkdir -p "builds/$target/docs"
    cp -R docs/. "builds/$target/docs/"
    mkdir -p "builds/$target/assets/kenney"
    cp assets/kenney/LICENSE.txt "builds/$target/assets/kenney/LICENSE.txt"
done
