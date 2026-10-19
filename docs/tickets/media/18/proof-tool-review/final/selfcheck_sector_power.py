import unittest
import copy
import subprocess
import sys
from pathlib import Path
from prove_sector_power import validate_result, validate_artifacts, LIGHT_IDS


def valid():
    return {'mode': 'perf', 'failures': [], 'performance_valid': True, 'waypoint_positions': [[0,0,z] for z in [-10,-16,-22,-32,-36,-42,-32,-12,7]], 'frames_drawn': 121, 'frame_intervals_ms': [16.7] * 120, 'frame_stages': ['walk'] * 120, 'travelled_m': 98, 'waypoints_completed': 9, 'rendering_method': 'gl_compatibility', 'display_driver': 'X11', 'renderer': 'llvmpipe', 'resolution': [1280, 720], 'commands': []}


def lighting_fixture():
    rows = []
    for zone in ['refuge', 'decontamination', 'maintenance', 'archives', 'core']:
        for powered in [True, False]:
            for enabled in [False, True]:
                label = zone + ('_power_on' if powered else '_power_off') + ('_flash_on' if enabled else '_flash_off')
                lights = [{'id': name, 'energy': 0 if not powered and name in ['ceiling_maintenance', 'ceiling_archives'] else 1, 'visible': powered or name not in ['ceiling_maintenance', 'ceiling_archives'], 'shadow': False, 'range': 10, 'mask': 1} for name in LIGHT_IDS]
                rows.append({'zone': zone, 'label': label, 'png': label + '.png', 'flashlight_requested': enabled, 'circuits_requested': {'maintenance': powered, 'archives': powered}, 'observation': {'energy': 0, 'scale_3d': 1.0, 'live_enemies': [{'health': 10}], 'lights': lights, 'flashlight': {'visible': enabled, 'shadow': True, 'energy': 1, 'range': 12, 'mask': 1}, 'circuits': {'maintenance': powered, 'archives': powered}, 'camera_position': [0,1.58,-20], 'camera_rotation': [0,0,0], 'fov': 76}})
    for label in ([f'critical_{target}_flash_{state}' for target in ['relay', 'breaker_maintenance', 'evidence'] for state in ['off', 'on']] + [f'neon_{i:02}' for i in range(13)] + [f'reduced_{i:02}' for i in range(3)] + ['alarm_active', 'alarm_expired']):
        row = copy.deepcopy(rows[0])
        row.update(label=label, png=label + '.png', zone='archives' if 'evidence' in label else 'maintenance', flashlight_requested=label.endswith('_on'))
        row['observation']['flashlight']['visible'] = row['flashlight_requested']
        power = not label.startswith(('critical_', 'alarm_'))
        row['circuits_requested'] = {'maintenance': power, 'archives': power if label.startswith('critical_') else True}
        row['observation']['circuits'] = row['circuits_requested'].copy()
        for light in row['observation']['lights']:
            if light['id'] in ['ceiling_maintenance', 'ceiling_archives']:
                light['visible'] = row['circuits_requested'][light['id'].removeprefix('ceiling_')]
                light['energy'] = int(light['visible'])
        rows.append(row)
    report = valid() | {'mode': 'lighting', 'performance_valid': False, 'scene_inspection': True, 'lighting_available': True, 'require_lighting': True, 'low_quality': False, 'lighting_samples': rows}
    return report



def cost_fixture():
    report = lighting_fixture()
    template = report['lighting_samples'][0]
    rows, windows = [], []
    for label in ['core_off', 'core_on', 'maintenance_alarm_off', 'maintenance_alarm_on']:
        row = copy.deepcopy(template)
        row.update(label=label, png='', zone='maintenance' if label.startswith('maintenance') else 'core', flashlight_requested=label.endswith('_on'))
        row['circuits_requested'] = {'maintenance': row['zone'] != 'maintenance', 'archives': True}
        actual = row['observation']
        actual['circuits'] = row['circuits_requested'].copy()
        actual['flashlight']['visible'] = row['flashlight_requested']
        actual['alarms'] = {'maintenance': 1.3 if row['zone'] == 'maintenance' else 0, 'archives': 0}
        actual['usec'] = 1000000
        for light in actual['lights']:
            if light['id'] == 'ceiling_maintenance':
                light.update(visible=row['circuits_requested']['maintenance'], energy=int(row['circuits_requested']['maintenance']))
        after = copy.deepcopy(actual)
        after['usec'] = 7000000
        windows.append({'label': label, 'frames_drawn': 61, 'intervals_ms': [100] * 60, 'observation_after': after, 'measurement_start_usec': 1000000, 'measurement_end_usec': 7000000})
        rows.append(row)
    return report | {'mode': 'lighting-perf', 'lighting_samples': rows, 'cost_windows': windows}


def perf_flashlight_fixture(enabled=True):
    lamp = {'visible': enabled, 'intent': enabled, 'energy': 2.0, 'range': 16.0, 'mask': 1, 'shadow': True}
    sample = {'usec': 1000000, 'stage': 'walk', 'flashlight': lamp}
    report = valid() | {'schema': 3, 'flashlight_requested': enabled, 'low_quality': False,
                        'perf_flashlight_before_warmup': copy.deepcopy(sample),
                        'perf_flashlight_samples': [copy.deepcopy(sample) for _ in range(121)],
                        'final_observation': {'flashlight': copy.deepcopy(lamp)}}
    return report


class PerfFlashlightValidation(unittest.TestCase):
    def test_on_and_explicit_off_observations_are_accepted(self):
        for enabled in [False, True]:
            self.assertEqual(validate_result(perf_flashlight_fixture(enabled), 0, ''), [])
        self.assertEqual(validate_result(valid(), 0, ''), [])
        report = perf_flashlight_fixture()
        report['low_quality'] = True
        for actual in [report['perf_flashlight_before_warmup'], *report['perf_flashlight_samples'], report['final_observation']]:
            actual['flashlight']['shadow'] = False
        self.assertEqual(validate_result(report, 0, ''), [])

    def test_wrapper_request_binds_report_without_rewriting_it(self):
        for enabled in [False, True]:
            report = perf_flashlight_fixture(not enabled)
            before = copy.deepcopy(report)
            self.assertTrue(validate_result(report, 0, '', flashlight_requested=enabled))
            self.assertEqual(report, before)
        self.assertTrue(validate_result(valid(), 0, '', flashlight_requested=False))

    def test_requested_on_observed_off_is_rejected(self):
        report = perf_flashlight_fixture()
        report['final_observation']['flashlight']['visible'] = False
        self.assertTrue(validate_result(report, 0, ''))

    def test_observed_route_change_is_rejected(self):
        for enabled in [False, True]:
            for field in ['visible', 'intent']:
                report = perf_flashlight_fixture(enabled)
                report['perf_flashlight_samples'][60]['flashlight'][field] = not enabled
                with self.subTest(enabled=enabled, field=field):
                    self.assertTrue(validate_result(report, 0, ''))

    def test_before_warmup_state_is_checked(self):
        report = perf_flashlight_fixture()
        report['perf_flashlight_before_warmup']['flashlight']['visible'] = False
        self.assertTrue(validate_result(report, 0, ''))

    def test_missing_on_observations_or_properties_are_rejected(self):
        for field in ['visible', 'intent', 'energy', 'range', 'mask', 'shadow']:
            report = perf_flashlight_fixture()
            del report['perf_flashlight_samples'][60]['flashlight'][field]
            with self.subTest(field=field): self.assertTrue(validate_result(report, 0, ''))
        for field in ['perf_flashlight_before_warmup', 'perf_flashlight_samples', 'final_observation']:
            report = perf_flashlight_fixture()
            del report[field]
            with self.subTest(field=field): self.assertTrue(validate_result(report, 0, ''))
        report = perf_flashlight_fixture()
        report['perf_flashlight_samples'][60]['flashlight'] = None
        self.assertTrue(validate_result(report, 0, ''))
        report = perf_flashlight_fixture()
        report['perf_flashlight_samples'].pop()
        self.assertTrue(validate_result(report, 0, ''))

    def test_on_must_emit_and_match_quality(self):
        for field, value in [('energy', 0), ('energy', float('nan')), ('range', 0), ('mask', 2), ('shadow', False)]:
            report = perf_flashlight_fixture()
            report['perf_flashlight_samples'][60]['flashlight'][field] = value
            with self.subTest(field=field): self.assertTrue(validate_result(report, 0, ''))
        report = perf_flashlight_fixture()
        report['low_quality'] = True
        self.assertTrue(validate_result(report, 0, ''))

    def test_other_modes_reject_flag_before_starting_runtime(self):
        for mode in ['mission', 'capture', 'lighting', 'lighting-perf']:
            result = subprocess.run([sys.executable, str(Path(__file__).with_name('prove_sector_power.py')),
                                     '--project', '/absent-project', '--godot', '/absent-engine', '--output', '/absent-output',
                                     '--mode', mode, '--flashlight-on'], capture_output=True, text=True)
            with self.subTest(mode=mode):
                self.assertEqual(result.returncode, 2)
                self.assertIn('--flashlight-on requires --mode perf', result.stderr)

class ProofValidation(unittest.TestCase):

    def test_requested_power_matches_effective_even_baseline(self):
        for baseline in [False, True]:
            report = lighting_fixture()
            if baseline:
                report.update(lighting_available=False, require_lighting=False)
                for row in report['lighting_samples']: row['observation']['flashlight'] = None
            report['lighting_samples'][2]['observation']['circuits']['maintenance'] = True
            with self.subTest(baseline=baseline): self.assertTrue(validate_result(report, 0, ''))

    def test_lamp_must_emit_into_world(self):
        for key, value in [('energy', 0), ('energy', float('nan')), ('range', 0), ('range', float('inf')), ('mask', 2)]:
            with self.subTest(key=key, value=value):
                report = lighting_fixture()
                report['lighting_samples'][1]['observation']['flashlight'][key] = value
                self.assertTrue(validate_result(report, 0, ''))

    def test_full_catalogue_and_critical_pose(self):
        for prefix in ['critical_', 'neon_', 'reduced_', 'alarm_']:
            report = lighting_fixture()
            report['lighting_samples'] = [row for row in report['lighting_samples'] if not row['label'].startswith(prefix)]
            with self.subTest(prefix=prefix): self.assertTrue(validate_result(report, 0, ''))
        report = lighting_fixture()
        report['lighting_samples'][21]['observation']['camera_position'][0] += 1
        self.assertTrue(validate_result(report, 0, ''))

    def test_cost_windows_duration_and_observations(self):
        report = cost_fixture()
        self.assertEqual(validate_result(report, 0, ''), [])
        for problem in ['short', 'long', 'missing_after', 'wrong_after', 'alarm_timer', 'alarm_light']:
            with self.subTest(problem=problem):
                broken = copy.deepcopy(report)
                window = broken['cost_windows'][2]
                if problem == 'short': window['intervals_ms'] = [0.001] * 60
                if problem == 'long': window['intervals_ms'] = [200] * 60
                if problem == 'missing_after': del window['observation_after']
                if problem == 'wrong_after': window['observation_after']['circuits']['maintenance'] = True
                if problem == 'alarm_timer': window['observation_after']['alarms']['maintenance'] = 0
                if problem == 'alarm_light':
                    next(light for light in window['observation_after']['lights'] if light['id'] == 'alarm_maintenance')['energy'] = 0
                self.assertTrue(validate_result(broken, 0, ''))

    def test_cost_clock_accepts_long_initial_unmeasured_gap(self):
        report = cost_fixture()
        for window in report['cost_windows']:
            window['measurement_start_usec'] += 500000
            window['measurement_end_usec'] += 500000
            window['observation_after']['usec'] += 550000
        self.assertEqual(validate_result(report, 0, ''), [])

    def test_cost_clock_rejects_forged_bounds_and_duration(self):
        for problem in ['missing_start', 'missing_end', 'sum_mismatch', 'before_start', 'after_end', 'short', 'long', 'rounding_too_long', 'noninteger', 'bool', 'nan', 'negative']:
            with self.subTest(problem=problem):
                report = cost_fixture()
                window = report['cost_windows'][0]
                if problem == 'missing_start': del window['measurement_start_usec']
                if problem == 'missing_end': del window['measurement_end_usec']
                if problem == 'sum_mismatch': window['measurement_start_usec'] += 1
                if problem == 'before_start': report['lighting_samples'][0]['observation']['usec'] += 1
                if problem == 'after_end': window['observation_after']['usec'] -= 1
                if problem in ['short', 'long', 'rounding_too_long']:
                    values = [100] * (59 if problem == 'short' else 62 if problem == 'long' else 61)
                    window['intervals_ms'] = values
                    window['frames_drawn'] = len(values) + 1
                    window['measurement_end_usec'] = 1000000 + sum(values) * 1000
                    window['observation_after']['usec'] = window['measurement_end_usec']
                if problem == 'noninteger': window['measurement_start_usec'] = 1000000.5
                if problem == 'bool': window['measurement_start_usec'] = True
                if problem == 'nan': window['measurement_start_usec'] = float('nan')
                if problem == 'negative': window['measurement_start_usec'] = -1
                self.assertTrue(validate_result(report, 0, ''))

    def test_cost_clock_accepts_last_frame_rounding(self):
        report = cost_fixture()
        for window in report['cost_windows']:
            window['intervals_ms'] = [99] * 61
            window['frames_drawn'] = 62
            window['measurement_end_usec'] = 7039000
            window['observation_after']['usec'] = 7040000
        self.assertEqual(validate_result(report, 0, ''), [])

    def test_valid_rendered_walk(self):
        self.assertEqual(validate_result(valid(), 0, ''), [])

    def test_rejects_failed_or_empty_runtime(self):
        for key, value in [('failures', ['blocked']), ('frames_drawn', 0), ('frame_intervals_ms', []), ('travelled_m', 0), ('waypoints_completed', 0), ('renderer', ''), ('resolution', [640, 480])]:
            with self.subTest(key=key):
                report = valid()
                report[key] = value
                self.assertTrue(validate_result(report, 0, ''))
        self.assertTrue(validate_result(valid(), 1, ''))
        self.assertTrue(validate_result(valid(), 0, 'SCRIPT ERROR: Invalid call'))

    def test_rejects_route_and_frame_forgery(self):
        for key, value in [('performance_valid', False), ('frames_drawn', 122), ('waypoints_completed', 8), ('waypoint_positions', [[0,0,-42]] * 9), ('mode', 'unknown'), ('frame_intervals_ms', [True] * 120)]:
            with self.subTest(key=key):
                report = valid() | {key: value}
                self.assertTrue(validate_result(report, 0, ''))

    def test_malformed_reports_fail_closed(self):
        for report in [None, [], {'failures': None}, valid() | {'frame_intervals_ms': None}, valid() | {'travelled_m': 'far'}]:
            with self.subTest(report=report):
                self.assertTrue(validate_result(report, 0, ''))

    def test_lighting_requires_real_observations(self):
        report = valid() | {'mode': 'lighting', 'performance_valid': False, 'lighting_available': True, 'lighting_samples': [], 'require_lighting': True}
        self.assertTrue(validate_result(report, 0, ''))

    def test_accepts_paired_real_lighting_and_absent_baseline(self):
        report = lighting_fixture()
        self.assertEqual(validate_result(report, 0, ''), [])
        report['lighting_available'] = False
        report['require_lighting'] = False
        for row in report['lighting_samples']:
            row['observation']['flashlight'] = None
        self.assertEqual(validate_result(report, 0, ''), [])
        report['require_lighting'] = True
        self.assertTrue(validate_result(report, 0, ''))

    def test_lighting_rejects_missing_pairs_and_wrong_pose(self):
        for problem in ['missing_pair', 'pose', 'shadow']:
            with self.subTest(problem=problem):
                report = lighting_fixture()
                if problem == 'missing_pair': report['lighting_samples'].pop(0)
                if problem == 'pose': report['lighting_samples'][1]['observation']['camera_position'][0] = 9
                if problem == 'shadow': report['lighting_samples'][0]['observation']['lights'][0]['shadow'] = True
                self.assertTrue(validate_result(report, 0, ''))

    def test_required_lighting_mission_needs_native_f(self):
        report = valid() | {'mode': 'mission', 'ending': 'mother', 'expected_ending': 'mother', 'health': 52, 'circuits_available': False, 'phase': 4, 'require_lighting': True}
        self.assertTrue(validate_result(report, 0, ''))
        report['events'] = [{'id': 'flashlight_native_f', 'native_exit': 0, 'intent_before': False, 'intent_after': True, 'visible_before': False, 'visible_after': True}]
        self.assertEqual(validate_result(report, 0, ''), [])

    def test_mission_requires_native_breakers_and_ending(self):
        report = valid() | {'mode': 'mission', 'ending': 'mother', 'expected_ending': 'mother', 'health': 52, 'circuits_available': True, 'phase': 4}
        self.assertTrue(validate_result(report, 0, ''))
        report['commands'] = [{'id': 'breaker_' + name, 'native': True, 'aim_valid': True, 'changed': True, 'prompt_changed': True} for name in ['maintenance', 'archives']]
        self.assertEqual(validate_result(report, 0, ''), [])
        report['ending'] = ''
        self.assertTrue(validate_result(report, 0, ''))



# Synthetic reports exercise rejection only; they are never runtime evidence.
ROBOT_IDS = ['sentinel_1', 'crawler_1', 'sentinel_2', 'crawler_2', 'sentinel_3', 'crawler_3']


def shot_fixture():
    return {'accepted': True, 'weapon': 0, 'ammo_before': 12, 'ammo_after': 11,
            'energy_before': 100, 'energy_after': 100, 'energy_cost': 0, 'impact_visible': True,
            'impact': [4, .4, -11.25], 'ray_from': [4, .4, -8], 'ray_to': [4, .4, -20],
            'target_before': 101, 'target_position': [4, .4125, -12],
            'target_half_size': [.825, .4125, .75], 'usec': 100}


def terminal_fixture(variant='candidate'):
    report = perf_flashlight_fixture()
    robots = []
    for index, ident in enumerate(ROBOT_IDS):
        robots.append({'id': ident, 'instance': index + 10, 'position_before': [index, 0, -20],
                       'yaw_before': .5, 'health_before': 65, 'collision_before': 1,
                       'position_after': [index, 0, -20], 'yaw_after': .5, 'health_after': 0,
                       'collision_after': 0, 'physics_after': False, 'defeated': True, 'damage': 1000})
    state = {'defeated': ROBOT_IDS.copy(), 'live_ids': [], 'trace_count': 6 if variant == 'candidate' else 0,
             'crate': {'broken': variant == 'candidate', 'intact': variant == 'reference',
                       'panels': 3 if variant == 'candidate' else 0, 'collision': 0 if variant == 'candidate' else 1},
             'flashlight': copy.deepcopy(report['final_observation']['flashlight']),
             'position': [0, 0, 7], 'velocity': [0, 0, 0], 'casings': 0, 'usec': 200, 'effects': {'impact': False, 'muzzle': False, 'beam': False, 'light': False, 'remaining': 0}}
    report['terminal'] = {'schema': 1, 'variant': variant, 'fixture': True, 'robots': robots,
                          'crate_shot': shot_fixture(), 'before_warmup': copy.deepcopy(state),
                          'before_measure': copy.deepcopy(state), 'measurement_start_usec': 2000200,
                          'measurement_end_usec': 4004200, 'preparation_start': [0, 0, 7]}
    report['terminal']['before_measure']['usec'] = 2000200
    for index, row in enumerate(report['perf_flashlight_samples']): row['usec'] = 2000200 + index*16700
    return report


def persistence_fixture():
    report = valid() | {'mode': 'persistence', 'schema': 4, 'low_quality': False,
                        'ending': 'mother', 'expected_ending': 'mother', 'phase': 4, 'health': 50}
    def objects(initial=False, restored=False):
        return {'crate': {'instance': 1101 if restored else 101, 'broken': not initial, 'intact': initial, 'panels': 0 if initial else 3,
                          'collision': 1 if initial else 0, 'position': [4, 0, -12]},
                'sentinel_1': {'instance': 1202 if restored else (102 if initial else 202), 'alive': initial, 'defeated': not initial, 'position': [3, 0, -20 if initial else -18],
                               'yaw': .3, 'visible': True, 'collision': 1 if initial else 0,
                               'processing': initial, 'meshes': 0 if initial else 3},
                'arc': {'instance': 1103 if restored else 103, 'disabled': not initial, 'fact': not initial, 'barrier': initial,
                        'prompt': 'Verrou électrique' if initial else 'Verrou hors tension', 'emissive': initial,
                        'position': [2.8, 0, -57]}}
    observations = []
    for index, label in enumerate(['initial', 'modified', 'revisited', 'restored']):
        observations.append({'label': label, 'usec': index * 1000 + 1, 'objects': objects(index == 0, index == 3),
                             'player_id': 1 if index < 3 else 3, 'world_id': 2 if index < 3 else 4,
                             'gate_y': 0 if index == 0 else 4, 'gate_blocked': index == 0,
                             'circuits': {'maintenance': False, 'archives': True}, 'core_available': index == 0})
    movement, visits = [], []
    t, z = 0., 7.
    for epoch, label in [(2, 'modified'), (2, 'revisited'), (4, 'restored')]:
        if epoch == 4:
            t += .1
            movement.append([t, 0, 0, z, epoch])
        for ident, destination in [('crate', -12), ('sentinel_1', -18), ('arc', -57), ('refuge', 7)]:
            while abs(z-destination) > .01:
                z += max(-.5, min(.5, destination-z)); t += .1
                movement.append([t, 0, 0, z, epoch])
            if ident != 'refuge': visits.append({'label': label, 'id': ident, 'sample': len(movement)-1})
    save = {'schema': 4, 'crate_broken': True, 'death_poses': {'sentinel_1': {'position': [3, 0, -18], 'yaw': .3}},
            'circuits': {'maintenance': False, 'archives': True}, 'relations': {'mother': 0, 'n7': 0},
            'health': 50, 'energy': 85, 'ammo': 10, 'reserve': 30, 'components': 0, 'medkits': 2, 'cells': 2,
            'upgraded': False, 'phase': 3, 'ending': '', 'collected': ['core'], 'defeated': ['sentinel_1'],
            'facts': ['arc_lock_disabled', 'core_recovered'], 'memory': [], 'player_position': [0, 0, 7],
            'player_yaw': 0, 'elapsed': 50}
    crate_shot = shot_fixture()
    robot_shot = shot_fixture() | {'target_before': 102, 'target_position': [3, .9, -18], 'target_half_size': [.5, .9, .5],
                                  'impact': [3, 1, -17.5], 'ray_from': [3, 1, -15], 'ray_to': [3, 1, -30], 'usec': 200}
    arc_shot = shot_fixture() | {'target_before': 103, 'weapon': 1, 'ammo_after': 12, 'energy_after': 85, 'energy_cost': 15,
                                'target_position': [2.8, .6, -57], 'target_half_size': [.4, .6, .225],
                                'impact': [2.8, .7, -56.775], 'ray_from': [2.8, .7, -54], 'ray_to': [2.8, .7, -65], 'usec': 300}
    payload = {'schema': 1, 'observations': observations, 'movement': movement, 'visits': visits,
               'actions': [{'id': 'crate', 'shot': crate_shot},
                           {'id': 'sentinel_1', 'shot': robot_shot, 'health_before': 5, 'health_after': 0,
                            'position_before': [3, 0, -18], 'yaw_before': .3, 'spawn': [3, 0, -20]},
                           {'id': 'arc', 'shot': arc_shot}],
               'save_load': {'f5_exit': 0, 'f9_exit': 0, 'file_absent_before': True,
                             'casings_before_f5': 1, 'casings_after_f5': 1, 'casings_after_f9': 0,
                             'before_ids': [1, 2], 'after_ids': [3, 4], 'saved': save,
                             'restored': copy.deepcopy(save), 'save_file': 'save.json', 'save_sha256': 'a'*64,
                             'save_bytes': 1000, 'f5_usec': 2200, 'f9_usec': 2500},
               'arc_repeat': {'disabled_signals': 0, 'changed_signals': 1, 'messages': 0,
                              'memory_before': [], 'memory_after': [], 'facts_before': ['arc_lock_disabled'], 'facts_after': ['arc_lock_disabled'], 'shot': copy.deepcopy(arc_shot)},
               'images': [{'label': label, 'id': ident, 'file': label+'_'+ident+'.png', 'camera_position': [0, 2, 0],
                           'camera_rotation': [0, 0, 0], 'fov': 76, 'controlled_camera': True}
                          for label in ['initial', 'modified', 'revisited', 'restored'] for ident in ['crate', 'sentinel_1', 'arc']]}
    payload['arc_repeat']['shot'].update(usec=3500, target_before=1103)
    before = copy.deepcopy(save); before['energy'] = 100
    payload['arc_repeat'].update(state_before=before, state_after=copy.deepcopy(save), changed_snapshots=[copy.deepcopy(save)])
    report['persistence'] = payload
    return report


class Issue18Validation(unittest.TestCase):
    def test_terminal_reference_and_candidate_contract(self):
        for variant in ['reference', 'candidate']:
            self.assertEqual(validate_result(terminal_fixture(variant), 0, '', flashlight_requested=True), [])

    def test_terminal_rejects_unobserved_death_or_mutated_pose(self):
        for field, value in [('defeated', False), ('health_after', 5), ('health_before', 0),
                             ('collision_after', 1), ('physics_after', True), ('position_after', [99, 0, 0]),
                             ('instance', True), ('yaw_before', float('nan'))]:
            with self.subTest(field=field):
                report = terminal_fixture(); report['terminal']['robots'][0][field] = value
                self.assertTrue(validate_result(report, 0, '', flashlight_requested=True))
        report = terminal_fixture(); report['terminal']['robots'].pop()
        self.assertTrue(validate_result(report, 0, '', flashlight_requested=True))

    def test_terminal_rejects_unchecked_start_or_wrong_visuals(self):
        for stage in ['before_warmup', 'before_measure']:
            for key, value in [('live_ids', ['sentinel_1']), ('casings', 1), ('velocity', [1, 0, 0]), ('trace_count', 0)]:
                with self.subTest(stage=stage, key=key):
                    report = terminal_fixture(); report['terminal'][stage][key] = value
                    self.assertTrue(validate_result(report, 0, '', flashlight_requested=True))
            report = terminal_fixture(); report['terminal'][stage]['flashlight']['visible'] = False
            self.assertTrue(validate_result(report, 0, '', flashlight_requested=True))

    def test_terminal_rejects_cli_count_or_fake_crate_shot(self):
        for key, value in [('accepted', False), ('ammo_after', 12), ('impact_visible', False),
                           ('impact', [0, 0, 0]), ('target_before', 0), ('ray_from', [True, 0, 0])]:
            with self.subTest(key=key):
                report = terminal_fixture(); report['terminal']['crate_shot'][key] = value
                self.assertTrue(validate_result(report, 0, '', flashlight_requested=True))
        for key in ['robots', 'before_measure', 'schema']:
            report = terminal_fixture(); del report['terminal'][key]
            self.assertTrue(validate_result(report, 0, '', flashlight_requested=True))

    def test_persistence_accepts_complete_synthetic_contract_only(self):
        self.assertEqual(validate_result(persistence_fixture(), 0, ''), [])

    def test_persistence_rejects_missing_or_inconsistent_stages(self):
        for mutation in ['object', 'stage', 'pose', 'collision', 'gate', 'arc', 'image', 'extra']:
            with self.subTest(mutation=mutation):
                report = persistence_fixture(); p = report['persistence']
                if mutation == 'object': del p['observations'][2]['objects']['crate']
                if mutation == 'stage': p['observations'].pop(2)
                if mutation == 'pose': p['observations'][3]['objects']['sentinel_1']['position'][0] += 1
                if mutation == 'collision': p['observations'][3]['objects']['crate']['collision'] = 1
                if mutation == 'gate': p['observations'][3]['gate_y'] = 0
                if mutation == 'arc': p['observations'][3]['objects']['arc']['disabled'] = False
                if mutation == 'image': p['images'].pop()
                if mutation == 'extra': p['invented'] = True
                self.assertTrue(validate_result(report, 0, ''))

    def test_persistence_rejects_teleports_fixed_camera_or_fake_revisit(self):
        for mutation in ['jump', 'frozen', 'visit', 'epoch', 'spawn_death']:
            with self.subTest(mutation=mutation):
                report = persistence_fixture(); p = report['persistence']
                if mutation == 'jump': p['movement'][5][1] += 100
                if mutation == 'frozen':
                    for row in p['movement']: row[1:4] = [0, 0, 7]
                if mutation == 'visit': p['visits'][3]['sample'] = p['visits'][0]['sample']
                if mutation == 'epoch': p['movement'][5][4] = 999
                if mutation == 'spawn_death': p['actions'][1]['position_before'] = p['actions'][1]['spawn']
                self.assertTrue(validate_result(report, 0, ''))

    def test_persistence_rejects_fake_load_effect_or_duplicate_arc(self):
        for key, value in [('before_ids', [3, 2]), ('f5_exit', 1), ('file_absent_before', False),
                           ('casings_after_f5', 0), ('casings_after_f9', 1), ('f9_usec', 2000), ('save_file', '../save.json')]:
            with self.subTest(key=key):
                report = persistence_fixture(); report['persistence']['save_load'][key] = value
                self.assertTrue(validate_result(report, 0, ''))
        report = persistence_fixture(); report['persistence']['save_load']['restored']['ammo'] += 1
        self.assertTrue(validate_result(report, 0, ''))
        report = persistence_fixture(); report['persistence']['arc_repeat']['disabled_signals'] = 1
        self.assertTrue(validate_result(report, 0, ''))



class Issue18BoundaryValidation(unittest.TestCase):
    def test_only_saved_Vector3_positions_are_decoded_to_float32(self):
        import struct
        report = persistence_fixture()
        saved = report['persistence']['save_load']['saved']
        restored = report['persistence']['save_load']['restored']
        saved['player_position'][1] = .00094166450435295
        restored['player_position'][1] = struct.unpack('f', struct.pack('f', saved['player_position'][1]))[0]
        self.assertEqual(validate_result(report, 0, ''), [])
        restored['player_position'][1] += .000001
        self.assertTrue(validate_result(report, 0, ''))

    def test_booleans_are_not_health_numbers(self):
        report = persistence_fixture(); report['health'] = True
        self.assertTrue(validate_result(report, 0, ''))
        report = persistence_fixture()
        for label in ['saved', 'restored']: report['persistence']['save_load'][label]['health'] = True
        self.assertTrue(validate_result(report, 0, ''))

    def test_review_counterexamples_are_rejected(self):
        for mutation in ['arc_time', 'unrelated_shot', 'camera', 'same_arc_instance', 'frame_clock', 'unknown_field']:
            with self.subTest(mutation=mutation):
                report = terminal_fixture() if mutation == 'frame_clock' else persistence_fixture()
                if mutation == 'arc_time': report['persistence']['arc_repeat']['shot']['usec'] = 300
                if mutation == 'unrelated_shot':
                    for key in ['impact', 'ray_from', 'ray_to', 'target_position']: report['persistence']['actions'][0]['shot'][key][0] += 100
                if mutation == 'camera': report['persistence']['images'][-1]['camera_position'] = [9000,9000,9000]
                if mutation == 'same_arc_instance': report['persistence']['arc_repeat']['shot']['target_before'] = report['persistence']['actions'][2]['shot']['target_before']
                if mutation == 'frame_clock':
                    for row in report['perf_flashlight_samples']: row['usec'] = 1
                if mutation == 'unknown_field': report['invented'] = True
                self.assertTrue(validate_result(report, 0, ''))

    def test_arc_changed_snapshot_and_all_transients_are_observed(self):
        report = persistence_fixture(); report['persistence']['arc_repeat']['changed_snapshots'][0]['ammo'] -= 1
        self.assertTrue(validate_result(report, 0, ''))
        report = persistence_fixture(); report['persistence']['arc_repeat']['changed_snapshots'] = []
        self.assertTrue(validate_result(report, 0, ''))
        for stage in ['before_warmup', 'before_measure']:
            for field in ['impact', 'muzzle', 'beam', 'light', 'remaining']:
                report = terminal_fixture(); report['terminal'][stage]['effects'][field] = 1 if field == 'remaining' else True
                self.assertTrue(validate_result(report, 0, '', flashlight_requested=True))

    def test_nonfinite_snapshot_value_is_rejected(self):
        report = persistence_fixture()
        report['persistence']['save_load']['saved']['elapsed'] = float('nan')
        self.assertTrue(validate_result(report, 0, ''))

    def test_arc_repetition_allows_only_exact_energy_notification(self):
        report = persistence_fixture()
        report['persistence']['arc_repeat']['shot']['energy_after'] = 99
        self.assertTrue(validate_result(report, 0, ''))
        report = persistence_fixture(); report['persistence']['arc_repeat']['changed_signals'] = 0
        self.assertTrue(validate_result(report, 0, ''))
        report = persistence_fixture(); report['persistence']['arc_repeat']['facts_after'].append('extra')
        self.assertTrue(validate_result(report, 0, ''))

    def test_terminal_request_is_compared_to_observed_scene(self):
        self.assertTrue(validate_result(terminal_fixture(), 0, '', terminal_variant='reference'))
        self.assertTrue(validate_result(perf_flashlight_fixture(), 0, '', terminal_variant='candidate'))

    def test_artifacts_require_real_contained_png_and_exact_save(self):
        import tempfile, json, hashlib, struct, zlib
        def chunk(kind, data):
            return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind+data))
        png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 1280, 720, 8, 2, 0, 0, 0))
        png += chunk(b'IDAT', zlib.compress((b'\0' + b'\0' * (1280*3)) * 720)) + chunk(b'IEND', b'')
        with tempfile.TemporaryDirectory(dir=Path(__file__).resolve().parents[1] / 'proof-tool-tests') as directory:
            output = Path(directory); report = persistence_fixture()
            data = json.dumps(report['persistence']['save_load']['saved']).encode()
            (output/'save.json').write_bytes(data)
            save = report['persistence']['save_load']; save['save_bytes'] = len(data); save['save_sha256'] = hashlib.sha256(data).hexdigest()
            for image in report['persistence']['images']: (output/image['file']).write_bytes(png)
            self.assertEqual(validate_artifacts(report, output), [])
            first = output/report['persistence']['images'][0]['file']
            first.unlink(); self.assertTrue(validate_artifacts(report, output)); first.write_bytes(png)
            first.write_bytes(png[:8]); self.assertTrue(validate_artifacts(report, output)); first.write_bytes(png)
            (output/'save.json').write_bytes(data+b' '); self.assertTrue(validate_artifacts(report, output))
            (output/'save.json').write_bytes(data)
            report['persistence']['images'][0]['file'] = '../outside.png'
            self.assertTrue(validate_artifacts(report, output))


if __name__ == '__main__':
    unittest.main()
