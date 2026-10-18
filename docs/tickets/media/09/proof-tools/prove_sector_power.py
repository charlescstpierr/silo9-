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


LIGHT_IDS = {'ceiling_refuge', 'ceiling_decontamination', 'ceiling_maintenance', 'ceiling_archives', 'ceiling_core_entry', 'ceiling_core_end', 'reactor', 'alarm_maintenance', 'alarm_archives'}
PERF_ROUTE = [[0, 0, z] for z in [-10, -16, -22, -32, -36, -42, -32, -12, 7]]


LIGHTING_ZONES = ('refuge', 'decontamination', 'maintenance', 'archives', 'core')
CRITICAL_TARGETS = ('relay', 'breaker_maintenance', 'evidence')
LIGHTING_LABELS = ({f'{zone}_power_{power}_flash_{flash}' for zone in LIGHTING_ZONES for power in ('on', 'off') for flash in ('on', 'off')}
                   | {f'critical_{target}_flash_{flash}' for target in CRITICAL_TARGETS for flash in ('on', 'off')}
                   | {f'neon_{i:02}' for i in range(13)} | {f'reduced_{i:02}' for i in range(3)} | {'alarm_active', 'alarm_expired'})
COST_LABELS = ['core_off', 'core_on', 'maintenance_alarm_off', 'maintenance_alarm_on']


def positive(value):
    return type(value) in (int, float) and math.isfinite(value) and value > 0


def emitting(light):
    return (light.get('visible') is True and positive(light.get('energy')) and positive(light.get('range'))
            and type(light.get('mask')) is int and light['mask'] & 1 != 0)


def validate_observation(actual, row, report):
    errors = []
    expected = row['circuits_requested']
    if set(expected) != {'maintenance', 'archives'} or any(type(v) is not bool for v in expected.values()) or actual['circuits'] != expected:
        errors.append('requested circuits differ from physical state')
    label = row['label']
    if '_power_' in label and any(v is not ('_power_on_' in label) for v in expected.values()):
        errors.append('power label disagrees with request')
    if label.startswith('critical_') and any(expected.values()):
        errors.append('critical scene must be unpowered')
    if label in COST_LABELS and expected != {'maintenance': not label.startswith('maintenance'), 'archives': True}:
        errors.append('cost circuit scenario mismatch')
    requested = row['flashlight_requested']
    if type(requested) is not bool or (label.endswith(('_on', '_off')) and requested is not label.endswith('_on')):
        errors.append('flashlight label disagrees with request')
    light = actual.get('flashlight')
    if report.get('lighting_available'):
        if light.get('visible') is not requested or (requested and not emitting(light)):
            errors.append('physical flashlight does not illuminate world')
        if report.get('low_quality') and light.get('shadow') or requested and not report.get('low_quality') and not light.get('shadow'):
            errors.append('flashlight shadow mismatch')
        for circuit in expected:
            ceiling = next(x for x in actual['lights'] if x['id'] == 'ceiling_' + circuit)
            if not expected[circuit] and (ceiling['visible'] or ceiling['energy'] != 0):
                errors.append('cut ceiling remains lit')
    elif light is not None:
        errors.append('baseline invents flashlight')
    return errors


def validate_result(report, exit_code, log):
    try:
        return _validate_result(report, exit_code, log)
    except (TypeError, ValueError, AttributeError, KeyError, OverflowError, StopIteration):
        return ['malformed proof report']


def _validate_result(report, exit_code, log):
    errors = list(report.get('failures', ['missing failures field']))
    if exit_code:
        errors.append(f'engine exit {exit_code}')
    if re.search(r'(?:SCRIPT ERROR:|ERROR:|Parse Error|Segmentation fault)', log):
        errors.append('engine error in log')
    if report.get('display_driver', '').lower() != 'x11' or report.get('rendering_method') != 'gl_compatibility' or not report.get('renderer') or report.get('resolution') != [1280, 720]:
        errors.append('render contract absent')
    samples = report.get('frame_intervals_ms', [])
    if report.get('frames_drawn', 0) <= 0 or not samples or any(type(v) not in (int, float) or not math.isfinite(v) or v <= 0 for v in samples) or len(samples) != len(report.get('frame_stages', [])):
        errors.append('invalid rendered frame samples')
    mode = report.get('mode')
    if mode not in ('perf', 'mission', 'capture', 'lighting', 'lighting-perf'):
        errors.append('unknown mode')
    if mode in ('perf', 'mission', 'capture') and report.get('frames_drawn') != len(samples) + 1:
        errors.append('drawn frames disagree with intervals')
    if mode == 'perf' and (report.get('performance_valid') is not True or report.get('waypoint_positions') != PERF_ROUTE or report.get('waypoints_completed') != 9):
        errors.append('historical route contract absent')
    if mode in ('perf', 'mission', 'capture') and (report.get('travelled_m', 0) < 90 or report.get('waypoints_completed', 0) < 8):
        errors.append('physical route incomplete')
    if report.get('mode') in ('mission', 'capture'):
        if report.get('require_lighting'):
            native = [event for event in report.get('events', []) if event.get('id') == 'flashlight_native_f']
            if len(native) != 1 or native[0].get('native_exit') != 0 or native[0].get('intent_before') is not False or native[0].get('intent_after') is not True or native[0].get('visible_before') is not False or native[0].get('visible_after') is not True:
                errors.append('native flashlight proof absent')
        if report.get('ending') != report.get('expected_ending') or report.get('ending') not in ('mother', 'n7') or report.get('health', 0) <= 0 or report.get('phase') != 4:
            errors.append('mission incomplete')
        if report.get('circuits_available'):
            for name in ('maintenance', 'archives'):
                commands = [c for c in report.get('commands', []) if c.get('id') == 'breaker_' + name]
                if not commands or not all(c.get('native') and c.get('aim_valid') and c.get('changed') and c.get('prompt_changed') for c in commands):
                    errors.append(f'native breaker proof missing: {name}')
    if mode in ('lighting', 'lighting-perf'):
        if report.get('performance_valid') is not False or report.get('scene_inspection') is not True:
            errors.append('controlled scene not declared')
        observations = report.get('lighting_samples', [])
        zones = {row['zone'] for row in observations}
        expected_zones = {'refuge', 'decontamination', 'maintenance', 'archives', 'core'} if mode == 'lighting' else {'maintenance', 'core'}
        if zones != expected_zones:
            errors.append('lighting zones incomplete')
        if mode == 'lighting':
            if len(observations) != len(LIGHTING_LABELS) or {row['label'] for row in observations} != LIGHTING_LABELS:
                errors.append('complete lighting catalogue absent')
            for target in CRITICAL_TARGETS:
                pair = [row for row in observations if row['label'].startswith('critical_' + target + '_flash_')]
                if len(pair) != 2 or len({json.dumps([row['observation'][key] for key in ['camera_position', 'camera_rotation', 'fov']]) for row in pair}) != 1:
                    errors.append('critical paired pose absent or different')
            for zone in expected_zones:
                paired = [row for row in observations if row['label'].startswith(zone + '_power_')]
                wanted = {zone + power + flash for power in ['_power_on', '_power_off'] for flash in ['_flash_on', '_flash_off']}
                if len(paired) != 4 or {row['label'] for row in paired} != wanted:
                    errors.append('paired lighting captures incomplete')
                poses = {json.dumps([row['observation'][key] for key in ['camera_position', 'camera_rotation', 'fov']]) for row in paired}
                if len(poses) != 1:
                    errors.append('paired poses differ')
        if report.get('require_lighting') and not report.get('lighting_available'):
            errors.append('required lighting absent')
        for row in observations:
            actual = row['observation']
            errors.extend(validate_observation(actual, row, report))
            lights = actual['lights']
            if actual.get('energy') != 0 or not actual.get('live_enemies'):
                errors.append('energy zero/live actor fixture absent')
            if actual.get('scale_3d') != (0.67 if report.get('low_quality') else 1.0):
                # Godot serializes single-precision viewport scaling.
                if abs(actual.get('scale_3d', -1) - (0.67 if report.get('low_quality') else 1.0)) > 1e-5:
                    errors.append('effective quality mismatch')
            if report.get('lighting_available'):
                if {light['id'] for light in lights} != LIGHT_IDS or len(lights) != 9:
                    errors.append('named physical lights absent')
                flashlight = actual['flashlight']
                if flashlight.get('visible') != row['flashlight_requested'] or (report.get('low_quality') and flashlight.get('shadow')) or (row['flashlight_requested'] and not report.get('low_quality') and not flashlight.get('shadow')):
                    errors.append('physical flashlight mismatch')
                if any(light.get('shadow') for light in lights):
                    errors.append('fixed lights exceed shadow budget')
                for light in lights:
                    if type(light.get('energy')) not in (int, float) or not math.isfinite(light['energy']) or light['energy'] < 0:
                        errors.append('invalid light energy')
                for circuit in ('maintenance', 'archives'):
                    if not actual['circuits'][circuit]:
                        light = next(x for x in lights if x['id'] == 'ceiling_' + circuit)
                        if light['visible'] or light['energy'] != 0:
                            errors.append('cut ceiling remains lit')
            elif actual.get('flashlight') is not None:
                errors.append('baseline invents flashlight')
            if mode == 'lighting' and not row.get('png'):
                errors.append('lighting screenshot absent')
        if mode == 'lighting-perf':
            windows = report.get('cost_windows', [])
            if [w['label'] for w in windows] != ['core_off', 'core_on', 'maintenance_alarm_off', 'maintenance_alarm_on']:
                errors.append('separate cost windows incomplete')
            if len(observations) != 4 or [row['label'] for row in observations] != COST_LABELS or any(row.get('png') for row in observations):
                errors.append('cost observations absent or captures mixed into measurement')
            for window in windows:
                values = window.get('intervals_ms', [])
                if len(values) < 20 or window.get('frames_drawn') != len(values) + 1 or any(not positive(v) for v in values):
                    errors.append('invalid cost window')
                    continue
                tolerance = max(values)
                if abs(sum(values) - 6000) > tolerance:
                    errors.append('cost window is not six seconds within one frame')
                row = next(row for row in observations if row['label'] == window['label'])
                before, after = row['observation'], window['observation_after']
                errors.extend(validate_observation(after, row, report))
                elapsed = (after['usec'] - before['usec']) / 1000
                if not positive(elapsed) or abs(elapsed - 6000) > tolerance:
                    errors.append('cost before/after duration mismatch')
                if any(before[key] != after[key] for key in ['camera_position', 'camera_rotation', 'fov', 'scale_3d', 'energy']):
                    errors.append('cost scene changed during window')
                if window['label'].startswith('maintenance'):
                    for observation in (before, after):
                        if not positive(observation['alarms']['maintenance']):
                            errors.append('cost alarm timer inactive')
                        if report.get('lighting_available') and not emitting(next(x for x in observation['lights'] if x['id'] == 'alarm_maintenance')):
                            errors.append('cost physical alarm inactive')
    return errors


def hashes(project):
    names = subprocess.check_output(['git', '-C', str(project), 'ls-files', '--cached', '--others', '--exclude-standard', '-z']).decode().split('\0')
    return {name: hashlib.sha256((project / name).read_bytes()).hexdigest() for name in names if name and (project / name).is_file()}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--project', type=Path, required=True)
    p.add_argument('--godot', required=True)
    p.add_argument('--output', type=Path, required=True)
    p.add_argument('--mode', choices=['perf', 'mission', 'capture', 'lighting', 'lighting-perf'], required=True)
    p.add_argument('--ending', choices=['mother', 'n7'], default='mother')
    p.add_argument('--display', default=':100')
    p.add_argument('--require-circuits', action='store_true')
    p.add_argument('--require-lighting', action='store_true')
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
    engine = Path(a.godot).resolve()
    wrapper = Path(__file__).resolve()
    artifact_paths = {'engine': engine, 'wrapper': wrapper, 'probe': wrapper.with_name('probe_sector_power.gd')}
    artifact_before = {key: hashlib.sha256(path.read_bytes()).hexdigest() for key, path in artifact_paths.items()}
    probe = Path(__file__).with_name('probe_sector_power.gd').resolve()
    command = [a.godot, '--path', str(project), '--display-driver', 'x11', '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', '--resolution', '1280x720', '--position', '0,0', '--script', str(probe), '--', '--proof-output=' + str(output), '--probe-mode=' + a.mode, '--ending=' + a.ending, '--display=' + a.display]
    if a.require_circuits:
        command.append('--require-circuits')
    if a.require_lighting:
        command.append('--require-lighting')
    if a.low:
        command.append('--low')
    manifest = {'artifacts_before': artifact_before, 'command': command, 'project': str(project), 'head': subprocess.check_output(['git', '-C', str(project), 'rev-parse', 'HEAD']).decode().strip(), 'probe_sha256': hashlib.sha256(probe.read_bytes()).hexdigest(), 'source_before': before, 'started_unix': time.time(), 'display': a.display, 'limits': 'Linux X11; renderer recorded by probe; no target GPU or Windows claim. Capture screenshots are not video or performance; Dummy audio does not prove audible output. No X server lifecycle changes.'}
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
    if isinstance(report, dict):
        report['require_lighting'] = a.require_lighting
    errors = validate_result(report, exit_code, (output / 'engine.log').read_text(errors='replace'))
    if not isinstance(report, dict):
        report = {}
    if report.get('mode') != a.mode or report.get('low_quality') is not a.low:
        errors.append('requested scenario/quality mismatch')
    after = hashes(project)
    artifact_after = {key: hashlib.sha256(path.read_bytes()).hexdigest() for key, path in artifact_paths.items()}
    manifest['artifacts_after'] = artifact_after
    if artifact_before != artifact_after:
        errors.append('engine/wrapper/probe changed during proof')
    if a.mode == 'lighting':
        for row in report.get('lighting_samples', []):
            png = output / row.get('png', '')
            if png.parent != output or not png.is_file() or png.read_bytes()[:8] != b'\x89PNG\r\n\x1a\n':
                errors.append('missing or invalid PNG artifact')
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
