#!/usr/bin/env python3
"""One private, sequential final evidence invocation. No engine starts until called with HEAD."""
import argparse
import hashlib
import importlib.util
import json
import math
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[5]
WORK = ROOT / '.worktrees/silo9-issue-08'
HERE = Path(__file__).resolve().parent
PROOFS = HERE.parent / 'visual-proof'
GODOT = ROOT / '.tools/Godot_v4.7.2-stable_linux.x86_64'
RUNNER = WORK / 'tools/prove_ads.py'
EXPECTED = {'inspection': ('probe_materials.gd', '0bbd18e20811ed92723f7c7101abd48698c1b93928c61b723617a037626af319'), 'film': ('probe_materials_film.gd', '44ad5e220bfb29672a6e8e3a7683278316c62a1d3ed85758e0a71b708d4b9570')}

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def save(path, value):
    path.write_text(json.dumps(value, indent=2, allow_nan=False) + '\n')

def freeze(head, probe, proof):
    actual_head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=WORK, text=True).strip()
    if actual_head != head:
        raise RuntimeError(f'HEAD changed: {actual_head} != {head}')
    return {'head': actual_head, 'source_sha256': proof.fingerprint(WORK, head, WORK), 'tools_sha256': {str(p): sha(p) for p in [probe, GODOT, RUNNER, Path(__file__)]}}

def validate(result, destination, mode):
    if result['failures'] or result['performance_valid']:
        raise RuntimeError('Probe failure or invalid performance claim')
    if result['display'] != 'X11' and result['display'].lower() != 'x11':
        raise RuntimeError('X11 required')
    if result['rendering_method'] != 'gl_compatibility' or result['rendering_driver'] not in ['opengl3', 'opengl3_es', 'opengl3_angle'] or not result['adapter'].strip() or not result['render_loop']:
        raise RuntimeError('Real Compatibility renderer required')
    if [result['engine'][k] for k in ['major', 'minor', 'patch']] != [4, 7, 2]:
        raise RuntimeError('Wrong engine version')
    count = 17 if mode == 'inspection' else 13
    if len(result['captures']) != count:
        raise RuntimeError('Wrong capture count')
    for capture in result['captures']:
        data = (destination / capture['file']).read_bytes()
        if data[:8] != b'\x89PNG\r\n\x1a\n' or tuple(int.from_bytes(data[i:i+4], 'big') for i in (16, 20)) != (1280, 720):
            raise RuntimeError('Invalid PNG')
        if capture['stage'] not in capture['overlay'] or capture['file'] != capture['stage'] + '.png' or capture['frame'] <= capture['frame_before']:
            raise RuntimeError('Mismatched label/frame progress')
    before, after = result['inventory_before'], result['inventory_after']
    for key in ['materials', 'textures', 'material_count', 'texture_count', 'estimated_rgba8_full_mips_bytes']:
        if before[key] != after[key]:
            raise RuntimeError('Mutable material/texture inventory: ' + key)
    if mode == 'film':
        frames = result['film_frames']
        if len(frames) != 1080 or len(result['segments']) != 6 or any(b['frame'] <= a['frame'] for a, b in zip(frames, frames[1:])):
            raise RuntimeError('Film quotas/progression wrong')
        for f in frames:
            for key in ['camera_position', 'camera_rotation', 'player_position']:
                if len(f[key]) != 3 or not all(math.isfinite(x) for x in f[key]):
                    raise RuntimeError('Nonfinite camera/movement')
        for s in result['segments']:
            if not s['accepted'] or not .1 <= s['max_displacement'] <= 3 or s['yaw_range'] <= math.radians(28) or s['pitch_range'] <= math.radians(9) or s['after']['aim_weight'] < .99:
                raise RuntimeError('Motion/ADS/acceptance failed')
            if s['after']['weapon'] == 0:
                if (s['after']['ammo'], s['after']['reserve']) != (12, 44): raise RuntimeError('R transfer failed')
            elif (s['after']['energy'], s['after']['cells']) != (100, 1): raise RuntimeError('B transfer failed')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('mode', choices=EXPECTED)
    parser.add_argument('--head', required=True)
    args = parser.parse_args()
    filename, expected = EXPECTED[args.mode]
    probe = PROOFS / filename
    if sha(probe) != expected:
        raise RuntimeError('Unreviewed probe hash')
    spec = importlib.util.spec_from_file_location('ads_proof', RUNNER)
    proof = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(proof)
    destination = HERE / ('film-final' if args.mode == 'film' else args.mode)
    destination.mkdir(exist_ok=False)
    launch_probe = destination / 'probe-at-launch.gd'
    shutil.copyfile(probe, launch_probe)
    shutil.copyfile(Path(__file__), destination / 'runner-at-launch.py')
    initial = freeze(args.head, probe, proof)
    command = [str(GODOT), '--path', str(WORK), '--display-driver', 'x11', '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', '--position', '0,0', '--resolution', '1280x720']
    if args.mode == 'film': command += ['--write-movie', str(destination / 'materials.avi'), '--fixed-fps', '30']
    command += ['--script', str(launch_probe), '--', '--proof-output=' + str(destination), '--probe-mode=' + args.mode, '--evidence-label=final-' + args.head[:12] + ('-frontal-z8' if args.mode == 'film' else '-original-z5')]
    manifest = {'before': initial, 'command': command, 'display': ':100', 'xdg_data_home': str(destination / 'user-data'), 'timeout_seconds': 360, 'performance_valid': False, 'probe_copy_sha256': sha(launch_probe)}
    save(destination / 'manifest.json', manifest)
    started = time.monotonic()
    try:
        with (destination / 'godot.log').open('w') as log:
            run = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, timeout=360, env=dict(os.environ, DISPLAY=':100', XDG_DATA_HOME=manifest['xdg_data_home']))
        manifest['exit_code'] = run.returncode
        if run.returncode or re.search(r'SCRIPT ERROR|ERROR:|Parse Error|Assertion failed', (destination / 'godot.log').read_text()):
            raise RuntimeError('Godot/log failed')
        result = json.loads((destination / 'materials.json').read_text())
        validate(result, destination, args.mode)
        manifest['validation'] = 'PASS'
    except Exception as error:
        manifest['error'] = str(error)
        raise
    finally:
        manifest['elapsed_seconds'] = time.monotonic() - started
        manifest['after'] = freeze(args.head, probe, proof)
        manifest['source_tools_unchanged'] = manifest['after'] == initial and sha(launch_probe) == expected
        manifest['artifacts_sha256'] = {str(p.relative_to(destination)): sha(p) for p in destination.iterdir() if p.is_file() and p.name != 'manifest.json'}
        save(destination / 'manifest.json', manifest)
        if not manifest['source_tools_unchanged']: raise RuntimeError('Source/tools changed')
    print(json.dumps({'mode': args.mode, 'head': args.head, 'exit_code': manifest['exit_code'], 'validation': manifest['validation'], 'elapsed_seconds': manifest['elapsed_seconds']}))

if __name__ == '__main__':
    main()
