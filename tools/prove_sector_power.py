"""Run one rendered proof; never starts or stops the shared X server."""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import time


def validate_result(report, exit_code, log):
    errors = list(report.get('failures', ['missing failures field']))
    if exit_code:
        errors.append(f'engine exit {exit_code}')
    if re.search(r'(?:SCRIPT ERROR:|ERROR:|Parse Error|Segmentation fault)', log):
        errors.append('engine error in log')
    if report.get('display_driver', '').lower() != 'x11' or report.get('rendering_method') != 'gl_compatibility' or not report.get('renderer') or report.get('resolution') != [1280, 720]:
        errors.append('render contract absent')
    samples = report.get('frame_intervals_ms', [])
    if report.get('frames_drawn', 0) <= 0 or not samples or any(not isinstance(v, (int, float)) or not math.isfinite(v) or v <= 0 for v in samples) or len(samples) != len(report.get('frame_stages', [])):
        errors.append('invalid rendered frame samples')
    if report.get('travelled_m', 0) < 90 or report.get('waypoints_completed', 0) < 8:
        errors.append('physical route incomplete')
    if report.get('mode') in ('mission', 'capture'):
        if report.get('ending') != report.get('expected_ending') or report.get('ending') not in ('mother', 'n7') or report.get('health', 0) <= 0 or report.get('phase') != 4:
            errors.append('mission incomplete')
        if report.get('circuits_available'):
            for name in ('maintenance', 'archives'):
                commands = [c for c in report.get('commands', []) if c.get('id') == 'breaker_' + name]
                if not commands or not all(c.get('native') and c.get('aim_valid') and c.get('changed') and c.get('prompt_changed') for c in commands):
                    errors.append(f'native breaker proof missing: {name}')
    return errors


def hashes(project):
    names = subprocess.check_output(['git', '-C', str(project), 'ls-files', '--cached', '--others', '--exclude-standard', '-z']).decode().split('\0')
    return {name: hashlib.sha256((project / name).read_bytes()).hexdigest() for name in names if name and (project / name).is_file()}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--project', type=Path, required=True)
    p.add_argument('--godot', required=True)
    p.add_argument('--output', type=Path, required=True)
    p.add_argument('--mode', choices=['perf', 'mission', 'capture'], required=True)
    p.add_argument('--ending', choices=['mother', 'n7'], default='mother')
    p.add_argument('--display', default=':100')
    p.add_argument('--require-circuits', action='store_true')
    p.add_argument('--low', action='store_true')
    p.add_argument('--timeout', type=int, default=900)
    a = p.parse_args()
    project, output = a.project.resolve(), a.output.resolve()
    if output.exists():
        p.error('output must be new to prevent stale evidence')
    if not (project / 'project.godot').is_file():
        p.error('project.godot absent')
    output.mkdir(parents=True)
    environment = dict(os.environ, DISPLAY=a.display, XDG_DATA_HOME=str(output / 'userdata'), XDG_CONFIG_HOME=str(output / 'config'))
    before = hashes(project)
    probe = Path(__file__).with_name('probe_sector_power.gd').resolve()
    command = [a.godot, '--path', str(project), '--display-driver', 'x11', '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', '--resolution', '1280x720', '--position', '0,0', '--script', str(probe), '--', '--proof-output=' + str(output), '--probe-mode=' + a.mode, '--ending=' + a.ending, '--display=' + a.display]
    if a.require_circuits:
        command.append('--require-circuits')
    if a.low:
        command.append('--low')
    manifest = {'command': command, 'project': str(project), 'head': subprocess.check_output(['git', '-C', str(project), 'rev-parse', 'HEAD']).decode().strip(), 'probe_sha256': hashlib.sha256(probe.read_bytes()).hexdigest(), 'source_before': before, 'started_unix': time.time(), 'display': a.display, 'limits': 'Linux X11; renderer recorded by probe; no target GPU or Windows claim. Capture screenshots are not video or performance; Dummy audio does not prove audible output. No X server lifecycle changes.'}
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2))
    with (output / 'engine.log').open('w') as log:
        try:
            result = subprocess.run(command, env=environment, stdout=log, stderr=subprocess.STDOUT, timeout=a.timeout)
            exit_code = result.returncode
        except subprocess.TimeoutExpired:
            exit_code = 124
    report_path = output / 'journey.json'
    try:
        report = json.loads(report_path.read_text())
    except (OSError, ValueError):
        report = {}
    errors = validate_result(report, exit_code, (output / 'engine.log').read_text(errors='replace'))
    after = hashes(project)
    manifest.update(source_after=after, source_unchanged=before == after, ended_unix=time.time(), exit_code=exit_code, validation_errors=errors)
    if before != after:
        errors.append('tracked source changed during proof')
    if a.require_circuits and not report.get('circuits_available'):
        errors.append('required circuits absent')
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2))
    print(json.dumps({'output': str(output), 'passed': not errors, 'errors': errors, 'travelled_m': report.get('travelled_m'), 'p95_ms': report.get('frame_p95_ms')}))
    return bool(errors)


if __name__ == '__main__':
    sys.exit(main())
