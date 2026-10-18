#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .cstack/silo9/evidence .cstack/silo9/test-user-data
export XDG_DATA_HOME="$PWD/.cstack/silo9/test-user-data"
./tools/godot.sh --headless --path . --editor --import --quit 2>&1 | tee .cstack/silo9/evidence/import.log
if rg -q 'SCRIPT ERROR|Parse Error|ERROR:' .cstack/silo9/evidence/import.log; then exit 1; fi
for test_file in tests/test_*.gd; do
    log_file=".cstack/silo9/evidence/$(basename "$test_file" .gd).log"
    timeout 120 ./tools/godot.sh --headless --path . --script "$test_file" 2>&1 | tee "$log_file"
    if rg -q 'SCRIPT ERROR|Parse Error|^FAIL:|^FAIL |^ERROR:' "$log_file"; then exit 1; fi
done
git diff --check
