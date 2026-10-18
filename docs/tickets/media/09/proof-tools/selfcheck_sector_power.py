import unittest
import copy
from prove_sector_power import validate_result, LIGHT_IDS


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
        windows.append({'label': label, 'frames_drawn': 61, 'intervals_ms': [100] * 60, 'observation_after': after})
        rows.append(row)
    return report | {'mode': 'lighting-perf', 'lighting_samples': rows, 'cost_windows': windows}

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


if __name__ == '__main__':
    unittest.main()
