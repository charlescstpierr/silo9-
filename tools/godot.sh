#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -n "${GODOT_BIN:-}" ]]; then
    exec "$GODOT_BIN" "$@"
elif [[ -x .tools/Godot_v4.7.2-stable_linux.x86_64 ]]; then
    exec .tools/Godot_v4.7.2-stable_linux.x86_64 "$@"
elif command -v godot >/dev/null; then
    exec godot "$@"
else
    echo 'Godot 4.7.2 requis : définir GODOT_BIN ou ouvrir project.godot dans Godot.' >&2
    exit 1
fi
