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
import struct
import zlib


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


def validate_result(report, exit_code, log, *, flashlight_requested=None, terminal_variant=None):
    try:
        errors = _validate_result(report, exit_code, log, flashlight_requested)
        if terminal_variant is not None and report.get('terminal', {}).get('variant') != terminal_variant:
            errors.append('requested terminal variant not observed')
        return errors
    except (TypeError, ValueError, AttributeError, KeyError, IndexError, OverflowError, StopIteration):
        return ['malformed proof report']


def _validate_result(report, exit_code, log, flashlight_requested=None):
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
    if mode not in ('perf', 'mission', 'capture', 'lighting', 'lighting-perf', 'persistence'):
        errors.append('unknown mode')
    if mode in ('perf', 'mission', 'capture') and report.get('frames_drawn') != len(samples) + 1:
        errors.append('drawn frames disagree with intervals')
    if mode == 'perf' and (report.get('performance_valid') is not True or report.get('waypoint_positions') != PERF_ROUTE or report.get('waypoints_completed') != 9):
        errors.append('historical route contract absent')
    if mode == 'perf' and (flashlight_requested is not None or 'flashlight_requested' in report or report.get('schema', 0) >= 3):
        requested = report['flashlight_requested']
        if type(requested) is not bool or flashlight_requested is not None and requested is not flashlight_requested:
            errors.append('requested perf flashlight scenario mismatch')
        if report.get('schema') != 3:
            errors.append('perf flashlight observation schema absent')
        route = report['perf_flashlight_samples']
        if len(route) != len(samples) + 1:
            errors.append('perf flashlight observations do not cover measured callbacks')
        observations = [report['perf_flashlight_before_warmup'], *route, report['final_observation']]
        for actual in observations:
            light = actual['flashlight']
            if light is None and requested is False:
                continue
            if light.get('visible') is not requested or light.get('intent') is not requested:
                errors.append('physical perf flashlight differs from request')
            if requested and (not emitting(light) or light.get('shadow') is not (not report.get('low_quality', False))):
                errors.append('physical perf flashlight emission/quality mismatch')
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
                start, end = window['measurement_start_usec'], window['measurement_end_usec']
                if any(type(tick) is not int or tick <= 0 for tick in (start, end)):
                    errors.append('invalid monotonic cost bounds')
                    continue
                elapsed_usec = end - start
                if abs(math.fsum(values) * 1000 - elapsed_usec) > 0.01:
                    errors.append('cost intervals disagree with measured bounds')
                if not (6000000 <= elapsed_usec < 6000000 + values[-1] * 1000):
                    errors.append('cost duration does not stop at first frame reaching six seconds')
                row = next(row for row in observations if row['label'] == window['label'])
                before, after = row['observation'], window['observation_after']
                errors.extend(validate_observation(after, row, report))
                if any(type(obs['usec']) is not int or obs['usec'] <= 0 for obs in (before, after)) or not (before['usec'] <= start < end <= after['usec']):
                    errors.append('cost observations do not enclose measured bounds')
                if any(before[key] != after[key] for key in ['camera_position', 'camera_rotation', 'fov', 'scale_3d', 'energy']):
                    errors.append('cost scene changed during window')
                if window['label'].startswith('maintenance'):
                    for observation in (before, after):
                        if not positive(observation['alarms']['maintenance']):
                            errors.append('cost alarm timer inactive')
                        if report.get('lighting_available') and not emitting(next(x for x in observation['lights'] if x['id'] == 'alarm_maintenance')):
                            errors.append('cost physical alarm inactive')
    if 'terminal' in report or mode == 'persistence':
        errors.extend(validate_issue18(report))
    return errors


ROBOT_IDS = {'sentinel_1', 'crawler_1', 'sentinel_2', 'crawler_2', 'sentinel_3', 'crawler_3'}
PRIMARY_IDS = {'crate', 'sentinel_1', 'arc'}
PERSISTENCE_STAGES = ['initial', 'modified', 'revisited', 'restored']
SAVE_KEYS = {'schema', 'crate_broken', 'death_poses', 'circuits', 'relations', 'health', 'energy', 'ammo',
             'reserve', 'components', 'medkits', 'cells', 'upgraded', 'phase', 'ending', 'collected',
             'defeated', 'facts', 'memory', 'player_position', 'player_yaw', 'elapsed'}


def require(value, message):
    if not value:
        raise ValueError(message)


def keys(value, expected):
    require(type(value) is dict and set(value) == set(expected.split()), 'unexpected or missing proof fields')


def number(value):
    return type(value) in (int, float) and math.isfinite(value)


def vector(value):
    return type(value) is list and len(value) == 3 and all(number(x) for x in value)


def close_vector(a, b, tolerance=.03):
    return vector(a) and vector(b) and math.dist(a, b) <= tolerance


def yaw_equal(a, b):
    return number(a) and number(b) and abs(math.remainder(a-b, 2*math.pi)) < .01


def relative_artifact(value, suffix):
    return (type(value) is str and bool(value) and Path(value).name == value
            and value.endswith(suffix) and '\\' not in value)


def validate_shot(shot, weapon):
    keys(shot, 'accepted weapon ammo_before ammo_after energy_before energy_after energy_cost impact_visible impact ray_from ray_to target_before target_position target_half_size usec')
    require(shot['accepted'] is True and type(shot['weapon']) is int and shot['weapon'] == weapon, 'real shot absent')
    require(type(shot['target_before']) is int and shot['target_before'] > 0, 'target instance absent')
    require(shot['impact_visible'] is True and type(shot['usec']) is int and shot['usec'] > 0, 'impact observation absent')
    require(all(type(shot[k]) is int and shot[k] >= 0 for k in ['ammo_before', 'ammo_after']), 'invalid shot ammunition')
    require(all(number(shot[k]) and shot[k] >= 0 for k in ['energy_before', 'energy_after', 'energy_cost']), 'invalid shot energy')
    require(shot['ammo_after'] == shot['ammo_before'] - (1 if weapon == 0 else 0), 'shot ammunition not consumed')
    require(shot['energy_cost'] > 0 if weapon == 1 else shot['energy_cost'] == 0, 'weapon energy cost mismatch')
    require(abs(shot['energy_after']-(shot['energy_before']-shot['energy_cost'])) < .001, 'shot energy inconsistent')
    require(all(vector(shot[k]) for k in ['impact', 'ray_from', 'ray_to', 'target_position', 'target_half_size']), 'invalid shot vector')
    require(all(x > 0 for x in shot['target_half_size']), 'invalid target bounds')
    impact, start, end = shot['impact'], shot['ray_from'], shot['ray_to']
    distance = math.dist(start, end)
    require(distance > 0 and abs(math.dist(start, impact)+math.dist(impact, end)-distance) < .03, 'impact outside actual shot segment')
    require(all(abs(p-c) <= h+.03 for p, c, h in zip(impact, shot['target_position'], shot['target_half_size'])), 'impact outside observed collider bounds')


def validate_crate(crate, broken, position=False):
    keys(crate, 'broken intact panels collision' + (' position' if position else ''))
    require(crate['broken'] is broken and crate['intact'] is (not broken), 'crate visual differs from canonical state')
    require(type(crate['panels']) is int and crate['panels'] == (3 if broken else 0), 'crate panels absent')
    require(type(crate['collision']) is int and crate['collision'] == (0 if broken else 1), 'crate collision mismatch')
    if position:
        require(close_vector(crate['position'], [4, 0, -12]), 'wrong crate position')


def validate_terminal(report):
    terminal = report['terminal']
    keys(terminal, 'schema variant fixture robots crate_shot before_warmup before_measure measurement_start_usec measurement_end_usec preparation_start')
    require(type(terminal['schema']) is int and terminal['schema'] == 1 and terminal['fixture'] is True, 'terminal fixture contract absent')
    require(report['mode'] == 'perf' and terminal['variant'] in ('reference', 'candidate'), 'unknown terminal scenario')
    robots = terminal['robots']
    require(type(robots) is list and len(robots) == 6 and {r['id'] for r in robots} == ROBOT_IDS, 'six observed robots required')
    require(len({r['instance'] for r in robots}) == 6, 'duplicate robot instance')
    for robot in robots:
        keys(robot, 'id instance position_before yaw_before health_before collision_before position_after yaw_after health_after collision_after physics_after defeated damage')
        require(type(robot['instance']) is int and robot['instance'] > 0, 'robot instance absent')
        require(number(robot['health_before']) and robot['health_before'] > 0 and number(robot['health_after']) and robot['health_after'] == 0, 'real robot death absent')
        require(number(robot['damage']) and robot['damage'] >= robot['health_before'], 'preparation damage insufficient')
        require(type(robot['collision_before']) is int and robot['collision_before'] > 0 and type(robot['collision_after']) is int and robot['collision_after'] == 0, 'robot death collision absent')
        require(robot['physics_after'] is False and robot['defeated'] is True, 'robot death state absent')
        require(close_vector(robot['position_before'], robot['position_after']) and yaw_equal(robot['yaw_before'], robot['yaw_after']), 'frozen death pose changed')
    validate_shot(terminal['crate_shot'], 0)
    require(close_vector(terminal['crate_shot']['target_position'], [4, .4125, -12]), 'wrong perf crate')
    for stage in ['before_warmup', 'before_measure']:
        state = terminal[stage]
        keys(state, 'defeated live_ids trace_count crate flashlight position velocity casings usec')
        require(type(state['defeated']) is list and len(state['defeated']) == 6 and set(state['defeated']) == ROBOT_IDS and state['live_ids'] == [], 'terminal scene still has living or missing robots')
        require(type(state['trace_count']) is int and state['trace_count'] == (6 if terminal['variant'] == 'candidate' else 0), 'terminal traces mismatch')
        validate_crate(state['crate'], terminal['variant'] == 'candidate')
        lamp = state['flashlight']
        require(lamp['visible'] is True and lamp['intent'] is True and emitting(lamp) and lamp['shadow'] is (not report['low_quality']), 'terminal physical lamp/quality mismatch')
        require(close_vector(state['position'], terminal['preparation_start']) and close_vector(state['velocity'], [0, 0, 0]) and type(state['casings']) is int and state['casings'] == 0, 'terminal measured start contaminated')
        require(type(state['usec']) is int and state['usec'] > 0, 'invalid preparation timestamp')
    start, end = terminal['measurement_start_usec'], terminal['measurement_end_usec']
    require(type(start) is int and type(end) is int and end > start, 'invalid measured bounds')
    require(terminal['crate_shot']['usec'] < terminal['before_warmup']['usec'] and terminal['before_measure']['usec'] - terminal['before_warmup']['usec'] >= 2000000, 'preparation or warmup incomplete')
    require(terminal['before_measure']['usec'] <= start, 'measurement preceded preparation')
    require(abs((end-start)/1000-sum(report['frame_intervals_ms'])) <= max(report['frame_intervals_ms'])*2, 'measured clock disagrees with raw intervals')


def validate_persistence(report):
    p = report['persistence']
    keys(p, 'schema observations movement visits actions save_load arc_repeat images')
    require(type(p['schema']) is int and p['schema'] == 1 and report['schema'] == 4, 'persistence schema absent')
    require(report['phase'] == 4 and report['ending'] == report['expected_ending'] and report['ending'] in ('mother', 'n7') and report['health'] > 0, 'persistence mission incomplete')
    observations = p['observations']
    require([o['label'] for o in observations] == PERSISTENCE_STAGES, 'persistence stages absent or unordered')
    for index, observation in enumerate(observations):
        keys(observation, 'label usec objects player_id world_id gate_y gate_blocked circuits core_available')
        require(type(observation['usec']) is int and observation['usec'] > 0 and (index == 0 or observation['usec'] > observations[index-1]['usec']), 'stage clock invalid')
        require(all(type(observation[k]) is int and observation[k] > 0 for k in ['player_id', 'world_id']), 'actor IDs absent')
        objects = observation['objects']; require(set(objects) == PRIMARY_IDS, 'primary objects missing')
        initial = index == 0
        validate_crate(objects['crate'], not initial, True)
        robot = objects['sentinel_1']
        keys(robot, 'alive defeated position yaw visible collision processing meshes')
        require(vector(robot['position']) and number(robot['yaw']) and robot['alive'] is initial and robot['defeated'] is (not initial), 'robot state mismatch')
        require(robot['visible'] is True and robot['processing'] is initial and type(robot['collision']) is int and (robot['collision'] > 0 if initial else robot['collision'] == 0), 'robot visual/collision mismatch')
        require(type(robot['meshes']) is int and (robot['meshes'] == 0 if initial else 1 <= robot['meshes'] <= 3), 'robot trace budget mismatch')
        arc = objects['arc']; keys(arc, 'disabled fact barrier prompt emissive position')
        require(arc['disabled'] is (not initial) and arc['fact'] is (not initial) and arc['barrier'] is initial and arc['emissive'] is initial, 'ARC state mismatch')
        require(type(arc['prompt']) is str and bool(arc['prompt']) and (initial or arc['prompt'] == 'Verrou hors tension'), 'ARC prompt mismatch')
        require(close_vector(arc['position'], [2.8, 0, -57]), 'wrong ARC object')
        require(number(observation['gate_y']) and abs(observation['gate_y']-(0 if initial else 4)) < .03 and observation['gate_blocked'] is initial, 'gate restore mismatch')
        require(type(observation['core_available']) is bool and (initial or not observation['core_available']), 'quest core duplicated')
        keys(observation['circuits'], 'maintenance archives')
        require(all(type(v) is bool for v in observation['circuits'].values()), 'invalid circuits')
        if index > 1:
            require(objects['crate'] == observations[1]['objects']['crate'] and objects['arc'] == observations[1]['objects']['arc'] and observation['circuits'] == observations[1]['circuits'], 'persistent projection changed')
            require(close_vector(robot['position'], observations[1]['objects']['sentinel_1']['position']) and yaw_equal(robot['yaw'], observations[1]['objects']['sentinel_1']['yaw']), 'restored death pose changed')
    require(observations[1]['circuits']['maintenance'] != observations[1]['circuits']['archives'], 'mixed circuits absent')
    actions = p['actions']
    require(len(actions) == 3 and {a['id'] for a in actions} == PRIMARY_IDS, 'real modification actions absent')
    require(len({a['shot']['target_before'] for a in actions}) == 3, 'actions reuse a target instance')
    for action in actions:
        keys(action, 'id shot' + (' health_before health_after position_before yaw_before spawn' if action['id'] == 'sentinel_1' else ''))
        validate_shot(action['shot'], 1 if action['id'] == 'arc' else 0)
        require(observations[0]['usec'] < action['shot']['usec'] < observations[1]['usec'], 'action outside modification stage')
        if action['id'] == 'sentinel_1':
            require(number(action['health_before']) and action['health_before'] > 0 and number(action['health_after']) and action['health_after'] == 0, 'lethal hit absent')
            require(vector(action['spawn']) and not close_vector(action['position_before'], action['spawn'], .1), 'death pose merely spawn')
            robot = observations[1]['objects']['sentinel_1']
            require(close_vector(robot['position'], action['position_before']) and yaw_equal(robot['yaw'], action['yaw_before']), 'trace differs from observed death')
    save = p['save_load']
    keys(save, 'f5_exit f9_exit file_absent_before casings_before_f5 casings_after_f5 casings_after_f9 before_ids after_ids saved restored save_file save_sha256 save_bytes f5_usec f9_usec')
    require(type(save['f5_exit']) is int and save['f5_exit'] == 0 and type(save['f9_exit']) is int and save['f9_exit'] == 0 and save['file_absent_before'] is True, 'native save/load absent')
    require(all(type(save[k]) is int for k in ['casings_before_f5', 'casings_after_f5', 'casings_after_f9']) and min(save['casings_before_f5'], save['casings_after_f5']) > 0 and save['casings_after_f9'] == 0, 'transient effects not observed around save/load')
    require(save['before_ids'] == [observations[2]['player_id'], observations[2]['world_id']] and save['after_ids'] == [observations[3]['player_id'], observations[3]['world_id']] and all(a != b for a, b in zip(save['before_ids'], save['after_ids'])), 'both actors must be reconstructed')
    require(all([o['player_id'], o['world_id']] == save['before_ids'] for o in observations[:3]), 'unexpected reconstruction during revisits')
    require(type(save['f5_usec']) is int and type(save['f9_usec']) is int and observations[2]['usec'] < save['f5_usec'] < save['f9_usec'] < observations[3]['usec'], 'save/load order invalid')
    require(set(save['saved']) == SAVE_KEYS and set(save['restored']) == SAVE_KEYS, 'save snapshot field mismatch')
    require({k:v for k,v in save['saved'].items() if k != 'elapsed'} == {k:v for k,v in save['restored'].items() if k != 'elapsed'}, 'inventory/quest changed across load')
    require(save['saved']['schema'] == 4 and save['saved']['crate_broken'] is True and 'sentinel_1' in save['saved']['defeated'] and 'arc_lock_disabled' in save['saved']['facts'] and save['saved']['phase'] == 3, 'saved canonical state absent')
    pose = save['saved']['death_poses']['sentinel_1']; robot = observations[1]['objects']['sentinel_1']
    require(close_vector(pose['position'], robot['position']) and yaw_equal(pose['yaw'], robot['yaw']), 'saved death pose differs from scene')
    require(relative_artifact(save['save_file'], '.json') and re.fullmatch('[a-f0-9]{64}', save['save_sha256']) and type(save['save_bytes']) is int and 0 < save['save_bytes'] <= 65536, 'save artifact invalid')
    repeat = p['arc_repeat']; keys(repeat, 'disabled_signals changed_signals messages memory_before memory_after facts_before facts_after shot')
    require(all(type(repeat[k]) is int and repeat[k] == 0 for k in ['disabled_signals', 'messages']) and type(repeat['changed_signals']) is int and repeat['changed_signals'] == 1 and repeat['memory_before'] == repeat['memory_after'] and repeat['facts_before'] == repeat['facts_after'], 'ARC repeated transition beyond energy consumption')
    validate_shot(repeat['shot'], 1)
    movement = p['movement']; require(type(movement) is list and len(movement) >= 10, 'walking samples absent')
    epochs, distance = [], 0.
    for index, row in enumerate(movement):
        require(type(row) is list and len(row) == 5 and all(number(x) for x in row[:4]) and type(row[4]) is int, 'invalid walking sample')
        if not epochs or epochs[-1] != row[4]: epochs.append(row[4])
        if index:
            previous = movement[index-1]; dt = row[0]-previous[0]
            require(dt > 0 and dt <= .5, 'walking coverage gap')
            if row[4] == previous[4]:
                step = math.dist(row[1:4], previous[1:4]); distance += step
                require(step <= 7*dt+.12, 'teleport inside native walking')
    require(epochs == [save['before_ids'][1], save['after_ids'][1]] and distance >= 150, 'walking/reconstruction sequence incomplete')
    visits = p['visits']
    require(len(visits) == 9 and {(v['label'], v['id']) for v in visits} == {(label, ident) for label in PERSISTENCE_STAGES[1:] for ident in PRIMARY_IDS}, 'physical revisits absent')
    last = -1
    for visit in visits:
        keys(visit, 'label id sample'); sample = visit['sample']
        require(type(sample) is int and last < sample < len(movement), 'visits not ordered')
        last = sample; row = movement[sample]
        observation = observations[PERSISTENCE_STAGES.index(visit['label'])]
        require(row[4] == observation['world_id'] and math.dist(row[1:4], observation['objects'][visit['id']]['position']) <= 5, 'object never physically revisited')
        if visit['label'] == 'revisited':
            prior = next(v['sample'] for v in visits if v['label'] == 'modified' and v['id'] == visit['id'])
            require(any(x[3] > 2 for x in movement[prior:sample]), 'no return through refuge between visits')
    images = p['images']
    require(len(images) == 12 and {(x['label'], x['id']) for x in images} == {(label, ident) for label in PERSISTENCE_STAGES for ident in PRIMARY_IDS}, 'proof images incomplete')
    require(len({x['file'] for x in images}) == 12, 'image artifact reused')
    for image in images:
        keys(image, 'label id file camera_position camera_rotation fov controlled_camera')
        require(relative_artifact(image['file'], '.png') and vector(image['camera_position']) and vector(image['camera_rotation']) and number(image['fov']) and 1 < image['fov'] < 180 and image['controlled_camera'] is True, 'invalid controlled capture metadata')


def finite_tree(value):
    if type(value) is float:
        require(math.isfinite(value), 'nonfinite proof value')
    elif type(value) is dict:
        for item in value.values(): finite_tree(item)
    elif type(value) is list:
        for item in value: finite_tree(item)


def validate_issue18(report):
    try:
        finite_tree(report)
        require(type(report['failures']) is list and report['failures'] == [], 'proof failures are not an empty list')
        if 'terminal' in report:
            validate_terminal(report)
        if report['mode'] == 'persistence':
            validate_persistence(report)
        return []
    except (ValueError, TypeError, AttributeError, KeyError, IndexError, OverflowError, StopIteration) as error:
        return ['issue18 contract: ' + str(error)]


def validate_png(path, resolution):
    data = path.read_bytes()
    require(len(data) <= 16*1024*1024 and data.startswith(b'\x89PNG\r\n\x1a\n'), 'invalid PNG signature/size')
    offset, compressed, header, ended = 8, bytearray(), None, False
    while offset < len(data):
        require(offset+12 <= len(data), 'truncated PNG chunk')
        length = struct.unpack('>I', data[offset:offset+4])[0]
        kind = data[offset+4:offset+8]; end = offset+12+length
        require(end <= len(data), 'truncated PNG data')
        payload = data[offset+8:end-4]
        require(zlib.crc32(kind+payload) == struct.unpack('>I', data[end-4:end])[0], 'PNG checksum mismatch')
        if kind == b'IHDR':
            require(header is None and offset == 8 and length == 13, 'invalid PNG header')
            header = struct.unpack('>IIBBBBB', payload)
        elif kind == b'IDAT': compressed.extend(payload)
        elif kind == b'IEND':
            require(length == 0 and end == len(data), 'invalid PNG end'); ended = True
        offset = end
    require(header is not None and ended and bool(compressed), 'incomplete PNG')
    width, height, depth, color, compression, filtering, interlace = header
    require([width, height] == resolution and depth == 8 and color in (2, 6) and (compression, filtering, interlace) == (0, 0, 0), 'PNG format/resolution mismatch')
    stride = 1 + width*(3 if color == 2 else 4)
    decoder = zlib.decompressobj(); raw = decoder.decompress(compressed, stride*height+1)
    require(decoder.eof and not decoder.unused_data and len(raw) == stride*height and all(raw[row*stride] <= 4 for row in range(height)), 'invalid PNG image data')


def validate_artifacts(report, output):
    if report.get('mode') != 'persistence':
        return []
    try:
        output = output.resolve(); p = report['persistence']
        for image in p['images']:
            require(relative_artifact(image['file'], '.png'), 'PNG escapes output')
            path = output / image['file']
            require(path.resolve().parent == output and path.is_file(), 'missing or escaped PNG')
            validate_png(path, report['resolution'])
        save = p['save_load']; require(relative_artifact(save['save_file'], '.json'), 'save escapes output')
        path = output / save['save_file']
        require(path.resolve().parent == output and path.is_file(), 'missing or escaped save')
        data = path.read_bytes()
        require(len(data) == save['save_bytes'] and hashlib.sha256(data).hexdigest() == save['save_sha256'], 'save bytes/hash mismatch')
        require(json.loads(data) == save['saved'], 'saved artifact differs from observations')
        return []
    except (OSError, ValueError, TypeError, KeyError, AttributeError, struct.error, zlib.error) as error:
        return ['issue18 artifacts: ' + str(error)]


def hashes(project):
    names = subprocess.check_output(['git', '-C', str(project), 'ls-files', '--cached', '--others', '--exclude-standard', '-z']).decode().split('\0')
    return {name: hashlib.sha256((project / name).read_bytes()).hexdigest() for name in names if name and (project / name).is_file()}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--project', type=Path, required=True)
    p.add_argument('--godot', required=True)
    p.add_argument('--output', type=Path, required=True)
    p.add_argument('--mode', choices=['perf', 'mission', 'capture', 'lighting', 'lighting-perf', 'persistence'], required=True)
    p.add_argument('--ending', choices=['mother', 'n7'], default='mother')
    p.add_argument('--display', default=':100')
    p.add_argument('--require-circuits', action='store_true')
    p.add_argument('--require-lighting', action='store_true')
    p.add_argument('--low', action='store_true')
    p.add_argument('--flashlight-on', action='store_true', help='perf only; enable the physical flashlight before warmup')
    p.add_argument('--terminal-variant', choices=['reference', 'candidate'], help='perf fixture; observed deaths and crate impact before warmup')
    p.add_argument('--timeout', type=int, default=900)
    a = p.parse_args()
    if a.flashlight_on and a.mode != 'perf':
        p.error('--flashlight-on requires --mode perf')
    if a.terminal_variant and (a.mode != 'perf' or not a.flashlight_on):
        p.error('--terminal-variant requires --mode perf --flashlight-on')
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
    artifact_paths = {'engine': engine, 'wrapper': wrapper, 'probe': wrapper.with_name('probe_sector_power.gd'), 'selfcheck': wrapper.with_name('selfcheck_sector_power.py'), 'input_helper': project / 'tools/x11_input.py'}
    artifact_before = {key: hashlib.sha256(path.read_bytes()).hexdigest() for key, path in artifact_paths.items()}
    probe = Path(__file__).with_name('probe_sector_power.gd').resolve()
    command = [a.godot, '--path', str(project), '--display-driver', 'x11', '--rendering-method', 'gl_compatibility', '--audio-driver', 'Dummy', '--resolution', '1280x720', '--position', '0,0', '--script', str(probe), '--', '--proof-output=' + str(output), '--probe-mode=' + a.mode, '--ending=' + a.ending, '--display=' + a.display]
    if a.require_circuits:
        command.append('--require-circuits')
    if a.require_lighting:
        command.append('--require-lighting')
    if a.flashlight_on:
        command.append('--flashlight-on')
    if a.low:
        command.append('--low')
    if a.terminal_variant:
        command.append('--terminal-variant=' + a.terminal_variant)
    manifest = {'artifacts_before': artifact_before, 'command': command, 'project': str(project), 'head': subprocess.check_output(['git', '-C', str(project), 'rev-parse', 'HEAD']).decode().strip(), 'probe_sha256': hashlib.sha256(probe.read_bytes()).hexdigest(), 'source_before': before, 'started_unix': time.time(), 'display': a.display, 'limits': 'Linux X11; renderer recorded by probe; no target GPU or Windows claim. Capture screenshots are not video or performance; Dummy audio does not prove audible output. No X server lifecycle changes.'}
    if a.mode == 'perf':
        manifest['flashlight_requested'] = a.flashlight_on
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
    errors = validate_result(report, exit_code, (output / 'engine.log').read_text(errors='replace'), flashlight_requested=a.flashlight_on if a.mode == 'perf' else None, terminal_variant=a.terminal_variant)
    if not isinstance(report, dict):
        report = {}
    errors.extend(validate_artifacts(report, output))
    if report.get('require_lighting') is not a.require_lighting:
        errors.append('requested lighting capability differs from report')
    if a.terminal_variant is None and 'terminal' in report:
        errors.append('unexpected terminal preparation')
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
