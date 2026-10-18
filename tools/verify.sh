#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .cstack/silo9/evidence .cstack/silo9/test-user-data
export XDG_DATA_HOME="$PWD/.cstack/silo9/test-user-data"
./tools/godot.sh --headless --path . --editor --import --quit 2>&1 | tee .cstack/silo9/evidence/import.log
if rg -q 'SCRIPT ERROR|Parse Error|ERROR:' .cstack/silo9/evidence/import.log; then exit 1; fi
for test_file in tests/test_*.gd; do
    log_file=".cstack/silo9/evidence/$(basename "$test_file" .gd).log"
    if [[ "$test_file" == tests/test_flashlight_input.gd || "$test_file" == tests/test_weapon_input.gd || "$test_file" == tests/test_weapon_modal_input.gd || "$test_file" == tests/test_menu_held_button.gd || "$test_file" == tests/test_weapon_motion.gd || "$test_file" == tests/test_player.gd || "$test_file" == tests/test_jump_tap.gd || "$test_file" == tests/test_weapon_beam_motion.gd || "$test_file" == tests/test_weapon_look_direction.gd || "$test_file" == tests/test_shot_*.gd || "$test_file" == tests/test_ads_*.gd ]]; then
        if [[ -n "${DISPLAY:-}" ]]; then
            timeout 120 ./tools/godot.sh --display-driver x11 --rendering-driver dummy --audio-driver Dummy --path . --script "$test_file" 2>&1 | tee "$log_file"
        else
            timeout 120 xvfb-run -a ./tools/godot.sh --display-driver x11 --rendering-driver dummy --audio-driver Dummy --path . --script "$test_file" 2>&1 | tee "$log_file"
        fi
    else
        timeout 120 ./tools/godot.sh --headless --path . --script "$test_file" 2>&1 | tee "$log_file"
    fi
    if rg -q 'SCRIPT ERROR|Parse Error|^FAIL:|^FAIL |^ERROR:' "$log_file"; then exit 1; fi
done
git diff --check
